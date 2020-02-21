//
//  VideoAndAudioObtainer.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
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

/// FFMPEG includes
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
    
    /// General data
    AVFormatContext* formatCtx = NULL;
    AVPacket packet;
    AVFrame* frame = NULL;
    
    /// Video data
    AVCodecContext* videoCodecCtx = NULL;
    AVCodec* videoCodec = NULL;
    AVFrame* pictureRgb = NULL;
    struct SwsContext* imgConvertCtx = NULL;
    int videoStreamIndex = -1;
    uint8_t* frameRawData[8];
    
    /// Audio data
    AVCodecContext* audioDecCtx = NULL;
    AVCodec* audioCodec = NULL;
    int audioStreamIndex = -1;
    
    bool tryingToReconnect = false;
    bool audioBlocked = false;
    std::string url = std::string();
    int frameSize = 0;
    
    /// Close video and audio stream.
    void closeStreams();
    
    
    int decode(AVCodecContext* avctx, AVFrame* frame, int* got_frame, AVPacket* pkt);
    
    /// Update the state in which object is.
    /// @param stateType Enum of possible state
    /// @param errorCode Error code used to parse occured error if any
    void updateState(StreamStateType stateType, int errorCode);
    
    /// United functions for setup video and audio streamer.
    /// @return Whether is setup succeeded
    bool setupStreamers();
    
    /// Making all setup for video stream.
    /// @return Whether is setup succeeded
    bool setupVideoStreamer();
    
    /// Making all setup for audio stream.
    /// @return Whether is setup succeeded
    bool setupAudioStreamer();
    
    /// Try to decode packet and if succeed save decoded frame to shared memory.
    /// @param packet_ Obtained video packet
    void processVideoPacket(AVPacket packet_);
    
    /// Try to decode packet and if succeed save decoded chunks to shared memory.
    /// @param packet_ Obtained audio packet
    void processAudioPacket(AVPacket packet_);
    
    StreamErrorOccurredCallback errorCallback;
public:
    
    /// Init method.
    /// @param ipAddress IP address of robot
    /// @param callback Callback in case or occured errors. Used to notify caller
    /// @param audioBlocked Flag whether audio both ways is blocked
    VideoAndAudioObtainer(std::string ipAddress, StreamErrorOccurredCallback callback, bool audioBlocked);
    
    /// Destructor.
    ~VideoAndAudioObtainer();
    
    /// Overloaded method which is triggered with `startThreaded()`.
    void run();
    
    /// Current state of the object.
    StreamStateType stateType = StreamStateNotInitialized;
};


#endif /* VideoAndAudioObtainer_h */
