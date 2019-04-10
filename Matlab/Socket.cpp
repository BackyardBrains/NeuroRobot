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
    std::string ipAddress_;
    std::string port_;
    
    boost::asio::io_context io_context;
    tcp::socket socket_;
    tcp::socket audioSocket_;
    
    
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
    
    Socket(SharedMemory *sharedMemory, std::string ip, std::string port) : socket_(io_context), audioSocket_(io_context)
    {
        openStreams();
        
        sharedMemoryInstance = sharedMemory;
        
        ipAddress_ = ip;
        port_ = port;
    }
    
    //-----------------------------------
    // Overloaded methods.
    void run() {
        connect(ipAddress_, port_);
        
        uint8_t dataToOpenReceiving[] = {0x01, 0x55};
        send(dataToOpenReceiving, 2);
        boost::system::error_code ec;
        
        while (!close) {
            
            std::string readSerialData = receiveSerial(&ec);
            
            while (ec == boost::asio::error::eof) {
                socket_.close();
                connect(ipAddress_, port_);
                send(dataToOpenReceiving, 2);
                
                readSerialData = receiveSerial(&ec);
            }
            std::cout << "received" << std::endl;
            
            
            if (readSerialData.length() > 0) {
                sharedMemoryInstance->writeSerialRead(readSerialData);
            }
            
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
        std::thread thread(&Socket::writeSerialThreadedString, this, data);
        thread.detach();
    }
    void writeSerialThreadedString(std::string data)
    {
        writeSerialThreaded((uint8_t *)data.c_str(), data.length());
    }
    void writeSerialThreaded(uint8_t *data, size_t length)
    {
        size_t totalLength = length + 3;
        uint8_t header[] = { 0x01, 0x55 };
        uint8_t *wholeData = (uint8_t *) malloc(totalLength);
        uint8_t footer[] = { '\n' };
        memcpy(wholeData, header, 2);
        memcpy(&wholeData[2], data, length);
        memcpy(&wholeData[totalLength - 1], footer, 1);
        
        std::to_string(send(wholeData, totalLength));
        
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
        
        boost::system::error_code ec;
        
        
        char head1[] = "POST /audio.input HTTP/1.1\r\n";
        char *head2 = (char *) malloc(30);
        strcpy(head2, "Host: ");
        strcat(head2, ipAddress_.c_str());
        strcat(head2, "\r\n");
        char head3[] = "Content-Type: audio/wav\r\n";
        char *head4 = (char *) malloc(30);
        strcpy(head4, "Content-Length: ");
        strcat(head4, lltoa(length, 10));
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
        
        logMessage(std::string(header));
        
        boost::asio::write(audioSocket_, boost::asio::buffer(header, std::strlen(header)), ec);
        
        int p = 0;
        int fpblen = 1024;//4096
        boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
        long sendLen = 0;
        
        while (length) {
            if (length > fpblen) {
                sendLen = boost::asio::write(audioSocket_, boost::asio::buffer(&repackedData[p], fpblen), ec);
                
                length -= fpblen;
                p += fpblen;
            } else {
                sendLen = boost::asio::write(audioSocket_, boost::asio::buffer(&repackedData[p], length), ec);
                length = 0;
            }
        }
        
        free(head2);
        free(head4);
        delete [] header;
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
    char *lltoa(long long number, int base){
        static char buffer[sizeof(number) * 3 + 1];  // Size could be a bit tighter
        char *p = &buffer[sizeof(buffer)];
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
    
    //MARK:- Socket APIs
    
    
    void connect(const std::string& host, const std::string& service)
    {
        boost::system::error_code ec;
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket_, resolver.resolve(host, service), ec);
        boost::asio::connect(audioSocket_, resolver.resolve(host, service), ec);
    }
    size_t send(const void *data, size_t length)
    {
        boost::system::error_code ec;
        size_t sentSize = boost::asio::write(socket_, boost::asio::buffer(data, length), ec);
        return sentSize;
    }
    std::string receiveSerial(boost::system::error_code *ec)
    {
        boost::asio::streambuf b;
        boost::asio::read_until(socket_, b, '\n', *ec);
        std::istream is(&b);
        std::string data;
        std::getline(is, data);
        
        boost::erase_all(data, "\x01U");
        
        return data;
    }
    void closeSocket()
    {
        socket_.close();
        audioSocket_.close();
    }
};
