//
//  Socket.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
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

#include <boost/asio.hpp>

using boost::asio::ip::tcp;

/// Derived class.
/// Intended to communicate with Neuro Robot through socket.
/// Used to write and read serial data and send audio data.
class Socket : public BackgroundThread, public Log {
    
private:
    std::string ipAddress;
    std::string port;
    
    boost::asio::io_context io_context;
    tcp::socket socket;
    tcp::socket audioSocket;
    tcp::resolver resolver;
    tcp::resolver audioResolver;
    
    std::mutex mutexReconnecting;
    std::mutex mutexSendingToSocket;
    std::mutex mutexSendingToSocket2;
    std::mutex mutexSendingAudio;
    
    /// Serial communication
    bool sendingInProgress = false;
    bool pendingWriting = false;
    std::string pendingData = "";
    
    /// Connect to socket for serial data.
    /// @param ipAddress IP address of robot
    /// @param port Port for socket communication
    void connectSerialSocket(const std::string& ipAddress, const std::string& port);
    
    /// Connect to socket for audio data.
    /// @param ipAddress IP address of robot
    /// @param port Port for socket communication
    void connectAudioSocket(const std::string& ipAddress, const std::string& port);
    
    /// Send the forwarded data to forwarded socket.
    /// @param socket Socket object which is determined to receive the data
    /// @param data Data for sending
    /// @param totalBytes Total number of bytes to send
    size_t send(tcp::socket* socket, const void* data, size_t totalBytes);
    
    /// Receive serial data.
    /// It takes only last valid line.
    /// @param ec Error code used to see which error occurs out of the function
    /// @return Last valid line of data
    std::string receiveSerial(boost::system::error_code *ec);
    
    /// Close serial and audio sockets.
    void closeSockets();
    
    /// Trigger sending data through serial socket.
    /// @param stringData Data for sending
    void writeSerialThreadedString(std::string stringData);
    
    /// Write audio data in chunks with delays between them.
    /// Method is responsible to keep ~1sec of data in robot's buffer.
    /// @param data Pointer to audio data
    /// @param numberOfBytes Total number of bytes of audio data
    void sendAudioThreaded(int16_t* data, size_t numberOfBytes);
    
    /// Close serial socker.
    void closeDataSocket();
    
    /// Close audio socker.
    void closeAudioSocket();
    
    /// Update the state in which socket object is.
    /// @param stateType Enum of possible state
    /// @param errorCode Error code used to parse occured error if any
    void updateState(SocketStateType stateType, boost::system::error_code errorCode);
    
    /// Stored callback for Socket state
    SocketErrorOccurredCallback errorCallback;
    
public:
    
    /// Init socket and connect to serial socket.
    /// @param ip IP address of robot
    /// @param port Port of socket
    /// @param callback Callback in case if the error occurs
    Socket(std::string ip, std::string port, SocketErrorOccurredCallback callback);
    
    /// Overloaded method which is triggered with `startThreaded()`.
    void run();
    
    /**
     Prepares serial data for sending. Initializes sending serial data.
     In case where data is already in process of sending, then it saves data locally for later sending.
     
     @param stringData Data for sending
     */
    void send(std::string stringData);
    
    /**
     Prepares audio data for sending. Initializes sending audio data.
     
     @param data Audio data
     @param numberOfBytes Number of bytes to send
     */
    void sendAudio(int16_t* data, size_t numberOfBytes);
    
    
    SocketStateType stateType = SocketStateNotInitialized;
};


#endif /* Socket_h */
