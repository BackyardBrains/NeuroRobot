//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//


#include "RAK5206.h"

#include <iostream>

/**
 Inits video and audio obtainer object and socket object.
 */
RAK5206::RAK5206(std::string ipAddress, std::string port, StreamStateType *error, ErrorOccurredCallback errorCallback)
{
    videoAndAudioObtainerObject = new VideoAndAudioObtainer(sharedMemory, ipAddress, error, errorCallback, audioBlocked);
    if (!socketBlocked) {
        socketObject = new Socket(sharedMemory, ipAddress, port);
    }
}

/**
 Starts the video, audio and serial data obtainers.
 */
void RAK5206::start()
{
    videoAndAudioObtainerObject->startThreaded();
    if (!socketBlocked) {
        socketObject->startThreaded();
    }
}

/**
 Reads audio from shared memory object.
 
 @param size Size of audio data which is forwarded parallel
 @return Audio data
 */
int16_t *RAK5206::readAudio(int *size)
{
    if (!audioBlocked) {
        int16_t *reply = sharedMemory->readAudio(size);
        return reply;
    } else {
        static int16_t *audioDataFoo = new int16_t[sharedMemory->audioSize * 2 * 10];
        return audioDataFoo;
    }
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
    if (!socketBlocked) {
        socketObject->stop();
    }
}

/**
 Queries whether the video and audio obtainer is working.
 
 @return Is video and audio obtainer working
 */
bool RAK5206::isRunning()
{
    if (!socketBlocked) {
        return videoAndAudioObtainerObject->isRunning() && videoAndAudioObtainerObject->state == StreamErrorNone && socketObject->isRunning() && socketObject->state == SocketErrorNone;
    } else {
        return videoAndAudioObtainerObject->isRunning() && videoAndAudioObtainerObject->state == StreamErrorNone;
    }
}

/**
 Writes forwarded serial data.
 
 @param data Serial data
 */
void RAK5206::writeSerial(std::string data)
{
    if (!socketBlocked) {
        socketObject->writeSerial(data);
    }
}
void RAK5206::writeSerial(char *data)
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
uint8_t *RAK5206::readSerial(int *size)
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
void RAK5206::sendAudio(int16_t *data, long long numberOfBytes)
{
    if (!audioBlocked) {
        socketObject->sendAudio(data, numberOfBytes);
    }
}

StreamStateType RAK5206::readStreamState()
{
    return videoAndAudioObtainerObject->state;
}

SocketStateType RAK5206::readSocketState()
{
    if (!socketBlocked) {
        return socketObject->state;
    } else {
        return SocketNotStarted;
    }
}
