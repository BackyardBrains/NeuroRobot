//
//  C-Header.h
//  RAK-Framework-dynamic
//
//  Created by Djordje Jovic on 6/12/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef C_Header_h
#define C_Header_h

#ifdef __cplusplus
extern "C" {
#endif
#include <stdint.h>
    
    int bridge_sizeOfVideoFrame();
    
    void *bridge_Init(char *ipAddress, char *port);
    void bridge_start(const void *object);
    uint8_t *bridge_readVideo(const void *object);
    void bridge_stop(const void *object);
    int16_t *bridge_readAudio(const void *object, int *size);
    uint8_t *bridge_readSerial(const void *object, int *size);
    
    void bridge_writeSerial(const void *object, char *message);
    void bridge_sendAudio(const void *object, int16_t *audioData, long long numberOfBytes);
    
#ifdef __cplusplus
}
#endif

#endif /* C_Header_h */
