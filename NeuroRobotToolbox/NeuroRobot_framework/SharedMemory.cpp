//
//  SharedMemory.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _SharedMemory_cpp
#define _SharedMemory_cpp

#include "SharedMemory.h"
#include "Macros.h"

#include <iostream>
#include <thread>

const static unsigned int maxAudioCounter = 20;

/// Null, because instance will be initialized on demand.
SharedMemory* SharedMemory::instance = 0;
SharedMemory* SharedMemory::getInstance()
{
    if (instance == 0) {
        instance = new SharedMemory();
    }
    return instance;
}

SharedMemory::SharedMemory()
: Log("SharedMemory")
{
    logMessage("SharedMemory >>> init");
}

SharedMemory::~SharedMemory()
{
    delete [] frameData;
    delete [] audioData;
    delete [] serialData;
}

void SharedMemory::blockWritters()
{
    isWritingBlocked = true;
}

void SharedMemory::unblockWritters()
{
    isWritingBlocked = false;
}

void SharedMemory::writeFrame(uint8_t* data, size_t totalBytes)
{
    if (totalBytes == 0) { return; }
    
    mutexVideo.lock();
    
    if (totalBytes != frameTotalBytes) {
        if (frameData) {
            logMessage("writeFrame >>> Rebasing frameData");
            delete [] frameData;
        }
        frameTotalBytes = totalBytes;
    }
    if (!frameData) {
        frameData = new uint8_t[frameTotalBytes];
    }
    
    memcpy(frameData, data, frameTotalBytes);
    mutexVideo.unlock();
}

uint8_t* SharedMemory::readVideoFrame()
{
    return frameData;
}

void SharedMemory::writeAudio(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_)
{
    std::thread processThread(&SharedMemory::writeAudioThreaded, this, data, numberOfSamples_, bytesPerSample_);
    processThread.detach();
}

void SharedMemory::writeAudioThreaded(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_)
{
    if (numberOfSamples_ == 0) { logMessage("numberOfSamples_ == 0"); return; }
    if (bytesPerSample_ == 0) { logMessage("bytesPerSample_ == 0"); return; }
    if (isWritingBlocked) { logMessage("Blocked audio"); return; }
    
    mutexAudio.lock();
    
    audioTotalBytes = numberOfSamples_ * bytesPerSample_;
    bytesPerSample = bytesPerSample_;
    
    /// Alloc
    if (!audioData) {
        /// Alloc `audioData` buffer with `audioTotalBytes` number of items multplied with `maxAudioCounter`
        audioData = new uint8_t[audioTotalBytes * maxAudioCounter + 1];
    }
    
    /// If the buffer is full then overwrite the first `audioTotalBytes` samples
    if (audioCounter == maxAudioCounter) {
        audioCounter--;
        memcpy(audioData, &audioData[audioTotalBytes], audioTotalBytes * audioCounter);
    }
    
    /// Write at the end of valid data
    memcpy(&audioData[audioTotalBytes * audioCounter], data, audioTotalBytes);
    audioCounter++;
    
    mutexAudio.unlock();
}

uint8_t* SharedMemory::readAudio(size_t* totalBytes_, unsigned short* bytesPerSample_)
{
    static uint8_t *audioDataFoo = new uint8_t[audioTotalBytes * maxAudioCounter];
    *totalBytes_ = (size_t)(audioTotalBytes * audioCounter);
    *bytesPerSample_ = bytesPerSample;
    
    if (audioCounter != 0) {
        
        mutexAudio.lock();
        audioCounter = 0;
        
        memcpy(audioDataFoo, audioData, *totalBytes_);

        mutexAudio.unlock();
    }
    
    return audioDataFoo;
}

void SharedMemory::setSerialData(std::string data)
{
    if (isWritingBlocked) {
        logMessage("setSerialData >>> Blocked serial writing");
        return;
    }
    mutexSerialRead.lock();
    
    if (data.length() > serialDataBufferCount) {
        logMessage("data.length(): " + std::to_string(data.length()) + " > serialDataBufferCount: " + std::to_string(serialDataBufferCount));
    }
    lastSerialResult = data;
    
    mutexSerialRead.unlock();
}

char* SharedMemory::getSerialData(size_t* totalBytes)
{
    mutexSerialRead.lock();
    
    *totalBytes = lastSerialResult.length();
    
    if (!serialData) {
        serialData = new char[serialDataBufferCount];
        logMessage("serialData = new uint8_t[serialDataBufferCount];");
    }
    
    strcpy(serialData, lastSerialResult.c_str());
    
    mutexSerialRead.unlock();
    
    return serialData;
}

#endif // ! _SharedMemory_cpp
