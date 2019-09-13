//
//  Socket.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef Socket_h
#define Socket_h

#include "MexThread.h"
#include "Macros.h"
#include "SharedMemory.h"
#include "Log.h"

//#include <iostream>
#include <chrono>
//#include <mutex>

// Boost includes
#include <boost/asio.hpp>

using boost::asio::ip::tcp;



/**
 Derived class.
 Intended to communicate with RAK through socket.
 Used to write and read serial data and send audio data.
 */
class Socket : public MexThread, public Log {
    
private:
    std::string ipAddress_;
    std::string port_;
    
    boost::asio::io_context io_context;
    tcp::socket socket_;
    tcp::socket audioSocket_;
    
    std::mutex mutexSendingToSocket;
    std::mutex mutexSendingToSocket2;
    std::mutex mutexSendingAudio;
    
    SharedMemory* sharedMemoryInstance;
    
    
    // Data used for mechanism of sending serial data
    bool sendingInProgress = false;
    bool pendingWriting = false;
    std::string pendingData = "";
    bool lostConnectionFlag = false;
    
public:
    Socket(SharedMemory* sharedMemory, std::string ip, std::string port);
    
    /**
     Overloaded method which is running from separate thread.
     */
    void run();
    
    /**
     Prepares serial data for sending. Initializes sending serial data.
     In case where data is already in process of sending, then it saves data locally for later sending.
     
     @param data Data for sending
     */
    void writeSerial(std::string data);
    
    /**
     Helper method for initialize sending serial data from other thread.
     
     @param data Data for sending
     */
    void writeSerialThreadedString(std::string data);
    
    /**
     Writes serial data.
     In the end it decides whether to send pending data if any.
     
     @param data Data for sending
     @param length Length of data
     */
    void writeSerialThreaded(uint8_t* data, size_t length);
    
    /**
     Prepares audio data for sending. Initializes sending audio data.
     
     @param data Audio data
     @param numberOfBytes Number of bytes to send
     */
    void sendAudio(int16_t* data, long long numberOfBytes);
    
    /**
     Writes audio data in chunks with delays between them.
     Method is resposible to keep ~1sec of data in RAK's buffer.
     
     @param data Audio data for sending
     @param numberOfBytes Number of bytes of audio data (Usually it is doubled because of two channels)
     */
    void sendAudioThreaded(int16_t* data, long long numberOfBytes);
    
    /**
     Rapacks forwarded audio data.
     It creates two channels from one and rapcks signed 16bit linear signal to unsigned 8bit ulaw signal.
     
     @param data Audio data for repacking
     @param numberOfBytes Number of bytes of audio data
     @return Repacked data
     */
    uint8_t* repack(int16_t* data, long long numberOfBytes);
    
    /**
     Rapacks chunk of audio data from linear to ulaw signal.
     
     @param pcm_val Chunk of audio data for rapacking
     @return Repacked chunk of audio data
     
     @see https://en.wikipedia.org/wiki/Μ-law_algorithm
     */
    uint8_t linear2ulaw(int pcm_val); /* 2's complement (16-bit range) */
    
    /**
     Searches for part in forwarded bounds of forwarded chunk of audio data
     
     @param val Chunk of audio data for deciding its part in table[]
     @param table Array of bounds
     @param size Size of table[]
     @return index of part in table[]
     
     @see https://en.wikipedia.org/wiki/Μ-law_algorithm
     */
    int search(int val, int table[], int size);
    
    /**
     Converts long long number into a string.
     
     @param number Long Long number
     @return Char array of number
     */
    char* lltoa(long long number);
    
    // MARK:- Socket APIs
    
    /**
     Connects to socket for serial data.
     
     @param host Ip address of socket
     @param service Port of socket
     */
    void connectSerialSocket(const std::string& host, const std::string& service);
    
    /**
     Connects to socket for audio data.
     
     @param host Ip address of socket
     @param service Port of socket
     */
    void connectAudioSocket(const std::string& host, const std::string& service);
    
    /**
     Sends the forwarded data to forwarded socket.
     
     @param socket Socket which is determined to receive the data
     @param data Data for sending
     @param length Length of data for sending
     @return Number of sent bytes
     */
    size_t send(tcp::socket* socket, const void* data, size_t length);
    
    /**
     Receives the serial data.
     It takes only last valid line.
     
     @param ec Error code while receiving the data if any
     @return Received data from socket data
     */
    std::string receiveSerial(boost::system::error_code* ec);
    
    /**
     * Return True if we detected via socket that we lost connection with WiFi 
     */
    bool lostConnection();
    
    /**
     Closes audio and serial sockets.
     */
    void closeSocket();
};


#endif /* Socket_h */
