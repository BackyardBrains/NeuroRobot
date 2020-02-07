//
//  TypeDefs.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 9/28/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef TypeDefs_h
#define TypeDefs_h

#include <stdio.h>

typedef enum : int {
    SocketStateNotInitialized = 0,
    SocketStateConnecting,
    SocketStateConnected,
    
    SocketErrorCannotConnect = 100,
    SocketErrorEOF,
    SocketErrorLostConnection,
    SocketErrorWhileSending,
    SocketErrorExists,
    SocketErrorCannotCancelDataSocket,
    SocketErrorCannotCancelAudioSocket,
    SocketErrorCannotCloseDataSocket,
    SocketErrorCannotCloseAudioSocket
} SocketStateType;
typedef void (*SocketErrorOccurredCallback) (SocketStateType error);

typedef enum : int {
    StreamStateNotInitialized = 0,
    StreamStateNotStarted,
    StreamStateRunning,
    
    StreamErrorNotConnected = 100,
    StreamErrorTimeOutWhileReceivingFrame,
    StreamErrorAvformatOpenInput,
    StreamErrorAvformatFindStreamInfo,
    StreamErrorAvcodecFindDecoderVideo,
    StreamErrorAvcodecParametersToContextVideo,
    StreamErrorAvcodecOpen2Video,
    StreamErrorAvcodecFindDecoderAudio,
    StreamErrorAvcodecParametersToContextAudio,
    StreamErrorAvcodecOpen2Audio,
    StreamErrorAvcodecFrameSize,
    
} StreamStateType;
typedef void (*StreamErrorOccurredCallback) (StreamStateType error);

static char* getSocketStateMessage(SocketStateType type)
{
    static char retVal[255];
    switch(type) {
        case SocketStateNotInitialized: {
            sprintf(retVal, "Socket state: not initialized");
            break;
        }
        case SocketStateConnected: {
            sprintf(retVal, "Socket state: connected");
            break;
        }
        case SocketStateConnecting: {
            sprintf(retVal, "Socket state: connecting");
            break;
        }
        case SocketErrorCannotConnect: {
            sprintf(retVal, "Socket error: cannot connect");
            break;
        }
        case SocketErrorEOF: {
            sprintf(retVal, "Socket error: End of file");
            break;
        }
        case SocketErrorLostConnection: {
            sprintf(retVal, "Socket error: lost connection");
            break;
        }
        case SocketErrorWhileSending: {
            sprintf(retVal, "Socket error: error occurred while sending");
            break;
        }
        case SocketErrorExists: {
            sprintf(retVal, "Socket error: exists");
            break;
        }
        case SocketErrorCannotCancelDataSocket: {
            sprintf(retVal, "Socket error: cannot cancel data socket");
            break;
        }
        case SocketErrorCannotCancelAudioSocket: {
            sprintf(retVal, "Socket error: cannot cancel audio socket");
            break;
        }
        case SocketErrorCannotCloseDataSocket: {
            sprintf(retVal, "Socket error: cannot close data socket");
            break;
        }
        case SocketErrorCannotCloseAudioSocket: {
            sprintf(retVal, "Socket error: cannot close audio socket");
            break;
        }
    }
    return retVal;
}

const static char* getStreamStateMessage(StreamStateType type)
{
    static char retVal[255];
    switch(type) {
        case StreamStateNotInitialized:
            sprintf(retVal, "Stream not initialized");
            break;
        case StreamStateNotStarted:
            sprintf(retVal, "Stream not started");
            break;
        case StreamStateRunning:
            sprintf(retVal, "Stream error: none");
            break;
        case StreamErrorNotConnected:
            sprintf(retVal, "Stream error: not connected");
            break;
        case StreamErrorTimeOutWhileReceivingFrame:
            sprintf(retVal, "Stream error: time out while receiving frame");
            break;
        case StreamErrorAvformatOpenInput:
            sprintf(retVal, "Stream error: avformat open input");
            break;
        case StreamErrorAvformatFindStreamInfo:
            sprintf(retVal, "Stream error: avformat find stream info");
            break;
        case StreamErrorAvcodecFindDecoderVideo:
            sprintf(retVal, "Stream error: avcodec find decoder for video");
            break;
        case StreamErrorAvcodecParametersToContextVideo:
            sprintf(retVal, "Stream error: avcodec parameters to context for video");
            break;
        case StreamErrorAvcodecOpen2Video:
            sprintf(retVal, "Stream error: avcodec open2 for video");
            break;
        case StreamErrorAvcodecFindDecoderAudio:
            sprintf(retVal, "Stream error: avcodec find decoder for audio");
            break;
        case StreamErrorAvcodecParametersToContextAudio:
            sprintf(retVal, "Stream error avcodec parameters to context for audio");
            break;
        case StreamErrorAvcodecOpen2Audio:
            sprintf(retVal, "Stream error avcodec open2 for audio");
            break;
        case StreamErrorAvcodecFrameSize:
            sprintf(retVal, "Stream error not obtained frame size from FFMPEG funciton");
            break;
            
    }
    return retVal;
}

#endif /* TypeDefs_h */
