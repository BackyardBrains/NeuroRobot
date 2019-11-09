//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _SharedMemory_cpp
#define _SharedMemory_cpp

#include "SharedMemory.h"
#include "Macros.h"

#include <iostream>


SharedMemory::SharedMemory()
{
    className = "SharedMemory";
    openLogFile();
    
    logMessage("SharedMemory >>> init");
}

SharedMemory::~SharedMemory()
{
    closeLogFile();
    
    delete [] videoData;
    delete [] audioData;
}

/**
 Blocks writers.
 */
void SharedMemory::blockWritters()
{
    isWritingBlocked = true;
}

/**
 Unblocks writers.
 */
void SharedMemory::unblockWritters()
{
    isWritingBlocked = false;
}

/**
 Writes one frame of video data to shared memory.
 
 @param data Video frame data
 @param frameSizeInBytes Data size in bytes
 */
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

/**
 Reads video frame from shared memory.
 
 @return Video frame data
 */
uint8_t* SharedMemory::readVideoFrame()
{
    return videoData;
}

/**
 Writes audio data to shared memory.
 
 @param data Audio data
 @param audioSizeInBytes Data size in bytes
 */
void SharedMemory::writeAudio(uint8_t* data, size_t audioSampleCount_)
{
    if (audioSampleCount_ == 0) { return; }
    
    if (isWritingBlocked) {
        logMessage("Blocked audio");
        return;
    }
    
    mutexAudio.lock();
    
    audioSampleCountPerReading = audioSampleCount_;
    
    if (!audioData) {
        audioData = new int16_t[audioSampleCountPerReading * 10 + 1];
    }
    
    if (audioStoredReadingCounter == 10) {
        audioStoredReadingCounter--;
        memcpy(audioData, &audioData[audioSampleCountPerReading], audioSampleCountPerReading * 2 * audioStoredReadingCounter);
    }
    memcpy(&audioData[audioSampleCountPerReading * audioStoredReadingCounter], data, audioSampleCountPerReading * 2);
    
    audioStoredReadingCounter++;
    
    mutexAudio.unlock();
}

/**
 Reads audio data from shared memory.
 Reads last ~1sec of audio data.
 
 @param size Size of audio data which is forwarded parallel
 @return Last ~1sec of audio static data
 */
int16_t* SharedMemory::readAudio(int* validAudioSampleCount_)
{
    static int16_t *audioDataFoo = new int16_t[audioSampleCountPerReading * 10];
    *validAudioSampleCount_ = (int)(audioSampleCountPerReading * audioStoredReadingCounter);
    
    if (audioStoredReadingCounter != 0) {
        
        mutexAudio.lock();
        audioStoredReadingCounter = 0;
        
        memcpy(audioDataFoo, audioData, *validAudioSampleCount_ * 2);

        mutexAudio.unlock();
    }
    
    return audioDataFoo;
}

/**
 Writes serial data to shared memory.
 
 @param data Data to write
 */
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

/**
 Reads serial data from shared memory.
 
 @param size Size of serial data which is forwarded parallel
 @return Serial data
 */
uint8_t* SharedMemory::readSerialRead(int* size)
{
    mutexSerialRead.lock();
    
    static uint8_t *returnSerialBuffer = new uint8_t[lastSerialResult.length() + 1];
    
    memcpy(returnSerialBuffer, lastSerialResult.c_str(), lastSerialResult.length() + 1);
    *size = (int)lastSerialResult.length();
    
    mutexSerialRead.unlock();
    
    return returnSerialBuffer;
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
