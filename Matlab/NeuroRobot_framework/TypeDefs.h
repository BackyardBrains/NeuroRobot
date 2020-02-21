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
    SocketStateEOF,
    
    SocketErrorCannotConnect = 100,
    SocketErrorLostConnection,
    SocketErrorWhileSending,
    SocketErrorConnectingAudioSocket,
    
    SocketInfoCannotCancelDataSocket = 200,
    SocketInfoCannotCancelAudioSocket,
    SocketInfoCannotCloseDataSocket,
    SocketInfoCannotCloseAudioSocket
} SocketStateType;
typedef void (*SocketErrorOccurredCallback) (SocketStateType error);

typedef enum : int {
    StreamStateNotInitialized = 0,
    StreamStateNotStarted,
    StreamStateRunning,
    StreamStateTimeOutWhileReceivingFrame,
    
    StreamErrorNotConnected = 100,
    StreamErrorAvformatOpenInput,
    StreamErrorAvformatFindStreamInfo,
    StreamErrorAvcodecFindDecoderVideo,
    StreamErrorAvcodecParametersToContextVideo,
    StreamErrorAvcodecOpen2Video,
    StreamErrorAvcodecFindDecoderAudio,
    StreamErrorAvcodecParametersToContextAudio,
    StreamErrorAvcodecOpen2Audio,
    StreamErrorAvcodecFrameSize,
    StreamErrorCannotReconnect,
    
    StreamInfoReconnecting = 200,
    
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
        case SocketStateEOF: {
            sprintf(retVal, "Socket state: End of file");
            break;
        }
        case SocketErrorCannotConnect: {
            sprintf(retVal, "Socket error: cannot connect");
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
        case SocketErrorConnectingAudioSocket: {
            sprintf(retVal, "Socket error: error while connecting to audio socket");
            break;
        }
        case SocketInfoCannotCancelDataSocket: {
            sprintf(retVal, "Socket info: cannot cancel data socket");
            break;
        }
        case SocketInfoCannotCancelAudioSocket: {
            sprintf(retVal, "Socket info: cannot cancel audio socket");
            break;
        }
        case SocketInfoCannotCloseDataSocket: {
            sprintf(retVal, "Socket info: cannot close data socket");
            break;
        }
        case SocketInfoCannotCloseAudioSocket: {
            sprintf(retVal, "Socket info: cannot close audio socket");
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
            sprintf(retVal, "Stream state: not initialized");
            break;
        case StreamStateNotStarted:
            sprintf(retVal, "Stream state: not started");
            break;
        case StreamStateRunning:
            sprintf(retVal, "Stream state: running");
            break;
        case StreamStateTimeOutWhileReceivingFrame:
            sprintf(retVal, "Stream state: time out while receiving frame");
            break;
        case StreamErrorNotConnected:
            sprintf(retVal, "Stream error: not connected");
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
            sprintf(retVal, "Stream error: avcodec parameters to context for audio");
            break;
        case StreamErrorAvcodecOpen2Audio:
            sprintf(retVal, "Stream error: avcodec open2 for audio");
            break;
        case StreamErrorAvcodecFrameSize:
            sprintf(retVal, "Stream error: Not obtained frame size from FFMPEG funciton");
            break;
        case StreamErrorCannotReconnect:
            sprintf(retVal, "Stream error: Cannot reconnect");
            break;
        case StreamInfoReconnecting:
            sprintf(retVal, "Stream info: Reconnecting");
            break;
    }
    return retVal;
}

#endif /* TypeDefs_h */
