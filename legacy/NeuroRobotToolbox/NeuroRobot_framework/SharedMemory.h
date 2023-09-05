//
//  SharedMemory.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef SharedMemory_h
#define SharedMemory_h

#include <iostream>
#include "Log.h"

#include <mutex>

/// Class for storing the data. Intended for using with `singleton` mechanism.
class SharedMemory : public Log {
    
private:
    
    /// Instance for used for `singleton` mechanism
    static SharedMemory* instance;
    
    /// Private constructor to prevent instancing
    SharedMemory();
    ~SharedMemory();
    
    /// Mutex used in blocking access to some data
    std::mutex mutexVideo;
    std::mutex mutexAudio;
    std::mutex mutexSerialRead;
    
    /// Video data
    uint8_t *frameData = NULL;
    
    /// Audio data
    uint8_t *audioData = NULL;
    unsigned short audioCounter = 0;
    unsigned short bytesPerSample = 0;
    bool isWritingBlocked = false;
    
    /// Serial data
    std::string lastSerialResult;
    char *serialData = NULL;
    static const unsigned int serialDataBufferCount = 1000;
    
    /// Writes audio data to store.
    /// @param data Audio data
    /// @param numberOfSamples_ Number of samples
    /// @param bytesPerSample_ Bytes per sample
    void writeAudioThreaded(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_);
    
public:
    
    /// Static instance.
    static SharedMemory* getInstance();
    
    /// Total number of audio data bytes.
    size_t audioTotalBytes = 0;
    
    /// Audio sample rate in Hz
    unsigned int audioSampleRate = 0;
    
    /// Total number of frame data bytes.
    size_t frameTotalBytes = 0;
    
    /// Video width in px
    unsigned int videoWidth = 0;
    
    /// Video height in px
    unsigned int videoHeight = 0;
    
    /// Block writers.
    void blockWritters();
    
    /// Unblock writers.
    void unblockWritters();
    
    /// Write one frame of video data to shared memory.
    /// @param data Video frame data
    /// @param frameSizeInBytes Data size in bytes
    void writeFrame(uint8_t* data, size_t frameSizeInBytes);
    
    /// Read video frame from shared memory.
    /// @return Video frame data
    uint8_t* readVideoFrame();
    
    /// Delegates other thread to write audio data to store.
    /// @param data Audio data
    /// @param numberOfSamples_ Number of samples
    /// @param bytesPerSample_ Bytes per sample
    void writeAudio(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_);
    
    /// Reads audio data from store.
    /// @param totalBytes_ Total number of bytes
    /// @param bytesPerSample_ Number of bytes per sample
    /// @return Audio data from store
    uint8_t* readAudio(size_t* totalBytes_, unsigned short* bytesPerSample_);
    
    /// Write serial data to store.
    /// @param data Data to write
    void setSerialData(std::string data);
    
    /// Read serial data from store.
    /// @param totalBytes Size of serial data which is forwarded parallel
    /// @return Serial data from store
    char* getSerialData(size_t* totalBytes);
};

#endif /* SharedMemory_h */
