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
    openStreams();
    
    logMessage("SharedMemory >>> init");
}

SharedMemory::~SharedMemory()
{
    closeStreams();
    
    delete [] videoData;
    delete [] audioData;
    delete [] serialData;
}

/**
 Blocks writers.
 */
void SharedMemory::blockWritters()
{
    isWrittersBlocked = true;
}

/**
 Unblocks writers.
 */
void SharedMemory::unblockWritters()
{
    isWrittersBlocked = false;
}

/**
 Writes one frame of video data to shared memory.
 
 @param data Video frame data
 */
void SharedMemory::writeFrame(uint8_t* data)
{
    mutexVideo.lock();
    memcpy(videoData, data, frameSize);
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
 */
void SharedMemory::writeAudio(uint8_t* data)
{
    if (isWrittersBlocked) {
        logMessage("Blocked audio");
        return;
    }
    
//     static int16_t *audioDataFoo = new int16_t[audioSize * 2 * 10];
//     memcpy(audioDataFoo, data, 2000);
    
//    logMessage("writeAudio >>> new");
//    for (int i = 0; i < 1000; i++) {
//        char string[100];
//        sprintf(string, "writeAudio >>> %d, data: %d", i, audioDataFoo[i]);
//        logMessage(string);
//    }
    
    mutexAudio.lock();
    if (audioChunkCounter == 10) {
        audioChunkCounter--;
        memcpy(audioData, &audioData[audioSize], audioSize * 2 * audioChunkCounter);
    }
    memcpy(&audioData[audioSize * audioChunkCounter], data, audioSize * 2);
    
    
//    static int16_t *audioDataFoo2 = new int16_t[audioSize * 2 * 10];
//    memcpy(audioDataFoo2, audioData, audioSize * 2 * audioChunkCounter);
//
//    logMessage("writeAudio2 >>> new");
//    for (int i = 0; i < audioSize * audioChunkCounter; i++) {
//        char string[100];
//        sprintf(string, "writeAudio2 >>> %d, data: %d", i, audioDataFoo2[i]);
//        logMessage(string);
//    }
    
    audioChunkCounter++;
    
    mutexAudio.unlock();
}

/**
 Reads audio data from shared memory.
 Reads last ~1sec of audio data.
 
 @param size Size of audio data which is forwarded parallel
 @return Last ~1sec of audio data
 */
int16_t* SharedMemory::readAudio(int* size)
{
    static int16_t *audioDataFoo = new int16_t[audioSize * 2 * 10];
    
    if (audioChunkCounter != 0) {
        
        mutexAudio.lock();
        *size = audioSize * 2 * audioChunkCounter;
        audioChunkCounter = 0;
        
        logMessage(std::to_string(*size));

        memcpy(audioDataFoo, audioData, *size);

    //    for (int i = 0; i < *size / 2; i++) {
    //        char string[100];
    //        sprintf(string, "readAudio >>> %d, data: %d", i, audioDataFoo[i]);
    //        logMessage(string);
    //    }

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
    if (isWrittersBlocked) {
        logMessage("Blocked serial");
        return;
    }
    mutexSerialRead.lock();
    
    memcpy(&serialData[serialReadWrittenSize], data.c_str(), data.length());
    
    char string[50];
    sprintf(string, "srwse %d", serialReadWrittenSize);
    logMessage(string);
    
    serialReadWrittenSize += data.length();
    if (serialReadWrittenSize > 900) {
        serialReadWrittenSize = 0;
    }
    
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
    
    *size = serialReadWrittenSize;
    
    mutexSerialRead.unlock();
    
    return serialData;
}

/**
 Reads serial data as string from shared memory.
 
 @return Serial data as string
 */
std::string SharedMemory::readSerialRead()
{
    return serialDataString;
}

#endif // ! _SharedMemory_cpp
