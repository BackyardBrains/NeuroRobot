//
//  TypeDefs.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 9/28/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef TypeDefs_h
#define TypeDefs_h

typedef enum : int {
    SocketNotStarted = 0,
    SocketErrorNone,
    SocketErrorExists,
    SocketErrorLostConnection,
} SocketStateType;

typedef enum : int {
    StreamNotStarted = 0,
    StreamErrorNone,
    StreamErrorAvformatOpenInput,
    StreamErrorAvformatFindStreamInfo,
    StreamErrorAvcodecFindDecoderVideo,
    StreamErrorAvcodecParametersToContextVideo,
    StreamErrorAvcodecOpen2Video,
    StreamErrorAvcodecFindDecoderAudio,
    StreamErrorAvcodecParametersToContextAudio,
    StreamErrorAvcodecOpen2Audio,
    
} StreamStateType;
typedef void (*ErrorOccurredCallback) (StreamStateType error);

#endif /* TypeDefs_h */
