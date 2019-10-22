//
//  SharedMemory.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef SharedMemory_h
#define SharedMemory_h

#include <iostream>
#include "Log.h"

#include <mutex>

/**
 Intended for data store.
 */
class SharedMemory : public Log {
    
private:
    std::mutex mutexVideo;
    std::mutex mutexAudio;
    std::mutex mutexSerialRead;
    
    uint8_t audioChunkCounter = 0;
    bool isWrittersBlocked = false;
    int serialReadWrittenSize = 0;
    int lastSerialSize = 0;
    
public:
    static const int audioSize = 1000;
    int frameSize = 1;
    static const int serialReadTotalSize = 1000;
    
    // Bridge
    uint8_t *videoData = NULL;
    int16_t *audioData = new int16_t[audioSize * 2 * 10];
    uint8_t *lastSerialResult = new uint8_t[serialReadTotalSize + 1];
    uint8_t *returnSerialBuffer = new uint8_t[serialReadTotalSize + 1];
    
    SharedMemory();
    ~SharedMemory();
    
    /**
     Blocks writers.
     */
    void blockWritters();
    
    /**
     Unblocks writers.
     */
    void unblockWritters();
    
    /**
     Writes one frame of video data to shared memory.
     
     @param data Video frame data
     */
    void writeFrame(uint8_t* data);
    
    /**
     Reads video frame from shared memory.
     
     @return Video frame data
     */
    uint8_t* readVideoFrame();
    
    /**
     Writes audio data to shared memory.
     
     @param data Audio data
     */
    void writeAudio(uint8_t* data);
    
    /**
     Reads audio data from shared memory.
     Reads last ~1sec of audio data.
     
     @param size Size of audio data which is forwarded parallel
     @return Last ~1sec of audio data
     */
    int16_t* readAudio(int* size);
    
    /**
     Writes serial data to shared memory.
     
     @param data Data to write
     */
    void writeSerialRead(std::string data);
    
    /**
     Reads serial data from shared memory.
     
     @param size Size of serial data which is forwarded parallel
     @return Serial data
     */
    uint8_t* readSerialRead(int* size);
};

#endif /* SharedMemory_h */
