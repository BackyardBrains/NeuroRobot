//
//  VideoAndAudioObtainer.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef VideoAndAudioObtainer_h
#define VideoAndAudioObtainer_h


#include "MexThread.h"
#include "Macros.h"
#include "SharedMemory.h"
#include "Log.h"

//#include <iostream>

//// FFMPEG includes
extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavformat/avformat.h>
    #include <libavformat/avio.h>
    #include <libswscale/swscale.h>
    #include <libavutil/imgutils.h>
}

/**
 Derived class.
 Reads video and audio data from RAK5206 and saves data to shared memory
 */
class VideoAndAudioObtainer : public MexThread, public Log {
    
private:
    AVFormatContext* format_ctx = NULL;
    AVCodecContext* videoCodec_ctx = NULL;
    struct SwsContext* img_convert_ctx = nullptr;
    int video_stream_index = 0;
    int audio_stream_index;
    int openInput = -1;
    
    AVPacket packet;
    AVCodec* videoCodec = NULL;
    AVFrame* picture = NULL;
    AVFrame* picture_rgb = NULL;
    int cnt = 0;
    
    SharedMemory* sharedMemoryInstance;
    
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    AVCodec* audioCodec = NULL;
    AVCodecContext* audio_dec_ctx = NULL;
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    
    std::string ipAddress;
    
    
    void freeAllObjects();
    
    //----------------------------------
    // Rest of the methods.
    int decode(AVCodecContext* avctx, AVFrame* frame, int* got_frame, AVPacket* pkt);
    
    void reset(int *error);
//    static int interrupt_cb(void *ctx);
//    static int interrupt_cb(void *ctx);
//    static std::clock_t startTime;
    
public:
    
    //-----------------------------------
    // Init methods.
    VideoAndAudioObtainer(SharedMemory* sharedMemory, std::string ipAddress, int *error);
    
    //-----------------------------------
    // Overloaded methods.
    void run();
};


#endif /* VideoAndAudioObtainer_h */
