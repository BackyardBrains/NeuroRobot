//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "VideoAndAudioObtainer.h"

#include <iostream>
#include <thread>

static std::string createUrl(std::string userName, std::string password, std::string ipAddress);
static std::chrono::system_clock::time_point beginTime;
static bool isReadingNextFrame = false;
static bool initDone = false;

static long long timeOutWhileConnecting = 3000;

static int interruptFunction(void* ctx)
{
    AVFormatContext* formatCtx = (AVFormatContext*) ctx;
    std::cout << "init >>> entered interruptFunction" << std::endl;

    if (!initDone) {
        long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
        std::cout << "init >>> elapsed time [ms]: " << elapsedTime << std::endl;
        if (elapsedTime > timeOutWhileConnecting && formatCtx) {
            // TODO: Test in Matlab under Windows.
            return 1;
        }
    } else if (isReadingNextFrame) {
        long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
        std::cout << "Reading frame >>> elapsed time [ms]: " << elapsedTime << std::endl;
        if (elapsedTime > 1000) {
            std::cout << "Continue to reconnection" << std::endl;
            isReadingNextFrame = false;
            return 1;
        }
    }
    return 0;
}

VideoAndAudioObtainer::VideoAndAudioObtainer(std::string ipAddress, StreamStateType *stateType_, StreamErrorOccurredCallback callback, bool audioBlocked)
{
    className = "VideoAndAudioObtainer";
    this->errorCallback = callback;
    this->url = createUrl("admin", "admin", ipAddress);
    this->audioBlocked = audioBlocked;
    openLogFile();
    logMessage("ip: " + ipAddress);
    reset(stateType_);
}

void VideoAndAudioObtainer::reset(StreamStateType *stateType_)
{
    logMessage("reset >>> started");
    
    int retVal = -1;
    
    
    SharedMemory::getInstance()->unblockWritters();

    logMessage("run >>> SharedMemory::getInstance()->unblockWritters(); >> ok");
    formatCtx = avformat_alloc_context();
    logMessage("run >>> formatCtx = avformat_alloc_context(); >> ok");
    frame = av_frame_alloc();
    logMessage("run >>> frame = av_frame_alloc(); >> ok");
    pictureRgb = av_frame_alloc();
    logMessage("run >>> pictureRgb = av_frame_alloc(); >> ok");

    /// Register everything
    avformat_network_init();
    logMessage("run >>> avformat_network_init(); >> ok");

    /// Open RTSP
    AVDictionary* stream_opts = 0;
    av_dict_set(&stream_opts, "rtp", "write_to_source", 0);
    
    /// Reset time for interrupt
    beginTime = std::chrono::system_clock::now();
    initDone = false;
    
    AVIOInterruptCB int_cb = { interruptFunction, &formatCtx };
    formatCtx->interrupt_callback = int_cb;
    
    /// Set flag because 16 is flag indicates to send bye packets while closing stream
    formatCtx->flags = formatCtx->flags | 16;
    logMessage("run >>> formatCtx->flags >> ok " + std::to_string(formatCtx->flags));
    
    retVal = avformat_open_input(&formatCtx, url.c_str(), NULL, &stream_opts);
    av_dict_free(&stream_opts);
    if (retVal != 0) {
        StreamStateType stateType = StreamErrorAvformatOpenInput;
        if (retVal == AVERROR_EXIT) {
            /// If it's returned by interrupt
            stateType = StreamErrorNotConnected;
        }
        updateState(stateType_, stateType, retVal);
        return;
    }
    logMessage("run >>> avformat_open_input >> ok");

    retVal = avformat_find_stream_info(formatCtx, NULL);
    if (retVal < 0) {
        updateState(stateType_, StreamErrorAvformatFindStreamInfo, retVal);
        return;
    }
    logMessage("run >>> avformat_find_stream_info >> ok");

    /// Search for video and audio stream index
    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIndex = i;
        } else if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamIndex = i;
        }
    }

    packet.data = NULL;
    packet.size = 0;

    av_read_play(formatCtx);
    
    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
    /// Get the codec
    videoCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!videoCodec) {
        updateState(stateType_, StreamErrorAvcodecFindDecoderVideo, -1);
        return;
    }
    logMessage("run >>> video >>> avcodec_find_decoder >> ok");

    videoCodecCtx = avcodec_alloc_context3(videoCodec);

    retVal = avcodec_parameters_to_context(videoCodecCtx, formatCtx->streams[videoStreamIndex]->codecpar);
    if (retVal < 0) {
        updateState(stateType_, StreamErrorAvcodecParametersToContextVideo, retVal);
        return;
    }
    logMessage("run >>> video >>> avcodec_parameters_to_context >> ok");

    retVal = avcodec_open2(videoCodecCtx, videoCodec, NULL);
    if (retVal < 0) {
        updateState(stateType_, StreamErrorAvcodecOpen2Video, retVal);
        return;
    }
    logMessage("run >>> video >>> avcodec_open2 >> ok");
    
    frameSize = av_image_get_buffer_size(AV_PIX_FMT_RGB24, videoCodecCtx->width, videoCodecCtx->height, 1);
    if (frameSize < 0) {
        logMessage("run >>> width: " + std::to_string(videoCodecCtx->width) + " height: " + std::to_string(videoCodecCtx->height));
        updateState(stateType_, StreamErrorAvcodecFrameSize, frameSize);
        frameSize = 6220800; // 1080 * 1920 * 3
    }
    logMessage("run >>> video >>> frameSize: " + std::to_string(frameSize));
    
    SharedMemory::getInstance()->frameDataCount = frameSize;
    logMessage("run >>> video >>> SharedMemory::getInstance()->frameDataCount: " + std::to_string(SharedMemory::getInstance()->frameDataCount));
    SharedMemory::getInstance()->videoWidth = videoCodecCtx->width;
    logMessage("run >>> video >>> videoCodecCtx->width: " + std::to_string(videoCodecCtx->width));
    SharedMemory::getInstance()->videoHeight = videoCodecCtx->height;
    logMessage("run >>> video >>> videoCodecCtx->height: " + std::to_string(videoCodecCtx->height));
    
    uint8_t* frameBufferFoo = (uint8_t*)(av_malloc(frameSize));
    logMessage("run >>> video >>> frameBufferFoo malloc >> ok");
    
    av_image_fill_arrays(pictureRgb->data, pictureRgb->linesize,
        frameBufferFoo, AV_PIX_FMT_RGB24,
        videoCodecCtx->width, videoCodecCtx->height, 1);
    logMessage("run >>> video >>> av_image_fill_arrays >> ok");
    
    av_free(frameBufferFoo);
    logMessage("run >>> video >>> free(frameBufferFoo) >> ok");
    
    frameRawData[0] = new uint8_t[frameSize];
    logMessage("run >>> video >>> frameRawData >> ok");
    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
    
    if (!audioBlocked && audioStreamIndex != -1) {
        // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
        
        //    audioCodec = avcodec_find_decoder(AV_CODEC_ID_PCM_ALAW);
        //    NeuroRobotManager -> rak id: AV_CODEC_ID_PCM_ALAW
        //    RAK5270 -> rak id: AV_CODEC_ID_AAC
        audioCodec = avcodec_find_decoder(formatCtx->streams[audioStreamIndex]->codecpar->codec_id);
        if (!audioCodec) {
            updateState(stateType_, StreamErrorAvcodecFindDecoderAudio, -1);
            return;
        }
        logMessage("run >>> audio >>> avcodec_find_decoder >> ok >> codec: " + std::to_string(formatCtx->streams[audioStreamIndex]->codecpar->codec_id));
        
        /// Add this to allocate the context by codec
        audioDecCtx = avcodec_alloc_context3(audioCodec);
        retVal = avcodec_parameters_to_context(audioDecCtx, formatCtx->streams[audioStreamIndex]->codecpar);
        if (retVal < 0) {
            updateState(stateType_, StreamErrorAvcodecParametersToContextAudio, retVal);
            return;
        }
        logMessage("run >>> audio >>> avcodec_alloc_context3 >> ok");
        
        retVal = avcodec_open2(audioDecCtx, audioCodec, NULL);
        if (retVal < 0) {
            updateState(stateType_, StreamErrorAvcodecOpen2Audio, retVal);
            return;
        }
        logMessage("run >>> audio >>> avcodec_open2 >> ok");
        // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    }
    
    stateType = StreamStateNotStarted;
    
    if (tryingToReconnect) {
        tryingToReconnect = false;
        
        logMessage("init >>> Trying to reconnect >>> reset done");
        run();
    }
    
    if (stateType_) {
        *stateType_ = stateType;
    }
    
    initDone = true;
    logMessage("init >>> done");
}

void VideoAndAudioObtainer::updateState(StreamStateType *stateToReturn, StreamStateType stateType_, int errorInt)
{
    stateType = stateType_;
    
    char buf[256] = "";
    if (errorInt != -1) {
        av_strerror(errorInt, buf, sizeof(buf));
    }
    
    logMessage("updateState >>> state: '" + std::string(getStreamStateMessage(stateType)) + "' >>> " + std::string(buf));
    if (errorCallback && stateType >= 100) {
        errorCallback(stateType);
    }
    
    if (!tryingToReconnect && stateToReturn) {
        *stateToReturn = stateType;
    }
}

// MARK:- Overloaded methods
void VideoAndAudioObtainer::run()
{
    logMessage("run >>> started");
    
    if (stateType == StreamStateNotStarted) {
        stateType = StreamStateRunning;
    }
    
    if (stateType != StreamStateRunning) {
        updateState(NULL, stateType, -1);
        stop();
        return;
    }
    
    SharedMemory::getInstance()->unblockWritters();
    isReadingNextFrame = true;
    
    int avReadFrameResponse = av_read_frame(formatCtx, &packet);
    
    while (avReadFrameResponse >= 0 && isRunning()) {
        isReadingNextFrame = false;
        
        if (packet.stream_index == videoStreamIndex) {
            /// decode video packet
            logMessage("run >>> video packet");
            int check = 0;

            decode(videoCodecCtx, frame, &check, &packet);

            if (check != 0) {
                imgConvertCtx = sws_getCachedContext(imgConvertCtx, videoCodecCtx->width, videoCodecCtx->height, videoCodecCtx->pix_fmt, videoCodecCtx->width, videoCodecCtx->height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
                sws_scale(imgConvertCtx, frame->data, frame->linesize, 0, videoCodecCtx->height, frameRawData, pictureRgb->linesize);
            
                SharedMemory::getInstance()->writeFrame(frameRawData[0], frameSize);
            } else {
                logMessage("run >>> video packet >>> Error with decoding video packet");
            }
        } else if (packet.stream_index == audioStreamIndex && !audioBlocked) {
            /// decode audio packet-
            logMessage("run >>> audio packet");
            int check = 0;

            decode(audioDecCtx, frame, &check, &packet);
            
            logMessage("run >>> audio >>> frame->nb_samples: " + std::to_string(frame->nb_samples));
            logMessage("run >>> audio >>> frame->sample_rate: " + std::to_string(frame->sample_rate));
            SharedMemory::getInstance()->setAudioSampleRate(frame->sample_rate);
            if (check != 0) {
                SharedMemory::getInstance()->writeAudio(frame->extended_data[0], frame->nb_samples);
            } else {
                logMessage("run >>> audio packet >> Error with decoding audio packet");
            }
        }
        av_packet_unref(&packet);

        /// Start measuring time for reading frame, to take action if it exceeds limit. @See interruptFunction function.
        beginTime = std::chrono::system_clock::now();
        isReadingNextFrame = true;
        avReadFrameResponse = av_read_frame(formatCtx, &packet);
    }
    long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
    
    logMessage("End of run()");
    
    closeStream();
    
    if (avReadFrameResponse < 0 && isRunning()) {
        /// Error occurred
        updateState(NULL, StreamErrorTimeOutWhileReceivingFrame, avReadFrameResponse);
        
        logMessage("End of run error >>> reading time: " + std::to_string(elapsedTime) + " >>> trying to reconnect");
        
        tryingToReconnect = true;
        
        reset(NULL);
        if (stateType != StreamStateNotStarted) {
            /// Cannot recover connection
            stop();
        }
    } else {
        /// Stop called
        stop();
        closeLogFile();
    }
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

void VideoAndAudioObtainer::closeStream()
{
    SharedMemory::getInstance()->blockWritters();

    av_packet_unref(&packet);
    av_frame_free(&frame);
    av_frame_free(&pictureRgb);
    avcodec_close(videoCodecCtx);
    avcodec_close(audioDecCtx);
    avcodec_free_context(&videoCodecCtx);
    avcodec_free_context(&audioDecCtx);
    sws_freeContext(imgConvertCtx);
    avformat_close_input(&formatCtx);
    avformat_network_deinit();
    
    imgConvertCtx = NULL;
}

static std::string createUrl(std::string userName, std::string password, std::string ipAddress)
{
    // rtsp://admin:admin@192.168.100.1:554/cam1/h264
    std::string url = std::string();
    url.append("rtsp://");
    url.append(userName);
    url.append(":");
    url.append(password);
    url.append("@");
    url.append(ipAddress);
    url.append(":554/cam1/h264");
    return url;
}
