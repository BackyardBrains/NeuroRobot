//
//  Socket.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "Socket.h"

#include <iostream>
#include <chrono>

#ifdef XCODE
    #include "Bridge/Helpers/AudioHelper.hpp"
#else
    #include "Helpers/AudioHelper.hpp"
#endif

// Boost includes
#include <boost/thread/thread.hpp>
#include <boost/algorithm/string.hpp>

typedef boost::asio::detail::socket_option::integer<SOL_SOCKET, SO_RCVTIMEO> rcv_timeout_option;

/// Convert long long number into a string.
/// @param number Long Long number
/// @return Char array of number
static char* lltoa(long long number)
{
    static char buffer[sizeof(number) * 3 + 1]; // Size could be a bit tighter
    char* p = &buffer[sizeof(buffer)];
    *(--p) = '\0';
    lldiv_t qr;
    qr.quot = number;
    do {
        qr = lldiv(qr.quot, 10);
        *(--p) = abs(qr.rem) + '0';
    } while (qr.quot);
    if (number < 0) {
        *(--p) = '-';
    }
    return p;
}

//MARK:- Socket
Socket::Socket(std::string ip_, std::string port_, SocketErrorOccurredCallback callback_)
: socket(io_context)
, audioSocket(io_context)
, resolver(io_context)
, audioResolver(io_context)
, Log("Socket")
{
    ipAddress = ip_;
    port = port_;
    errorCallback = callback_;
    
    connectSerialSocket(ipAddress, port);
}

Socket::~Socket()
{
    if (whileLoopIsRunning) {
        semaphore.wait();
    }
    closeSockets();
}

void Socket::run()
{
    logMessage("run >> entered ");
    
    whileLoopIsRunning = true;
    while (isRunning()) {
        logMessage("run >> while >> entered ");
        
        boost::system::error_code ec;
        std::string readSerialData = receiveSerial(&ec);
        logMessage("run >> while >> received ");
        
        if (ec) {
            logMessage("run >> while >> error ");
            updateState(SocketStateEOF, ec);
            
            mutexReconnecting.lock();
            closeDataSocket();
            boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
            connectSerialSocket(ipAddress, port);
            mutexReconnecting.unlock();
        }
        logMessage("run >> while >> no err ");
        
        if (readSerialData.length() > 0) {
            if (isRunning()) {
                SharedMemory::getInstance()->setSerialData(readSerialData);
                logMessage("run >> while >> setSerialData");
            }
            readSerialData.erase(std::remove(readSerialData.begin(), readSerialData.end(), '\n'), readSerialData.end());
            logMessage(readSerialData);
        }
    }
    whileLoopIsRunning = false;
    closeSockets();
    semaphore.signal();
    
    logMessage("Socket -> read serial ended");
}

void Socket::send(std::string stringData)
{
    if (stateType != SocketStateConnected) {
        return;
    }
    mutexSendingToSocket2.lock();
    if (sendingInProgress) {
        pendingWriting = true;
        pendingData = pendingData + "\n" + stringData;
    } else {
        sendingInProgress = true;
        pendingData = "";
        std::thread thread(&Socket::writeSerialThreadedString, this, stringData);
        thread.detach();
    }
    mutexSendingToSocket2.unlock();
}

void Socket::writeSerialThreadedString(std::string stringData)
{
    uint8_t* data = (uint8_t*)stringData.c_str();
    size_t dataBytes = stringData.length();
    size_t totalBytes = dataBytes + 3;
    
    uint8_t header[] = { 0x01, 0x55 };
    uint8_t* wholeData = new uint8_t[totalBytes];
    uint8_t footer[] = { '\n' };
    memcpy(wholeData, header, 2);
    memcpy(&wholeData[2], data, dataBytes);
    memcpy(&wholeData[totalBytes - 1], footer, 1);
    
    size_t sentBytes = send(&socket, wholeData, totalBytes);
    logMessage("serial data sent size: " + std::to_string(sentBytes));
    delete [] wholeData;
    
    sendingInProgress = false;
    if (pendingWriting) {
        pendingWriting = false;
        send(pendingData);
    }
}

void Socket::sendAudio(int16_t* data, size_t numberOfBytes)
{
    if (stateType != SocketStateConnected) {
        return;
    }
    int16_t* dataToSend = (int16_t*)malloc(numberOfBytes + 1);
    std::memcpy(dataToSend, data, numberOfBytes);
    std::thread thread(&Socket::sendAudioThreaded, this, dataToSend, numberOfBytes);
    thread.detach();
}

void Socket::sendAudioThreaded(int16_t* data, size_t numberOfBytes)
{
    mutexSendingAudio.lock();
    
    int sampleRate = 8000;
    int sentBytes = 0;
    size_t packetSize = 4096;
    short numberOfChannels = 2;
    long long maxMSInBuffer = 500;
    long long elapsedTime = 0;
    long long difference = 0;
    
    int packetSizeInMilliseconds = ((float)packetSize / numberOfChannels) / sampleRate * 1000;
    
    std::chrono::system_clock::time_point beginTime;
    
    connectAudioSocket(ipAddress, port);
    if (stateType != SocketStateConnected) {
        mutexSendingAudio.unlock();
        return;
    }
    
    std::string header = std::string();
    header.append("POST /audio.input HTTP/1.1\r\n");
    header.append("Host: ");
    header.append(ipAddress);
    header.append("\r\n");
    header.append("Content-Type: audio/wav\r\n");
    header.append("Content-Length: ");
    header.append(lltoa(numberOfBytes));
    header.append("\r\n");
    header.append("Connection: keepalive\r\n");
    header.append("Accept: */*\r\n\r\n");
    send(&audioSocket, header.c_str(), header.length());
    logMessage(header);
    boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
    
    uint8_t* repackedData = AudioHelper::repack(data, numberOfBytes);
    free(data);
    
    beginTime = std::chrono::system_clock::now();
    
    while (numberOfBytes && isRunning()) {
        size_t sentSize;
        
        /// Calculating how many ms there are in robot's buffer which are not played. Try to keep apx. 500ms adventege of data in buffer.
        elapsedTime = (long long)std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
        long long sentDataInMilliseconds = (float)sentBytes / packetSize * packetSizeInMilliseconds;
        difference = sentDataInMilliseconds - elapsedTime;
        logMessage("sendAudioThreaded >>> difference: " + std::to_string(difference));
        
        /// Keep apx. 500ms in robot's buffer. For 1000ms, video stream stuck.
        /// Make delay of at least 100ms and make sure not to block robot only with audio data.
        long long sleepMS = difference - maxMSInBuffer;
        if (sleepMS < 100) sleepMS = 100;
        boost::this_thread::sleep_for(boost::chrono::milliseconds(sleepMS));
        
        /// Whether to send full packet or rest of the audio data.
        if (numberOfBytes > packetSize) {
            sentSize = send(&audioSocket, &repackedData[sentBytes], packetSize);
            numberOfBytes -= packetSize;
            sentBytes += packetSize;
        } else {
            sentSize = send(&audioSocket, &repackedData[sentBytes], numberOfBytes);
            sentBytes += packetSize;
            numberOfBytes = 0;
            
            /// Wait until the song is over and add additionally 2 sec just in case
            sentDataInMilliseconds = (float)sentBytes / packetSize * packetSizeInMilliseconds;
            difference = sentDataInMilliseconds - elapsedTime;
            boost::this_thread::sleep_for(boost::chrono::milliseconds(difference + 2000));
        }
        logMessage("audio chunk sent");
    }
    
    free(repackedData);
    
    closeAudioSocket();
    mutexSendingAudio.unlock();
}

void Socket::connectSerialSocket(const std::string& ipAddress, const std::string& port)
{
    boost::system::error_code ec;
    updateState(SocketStateConnecting, ec);
    
    boost::asio::connect(socket, resolver.resolve(ipAddress, port), ec);
    if (ec) {
        updateState(SocketErrorCannotConnect, ec);
        logMessage("connectSerialSocket >>> error: " + ec.message() + " ipAddress: " + ipAddress + " port: " + port);
    } else {
        #ifdef _WIN32
            socket.set_option(rcv_timeout_option{ 1000 }, ec);
            if (ec) {
                logMessage("connectSerialSocket >>> socket.set_option error: " + ec.message());
            }
        #endif
        
        uint8_t dataToOpenReceiving[] = { 0x01, 0x55 };
        size_t sentSize = socket.send(boost::asio::buffer(dataToOpenReceiving, 2), 0, ec);
        
        logMessage("connectSerialSocket >>> sentSize: " + std::to_string(sentSize));
        
        if (!sentSize || ec) {
            logMessage("connectSerialSocket >>> cannot open socket");
            logMessage("connectSerialSocket >>> ec: " + ec.message());
        } else {
            boost::this_thread::sleep_for(boost::chrono::milliseconds(200));
            updateState(SocketStateConnected, ec);
        }
    }
}

void Socket::connectAudioSocket(const std::string& ipAddress, const std::string& port)
{
    boost::system::error_code ec;
    boost::asio::connect(audioSocket, audioResolver.resolve(ipAddress, port), ec);
    if (ec) {
        updateState(SocketErrorConnectingAudioSocket, ec);
    }
}

size_t Socket::send(tcp::socket* socket, const void* data, size_t totalBytes)
{
    logMessage("send >> enter");
    if (stateType != SocketStateConnected) {
        return 0;
    }
    boost::system::error_code ec;
    
    mutexSendingToSocket.lock();
    size_t sentSize = boost::asio::write(*socket, boost::asio::buffer(data, totalBytes), ec);
    logMessage("send >> boost::asio::write >> size: " + std::to_string(sentSize));
    if (ec) {
        logMessage("send >> error " + ec.message());
        if ((boost::asio::error::eof == ec) || (boost::asio::error::connection_reset == ec)) {
            //when we lose wifi network completely this error will appear net time we try to send something:
            //Error in Socket::send: An existing connection was forcibly closed by the remote host
            logMessage("We lost WiFi network. Need to reset everything.");
            updateState(SocketErrorLostConnection, ec);
        } else {
            updateState(SocketErrorWhileSending, ec);
        }
    }
    logMessage("send >> no err ");
    boost::this_thread::sleep_for(boost::chrono::milliseconds(20));
    mutexSendingToSocket.unlock();
    
    return sentSize;
}

std::string Socket::receiveSerial(boost::system::error_code* ec)
{
    logMessage("receiveSerial >> entered");
    if (stateType != SocketStateConnected && !socket.is_open()) {
        return "";
    }
    logMessage("receiveSerial >> passed >> stateType != SocketStateConnected");
    boost::asio::streambuf b(10000);
    logMessage("receiveSerial >> boost::asio::streambuf b;");
    boost::asio::read_until(socket, b, "\r\n", *ec);
    logMessage("receiveSerial >> boost::asio::read_until(");
    
    if (*ec) { logMessage("receiveSerial >> ec >> " + ec->message()); return ""; }
    
    std::istream is(&b);
    std::string data;
    std::string dataFoo;
    std::string dataLastLine;
    std::string dataPreLastLine;
    
    while (std::getline(is, dataFoo)) {
        dataPreLastLine = dataLastLine;
        dataLastLine = dataFoo;
    }
    
    if (dataPreLastLine == "") {
        dataPreLastLine = dataLastLine;
    }
    
    boost::erase_all(dataPreLastLine, "\x01U");
    logMessage("receiveSerial >> done");
    
    return dataPreLastLine;
}

void Socket::closeSockets()
{
    if (stateType == SocketStateStopped) { return; }
    boost::system::error_code ec;
    updateState(SocketStateStopped, ec);
    
    logMessage("------------- closeSockets -----------");
    
    closeDataSocket();
    closeAudioSocket();
    
    io_context.reset();
    io_context.stop();
}

void Socket::closeDataSocket()
{
    boost::system::error_code ec;
    
    resolver.cancel();
    socket.cancel(ec);
    if (ec) {
        updateState(SocketInfoCannotCancelDataSocket, ec);
    }
    socket.close(ec);
    if (ec) {
        updateState(SocketInfoCannotCloseDataSocket, ec);
    }
}

void Socket::closeAudioSocket()
{
    boost::system::error_code ec;
    
    audioResolver.cancel();
    
    audioSocket.cancel(ec);
    if (ec) {
        updateState(SocketInfoCannotCancelAudioSocket, ec);
    }
    
    audioSocket.close(ec);
    if (ec) {
        updateState(SocketInfoCannotCloseAudioSocket, ec);
    }
}

void Socket::updateState(SocketStateType stateType_, boost::system::error_code errorCode)
{
    stateType = stateType_;
    
    std::string errorMessage = "(no desc)";
    if (errorCode) {
        errorMessage = errorCode.message();
    }
    
    logMessage("updateState >>> state: '" + std::string(getSocketStateMessage(stateType)) + "' >>> " + errorMessage);
    if (errorCallback && stateType >= 100) {
        errorCallback(stateType);
    }
}
