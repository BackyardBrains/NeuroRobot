//
//  VideoAndAudioObtainer.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef VideoAndAudioObtainer_h
#define VideoAndAudioObtainer_h


#include "BackgroundThread.h"
#include "Macros.h"
#include "SharedMemory.h"
#include "Log.h"

#ifdef MATLAB
    #include "TypeDefs.h"
#else
    #include "Bridge/TypeDefs.h"
#endif

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
 Reads video and audio data from NeuroRobotManager and saves data to shared memory
 */
class VideoAndAudioObtainer : public BackgroundThread, public Log {
    
private:
    
    AVFormatContext* formatCtx = NULL;
    AVPacket packet;
    AVFrame* frame = NULL;
    
    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
    AVCodecContext* videoCodecCtx = NULL;
    AVCodec* videoCodec = NULL;
    AVFrame* pictureRgb = NULL;
    struct SwsContext* imgConvertCtx = NULL;
    int videoStreamIndex = -1;
    uint8_t* frameRawData[8];
    // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
    
    
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    AVCodecContext* audioDecCtx = NULL;
    AVCodec* audioCodec = NULL;
    int audioStreamIndex = -1;
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    
    SharedMemory* sharedMemoryInstance;
    
    bool tryingToReconnect = false;
    bool audioBlocked = false;
    std::string url = std::string();
    int frameSize = 0;
    
    void closeStream();
    
    //----------------------------------
    // Rest of the methods.
    int decode(AVCodecContext* avctx, AVFrame* frame, int* got_frame, AVPacket* pkt);
    void updateState(StreamStateType *stateToReturn, StreamStateType stateType, int errorInt);
    void reset(StreamStateType *error);
    
    StreamErrorOccurredCallback errorCallback;
public:
    
    
    
    //-----------------------------------
    // Init methods.
    VideoAndAudioObtainer(SharedMemory* sharedMemory, std::string ipAddress, StreamStateType *state, StreamErrorOccurredCallback callback, bool audioBlocked);
    
    /**
    Overloaded method which is running from separate thread.
    */
    void run();
    
    StreamStateType stateType = StreamStateNotInitialized;
};


#endif /* VideoAndAudioObtainer_h */
