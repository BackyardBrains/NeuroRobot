//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

//// Base RAK API class

#include "Macros.h"
#include "SharedMemory.cpp"
#include "WriterThread.cpp"
#include "Socket.cpp"

#include <iostream>
#include <fstream>
//#include <mex.h>


class RAK5206
{
private:
    char ipAddress[64], port[3];
    
    SharedMemory *sharedMemory = new SharedMemory();
    WriterThread *writer;
    Socket *socket;
    
public:
    void init(char *ipAddress, char *port) {
        memcpy(this->ipAddress, ipAddress, 64);
        memcpy(this->port, port, 3);
        
        writer = new WriterThread(sharedMemory, ipAddress);
        socket = new Socket(sharedMemory, ipAddress, port);
    }
    void start() {
        writer->startThreaded();
        socket->startThreaded();
    }
    char* getIp(){
        
        return ipAddress;
    }
    char* getPort(){
        
        return port;
    }
    AudioReply *readAudio() {
        
        AudioReply *reply = sharedMemory->readAudio();
        return reply;
    }
    uint8_t *readVideo() {
        return sharedMemory->readVideo();
    }
    void stop() {
        writer->stop();
        socket->stop();
    }
    bool isRunning() {
        return writer->isRunning();
    }
    
    void writeSerial(uint8_t *data, size_t length) {
        socket->writeSerial(data, length);
    }
    uint8_t *readSerial(int *size) {
        return sharedMemory->readSerialRead(size);
    }
    
    void sendAudio(int16_t *data, long long length) {
        socket->sendAudio(data, length);
    }
    
    
#ifdef MATLAB
    
    void processMexCall( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {

        //// Get the command string
        char cmd[64];

        if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd))) { mexErrMsgTxt("First input should be a command string less than 64 characters long."); return; }

        if ( !strcmp("init", cmd) ) {
            if (nrhs < 3 ) { mexErrMsgTxt("Missing second and third input."); return; }

            mxGetString(prhs[1], ipAddress, sizeof(ipAddress));
            mxGetString(prhs[2], port, sizeof(port));


            init(ipAddress, port);
            return;
        } else if ( !strcmp("start", cmd) ) {

            start();
            return;
        } else if ( !strcmp("getIp", cmd) ) {

            plhs[0] = mxCreateString(getIp());
            return;
        } else if ( !strcmp("getPort", cmd) ) {

            plhs[0] = mxCreateString(getPort());
            return;
        } else if ( !strcmp("readAudio", cmd) ) {

            AudioReply *reply = readAudio();
            if (reply->length > 0) {
                plhs[0] = mxCreateNumericMatrix(1, reply->length / 2, mxINT16_CLASS, mxREAL);
                int16_t *yp;
                yp  = (int16_t*) mxGetData(plhs[0]);

                memcpy(yp, reply->data, reply->length);
            } else {
                plhs[0] = mxCreateNumericMatrix(1, 0, mxINT16_CLASS, mxREAL);
            }
            free(reply);
            return;
        } else if ( !strcmp("readVideo", cmd) ) {


            uint8_t *videoData = readVideo();

            plhs[0] = mxCreateNumericMatrix(1, sharedMemory->frameSize, mxUINT8_CLASS, mxREAL);
            uint8_t *yp;
            yp  = (uint8_t*) mxGetData(plhs[0]);
            memcpy(yp, videoData, sharedMemory->frameSize);


            return;
        } else if ( !strcmp("stop", cmd) ) {

            stop();
            return;
        } else if ( !strcmp("isRunning", cmd) ) {

            bool payload = isRunning();

            bool *yp;
            plhs[0] = mxCreateNumericMatrix(1, 1, mxLOGICAL_CLASS, mxREAL);
            yp  = (bool*) mxGetData(plhs[0]);
            memcpy(yp, &payload, 1);

            return;
        } else if ( !strcmp("writeSerial", cmd) ) {

            long long rows = mxGetM(prhs[1]);
            uint8_t *data = (uint8_t *)mxGetData(prhs[1]);

            writeSerial(data, rows);

            return;
        } else if ( !strcmp("readSerial", cmd) ) {

            int size = 0;
            uint8_t *serialData = readSerial(&size);

            uint8_t *yp;
            plhs[0] = mxCreateNumericMatrix(1, size, mxUINT8_CLASS, mxREAL);
            yp  = (uint8_t *) mxGetData(plhs[0]);
            memcpy(yp, serialData, size);

            return;
        } else if ( !strcmp("sendAudio", cmd) ) {

            short columns = mxGetN(prhs[1]);
            long long rows = mxGetM(prhs[1]);
            int16_t *data = (int16_t *)mxGetData(prhs[1]);
            columns = 2;

            sendAudio(data, rows);
            
            return;
        }
    }
#endif
};



#ifdef MATLAB
//// Matlab bridge
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    static RAK5206 rakObject;

    rakObject.processMexCall( nlhs, plhs, nrhs, prhs );
}
#endif
