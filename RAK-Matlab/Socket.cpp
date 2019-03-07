//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright ? 2018 Backyard Brains. All rights reserved.
//

#include <iostream>

#include "MexThread.h"
#include "Macros.h"
#include "SharedMemory.cpp"

// Boost includes
#include <boost/asio.hpp>
#include <boost/chrono.hpp>
#include <boost/thread/thread.hpp>
#include <boost/algorithm/string.hpp>

#ifdef DEBUG
#include <fstream>
#include <ctime>
#include <chrono>
#endif

using boost::asio::ip::tcp;


class Socket : public MexThread
{
private:
    char _ipAddress[64];
    char _port[3];
    
    boost::asio::io_context io_context;
    tcp::socket socket_;
    
    
#ifdef DEBUG
    std::ofstream logFile;
#endif
    
    
    void openStreams() {
#ifdef DEBUG
        logFile.open ("logFile_Socket.txt");
        logMessage("openStreams >> Socket >>> opened");
#endif
    }
    void closeStreams() {
#ifdef DEBUG
        logMessage("closeStreams >>> closed");
        logFile.close();
#endif
    }
    
    void logMessage(std::string message) {
#ifdef DEBUG
        std::time_t end_time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        std::string t(std::ctime(&end_time));
        logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
        std::cout << message << std::endl;
#endif
    }
    
public:
    
    SharedMemory *sharedMemoryInstance;
    
    //// Custom
    bool close = false;
    
    Socket(SharedMemory *sharedMemory, char ip[64], char port[2]) : socket_(io_context)
    {
        openStreams();
        
        sharedMemoryInstance = sharedMemory;
        
        memcpy(_ipAddress, ip, 64);
        memcpy(_port, port, 3);
    }
    
    //-----------------------------------
    // Overloaded methods.
    void run() {
        connect(_ipAddress, _port);
        
        uint8_t dataToOpenReceiving[] = {0x01, 0x55};
        send(dataToOpenReceiving, 2);
        boost::system::error_code ec;
        
        while (!close) {
            
            
            size_t length = 0;
            
            uint8_t *readSerialData = receiveSerial(&ec, &length);
            
            while (ec == boost::asio::error::eof) {
                closeSocket();
                connect(_ipAddress, _port);
                send(dataToOpenReceiving, 2);
                
                readSerialData = receiveSerial(&ec, &length);
            }
            std::cout << "received" << std::endl;
            
            
            if (length > 0) {
                sharedMemoryInstance->writeSerialRead(readSerialData, length);
            }
            
            free(readSerialData);
            
        }
        closeSocket();
        
        logMessage("Socket -> read serial ended");
        
    }
    
    void stop() {
        
        close = true;
    }
    
#ifdef MATLAB
    //! Overload this. Get any additional input parameters
    void parseInputParameters( const std::vector<const mxArray*>& rhs ) {}
#endif
    
#ifdef MATLAB
    //! Overload this. Return results
    void returnResults( mxArray *plhs[] ) {}
#endif
    
    //-----------------------------------
    // Custom methods.
    
    void writeSerial(uint8_t *data, size_t length)
    {
        std::thread thread(&Socket::writeSerialThreaded, this, data, length);
        thread.detach();
    }
    void writeSerial(std::string data)
    {
        logMessage("writeSerialString " + data);
        std::thread thread(&Socket::writeSerialThreadedString, this, data);
        thread.detach();
    }
    void writeSerialThreadedString(std::string data)
    {
        writeSerialThreaded((uint8_t *)data.c_str(), data.length());
    }
    void writeSerialThreaded(uint8_t *data, size_t length)
    {
        logMessage("writeSerialThreaded enter");
        
        size_t totalLength = length + 3;
        uint8_t header[] = { 0x01, 0x55 };
        uint8_t *wholeData = (uint8_t *) malloc(totalLength);
        uint8_t footer[] = { '\n' };
        memcpy(wholeData, header, 2);
        memcpy(&wholeData[2], data, length);
        memcpy(&wholeData[totalLength - 1], footer, 1);
        
        for (int i = 0; i < totalLength; i++) {
            logMessage(std::to_string((char)wholeData[i]));
        }
        
        logMessage("writeSerialThreaded end: " + std::to_string(send(wholeData, totalLength)));
        
        free(wholeData);
    }
    
    void sendAudio(int16_t *data, long long length)
    {
        std::thread thread(&Socket::sendAudioThreaded, this, data, length);
        thread.detach();
    }
    
    void sendAudioThreaded(int16_t *data, long long length)
    {
        uint8_t *repackedData = repack(data, length);
        
        std::cout << "sendAudioThreaded called" << std::endl;
        
        boost::asio::io_context io_context;
        tcp::socket audioSocket(io_context);
        
        boost::system::error_code ec;
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket_, resolver.resolve(_ipAddress, _port), ec);
        
        
        char lengthString[5];
        printf(lengthString, "%d", length);
        
        
        char head1[] = "POST /audio.input HTTP/1.1\r\n";
        char *head2 = (char *) malloc(30);
        strcpy(head2, "Host: ");
        strcat(head2, _ipAddress);
        strcat(head2, "\r\n");
        char head3[] = "Content-Type: audio/wav\r\n";
        char *head4 = (char *) malloc(30);
        strcpy(head4, "Content-Length: ");
        strcat(head4, lengthString);
        strcat(head4, "\r\n");
        char head5[] = "Connection: keepalive\r\n";
        char head6[] = "Accept: */*\r\n\r\n";
        
        char *header = new char[std::strlen(head1) +
                                std::strlen(head2) +
                                std::strlen(head3) +
                                std::strlen(head4) +
                                std::strlen(head5) +
                                std::strlen(head6) + 1];
        
        std::strcpy(header, head1);
        std::strcat(header, head2);
        std::strcat(header, head3);
        std::strcat(header, head4);
        std::strcat(header, head5);
        std::strcat(header, head6);
        
        std::cout << header << std::endl;
        
        boost::asio::write(audioSocket, boost::asio::buffer(header, std::strlen(header)), ec);
        
        int p = 0;
        int fpblen = 1024;//4096
        boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
        long sendLen = 0;
        
        while (length) {
            if (length > fpblen) {
                sendLen = boost::asio::write(audioSocket, boost::asio::buffer(&repackedData[p], fpblen), ec);
                
                length -= fpblen;
                p += fpblen;
            } else {
                sendLen = boost::asio::write(audioSocket, boost::asio::buffer(&repackedData[p], length), ec);
                length = 0;
            }
        }
        audioSocket.close();
        
        free(head2);
        free(head4);
        free(repackedData);
        
        std::cout << "sendAudioThreaded ended" << std::endl;
    }
    
    
    uint8_t linear2ulaw(int pcm_val) /* 2's complement (16-bit range) */
    {
        int BIAS = 0x84;
        int seg_end[] = {0xFF, 0x1FF, 0x3FF, 0x7FF,0xFFF, 0x1FFF, 0x3FFF, 0x7FFF};
        
        int  mask;
        int  seg;
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
        if (seg >= 8)  /* out of range, return maximum value. */
            return (0x7F ^ mask);
        else
        {
            uval = (uint8_t) ((seg << 4) | ((pcm_val >> (seg + 3)) & 0xF));
            return (uval ^ mask);
        }
    }
    
    int search(int val,int table[], int size)
    {
        int  i;
        for (i = 0; i < size; i++)
        {
            if (val <= table[i])
                return (i);
        }
        return (size);
    }
    
    uint8_t *repack(int16_t *data, long long rows)
    {
        short channels = 2;
        int16_t *wholeData = (int16_t *) malloc(channels * rows * 2);
        
        
        
        for (long long i = 0; i < rows; i++ ) {
            memcpy(&wholeData[i * 2], &data[i], 2);
            memcpy(&wholeData[i * 2 + 1], &data[i], 2);
        }
        
        
        uint8_t *PCM_Data = (uint8_t *)malloc(channels * rows);
        for (long long i = 0; i < rows * channels; i++) {
            PCM_Data[i] = linear2ulaw(wholeData[i]);
        }
        free(wholeData);
        //        free(data);
        return PCM_Data;
    }
    
    //MARK:- Socket APIs
    
    
    void connect(const std::string& host, const std::string& service)
    {
        boost::system::error_code ec;
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket_, resolver.resolve(host, service), ec);
    }
    size_t send(const void *data, size_t length)
    {
        boost::system::error_code ec;
        size_t sentSize = boost::asio::write(socket_, boost::asio::buffer(data, length), ec);
        return sentSize;
    }
    uint8_t * receiveSerial(boost::system::error_code *ec, size_t *size)
    {
        size_t readSize;
        
        boost::asio::streambuf b;
        readSize = boost::asio::read_until(socket_, b, '\n', *ec);
        std::istream is(&b);
        std::string data;
        std::getline(is, data);
        
        boost::erase_all(data, "\x01U");
        readSize = data.size();
        
        std::memcpy(size, &readSize, sizeof(size_t));
        
        
        char *replyData = (char *) malloc(readSize);
        data.copy(replyData, readSize);
        return (uint8_t *)replyData;
    }
    void closeSocket()
    {
        socket_.close();
    }
};
