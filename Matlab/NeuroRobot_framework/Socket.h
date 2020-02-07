//
//  Socket.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef Socket_h
#define Socket_h

#include "BackgroundThread.h"
#include "Macros.h"
#include "SharedMemory.h"
#include "Log.h"

#ifdef MATLAB
    #include "TypeDefs.h"
#else
    #include "Bridge/TypeDefs.h"
#endif

#include <chrono>

// Boost includes
#include <boost/asio.hpp>

using boost::asio::ip::tcp;



/**
 Derived class.
 Intended to communicate with Neuro Robot through socket.
 Used to write and read serial data and send audio data.
 */
class Socket : public BackgroundThread, public Log {
    
private:
    std::string ipAddress;
    std::string port;
    
    boost::asio::io_context io_context;
    tcp::socket socket;
    tcp::socket audioSocket;
    tcp::resolver resolver;
    
    std::mutex mutexReconnecting;
    std::mutex mutexSendingToSocket;
    std::mutex mutexSendingToSocket2;
    std::mutex mutexSendingAudio;
    
    // Data used for mechanism of sending serial data
    bool sendingInProgress = false;
    bool pendingWriting = false;
    std::string pendingData = "";
    
    
    
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
    std::string receiveSerial(boost::system::error_code ec);
    
    /**
     Closes audio and serial sockets.
     */
    void closeSockets();
    
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
     Writes audio data in chunks with delays between them.
     Method is resposible to keep ~1sec of data in robot's buffer.
     
     @param data Audio data for sending
     @param numberOfBytes Number of bytes of audio data (Usually it is doubled because of two channels)
     */
    void sendAudioThreaded(int16_t* data, long long numberOfBytes);
    
    void closeDataSocket();
    
    void closeAudioSocket();
    
    
    void updateState(SocketStateType *stateToReturn, SocketStateType stateType, boost::system::error_code errorCode);
    SocketErrorOccurredCallback errorCallback;
    
public:
    
    Socket(std::string ip, std::string port, SocketErrorOccurredCallback callback);
    
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
     Prepares audio data for sending. Initializes sending audio data.
     
     @param data Audio data
     @param numberOfBytes Number of bytes to send
     */
    void sendAudio(int16_t* data, long long numberOfBytes);
    
    
    SocketStateType stateType = SocketStateNotInitialized;
};


#endif /* Socket_h */
