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
    SocketErrorNone = 0,
    SocketErrorExists,
} SocketErrorType;

typedef enum : int {
    VideoAudioErrorNone = 0,
    VideoAudioErrorAvformatOpenInput,
    VideoAudioErrorAvformatFindStreamInfo,
    VideoAudioErrorAvcodecFindDecoderVideo,
    VideoAudioErrorAvcodecParametersToContextVideo,
    VideoAudioErrorAvcodecOpen2Video,
    VideoAudioErrorAvcodecFindDecoderAudio,
    VideoAudioErrorAvcodecParametersToContextAudio,
    VideoAudioErrorAvcodecOpen2Audio,
    
} VideoAudioErrorType;
typedef void (*ErrorOccurredCallback) (VideoAudioErrorType error);

#endif /* TypeDefs_h */
