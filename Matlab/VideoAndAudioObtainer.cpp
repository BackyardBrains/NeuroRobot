//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "VideoAndAudioObtainer.h"

#include <iostream>
#include <thread>
//#include <boost/thread/thread.hpp>

static std::chrono::system_clock::time_point beginTime;
static bool initDone;
static int interrupt_cb(void* ctx)
{
    std::cout << "init >>> entered interrupt_cb" << std::endl;

    if (!initDone) {
        long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
        std::cout << "init >>> elapsed time [ms]: " << elapsedTime << std::endl;
        if (elapsedTime > 5000) {
            return 1;
        }
    }
    return 0;
}

VideoAndAudioObtainer::VideoAndAudioObtainer(SharedMemory* sharedMemory, std::string ipAddress, StreamStateType *error, ErrorOccurredCallback callback)
{
    className = "VideoAndAudioObtainer";
    sharedMemoryInstance = sharedMemory;
    this->errorCallback = callback;
    this->ipAddress = ipAddress;
    openStreams();
    reset(error);
}

void VideoAndAudioObtainer::reset(StreamStateType *error)
{
    int retVal = -1;
    
    sharedMemoryInstance->unblockWritters();

    format_ctx = avformat_alloc_context();
    frame = av_frame_alloc();
    picture_rgb = av_frame_alloc();

    /// Register everything
    avformat_network_init();

    /// Open RTSP
    std::string url = std::string();
    // rtsp://admin:admin@192.168.100.1:554/cam1/h264
    url.append("rtsp://admin:admin@");
    url.append(this->ipAddress);
    url.append(":554/cam1/h264");
    
    int dictSetRet = 0;
    AVDictionary* stream_opts = 0;
    dictSetRet = av_dict_set(&stream_opts, "rtp", "write_to_source", 0);
    dictSetRet = av_dict_set_int(&stream_opts, "stimeout", (int64_t)5, 0); // timeout while connecting, 5sec
    
    beginTime = std::chrono::system_clock::now();
    initDone = false;

    AVIOInterruptCB int_cb = { interrupt_cb, &format_ctx };
    format_ctx->interrupt_callback = int_cb;

    openInput = avformat_open_input(&format_ctx, url.c_str(), NULL, &stream_opts);

    if (openInput != 0) {
        errorOccurred(error, StreamErrorAvformatOpenInput, openInput);
        return;
    }

    retVal = avformat_find_stream_info(format_ctx, NULL);
    if (retVal < 0) {
        errorOccurred(error, StreamErrorAvformatFindStreamInfo, retVal);
        return;
    }

    /// Search for video and audio stream index
    for (int i = 0; i < format_ctx->nb_streams; i++) {
        if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
        } else if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audio_stream_index = i;
        }
    }

    packet.data = NULL;
    packet.size = 0;

    av_read_play(format_ctx);
    logMessage("av_read_play completed");

    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
    /// Get the codec
    videoCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!videoCodec) {
        errorOccurred(error, StreamErrorAvcodecFindDecoderVideo, -1);
        return;
    }

    videoCodec_ctx = avcodec_alloc_context3(videoCodec);

    retVal = avcodec_parameters_to_context(videoCodec_ctx, format_ctx->streams[video_stream_index]->codecpar);
    if (retVal < 0) {
        errorOccurred(error, StreamErrorAvcodecParametersToContextVideo, retVal);
        return;
    }

    retVal = avcodec_open2(videoCodec_ctx, videoCodec, NULL);
    if (retVal < 0) {
        errorOccurred(error, StreamErrorAvcodecOpen2Video, retVal);
        return;
    }

    int size2 = av_image_get_buffer_size(AV_PIX_FMT_BGR24, videoCodec_ctx->width, videoCodec_ctx->height, 1);
    
    logMessage("reset >> width: " + std::to_string(videoCodec_ctx->width));
    logMessage("reset >> height: " + std::to_string(videoCodec_ctx->height));
    
    
    uint8_t* picture_buffer = (uint8_t*)(av_malloc(size2));
    av_image_fill_arrays(picture_rgb->data, picture_rgb->linesize,
        picture_buffer, AV_PIX_FMT_BGR24,
        videoCodec_ctx->width, videoCodec_ctx->height, 1);
    av_free(picture_buffer);

    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<

    
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<

    
    logMessage("reset >> codec id: " + std::to_string(format_ctx->streams[audio_stream_index]->codecpar->codec_id));
//    audioCodec = avcodec_find_decoder(AV_CODEC_ID_PCM_ALAW);
    audioCodec = avcodec_find_decoder(format_ctx->streams[audio_stream_index]->codecpar->codec_id);
    if (!audioCodec) {
        errorOccurred(error, StreamErrorAvcodecFindDecoderAudio, -1);
        return;
    }
    // Add this to allocate the context by codec
    audio_dec_ctx = avcodec_alloc_context3(audioCodec);
    retVal = avcodec_parameters_to_context(audio_dec_ctx, format_ctx->streams[audio_stream_index]->codecpar);
    if (retVal < 0) {
        errorOccurred(error, StreamErrorAvcodecParametersToContextAudio, retVal);
        return;
    }

    retVal = avcodec_open2(audio_dec_ctx, audioCodec, NULL);
    if (retVal < 0) {
        errorOccurred(error, StreamErrorAvcodecOpen2Audio, retVal);
        return;
    }

    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    
    if (tryingToReconnect) {
        tryingToReconnect = false;
        startThreaded();
    }
    
    if (error) {
        *error = state;
    }
    
    initDone = true;
    logMessage("init >>> done");
}

void VideoAndAudioObtainer::errorOccurred(StreamStateType *errorToReturn, StreamStateType errorType, int errorInt)
{
    state = errorType;
    
    char buf[256];
    if (errorInt != -1) {
        av_strerror(errorInt, buf, sizeof(buf));
    }
    
    logMessage("init >>> not succeeded '" + std::to_string(errorType) + "' (@see StreamStateType in TypeDefs.h for details) >>> " + std::string(buf));
    if (errorCallback) {
        errorCallback(errorType);
    }
    
    if (!tryingToReconnect && errorToReturn) {
        *errorToReturn = errorType;
    }
}

// MARK:- Overloaded methods
void VideoAndAudioObtainer::run()
{
    if (state == StreamNotStarted) {
        state = StreamErrorNone;
    }
    if (openInput != 0) {
        errorOccurred(NULL, StreamErrorAvformatOpenInput, openInput);
        return;
    }

    uint8_t* rgb_data[8];
    int avReadFrameResponse = av_read_frame(format_ctx, &packet);

    logMessage("run >>> av_read_frame completed");
    
    for (int i = 0; i < 1; i++) {
        rgb_data[i] = (uint8_t*)malloc(6220800);
        
        logMessage("run >>> rgb_data initialized");
    }
    
//    avio_open(&format_ctx->pb, NULL, AVIO_FLAG_WRITE);
//
//    int dictSetRet = 0;
//    AVDictionary* stream_opts = 0;
//    dictSetRet = av_dict_set(&stream_opts, "rtp", "write_to_source", 0);
//    dictSetRet = av_dict_set_int(&stream_opts, "stimeout", (int64_t)5, 0);
//    dictSetRet = av_dict_set(&stream_opts, "rtpflags", "send_bye", 0);
//    avformat_write_header(format_ctx, &stream_opts);

    while (avReadFrameResponse >= 0 && isRunning()) {

        if (packet.stream_index == video_stream_index) {
            /// decode video packet
            logMessage("run >>> video packet");
            int check = 0;

            decode(videoCodec_ctx, frame, &check, &packet);
            logMessage("run >>> decode completed");
            if (check != 0) {
                logMessage("run >>> video >>> check not 0");
                
                img_convert_ctx = sws_getCachedContext(
                    img_convert_ctx, videoCodec_ctx->width, videoCodec_ctx->height,
                    videoCodec_ctx->pix_fmt, videoCodec_ctx->width,
                    videoCodec_ctx->height, AV_PIX_FMT_BGR24, SWS_BICUBIC, NULL, NULL,
                    NULL);
                logMessage("run >>> video >>> sws_getCachedContext converted");
                sws_scale(img_convert_ctx, frame->data, frame->linesize, 0,
                    videoCodec_ctx->height, rgb_data, picture_rgb->linesize);
                logMessage("run >>> video >>> sws_scale converted");
                
                logMessage("run >>> video >>> width: " + std::to_string(picture_rgb->width));
                logMessage("run >>> video >>> height: " + std::to_string(picture_rgb->height));
                logMessage("run >>> video >>> linesize[0]: " + std::to_string(picture_rgb->linesize[0]));
                
                sharedMemoryInstance->frameSize = videoCodec_ctx->width * videoCodec_ctx->height * 3;
                logMessage("run >>> video >>> frameSize: " + std::to_string(sharedMemoryInstance->frameSize));
                
                sharedMemoryInstance->writeFrame(rgb_data[0]);
                logMessage("run >>> video >>> frame copy completed");
            }
        } else if (packet.stream_index == audio_stream_index) {
            /// decode audio packet
            logMessage("run >>> audio packet");
            int ret = 0;

            int decoded = packet.size;
            logMessage("run >>> audio >>> packet size: " + std::to_string(packet.size));
            
            avcodec_send_packet(audio_dec_ctx, &packet);
            logMessage("run >>> audio >>> avcodec_send_packet completed");
            ret = avcodec_receive_frame(audio_dec_ctx, frame);
            logMessage("run >>> audio >>> avcodec_receive_frame completed");
            if (ret < 0) {
                break;
            }
            logMessage("run >>> audio >>> ret greater than 0");
            decoded = FFMIN(ret, packet.size);
            logMessage("run >>> audio >>> FFMIN: " + std::to_string(decoded));
            if (ret == 0) {
                logMessage("run >>> audio >>> ret = 0");
                sharedMemoryInstance->audioSize = frame->nb_samples;
                logMessage("run >>> audio >>> changed size to: " + std::to_string(frame->nb_samples));
                logMessage("run >>> audio >>> frame->nb_samples: " + std::to_string(frame->nb_samples));
                logMessage("run >>> audio >>> frame->sample_rate: " + std::to_string(frame->sample_rate));
                readAudioSampleRate = frame->sample_rate;
                sharedMemoryInstance->writeAudio(frame->extended_data[0]);
                logMessage("run >>> audio >>> audio written");
            }
        }
        av_packet_unref(&packet);
        logMessage("run >>> av_packet_unref completed");

        avReadFrameResponse = av_read_frame(format_ctx, &packet);
        logMessage("run >>> av_read_frame completed");
    }
    free(rgb_data[0]);
    logMessage("run >>> free(rgb_data[0]) completed");
    
    logMessage("End of run()");
//    if (avReadFrameResponse < 0 && isRunning()) {
//        char buf[256];
//        av_strerror(avReadFrameResponse, buf, sizeof(buf));
//        logMessage("End of run error' >>> " + std::string(buf));
//
//
//        
//        tryingToReconnect = true;
//
//        av_packet_unref(&packet);
//        av_free(frame);
//        av_free(picture_rgb);
//        avcodec_close(videoCodec_ctx);
//        sws_freeContext(img_convert_ctx);
//        avformat_close_input(&format_ctx);
//
//        reset(NULL);
//        return;
//    }

    //         avformat_close_input(&format_ctx);
    
    freeAllObjects();
}

// MARK:- Rest of the methods
int VideoAndAudioObtainer::decode(AVCodecContext* avctx, AVFrame* frame, int* got_frame, AVPacket* pkt)
{
    int ret;

    *got_frame = 0;

    if (pkt) {
        ret = avcodec_send_packet(avctx, pkt);
        // In particular, we don't expect AVERROR(EAGAIN), because we read all
        // decoded frames with avcodec_receive_frame() until done.
        if (ret < 0)
            return ret == AVERROR_EOF ? 0 : ret;
    }

    ret = avcodec_receive_frame(avctx, frame);

    if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF)
        return ret;
    if (ret >= 0)
        *got_frame = 1;

    return 0;
}

void VideoAndAudioObtainer::freeAllObjects()
{
    stop();
    sharedMemoryInstance->blockWritters();
    logMessage("freeAllObjects >>> entered");

    try {
        av_packet_unref(&packet);
        logMessage("freeAllObjects >>> av_packet_unref");
        av_free(frame);
        logMessage("freeAllObjects >>> av_free(frame);");
        av_free(picture_rgb);
        logMessage("freeAllObjects >>> av_free(picture_rgb);");
        avcodec_close(videoCodec_ctx);
        logMessage("freeAllObjects >>> avcodec_close(videoCodec_ctx);");
        sws_freeContext(img_convert_ctx);
        logMessage("freeAllObjects >>> sws_freeContext(img_convert_ctx);");
        avformat_close_input(&format_ctx);
        logMessage("freeAllObjects >>> avformat_close_input(&format_ctx);");

    } catch (...) {

        logMessage("freeAllObjects >>> catched error");
    }
    
//    boost::this_thread::sleep_for(boost::chrono::milliseconds(1020));

    closeStreams();
    format_ctx = NULL;
    videoCodec_ctx = NULL;
    openInput = -1;
}
