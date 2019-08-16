//
//  RAK5206.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 6/9/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef RAK5206_h
#define RAK5206_h

#include "Macros.h"
#include "SharedMemory.h"
#include "VideoAndAudioObtainer.h"
#include "Socket.h"

/**
 Base RAK API class. It is intended to have only one statically allocated object of this class and all mex calls will be executed through that object.
 */
class RAK5206
{
private:
    SharedMemory *sharedMemory = new SharedMemory();
    VideoAndAudioObtainer *videoAndAudioObtainerObject;
    Socket *socketObject;
    
public:
    RAK5206(std::string ipAddress, std::string port, int *error);
//    RAK5206(char *ipAddress, char *port);
//    void init(std::string ipAddress, std::string port);
//    void initialize(char *ipAddress, char *port);
    void start();
    int16_t *readAudio(int *size);
    uint8_t *readVideo();
    void stop();
    bool isRunning();
    void writeSerial(std::string data);
    void writeSerial(char *data);
    uint8_t *readSerial(int *size);
    /**
     Reads serial data from shared memory object as string.
     
     @param size Size of serial data which is forwarded parallel
     @return Serial data
     */
    std::string readSerial();
    
    void sendAudio(int16_t *data, long long numberOfBytes);
};

#endif /* RAK5206_h */
