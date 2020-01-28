//
//  NeuroRobotManager.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 6/9/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef NeuroRobot_h
#define NeuroRobot_h

#include "Macros.h"
#include "SharedMemory.h"
#include "VideoAndAudioObtainer.h"
#include "Socket.h"

#ifdef MATLAB
    #include "TypeDefs.h"
#else
    #include "Bridge/TypeDefs.h"
#endif


/**
 Base Neuro Robot API class. It is intended to have only one statically allocated object of this class and all mex calls will be executed through that object.
 */
class NeuroRobotManager: public Log
{
private:
//    SharedMemory *sharedMemory = new SharedMemory();
    VideoAndAudioObtainer *videoAndAudioObtainerObject = NULL;
    Socket *socketObject = NULL;
    
    bool audioBlocked = false;
    bool socketBlocked = false;
    
public:
    NeuroRobotManager(std::string ipAddress, std::string port, StreamStateType *error, StreamErrorOccurredCallback streamCallback, SocketErrorOccurredCallback socketCallback);
    void start();
    int16_t *readAudio(int *size);
    uint8_t *readVideo();
    void stop();
    bool isRunning();
    void writeSerial(std::string data);
    void writeSerial(char *data);
    uint8_t *readSerial(int *size);
    
    StreamStateType readStreamState();
    SocketStateType readSocketState();
    
    void sendAudio(int16_t *data, long long numberOfBytes);
    long long frameDataCount();
    long long audioSampleCount();
    
    int audioSampleRate();
    
    int videoWidth();
    int videoHeight();
};

#endif /* NeuroRobot_h */
