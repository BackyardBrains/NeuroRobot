//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "MexThread.h"
#include "Macros.h"
#include "SharedMemory.cpp"
#include "Log.cpp"

#include <iostream>
#include <chrono>

// Boost includes
#include <boost/asio.hpp>
#include <boost/thread/thread.hpp>
#include <boost/algorithm/string.hpp>

using boost::asio::ip::tcp;

typedef boost::asio::detail::socket_option::integer<SOL_SOCKET, SO_RCVTIMEO> rcv_timeout_option;

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
    
public:
    Socket(SharedMemory* sharedMemory, std::string ip, std::string port)
        : socket_(io_context)
        , audioSocket_(io_context)
    {
        className = "Socket";
        openStreams();

        sharedMemoryInstance = sharedMemory;

        ipAddress_ = ip;
        port_ = port;
    }
    
    
    /**
     Overloaded method which is running from separate thread.
     */
    void run()
    {
        connectSerialSocket(ipAddress_, port_);
        #ifdef _WIN32 
            socket_.set_option(rcv_timeout_option{ 1000 });
        #endif
            
        uint8_t dataToOpenReceiving[] = { 0x01, 0x55 };
        send(&socket_, dataToOpenReceiving, 2);
        boost::system::error_code ec;

        while (isRunning()) {

            std::string readSerialData = receiveSerial(&ec);

            if (ec == boost::asio::error::eof) {
                mutexSendingToSocket.lock();
                logMessage("error while receiving: eof");
                socket_.close();
                connectSerialSocket(ipAddress_, port_);
                #ifdef _WIN32 
                    socket_.set_option(rcv_timeout_option{ 1000 });
                #endif
                mutexSendingToSocket.unlock();

                send(&socket_, dataToOpenReceiving, 2);

                readSerialData = receiveSerial(&ec);
            }


            if (readSerialData.length() > 0) {
                if (isRunning()) {
                    sharedMemoryInstance->writeSerialRead(readSerialData);
                }
                logMessage(readSerialData);
            }
        }
        closeSocket();

        logMessage("Socket -> read serial ended");
    }
    
    /**
     Prepares serial data for sending. Initializes sending serial data.
     In case where data is already in process of sending, then it saves data locally for later sending.

     @param data Data for sending
     */
    void writeSerial(std::string data)
    {
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
    
    
    /**
     Helper method for initialize sending serial data from other thread.

     @param data Data for sending
     */
    void writeSerialThreadedString(std::string data)
    {
        writeSerialThreaded((uint8_t*)data.c_str(), data.length());
    }
    
    /**
     Writes serial data.
     In the end it decides whether to send pending data if any.

     @param data Data for sending
     @param length Length of data
     */
    void writeSerialThreaded(uint8_t* data, size_t length)
    {
        size_t totalLength = length + 3;
        uint8_t header[] = { 0x01, 0x55 };
        uint8_t* wholeData = (uint8_t*)malloc(totalLength);
        uint8_t footer[] = { '\n' };
        memcpy(wholeData, header, 2);
        memcpy(&wholeData[2], data, length);
        memcpy(&wholeData[totalLength - 1], footer, 1);
        
        logMessage("serial data sent size: " + std::to_string(send(&socket_, wholeData, totalLength)));
        free(wholeData);
        
        sendingInProgress = false;
        if (pendingWriting) {
            pendingWriting = false;
            writeSerial(pendingData);
        }
    }

    /**
     Prepares audio data for sending. Initializes sending audio data.

     @param data Audio data
     @param numberOfBytes Number of bytes to send
     */
    void sendAudio(int16_t* data, long long numberOfBytes)
    {
        int16_t* dataToSend = (int16_t*)malloc(numberOfBytes + 1);
        std::memcpy(dataToSend, data, numberOfBytes);
        std::thread thread(&Socket::sendAudioThreaded, this, dataToSend, numberOfBytes);
        thread.detach();
    }

    /**
     Writes audio data in chunks with delays between them.
     Method is resposible to keep ~1sec of data in RAK's buffer.

     @param data Audio data for sending
     @param numberOfBytes Number of bytes of audio data (Usually it is doubled because of two channels)
     */
    void sendAudioThreaded(int16_t* data, long long numberOfBytes)
    {
        mutexSendingAudio.lock();
        
        int sentBytes = 0;
        int packetSize = 1000;
        int sampleRate = 8000;
        short numberOfChannels = 2;
        int packetSizeInMilliseconds = ((float)packetSize / numberOfChannels) / sampleRate * 1000;
        long elapsedTime = 0;
        long difference = 0;
        std::chrono::system_clock::time_point beginTime;
        
        connectAudioSocket(ipAddress_, port_);

        std::string header = std::string();
        header.append("POST /audio.input HTTP/1.1\r\n");
        header.append("Host: ");
        header.append(ipAddress_);
        header.append("\r\n");
        header.append("Content-Type: audio/wav\r\n");
        header.append("Content-Length: ");
        header.append(lltoa(numberOfBytes));
        header.append("\r\n");
        header.append("Connection: keepalive\r\n");
        header.append("Accept: */*\r\n\r\n");
        send(&audioSocket_, header.c_str(), header.length());
        logMessage(header);
        boost::this_thread::sleep_for(boost::chrono::milliseconds(100));

        uint8_t* repackedData = repack(data, numberOfBytes);
        free(data);

        
        beginTime = std::chrono::system_clock::now();
        
        while (numberOfBytes && isRunning()) {
            size_t sentSize;
            
            // Calculating how many seconds there are in RAK's buffer which are not played. Try to keep 1 second adventege of data in buffer.
            elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - beginTime).count();
            long sentDataInMilliseconds = (float)sentBytes / packetSize * packetSizeInMilliseconds;
            difference = sentDataInMilliseconds - elapsedTime;
            if (difference > 1000) {
                // 1015 = 1 sec + 15ms delay in `send` function
                boost::this_thread::sleep_for(boost::chrono::milliseconds(difference - 1015));
            } else {
                // Delay eventually if there is no 1 second in RAK's buffer and make sure to not block socket only with audio data. 
                boost::this_thread::sleep_for(boost::chrono::milliseconds(20));
            }
            
            if (numberOfBytes > packetSize) {
                sentSize = send(&audioSocket_, &repackedData[sentBytes], packetSize);
                numberOfBytes -= packetSize;
                sentBytes += packetSize;
            } else {
                sentSize = send(&audioSocket_, &repackedData[sentBytes], numberOfBytes);
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

        audioSocket_.close();
        mutexSendingAudio.unlock();
    }

    /**
     Rapacks forwarded audio data.
     It creates two channels from one and rapcks signed 16bit linear signal to unsigned 8bit ulaw signal.

     @param data Audio data for repacking
     @param numberOfBytes Number of bytes of audio data
     @return Repacked data
     */
    uint8_t* repack(int16_t* data, long long numberOfBytes)
    {
        short numberOfChannels = 2;
        long long numberOfSamples_16bit = numberOfBytes * 0.5;

        // Creating two channels signal. LRLR patern
        int16_t* twoChannelsData = (int16_t*)malloc(numberOfChannels * numberOfBytes);
        for (long long i = 0; i < numberOfSamples_16bit; i++) {
            memcpy(&twoChannelsData[i * 2], &data[i], 2);
            memcpy(&twoChannelsData[i * 2 + 1], &data[i], 2);
        }

        // Repacking signed 16bit linear signal to unsigned 8bit ulaw signal
        uint8_t* PCM_Data = (uint8_t*)malloc(numberOfChannels * numberOfSamples_16bit);
        for (long long i = 0; i < numberOfSamples_16bit * numberOfChannels; i++) {
            PCM_Data[i] = linear2ulaw(twoChannelsData[i]);
        }
        free(twoChannelsData);
        return PCM_Data;
    }
    
    /**
     Rapacks chunk of audio data from linear to ulaw signal.
     
     @param pcm_val Chunk of audio data for rapacking
     @return Repacked chunk of audio data
     
     @see https://en.wikipedia.org/wiki/Μ-law_algorithm
     */
    uint8_t linear2ulaw(int pcm_val) /* 2's complement (16-bit range) */
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
    
    /**
     Searches for part in forwarded bounds of forwarded chunk of audio data

     @param val Chunk of audio data for deciding its part in table[]
     @param table Array of bounds
     @param size Size of table[]
     @return index of part in table[]
     
     @see https://en.wikipedia.org/wiki/Μ-law_algorithm
     */
    int search(int val, int table[], int size)
    {
        for (int i = 0; i < size; i++) {
            if (val <= table[i]) {
                return i;
            }
        }
        return size;
    }
    
    /**
     Converts long long number into a string.

     @param number Long Long number
     @return Char array of number
     */
    char* lltoa(long long number)
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

    // MARK:- Socket APIs
    
    /**
     Connects to socket for serial data.

     @param host Ip address of socket
     @param service Port of socket
     */
    void connectSerialSocket(const std::string& host, const std::string& service)
    {
        boost::system::error_code ec;
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket_, resolver.resolve(host, service), ec);
        if (ec) {
            logMessage("Connect to serial socket error");
        }
    }
    
    /**
     Connects to socket for audio data.

     @param host Ip address of socket
     @param service Port of socket
     */
    void connectAudioSocket(const std::string& host, const std::string& service)
    {
        boost::system::error_code ec;
        tcp::resolver resolver(io_context);
        boost::asio::connect(audioSocket_, resolver.resolve(host, service), ec);
        if (ec) {
            logMessage("Connect to audio socket error");
        }
    }
    
    /**
     Sends the forwarded data to forwarded socket.

     @param socket Socket which is determined to receive the data
     @param data Data for sending
     @param length Length of data for sending
     @return Number of sent bytes
     */
    size_t send(tcp::socket* socket, const void* data, size_t length)
    {
        boost::system::error_code ec;

        mutexSendingToSocket.lock();
        size_t sentSize = boost::asio::write(*socket, boost::asio::buffer(data, length), ec);
        boost::this_thread::sleep_for(boost::chrono::milliseconds(15));
        mutexSendingToSocket.unlock();

        return sentSize;
    }
    
    /**
     Receives the serial data.
     It takes only last valid line.

     @param ec Error code while receiving the data if any
     @return Received data from socket data
     */
    std::string receiveSerial(boost::system::error_code* ec)
    {
        boost::asio::streambuf b;
        boost::asio::read_until(socket_, b, "\r\n", *ec);
        if (*ec == boost::asio::error::eof) {
            logMessage("Error readUntill");
            return "";
        }
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

        return dataPreLastLine;
    }
    
    /**
     Closes audio and serial sockets.
     */
    void closeSocket()
    {
        logMessage("------------- Close socket -----------");
        socket_.close();
        audioSocket_.close();
    }
};
