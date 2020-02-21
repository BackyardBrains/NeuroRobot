//
//  NeuroRobotManager.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "NeuroRobotManager.h"

#include <iostream>
#include <boost/thread/thread.hpp>

NeuroRobotManager::NeuroRobotManager(std::string ipAddress, std::string port, StreamErrorOccurredCallback streamCallback, SocketErrorOccurredCallback socketCallback)
: Log("NeuroRobotManager")
{
    if (!videoAndAudioObtainerObject) {
        videoAndAudioObtainerObject = new VideoAndAudioObtainer(ipAddress, streamCallback, audioBlocked);
    }
    
    if (videoAndAudioObtainerObject->stateType == StreamStateNotStarted && !socketBlocked && !socketObject) {
        socketObject = new Socket(ipAddress, port, socketCallback);
    }
}

void NeuroRobotManager::start()
{
    videoAndAudioObtainerObject->startThreaded();
    if (socketObject && !socketBlocked) {
        socketObject->startThreaded();
    }
    boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
}

void *NeuroRobotManager::readAudio(size_t *totalBytes, unsigned short *bytesPerSample)
{
    *totalBytes = 0;
    *bytesPerSample = 0;
    
    if (audioBlocked) { return nullptr; }
    
    void *reply = SharedMemory::getInstance()->readAudio(totalBytes, bytesPerSample);
    return reply;
}

uint8_t *NeuroRobotManager::readVideoFrame()
{
    return SharedMemory::getInstance()->readVideoFrame();
}

void NeuroRobotManager::stop()
{
    if (!socketBlocked && socketObject && socketObject->isRunning()) {
        socketObject->stop();
    }
    
    if (videoAndAudioObtainerObject && videoAndAudioObtainerObject->isRunning()) {
        videoAndAudioObtainerObject->stop();
    }
    
    boost::this_thread::sleep_for(boost::chrono::milliseconds(2000));
    
    delete socketObject;
    delete videoAndAudioObtainerObject;
}

bool NeuroRobotManager::isRunning()
{
    bool videoAndAudioStreamerLegalState = videoAndAudioObtainerObject->isRunning() && !(videoAndAudioObtainerObject->stateType >= 100);
    
    if (!socketBlocked) {
        
        if (!socketObject) {
            logMessage("isRunning >> socketObject doesn't exist");
            return false;
        }
        
        bool socketLegalState = socketObject->isRunning() && !(socketObject->stateType >= 100 && socketObject->stateType < 200);
        
        if (!videoAndAudioObtainerObject->isRunning()) {
            logMessage("issue with videoAndAudioObtainerObject->isRunning()");
        }
        if (videoAndAudioObtainerObject->stateType != StreamStateRunning) {
            logMessage("issue with videoAndAudioObtainerObject->stateType: " + std::string(getStreamStateMessage(videoAndAudioObtainerObject->stateType)));
        }
        if (!socketObject->isRunning()) {
            logMessage("issue with socketObject->isRunning()");
        }
        if (socketObject->stateType != SocketStateConnected) {
            logMessage("issue with socketObject->stateType: " + std::string(getSocketStateMessage(socketObject->stateType)));
        }
        return videoAndAudioStreamerLegalState && socketLegalState;
    } else {
        return videoAndAudioStreamerLegalState;
    }
}

void NeuroRobotManager::writeSerial(std::string data)
{
    if (socketBlocked) { return; }
    
    socketObject->send(data);
}

void NeuroRobotManager::writeSerial(char *data)
{
    if (socketBlocked) { return; }
    
    writeSerial(std::string(data));
}

char *NeuroRobotManager::readSerial(size_t *totalBytes)
{
    *totalBytes = 0;
    if (socketBlocked) { return nullptr; }
    
    return SharedMemory::getInstance()->getSerialData(totalBytes);
}

void NeuroRobotManager::sendAudio(int16_t *data, size_t totalBytes)
{
    if (socketBlocked) { return; }
    
    socketObject->sendAudio(data, totalBytes);
}

StreamStateType NeuroRobotManager::readStreamState()
{
    return videoAndAudioObtainerObject->stateType;
}

SocketStateType NeuroRobotManager::readSocketState()
{
    if (socketBlocked) { return SocketStateNotInitialized; }
    
    return socketObject->stateType;
}

size_t NeuroRobotManager::videoFrameBytes()
{
    return SharedMemory::getInstance()->frameTotalBytes;
}

size_t NeuroRobotManager::audioBytes()
{
    return SharedMemory::getInstance()->audioTotalBytes;
}

unsigned int NeuroRobotManager::audioSampleRate()
{
    return SharedMemory::getInstance()->audioSampleRate;
}

unsigned int NeuroRobotManager::videoWidth()
{
    return SharedMemory::getInstance()->videoWidth;
}

unsigned int NeuroRobotManager::videoHeight()
{
    return SharedMemory::getInstance()->videoHeight;
}
