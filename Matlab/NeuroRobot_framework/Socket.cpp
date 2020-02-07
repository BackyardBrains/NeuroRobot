
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "Socket.h"

#include <iostream>
#include <chrono>

// Boost includes
#include <boost/thread/thread.hpp>
#include <boost/algorithm/string.hpp>

typedef boost::asio::detail::socket_option::integer<SOL_SOCKET, SO_RCVTIMEO> rcv_timeout_option;


/**
 Searches for part in forwarded bounds of forwarded chunk of audio data
 
 @param val Chunk of audio data for deciding its part in table[]
 @param table Array of bounds
 @param size Size of table[]
 @return index of part in table[]
 
 @see https://en.wikipedia.org/wiki/Μ-law_algorithm
 */
static int search(int val, int table[], int size);

/**
 Converts long long number into a string.
 
 @param number Long Long number
 @return Char array of number
 */
static char* lltoa(long long number);

/**
 Rapacks forwarded audio data.
 It creates two channels from one and rapcks signed 16bit linear signal to unsigned 8bit ulaw signal.
 
 @param data Audio data for repacking
 @param numberOfBytes Number of bytes of audio data
 @return Repacked data
 */
static uint8_t* repack(int16_t* data, long long numberOfBytes);

/**
 Rapacks chunk of audio data from linear to ulaw signal.
 
 @param pcm_val Chunk of audio data for rapacking
 @return Repacked chunk of audio data
 
 @see https://en.wikipedia.org/wiki/Μ-law_algorithm
 */
static uint8_t linear2ulaw(int pcm_val); /* 2's complement (16-bit range) */

//MARK: Static functions - implemetation
static uint8_t* repack(int16_t* data, long long numberOfBytes)
{
    short numberOfChannels = 2;
    long long numberOfSamples_16bit = numberOfBytes * 0.5;
    
    // Creating two channels signal. LRLR patern
    int16_t* twoChannelsData = (int16_t*)malloc((size_t)(numberOfChannels * numberOfBytes));
    for (long long i = 0; i < numberOfSamples_16bit; i++) {
        memcpy(&twoChannelsData[i * 2], &data[i], 2);
        memcpy(&twoChannelsData[i * 2 + 1], &data[i], 2);
    }
    
    // Repacking signed 16bit linear signal to unsigned 8bit ulaw signal
    uint8_t* PCM_Data = (uint8_t*)malloc((size_t)(numberOfChannels * numberOfSamples_16bit));
    for (long long i = 0; i < numberOfSamples_16bit * numberOfChannels; i++) {
        PCM_Data[i] = linear2ulaw(twoChannelsData[i]);
    }
    free(twoChannelsData);
    return PCM_Data;
}

static uint8_t linear2ulaw(int pcm_val) /* 2's complement (16-bit range) */
{
    int BIAS = 0x84;
    int seg_end[] = { 0xFF, 0x1FF, 0x3FF, 0x7FF, 0xFFF, 0x1FFF, 0x3FFF, 0x7FFF };
    
    int mask;
    int seg;
    char uval;
    
    /* Get the sign and the magnitude of the value. */
    if (pcm_val < 0) {
        pcm_val = BIAS - pcm_val;
        mask = 0x7F;
    } else {
        pcm_val += BIAS;
        mask = 0xFF;
    }
    
    /* Convert the scaled magnitude to segment number. */
    seg = search(pcm_val, seg_end, 8);
    
    /*
     * Combine the sign, segment, quantization bits;
     * and complement the code word.
     */
    if (seg >= 8) /* out of range, return maximum value. */
        return (0x7F ^ mask);
    else {
        uval = (uint8_t)((seg << 4) | ((pcm_val >> (seg + 3)) & 0xF));
        return (uval ^ mask);
    }
}

static int search(int val, int table[], int size)
{
    for (int i = 0; i < size; i++) {
        if (val <= table[i]) {
            return i;
        }
    }
    return size;
}

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
{
    className = "Socket";
    openLogFile();
    
    ipAddress = ip_;
    port = port_;
    errorCallback = callback_;
    
    connectSerialSocket(ipAddress, port);
}

void Socket::run()
{
    logMessage("run >> entered ");
    return;
    
    while (isRunning()) {
        logMessage("run >> while >> entered ");
        
        boost::system::error_code ec;
        std::string readSerialData = receiveSerial(ec);
        logMessage("run >> while >> received ");
        
        if (ec == boost::asio::error::eof) {
            logMessage("run >> while >> error ");
            updateState(NULL, SocketErrorEOF, ec);
            
            mutexReconnecting.lock();
            closeDataSocket();
            boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
            connectSerialSocket(ipAddress, port);
            mutexReconnecting.unlock();
        }
        logMessage("run >> while >> no err ");
        
        if (readSerialData.length() > 0) {
            if (isRunning()) {
                SharedMemory::getInstance()->writeSerialRead(readSerialData);
                logMessage("run >> while >> writeSerialRead");
            }
            logMessage(readSerialData);
        }
    }
    closeSockets();
    
    logMessage("Socket -> read serial ended");
}

void Socket::writeSerial(std::string data)
{
    if (stateType != SocketStateConnected) {
        return;
    }
    mutexSendingToSocket2.lock();
    if (sendingInProgress) {
        pendingWriting = true;
        pendingData = pendingData + "\n" + data;
    } else {
        sendingInProgress = true;
        std::thread thread(&Socket::writeSerialThreadedString, this, data);
        thread.detach();
        pendingData = "";
    }
    mutexSendingToSocket2.unlock();
}

void Socket::writeSerialThreadedString(std::string data)
{
    writeSerialThreaded((uint8_t*)data.c_str(), data.length());
}

void Socket::writeSerialThreaded(uint8_t* data, size_t length)
{
    size_t totalLength = length + 3;
    uint8_t header[] = { 0x01, 0x55 };
    uint8_t* wholeData = (uint8_t*)malloc(totalLength);
    uint8_t footer[] = { '\n' };
    memcpy(wholeData, header, 2);
    memcpy(&wholeData[2], data, length);
    memcpy(&wholeData[totalLength - 1], footer, 1);
    
    size_t sentBytes = send(&socket, wholeData, totalLength);
    logMessage("serial data sent size: " + std::to_string(sentBytes));
    free(wholeData);
    
    sendingInProgress = false;
    if (pendingWriting) {
        pendingWriting = false;
        writeSerial(pendingData);
    }
}

void Socket::sendAudio(int16_t* data, long long numberOfBytes)
{
    if (stateType != SocketStateConnected) {
        return;
    }
    int16_t* dataToSend = (int16_t*)malloc((size_t)numberOfBytes + 1);
    std::memcpy(dataToSend, data, (size_t)numberOfBytes);
    std::thread thread(&Socket::sendAudioThreaded, this, dataToSend, numberOfBytes);
    thread.detach();
}

void Socket::sendAudioThreaded(int16_t* data, long long numberOfBytes)
{
    mutexSendingAudio.lock();
    
    int sentBytes = 0;
    int packetSize = 1000;
    int sampleRate = SharedMemory::getInstance()->getAudioSampleRate();
    short numberOfChannels = 2;
    int packetSizeInMilliseconds = ((float)packetSize / numberOfChannels) / sampleRate * 1000;
    long long elapsedTime = 0;
    long long difference = 0;
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
    
    uint8_t* repackedData = repack(data, numberOfBytes);
    free(data);
    
    beginTime = std::chrono::system_clock::now();
    
    while (numberOfBytes && isRunning()) {
        size_t sentSize;
        
        // Calculating how many seconds there are in robot's buffer which are not played. Try to keep 1 second adventege of data in buffer.
        elapsedTime = (long long)std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
        long long sentDataInMilliseconds = (float)sentBytes / packetSize * packetSizeInMilliseconds;
        difference = sentDataInMilliseconds - elapsedTime;
        if (difference > 1000) {
            // 1015 = 1 sec + 15ms delay in `send` function
            boost::this_thread::sleep_for(boost::chrono::milliseconds(difference - 1020));
        } else {
            // Delay eventually if there is no 1 second in robot's buffer and make sure to not block socket only with audio data.
            boost::this_thread::sleep_for(boost::chrono::milliseconds(20));
        }
        
        if (numberOfBytes > packetSize) {
            sentSize = send(&audioSocket, &repackedData[sentBytes], packetSize);
            numberOfBytes -= packetSize;
            sentBytes += packetSize;
        } else {
            sentSize = send(&audioSocket, &repackedData[sentBytes], (size_t)numberOfBytes);
            sentBytes += packetSize;
            numberOfBytes = 0;
            
            // Wait until the song is over and add additionally 2 sec just in case
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

void Socket::connectSerialSocket(const std::string& host, const std::string& service)
{
    boost::system::error_code ec;
    updateState(NULL, SocketStateConnecting, ec);
    
    boost::asio::connect(socket, resolver.resolve(host, service), ec);
    if (ec) {
        updateState(NULL, SocketErrorCannotConnect, ec);
        logMessage("connectSerialSocket >>> error: " + ec.message() + " ipAddress: " + host + " port: " + service);
    } else {
        #ifdef _WIN32
            socket.set_option(rcv_timeout_option{ 1000 }, ec);
            if (ec) {
                logMessage("connectSerialSocket >>> socket.set_option error: " + ec.message());
            }
        #else
            boost::asio::ip::tcp::no_delay option(true);
            socket.set_option(option);
        #endif
        
        uint8_t dataToOpenReceiving[] = { 0x01, 0x55 };
        size_t sentSize = socket.send(boost::asio::buffer(dataToOpenReceiving, 2), 0, ec);
        
        logMessage("connectSerialSocket >>> sentSize: " + std::to_string(sentSize));
        
        if (!sentSize || ec) {
            logMessage("connectSerialSocket >>> cannot open socket");
            logMessage("connectSerialSocket >>> ec: " + ec.message());
        } else {
            boost::this_thread::sleep_for(boost::chrono::milliseconds(200));
            updateState(NULL, SocketStateConnected, ec);
        }
    }
}

void Socket::connectAudioSocket(const std::string& host, const std::string& service)
{
    boost::system::error_code ec;
    tcp::resolver resolver(io_context);
    boost::asio::connect(audioSocket, resolver.resolve(host, service), ec);
    if (ec) {
        logMessage("connectAudioSocket >>> error: " + ec.message() + " ipAddress: " + host + " port: " + service);
        stateType = SocketErrorExists;
    }
}

size_t Socket::send(tcp::socket* socket, const void* data, size_t length)
{
    logMessage("send >> enter");
    if (stateType != SocketStateConnected) {
        return 0;
    }
    boost::system::error_code ec;
    
    mutexSendingToSocket.lock();
    logMessage("send >> mutexSendingToSocket locked");
    size_t sentSize = boost::asio::write(*socket, boost::asio::buffer(data, length), ec);
    logMessage("send >> boost::asio::write >> size: " + std::to_string(sentSize));
    if (ec) {
        logMessage("send >> error " + ec.message());
        if ((boost::asio::error::eof == ec) || (boost::asio::error::connection_reset == ec)) {
            //when we lose wifi network completely this error will appear net time we try to send something:
            //Error in Socket::send: An existing connection was forcibly closed by the remote host
            logMessage("We lost WiFi network. Need to reset everything.");
            updateState(NULL, SocketErrorLostConnection, ec);
        } else {
            updateState(NULL, SocketErrorWhileSending, ec);
        }
    }
    logMessage("send >> no err ");
    boost::this_thread::sleep_for(boost::chrono::milliseconds(20));
    mutexSendingToSocket.unlock();
    logMessage("send >> mutexSendingToSocket unlocked ");
    
    return sentSize;
}

std::string Socket::receiveSerial(boost::system::error_code ec)
{
    logMessage("receiveSerial >> entered");
    if (stateType != SocketStateConnected && !socket.is_open()) {
        return "";
    }
    logMessage("receiveSerial >> passed >> stateType != SocketStateConnected");
    boost::asio::streambuf b(10000);
    logMessage("receiveSerial >> boost::asio::streambuf b;");
    boost::asio::read_until(socket, b, "\r\n", ec);

    logMessage("receiveSerial >> boost::asio::read_until(");
    if (ec == boost::asio::error::eof) {
        logMessage("receiveSerial >> if (*ec == boost::asio::error::eof) {");
        logMessage("receiveSerial >> Error readUntill");
        return "";
    }
    logMessage("receiveSerial >> ec >> " + ec.message());
    std::istream is(&b);
    logMessage("receiveSerial >> std::istream is(&b);");
    std::string data;
    std::string dataFoo;
    std::string dataLastLine;
    std::string dataPreLastLine;
    
    logMessage("receiveSerial >> definitions");
    
    while (std::getline(is, dataFoo)) {
        logMessage("receiveSerial >> while (std::getline(is, dataFoo)) {");
        
        dataPreLastLine = dataLastLine;
        logMessage("receiveSerial >> dataPreLastLine = dataLastLine;");
        dataLastLine = dataFoo;
        logMessage("receiveSerial >> dataLastLine = dataFoo;");
    }
    logMessage("receiveSerial >> while passed");
    if (dataPreLastLine == "") {
        logMessage("receiveSerial >> if (dataPreLastLine == "") {");
        dataPreLastLine = dataLastLine;
        logMessage("receiveSerial >> dataPreLastLine = dataLastLine;");
    }
    logMessage("receiveSerial >> if passed");
    
    boost::erase_all(dataPreLastLine, "\x01U");
    logMessage("receiveSerial >> boost::erase_all(");
    
    return dataPreLastLine;
}

void Socket::closeSockets()
{
    logMessage("------------- closeSockets -----------");
    
    resolver.cancel();
    
    closeDataSocket();
    closeAudioSocket();
    
    io_context.reset();
    io_context.stop();
}

void Socket::closeDataSocket() {
    boost::system::error_code ec;
    
    socket.cancel(ec);
    if (ec) {
        updateState(NULL, SocketErrorCannotCancelDataSocket, ec);
    }
    socket.close(ec);
    if (ec) {
        updateState(NULL, SocketErrorCannotCloseDataSocket, ec);
    }
}

void Socket::closeAudioSocket() {
    boost::system::error_code ec;
    
    audioSocket.cancel(ec);
    if (ec) {
        updateState(NULL, SocketErrorCannotCancelAudioSocket, ec);
    }
    
    audioSocket.close(ec);
    if (ec) {
        updateState(NULL, SocketErrorCannotCloseAudioSocket, ec);
    }
}

void Socket::updateState(SocketStateType *stateToReturn, SocketStateType stateType_, boost::system::error_code errorCode)
{
    stateType = stateType_;
    
    std::string errorMessage = "";
    if (errorCode) {
        errorMessage = errorCode.message();
    }
    
    logMessage("updateState >>> state: '" + std::string(getSocketStateMessage(stateType)) + "' >>> " + errorMessage);
    if (errorCallback && stateType >= 100) {
        errorCallback(stateType);
    }
    
    if (stateToReturn) {
        *stateToReturn = stateType;
    }
}
