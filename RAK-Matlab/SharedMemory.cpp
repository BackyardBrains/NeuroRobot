//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright ? 2018 Backyard Brains. All rights reserved.
//

#ifndef _SharedMemory_cpp
#define _SharedMemory_cpp

#include "Macros.h"

#include <iostream>
#include <thread>
#include <mutex>

// Boost includes
#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>


#ifdef DEBUG
#include <fstream>
#endif

using namespace boost::interprocess;

class SharedMemory
{
    
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
    
    int serialReadTotalSize = 200000;
    int serialReadWrittenSize = 0;
    
#ifdef DEBUG
    std::ofstream logFile;
#endif
    
    public:
    
    int audioSize = 1000;
    int frameSize = 2764800;
    bool audioObtained = false;
    
    SharedMemory() {
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
    
    ~SharedMemory() {
        closeStreams();
    }
    
    void writeFrame(uint8_t *data) {
        mutexVideo.lock();
        
        memcpy(frameRegion.get_address(), data, frameSize);
        
        mutexVideo.unlock();
    }
    
    uint8_t * readFrame() {
        mutexVideo.lock();
        
        uint8_t *payload = reinterpret_cast<uint8_t*>(frameRegion.get_address());
        
        mutexVideo.unlock();
        
        return payload;
    }
    
    void writeAudio(uint8_t *data) {
        logMessage("writeAudio >> enter");
        mutexAudio.lock();
        
        if (audioChunkCounter == 10) {
            audioChunkCounter--;
            fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, audioSize * 2, audioSize * 2 * audioChunkCounter);
            memcpy(audioRegion.get_address(), fooAudioRegion.get_address(), audioSize * 2 * audioChunkCounter);
        }
        
        fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, audioSize * 2 * audioChunkCounter, audioSize * 2);
        
        memcpy(fooAudioRegion.get_address(), data, audioSize * 2);
        
        audioChunkCounter++;
        
        audioObtained = true;
        
        mutexAudio.unlock();
    }
    
    
    int16_t * readAudio(int *size) {
        mutexAudio.lock();
        
        fooAudioRegion = mapped_region(sharedMemoryAudio, read_write, 0, audioSize * 2 * audioChunkCounter);
        
        *size = audioSize * 2 * audioChunkCounter;
        
        int16_t *audioData = (int16_t *) malloc(*size + 1);
        memcpy(audioData, fooAudioRegion.get_address(), *size);
        
        audioChunkCounter = 0;
        audioObtained = false;
        mutexAudio.unlock();
        
        return audioData;
    }
    
    uint8_t *readVideo() {
        return readFrame();
    }
    
    void writeSerialRead(std::string data) {
        
        std::thread thread(&SharedMemory::writeSerialReadThreaded, this, data);
        thread.detach();
    }
    
    void writeSerialReadThreaded(std::string data) {
        mutexSerialRead.lock();
        logMessage("writeSerialRead >>> enter");
        
        serialReadRegion = mapped_region(sharedMemorySerialRead, read_write, serialReadWrittenSize, data.length());
        memcpy(serialReadRegion.get_address(), data.c_str(), data.length());
        
        serialReadWrittenSize += data.length();
        
        mutexSerialRead.unlock();
    }
    
    uint8_t *readSerialRead(int *size) {
        
        mutexSerialRead.lock();
        uint8_t *payload = (uint8_t *) malloc(serialReadWrittenSize);
        *size = serialReadWrittenSize;
        if (serialReadWrittenSize > 0) {
            serialReadRegion = mapped_region(sharedMemorySerialRead, read_write, 0, serialReadWrittenSize);
            memcpy(payload, serialReadRegion.get_address(), serialReadWrittenSize);
            serialReadWrittenSize = 0;
        }
        
        mutexSerialRead.unlock();
        
        return payload;
        
    }
    
    void isAudioObtained(bool *yp) {
        bool payload = audioObtained;
        memcpy(yp, &payload, 1);
    }
    
    
    
    
    
    void openStreams() {
#ifdef DEBUG
        logFile.open ("logFile_SharedMemory.txt");
        logMessage("openStreams >> SharedMemory >>> opened");
#endif
    }
    void closeStreams() {
#ifdef DEBUG
        logMessage("closeStreams >>> closed");
        logFile.close();
#endif
    }
    
    void logMessage(std::string message) {
#ifdef DEBUG
        std::time_t end_time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        std::string t(std::ctime(&end_time));
        logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
        std::cout << message << std::endl;
#endif
    }
};


#endif // ! _SharedMemory_cpp
