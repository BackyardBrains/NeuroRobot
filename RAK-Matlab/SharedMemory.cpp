//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _SharedMemory_cpp
#define _SharedMemory_cpp

#include "Macros.h"
#include "Log.cpp"

#include <iostream>
#include <thread>
#include <mutex>

// Boost includes
#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>

using namespace boost::interprocess;

class SharedMemory : public Log {
    
private:
    std::mutex mutexVideo;
    std::mutex mutexAudio;
    std::mutex mutexSerialRead;
    
    shared_memory_object sharedMemoryVideo;
    shared_memory_object sharedMemoryAudio;
    shared_memory_object sharedMemorySerialRead;
    mapped_region frameRegion;
    mapped_region audioRegion;
    mapped_region serialReadRegion;
    mapped_region fooAudioRegion;
    
    uint8_t audioChunkCounter = 0;
    uint8_t blockWrittersFlag = 0;
    int serialReadTotalSize = 1000;
    int serialReadWrittenSize = 0;
    
public:
    int audioSize = 1000;
    int frameSize = 2764800;
    bool audioObtained = false;
    
    SharedMemory()
    {
        className = "SharedMemory";
        openStreams();
        
        logMessage("SharedMemory >>> init");
        
        sharedMemoryVideo = shared_memory_object(open_or_create, "sharedMemoryVideo", read_write);
        sharedMemoryVideo.truncate(frameSize);
        
        sharedMemoryAudio = shared_memory_object(open_or_create, "sharedMemoryAudio", read_write);
        sharedMemoryAudio.truncate(audioSize * 2 * 10);
        
        sharedMemorySerialRead = shared_memory_object(open_or_create, "sharedMemorySerialRead", read_write);
        sharedMemorySerialRead.truncate(serialReadTotalSize);
        
        frameRegion = mapped_region(sharedMemoryVideo, read_write, 0, frameSize);
        audioRegion = mapped_region(sharedMemoryAudio, read_write, 0, audioSize * 2 * 10);
    }
    
    ~SharedMemory()
    {
        closeStreams();
    }
    void blockWritters(void)
    {
        blockWrittersFlag = 1;
    }
    
    void unblockWritters(void)
    {
        blockWrittersFlag = 0;
    }
    
    void writeFrame(uint8_t* data)
    {
        mutexVideo.lock();
        memcpy(frameRegion.get_address(), data, frameSize);
        mutexVideo.unlock();
    }
    
    uint8_t* readFrame()
    {
        mutexVideo.lock();
        uint8_t* payload = reinterpret_cast<uint8_t*>(frameRegion.get_address());
        mutexVideo.unlock();
        return payload;
    }
    
    void writeAudio(uint8_t* data)
    {
        if (blockWrittersFlag) {
            logMessage("Blocked audio");
            return;
        }
        mutexAudio.lock();
        
        if (audioChunkCounter == 10) {
            audioChunkCounter--;
            fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, audioSize * 2, audioSize * 2 * audioChunkCounter);
            memcpy(audioRegion.get_address(), fooAudioRegion.get_address(), audioSize * 2 * audioChunkCounter);
        }
        char string[50];
        sprintf(string, "-- audio offset w %d", audioSize * 2 * audioChunkCounter);
        logMessage(string);
        fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, audioSize * 2 * audioChunkCounter, audioSize * 2);
        
        memcpy(fooAudioRegion.get_address(), data, audioSize * 2);
        
        audioChunkCounter++;
        
        audioObtained = true;
        
        mutexAudio.unlock();
    }
    
    int16_t* readAudio(int* size)
    {
        mutexAudio.lock();
        char string[50];
        sprintf(string, "-- audio offset r %d", audioSize * 2 * audioChunkCounter);
        logMessage(string);
        fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, 0, audioSize * 2 * audioChunkCounter);
        
        *size = audioSize * 2 * audioChunkCounter;
        
        int16_t* audioData = (int16_t*)malloc(*size + 1);
        memcpy(audioData, fooAudioRegion.get_address(), *size);
        
        audioChunkCounter = 0;
        audioObtained = false;
        mutexAudio.unlock();
        
        return audioData;
    }
    
    uint8_t* readVideo()
    {
        return readFrame();
    }
    
    void writeSerialRead(std::string data)
    {
        if (blockWrittersFlag) {
            logMessage("Blocked serial");
            return;
        }
        mutexSerialRead.lock();
        
        serialReadRegion = mapped_region(sharedMemorySerialRead, read_write, serialReadWrittenSize, data.length());
        memcpy(serialReadRegion.get_address(), data.c_str(), data.length());
        char string[50];
        
        serialReadWrittenSize += data.length();
        if (serialReadWrittenSize > 400) {
            serialReadWrittenSize = 0;
        }
        sprintf(string, "srwse %d", serialReadWrittenSize);
        logMessage(string);
        mutexSerialRead.unlock();
    }
    
    uint8_t* readSerialRead(int* size)
    {
        mutexSerialRead.lock();
        uint8_t* payload = (uint8_t*)malloc(serialReadWrittenSize + 1);
        *size = serialReadWrittenSize;
        char string[50];
        
        sprintf(string, "readser--- %d", serialReadWrittenSize);
        logMessage(string);
        if (serialReadWrittenSize > 0) {
            serialReadRegion = mapped_region(sharedMemorySerialRead, read_write, 0, serialReadWrittenSize);
            memcpy(payload, (uint8_t*)serialReadRegion.get_address(), serialReadWrittenSize);
            payload[serialReadWrittenSize] = 0;
            serialReadWrittenSize = 0;
        } else {
            payload[0] = 0;
        }
        mutexSerialRead.unlock();
        if (*size > 0) {
            *size = *size - 1;
        }
        
        return payload;
    }
    
    void isAudioObtained(bool* yp)
    {
        bool payload = audioObtained;
        memcpy(yp, &payload, 1);
    }
};

#endif // ! _SharedMemory_cpp
