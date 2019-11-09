//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//


#include "NeuroRobotManager.h"

#include <iostream>
#include <boost/thread/thread.hpp>

/**
 Inits video and audio obtainer object and socket object.
 */
NeuroRobotManager::NeuroRobotManager(std::string ipAddress, std::string port, StreamStateType *error, StreamErrorOccurredCallback streamCallback, SocketErrorOccurredCallback socketCallback)
{
    if (!videoAndAudioObtainerObject) {
        videoAndAudioObtainerObject = new VideoAndAudioObtainer(sharedMemory, ipAddress, error, streamCallback, audioBlocked);
    }
    
    if (videoAndAudioObtainerObject->stateType == StreamStateNotStarted && !socketBlocked && !socketObject) {
        socketObject = new Socket(sharedMemory, ipAddress, port, socketCallback);
    }
}

/**
 Starts the video, audio and serial data obtainers.
 */
void NeuroRobotManager::start()
{
    videoAndAudioObtainerObject->startThreaded();
    if (socketObject && !socketBlocked) {
        socketObject->startThreaded();
    }
    boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
}

/**
 Reads audio from shared memory object.
 
 @param size Size of audio data which is forwarded parallel
 @return Audio data
 */
int16_t *NeuroRobotManager::readAudio(int *size)
{
    *size = 0;
    
    if (!audioBlocked) {
        int16_t *reply = sharedMemory->readAudio(size);
        return reply;
    } else {
        static int16_t *audioDataFoo = new int16_t[sharedMemory->audioSampleCountPerReading * 10];
        return audioDataFoo;
    }
}

/**
 Reads video frame from shared memory object.
 
 @return Video frame data
 */
uint8_t *NeuroRobotManager::readVideo()
{
    return sharedMemory->readVideoFrame();
}

/**
 Stops video, audio and serial data obtainers.
 */
void NeuroRobotManager::stop()
{
    videoAndAudioObtainerObject->stop();
    if (!socketBlocked && socketObject) {
        socketObject->stop();
    }
}

/**
 Queries whether the video and audio obtainer is working.
 
 @return Is video and audio obtainer working
 */
bool NeuroRobotManager::isRunning()
{
    if (!socketBlocked) {
        return videoAndAudioObtainerObject->isRunning() && videoAndAudioObtainerObject->stateType == StreamStateRunning && socketObject->isRunning() && socketObject->stateType == SocketStateConnected;
    } else {
        return videoAndAudioObtainerObject->isRunning() && videoAndAudioObtainerObject->stateType == StreamStateRunning;
    }
}

/**
 Writes forwarded serial data.
 
 @param data Serial data
 */
void NeuroRobotManager::writeSerial(std::string data)
{
    if (!socketBlocked) {
        socketObject->writeSerial(data);
    }
}
void NeuroRobotManager::writeSerial(char *data)
{
    if (!socketBlocked) {
        writeSerial(std::string(data));
    }
}

/**
 Reads serial data from shared memory object.
 
 @param size Size of serial data which is forwarded parallel
 @return Serial data
 */
uint8_t *NeuroRobotManager::readSerial(int *size)
{
    if (!socketBlocked) {
        return sharedMemory->readSerialRead(size);
    } else {
        static uint8_t *returnSerialBuffer = new uint8_t[1000 + 1];
        return returnSerialBuffer;
    }
}

/**
 Sends audio data through socket object.
 
 @param data Data to send
 @param numberOfBytes Number of bytes to send
 */
void NeuroRobotManager::sendAudio(int16_t *data, long long numberOfBytes)
{
    if (!socketBlocked) {
        socketObject->sendAudio(data, numberOfBytes);
    }
}

StreamStateType NeuroRobotManager::readStreamState()
{
    return videoAndAudioObtainerObject->stateType;
}

SocketStateType NeuroRobotManager::readSocketState()
{
    if (!socketBlocked) {
        return socketObject->stateType;
    } else {
        return SocketStateNotInitialized;
    }
}

long long NeuroRobotManager::frameDataCount()
{
    return sharedMemory->frameDataCount;
}

long long NeuroRobotManager::audioSampleCount()
{
    return sharedMemory->audioSampleCountPerReading;
}

int NeuroRobotManager::audioSampleRate()
{
    return sharedMemory->getAudioSampleRate();
}

int NeuroRobotManager::videoWidth()
{
    return sharedMemory->videoWidth;
}

int NeuroRobotManager::videoHeight()
{
    return sharedMemory->videoHeight;
}
