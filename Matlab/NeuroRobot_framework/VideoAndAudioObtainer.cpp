//
//  VideoAndAudioObtainer.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "VideoAndAudioObtainer.h"

#ifdef XCODE
    #include "Bridge/Helpers/StringHelper.hpp"
#else
    #include "Helpers/StringHelper.hpp"
#endif

#include <iostream>
#include <thread>

/// Used for `interruptFunction`.
static std::chrono::system_clock::time_point beginTime;

/// Used to derermine whether is process of reading new packet running.
static bool isReadingNextFrame = false;

/// Used to deremine if initial setup of streamers is done.
static bool initDone = false;

/// Used as maxium ms for connecting.
static long long timeOutWhileConnecting = 5000;

/// Used as maxium ms for obtaining new packet from robot.
static long long timeOutWhileObtainingPacket = 2000;

/// Interrupt function used for determining if some critical point in code are blocking other parts more then expected.
/// @param ctx Pointer to `AVFormatContext`
static int interruptFunction(void* ctx)
{
    if (!initDone) {
        AVFormatContext* formatCtx = (AVFormatContext*) ctx;
        long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
//        std::cout << "init >>> elapsed time [ms]: " << elapsedTime << std::endl;
        if (elapsedTime > timeOutWhileConnecting && formatCtx) {
            return 1;
        }
    } else if (isReadingNextFrame) {
        long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
//        std::cout << "Reading frame >>> elapsed time [ms]: " << elapsedTime << std::endl;
        if (elapsedTime > timeOutWhileObtainingPacket) {
            std::cout << "Continue to reconnection" << std::endl;
            isReadingNextFrame = false;
            return 1;
        }
    }
    return 0;
}

VideoAndAudioObtainer::VideoAndAudioObtainer(std::string ipAddress, StreamErrorOccurredCallback callback, bool audioBlocked)
: Log("VideoAndAudioObtainer")
{
    this->errorCallback = callback;
    this->url = StringHelper::createUrl("admin", "admin", ipAddress);
    this->audioBlocked = audioBlocked;
    logMessage("ip: " + ipAddress);
    setupStreamers();
}

VideoAndAudioObtainer::~VideoAndAudioObtainer()
{
    if (whileLoopIsRunning) {
        semaphore.wait();
    }
    closeStreams();
}

bool VideoAndAudioObtainer::setupStreamers()
{
    logMessage("reset >>> started");
    
    int retVal = -1;
    
    SharedMemory::getInstance()->unblockWritters();

    logMessage("setupStreamers >>> SharedMemory::getInstance()->unblockWritters(); >> ok");
    formatCtx = avformat_alloc_context();
    logMessage("setupStreamers >>> formatCtx = avformat_alloc_context(); >> ok");
    frame = av_frame_alloc();
    logMessage("setupStreamers >>> frame = av_frame_alloc(); >> ok");
    pictureRgb = av_frame_alloc();
    logMessage("setupStreamers >>> pictureRgb = av_frame_alloc(); >> ok");

    /// Register everything
    avformat_network_init();
    logMessage("setupStreamers >>> avformat_network_init(); >> ok");

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
    logMessage("setupStreamers >>> formatCtx->flags >> ok " + std::to_string(formatCtx->flags));
    
    retVal = avformat_open_input(&formatCtx, url.c_str(), NULL, &stream_opts);
    av_dict_free(&stream_opts);
    if (retVal != 0) {
        StreamStateType stateType = StreamErrorAvformatOpenInput;
        if (retVal == AVERROR_EXIT) {
            /// If it's returned by interrupt
            stateType = StreamErrorNotConnected;
        }
        updateState(stateType, retVal);
        return false;
    }
    logMessage("setupStreamers >>> avformat_open_input >> ok");

    retVal = avformat_find_stream_info(formatCtx, NULL);
    if (retVal < 0) { updateState(StreamErrorAvformatFindStreamInfo, retVal); return false; }
    logMessage("setupStreamers >>> avformat_find_stream_info >> ok");

    /// Search for video and audio stream index
    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIndex = i;
        } else if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamIndex = i;
        }
    }

    av_read_play(formatCtx);
    
    if (videoStreamIndex == -1) { logMessage("setupStreamers >>> Cannot find video stream"); }
    setupVideoStreamer();
    
    if (!audioBlocked && audioStreamIndex != -1) {
        setupAudioStreamer();
    } else {
        logMessage("setupStreamers >>> Audio blocked or cannot find audio stream");
    }
    
    stateType = StreamStateNotStarted;
    
    initDone = true;
    logMessage("setupStreamers >>> done");
    
    return true;
}

bool VideoAndAudioObtainer::setupVideoStreamer()
{
    int retVal = -1;
    
    /// Get the codec
    videoCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!videoCodec) { updateState(StreamErrorAvcodecFindDecoderVideo, -1); return false; }
    logMessage("setupVideoStreamer >>> avcodec_find_decoder >> ok");

    videoCodecCtx = avcodec_alloc_context3(videoCodec);

    retVal = avcodec_parameters_to_context(videoCodecCtx, formatCtx->streams[videoStreamIndex]->codecpar);
    if (retVal < 0) { updateState(StreamErrorAvcodecParametersToContextVideo, retVal); return false; }
    logMessage("setupVideoStreamer >>> avcodec_parameters_to_context >> ok");

    retVal = avcodec_open2(videoCodecCtx, videoCodec, NULL);
    if (retVal < 0) { updateState(StreamErrorAvcodecOpen2Video, retVal); return false; }
    logMessage("setupVideoStreamer >>> avcodec_open2 >> ok");
    
    frameSize = av_image_get_buffer_size(AV_PIX_FMT_RGB24, videoCodecCtx->width, videoCodecCtx->height, 1);
    if (frameSize < 0) {
        logMessage("run >>> width: " + std::to_string(videoCodecCtx->width) + " height: " + std::to_string(videoCodecCtx->height));
        updateState(StreamErrorAvcodecFrameSize, frameSize);
        frameSize = 6220800; // 1080 * 1920 * 3
    }
    logMessage("setupVideoStreamer >>> frameSize: " + std::to_string(frameSize));
    
    SharedMemory::getInstance()->frameTotalBytes = frameSize;
    SharedMemory::getInstance()->videoWidth = videoCodecCtx->width;
    SharedMemory::getInstance()->videoHeight = videoCodecCtx->height;
    
    uint8_t* frameBufferFoo = (uint8_t*)(av_malloc(frameSize));
    logMessage("setupVideoStreamer >>> frameBufferFoo malloc >> ok");
    
    av_image_fill_arrays(pictureRgb->data, pictureRgb->linesize, frameBufferFoo, AV_PIX_FMT_RGB24, videoCodecCtx->width, videoCodecCtx->height, 1);
    logMessage("setupVideoStreamer >>> av_image_fill_arrays >> ok");
    
    av_free(frameBufferFoo);
    logMessage("setupVideoStreamer >>> free(frameBufferFoo) >> ok");
    
    frameRawData[0] = new uint8_t[frameSize];
    logMessage("setupVideoStreamer >>> frameRawData >> ok");
    
    return true;
}

bool VideoAndAudioObtainer::setupAudioStreamer()
{
    int retVal = -1;
    
    //    audioCodec = avcodec_find_decoder(AV_CODEC_ID_PCM_ALAW);
    //    RAK5206 -> audio id: AV_CODEC_ID_PCM_ALAW
    //    RAK5270 -> audio id: AV_CODEC_ID_AAC
    audioCodec = avcodec_find_decoder(formatCtx->streams[audioStreamIndex]->codecpar->codec_id);
    if (!audioCodec) { updateState(StreamErrorAvcodecFindDecoderAudio, -1); return false; }
    logMessage("setupAudioStreamers >>> avcodec_find_decoder >> ok >> codec: " + std::to_string(formatCtx->streams[audioStreamIndex]->codecpar->codec_id));
    
    /// Add this to allocate the context by codec
    audioDecCtx = avcodec_alloc_context3(audioCodec);
    retVal = avcodec_parameters_to_context(audioDecCtx, formatCtx->streams[audioStreamIndex]->codecpar);
    if (retVal < 0) { updateState(StreamErrorAvcodecParametersToContextAudio, retVal); return false; }
    logMessage("setupAudioStreamers >>> avcodec_alloc_context3 >> ok");
    
    retVal = avcodec_open2(audioDecCtx, audioCodec, NULL);
    if (retVal < 0) { updateState(StreamErrorAvcodecOpen2Audio, retVal); return false; }
    logMessage("setupAudioStreamers >>> avcodec_open2 >> ok");
    
    return true;
}

void VideoAndAudioObtainer::run()
{
    logMessage("run >>> started");
    
    if (stateType == StreamStateNotStarted) {
        stateType = StreamStateRunning;
    }
    
    if (stateType != StreamStateRunning) {
        updateState(stateType, -1);
        stop();
        closeStreams();
        return;
    }
    
    SharedMemory::getInstance()->unblockWritters();
    isReadingNextFrame = true;
    
    /// Load first packet before while loop and every next we are reading at the end of while loop.
    /// This mechanism is used to take adventage of `interruptFunction` and break reading of frame if it exceeds time limit.
    int avReadFrameResponse = av_read_frame(formatCtx, &packet);
    
    whileLoopIsRunning = true;
    while (avReadFrameResponse >= 0 && isRunning()) {
        isReadingNextFrame = false;
        
        if (packet.stream_index == videoStreamIndex) {
            /// decode video packet
            logMessage("run >>> video packet");
            processVideoPacket(packet);
            
        } else if (packet.stream_index == audioStreamIndex && !audioBlocked) {
            /// decode audio packet
            logMessage("run >>> audio packet");
            processAudioPacket(packet);
        }
        logMessage("run >>> packet processing finished");
        
        av_packet_unref(&packet);
        logMessage("run >>> av_packet_unref(&packet);");
        
        /// Start measuring time for reading frame, to take action if it exceeds limit. @See interruptFunction function.
        beginTime = std::chrono::system_clock::now();
        isReadingNextFrame = true;
        avReadFrameResponse = av_read_frame(formatCtx, &packet);
        logMessage("run >>> avReadFrameResponse = av_read_frame(formatCtx, &packet);");
    }
    whileLoopIsRunning = false;
    long long elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
    
    logMessage("run >>> End of run()");
    
    closeStreams();
    
    if (avReadFrameResponse < 0 && isRunning()) {
        /// Error occurred
        updateState(StreamStateTimeOutWhileReceivingFrame, avReadFrameResponse);
        
        logMessage("run >>> End of run error >>> reading time: " + std::to_string(elapsedTime) + " >>> trying to reconnect");
        
        if (setupStreamers()) {
            logMessage("run >>> Trying to reconnect >>> reset done");
            
            std::thread processThread(&VideoAndAudioObtainer::run, this);
            processThread.detach();
            
//            run();
        } else {
            /// Cannot recover connection
            updateState(StreamErrorCannotReconnect, -1);
            stop();
            closeStreams();
        }
    } else {
        /// Stop called
        stop();
        semaphore.signal();
    }
}

void VideoAndAudioObtainer::processVideoPacket(AVPacket packet_)
{
    int check = 0;

    decode(videoCodecCtx, frame, &check, &packet_);

    if (check != 0) {
        imgConvertCtx = sws_getCachedContext(imgConvertCtx, videoCodecCtx->width, videoCodecCtx->height, videoCodecCtx->pix_fmt, videoCodecCtx->width, videoCodecCtx->height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
        sws_scale(imgConvertCtx, frame->data, frame->linesize, 0, videoCodecCtx->height, frameRawData, pictureRgb->linesize);
    
        SharedMemory::getInstance()->writeFrame(frameRawData[0], frameSize);
    } else {
        logMessage("processVideoPacket >>> Error with decoding video packet");
    }
}

void VideoAndAudioObtainer::processAudioPacket(AVPacket packet_)
{
    int check = 0;

    decode(audioDecCtx, frame, &check, &packet_);
    
    logMessage("processAudioPacket >>> frame->nb_samples: " + std::to_string(frame->nb_samples));
    logMessage("processAudioPacket >>> frame->sample_rate: " + std::to_string(frame->sample_rate));
    logMessage("processAudioPacket >>> frame->linesize[0]: " + std::to_string(frame->linesize[0]));
    logMessage("processAudioPacket >>> frame->pkt_size: " + std::to_string(frame->pkt_size));
    logMessage("processAudioPacket >>> frame->channels: " + std::to_string(frame->channels));
    
    SharedMemory::getInstance()->audioSampleRate = frame->sample_rate;
    if (check != 0) {
        unsigned short bytesPerSample = (unsigned short)av_get_bytes_per_sample(AVSampleFormat(frame->format));
        SharedMemory::getInstance()->writeAudio(frame->extended_data[0], (size_t)frame->nb_samples, bytesPerSample);
        
        logMessage("processAudioPacket >>> bytesPerSample: " + std::to_string(bytesPerSample));
    } else {
        logMessage("processAudioPacket >>> Error with decoding audio packet");
    }
}

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

void VideoAndAudioObtainer::closeStreams()
{
    if (stateType == StreamStateStopped) { return; }
    updateState(StreamStateStopped, -1);
    
    logMessage("closeStreams >>> entered");
    SharedMemory::getInstance()->blockWritters();
    
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
    
    logMessage("closeStreams >>> finished");
}

void VideoAndAudioObtainer::updateState(StreamStateType stateType_, int errorCode)
{
    stateType = stateType_;
    
    char buf[256] = "";
    if (errorCode != -1) {
        av_strerror(errorCode, buf, sizeof(buf));
    }
    
    logMessage("updateState >>> state: '" + std::string(getStreamStateMessage(stateType)) + "' >>> " + std::string(buf));
    if (errorCallback && stateType >= 100) {
        errorCallback(stateType);
    }
}
