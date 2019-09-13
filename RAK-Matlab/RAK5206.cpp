//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//


#include "RAK5206.h"

#include <iostream>

/**
 Inits video and audio obtainer object and socket object.
 */
RAK5206::RAK5206(std::string ipAddress, std::string port, int *error)
{
    videoAndAudioObtainerObject = new VideoAndAudioObtainer(sharedMemory, ipAddress, error);
    socketObject = new Socket(sharedMemory, ipAddress, port);
}

/**
 Starts the video, audio and serial data obtainers.
 */
void RAK5206::start()
{
    videoAndAudioObtainerObject->startThreaded();
    socketObject->startThreaded();
}

/**
 Reads audio from shared memory object.
 
 @param size Size of audio data which is forwarded parallel
 @return Audio data
 */
int16_t *RAK5206::readAudio(int *size)
{
    int16_t *reply = sharedMemory->readAudio(size);
    return reply;
}

/**
 Reads video frame from shared memory object.
 
 @return Video frame data
 */
uint8_t *RAK5206::readVideo()
{
    return sharedMemory->readVideoFrame();
}

/**
 Stops video, audio and serial data obtainers.
 */
void RAK5206::stop()
{
    videoAndAudioObtainerObject->stop();
    socketObject->stop();
}

/**
 Queries whether the video and audio obtainer is working.
 
 @return Is video and audio obtainer working
 */
bool RAK5206::isRunning()
{
    return videoAndAudioObtainerObject->isRunning() && !socketObject->lostConnection();
}

/**
 Writes forwarded serial data.
 
 @param data Serial data
 */
void RAK5206::writeSerial(std::string data)
{
    socketObject->writeSerial(data);
}
void RAK5206::writeSerial(char *data)
{
    writeSerial(std::string(data));
}

/**
 Reads serial data from shared memory object.
 
 @param size Size of serial data which is forwarded parallel
 @return Serial data
 */
uint8_t *RAK5206::readSerial(int *size)
{
    return sharedMemory->readSerialRead(size);
}

/**
 Reads serial data from shared memory object as string.
 
 @param size Size of serial data which is forwarded parallel
 @return Serial data
 */
std::string RAK5206::readSerial()
{
    return sharedMemory->readSerialRead();
}

/**
 Sends audio data through socket object.
 
 @param data Data to send
 @param numberOfBytes Number of bytes to send
 */
void RAK5206::sendAudio(int16_t *data, long long numberOfBytes)
{
    socketObject->sendAudio(data, numberOfBytes);
}
//    }

