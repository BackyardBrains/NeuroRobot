//
//  NeuroRobotManager.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef NeuroRobotManager_h
#define NeuroRobotManager_h

#include "Macros.h"
#include "SharedMemory.h"
#include "VideoAndAudioObtainer.h"
#include "Socket.h"

#ifdef MATLAB
    #include "TypeDefs.h"
#else
    #include "Bridge/TypeDefs.h"
#endif

/// Base `Neuro Robot` API class.
/// It is intended to have only one statically allocated object of this class and whole communication with robot will be executed through that object.
class NeuroRobotManager: public Log
{
    
private:
    
    /// Video/Audio worker.
    VideoAndAudioObtainer *videoAndAudioObtainerObject = NULL;
    
    /// Socket worker.
    Socket *socketObject = NULL;
    
    /// Flag whether to block obtaining audio data.
    /// @warning Used only for testing
    bool audioBlocked = false;
    
    /// Flag whether to block serial communication through socket.
    /// @warning Used only for testing
    bool socketBlocked = false;
    
public:

    /// Init workers to communicate with robot.
    /// @param ipAddress IP address of robot
    /// @param port Port used for serial communication
    /// @param streamCallback Stream callback for notifying about errors while obtaining video and audio data
    /// @param socketCallback Socket callback for notifying about errors while communicating through socket
    NeuroRobotManager(std::string ipAddress, std::string port, StreamErrorOccurredCallback streamCallback, SocketErrorOccurredCallback socketCallback);
    
    /// Start the video, audio and serial data workers.
    void start();
    
    /// Read audio from shared memory object.
    /// @param totalBytes Total number of bytes forwarded parallel
    /// @param bytesPerSample Number of bytes per one sample
    /// @return Pointer to audio data
    void *readAudio(size_t *totalBytes, unsigned short *bytesPerSample);
    
    /// Read video frame from shared memory object.
    /// @return Pointer to frame data
    uint8_t *readVideoFrame();
    
    /// Stop video, audio and serial data workers.
    void stop();
    
    /// Queries whether the video and audio obtainer is working.
    /// @return Flag whether workers are running
    bool isRunning();
    
    /// Write forwarded serial data.
    /// @param data Serial data
    void writeSerial(std::string data);
    
    /// Write forwarded serial data.
    /// @param data Pointer to serial data
    /// @warning Data have to be terminated with `\0'.
    void writeSerial(char *data);
    
    /// Read serial data from stock.
    /// @param totalBytes Total number of bytes forwarded parallel
    /// @return Pointer to serial data
    char *readSerial(size_t *totalBytes);
    
    /// Read state of video/audio worker.
    /// @return State of video/audio worker.
    /// @see `StreamStateType` enum for possible states
    StreamStateType readStreamState();
    
    /// Read state of socket worker.
    /// @return State of socket worker.
    /// @see `SocketStateType` enum for possible states
    SocketStateType readSocketState();
    
    /// Send audio data through socket worker.
    /// @param data Pointer to audio data
    /// @param totalBytes Total number of bytes to send
    void sendAudio(int16_t *data, size_t totalBytes);
    
    /// Total number of frame data bytes.
    size_t videoFrameBytes();
    
    /// Total number of audio data bytes.
    size_t audioBytes();
    
    /// Get audio sample rate in Hz.
    /// @return Audio sample rate
    unsigned int audioSampleRate();
    
    /// Video width
    /// @return Video width in px
    unsigned int videoWidth();
    
    /// Video height
    /// @return Video height in px
    unsigned int videoHeight();
};

#endif /* NeuroRobotManager_h */
