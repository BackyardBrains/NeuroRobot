//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _SharedMemory_cpp
#define _SharedMemory_cpp

#include "SharedMemory.h"
#include "Macros.h"

#include <iostream>


/* Null, because instance will be initialized on demand. */
SharedMemory* SharedMemory::instance = 0;
SharedMemory* SharedMemory::getInstance()
{
    if (instance == 0) {
        instance = new SharedMemory();
    }
    return instance;
}

SharedMemory::SharedMemory()
{
    className = "SharedMemory";
    openLogFile();
    
    logMessage("SharedMemory >>> init");
}

SharedMemory::~SharedMemory()
{
    delete [] videoData;
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

void SharedMemory::writeFrame(uint8_t* data, size_t frameSizeInBytes)
{
    if (frameSizeInBytes == 0) { return; }
    
    mutexVideo.lock();
    
    if (frameSizeInBytes != frameDataCount) {
        if (videoData) {
            delete [] videoData;
        }
        frameDataCount = frameSizeInBytes;
    }
    if (!videoData) {
        videoData = new uint8_t[frameDataCount];
    }
    
    memcpy(videoData, data, frameDataCount);
    mutexVideo.unlock();
}

uint8_t* SharedMemory::readVideoFrame()
{
    return videoData;
}

void SharedMemory::writeAudio(uint8_t* data, size_t numberOfSamples_, unsigned short bytesPerSample_)
{
    if (numberOfSamples_ == 0) { logMessage("numberOfBytes_ == 0"); return; }
    if (bytesPerSample_ == 0) { logMessage("bytesPerSample_ == 0"); return; }
    if (isWritingBlocked) { logMessage("Blocked audio"); return; }
    
    mutexAudio.lock();
    
    audioNumberOfBytes = numberOfSamples_ * bytesPerSample_;
    bytesPerSample = bytesPerSample_;
    
    // Alloc
    if (!audioData) {
        audioData = new uint8_t[audioNumberOfBytes * 20 + 1];
    }
    
    // If the buffer is full overwrite the first `audioNumberOfBytes` samples
    if (audioCounter == 20) {
        audioCounter--;
        memcpy(audioData, &audioData[audioNumberOfBytes], audioNumberOfBytes * audioCounter);
    }
    
    // Write at the end of valid data
    memcpy(&audioData[audioNumberOfBytes * audioCounter], data, audioNumberOfBytes);
    audioCounter++;
    
    mutexAudio.unlock();
}

uint8_t* SharedMemory::readAudio(size_t* totalBytes_, unsigned short* bytesPerSample_)
{
    static uint8_t *audioDataFoo = new uint8_t[audioNumberOfBytes * 20];
    *totalBytes_ = (size_t)(audioNumberOfBytes * audioCounter);
    *bytesPerSample_ = bytesPerSample;
    
    if (audioCounter != 0) {
        
        mutexAudio.lock();
        audioCounter = 0;
        
        memcpy(audioDataFoo, audioData, *totalBytes_);

        mutexAudio.unlock();
    }
    
    return audioDataFoo;
}

void SharedMemory::writeSerialRead(std::string data)
{
    if (isWritingBlocked) {
        logMessage("Blocked serial");
        return;
    }
    mutexSerialRead.lock();
    
    if (data.length() > serialDataBufferCount) {
        logMessage("data.length(): " + std::to_string(data.length()) + " > serialDataBufferCount: " + std::to_string(serialDataBufferCount));
    }
    lastSerialResult = data;
    
    mutexSerialRead.unlock();
}

char* SharedMemory::readSerialRead(int* size)
{
    mutexSerialRead.lock();
    
    *size = (int)lastSerialResult.length();
    
    if (!serialData) {
        serialData = new char[1000];
        logMessage("serialData = new uint8_t[1000];");
    }
    
    strcpy(serialData, lastSerialResult.c_str());
    
    mutexSerialRead.unlock();
    
    return serialData;
}

void SharedMemory::setAudioSampleRate(int sampleRate)
{
    audioSampleRate = sampleRate;
}

int SharedMemory::getAudioSampleRate()
{
    return audioSampleRate;
}

#endif // ! _SharedMemory_cpp
