//
//  SharedMemory.h
//  Neurorobot-Framework
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
    
    /* Here will be the instance stored. */
    static SharedMemory* instance;
    /* Private constructor to prevent instancing. */
    SharedMemory();
    ~SharedMemory();
    
    std::mutex mutexVideo;
    std::mutex mutexAudio;
    std::mutex mutexSerialRead;
    
    uint8_t audioStoredReadingCounter = 0;
    bool isWritingBlocked = false;
    int serialReadWrittenSize = 0;
    int lastSerialSize = 0;
    
    uint8_t *videoData = NULL;
    int16_t *audioData = NULL;
    uint8_t *serialData = NULL;
    std::string lastSerialResult;
    int audioSampleRate = 0;
    
public:
    /* Static access method. */
    static SharedMemory* getInstance();
    
    size_t audioSampleCountPerReading = 0;
    size_t frameDataCount = 0;
    
    int videoWidth = 0;
    int videoHeight = 0;
    
    static const int serialDataBufferCount = 1000;
    
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
     @param frameSizeInBytes Data size in bytes
     */
    void writeFrame(uint8_t* data, size_t frameSizeInBytes);
    
    /**
     Reads video frame from shared memory.
     
     @return Video frame data
     */
    uint8_t* readVideoFrame();
    
    /**
     Writes audio data to shared memory.
     
     @param data Audio data
     @param audioSampleCount Data size in bytes
     */
    void writeAudio(uint8_t* data, size_t audioSampleCount);
    
    /**
     Reads audio data from shared memory.
     Reads last ~1sec of audio data.
     
     @param audioSampleCount Size of audio data which is forwarded parallel
     @return Last ~1sec of audio static data
     */
    int16_t* readAudio(int* audioSampleCount);
    
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
    
    
    /// Set sample rate for audio
    /// @param sampleRate sample rate in Hz
    void setAudioSampleRate(int sampleRate);
    
    /// Get audio sample rate
    int getAudioSampleRate();
};

#endif /* SharedMemory_h */
