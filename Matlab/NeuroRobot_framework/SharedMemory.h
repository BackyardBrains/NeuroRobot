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
    
    unsigned short audioCounter = 0;
    bool isWritingBlocked = false;
    int serialReadWrittenSize = 0;
    int lastSerialSize = 0;
    unsigned short bytesPerSample = 0;
    
    uint8_t *videoData = NULL;
    uint8_t *audioData = NULL;
    std::string lastSerialResult;
    int audioSampleRate = 0;
    
    char *serialData = NULL;
    
public:
    /* Static access method. */
    static SharedMemory* getInstance();
    
    size_t audioNumberOfBytes = 0;
    size_t frameDataCount = 0;
    
    int videoWidth = 0;
    int videoHeight = 0;
    
    static const int serialDataBufferCount = 1000;
    
    /// Blocks writers.
    void blockWritters();
    
    /// Unblocks writers.
    void unblockWritters();
    
    /// Writes one frame of video data to shared memory.
    /// @param data Video frame data
    /// @param frameSizeInBytes Data size in bytes
    void writeFrame(uint8_t* data, size_t frameSizeInBytes);
    
    
    /// Reads video frame from shared memory.
    /// @return Video frame data
    uint8_t* readVideoFrame();
    
    /// Writes audio data to store.
    /// @param data Audio data
    /// @param numberOfSamples_ Number of samples
    /// @param bytesPerSample_ Bytes per sample
    void writeAudio(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_);
    
    /// Reads audio data from store.
    /// @param totalBytes_ Total number of bytes
    /// @param bytesPerSample_ Number of bytes per sample
    /// @return Audio data from store
    uint8_t* readAudio(size_t* totalBytes_, unsigned short* bytesPerSample_);
    
    /// Writes serial data to store.
    /// @param data Data to write
    void writeSerialRead(std::string data);
    
    /// Reads serial data from store.
    /// @param size Size of serial data which is forwarded parallel
    /// @return Serial data from store
    char* readSerialRead(int* size);
    
    /// Set sample rate for audio
    /// @param sampleRate sample rate in Hz
    void setAudioSampleRate(int sampleRate);
    
    /// Get audio sample rate
    int getAudioSampleRate();
};

#endif /* SharedMemory_h */
