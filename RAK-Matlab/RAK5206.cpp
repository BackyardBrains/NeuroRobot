//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright ? 2018 Backyard Brains. All rights reserved.
//

//// Base RAK API class

#include "Macros.h"
#include "SharedMemory.cpp"
#include "WriterThread.cpp"
#include "Socket.cpp"

#include <iostream>
#include <fstream>


class RAK5206
{
private:
    
    SharedMemory *sharedMemory = new SharedMemory();
    WriterThread *writer;
    Socket *socket;
    
public:
    
    void init(std::string ipAddress, std::string port) {
        
        writer = new WriterThread(sharedMemory, ipAddress);
        socket = new Socket(sharedMemory, ipAddress, port);
    }
    void start() {
        writer->startThreaded();
        socket->startThreaded();
    }
    int16_t *readAudio(int *size) {
        int16_t *reply = sharedMemory->readAudio(size);
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
    
    void writeSerial(std::string data) {
        socket->writeSerial(data);
    }
    
    uint8_t *readSerial(int *size) {
        return sharedMemory->readSerialRead(size);
    }
    
    void sendAudio(int16_t *data, long long numberOfBytes) {
        socket->sendAudio(data, numberOfBytes);
    }
    
    
#ifdef MATLAB
    
    void processMexCall( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
        
        //// Get the command string
        char cmd[64];
        
        if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd))) { mexErrMsgTxt("First input should be a command string less than 64 characters long."); return; }
        
        if ( !strcmp("init", cmd) ) {
            if (nrhs < 3 ) { mexErrMsgTxt("Missing second and third input."); return; }
            
            char *ipAddress = (char *)malloc(20);
            char *port = (char *)malloc(5);
            mxGetString(prhs[1], ipAddress, (mwSize)mxGetN(prhs[1]) + 1);
            mxGetString(prhs[2], port, (mwSize)mxGetN(prhs[2]) + 1);
            
            std::string ipAddressString = std::string(ipAddress, mxGetN(prhs[1]));
            std::string portString = std::string(port, mxGetN(prhs[2]));
            
            free(ipAddress);
            free(port);
            
            init(ipAddressString, portString);
            return;
        } else if ( !strcmp("start", cmd) ) {
            
            start();
            return;
        } else if ( !strcmp("readAudio", cmd) ) {
            int size = 0;
            int16_t *reply = readAudio(&size);
            plhs[0] = mxCreateNumericMatrix(1, size * 0.5, mxINT16_CLASS, mxREAL);
            int16_t *yp;
            yp  = (int16_t*) mxGetData(plhs[0]);
            memcpy(yp, reply, size);
            
                
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
            char *input_buf;
            int   buflen,status;
            
            /* Check for proper number of arguments. */
            if (nrhs != 2)
                mexErrMsgTxt("One input required.");
            else if (nlhs > 2)
                mexErrMsgTxt("Too many output arguments.");
            
            /* Input must be a string. */
            if (mxIsChar(prhs[0]) != 1)
                mexErrMsgTxt("Input must be a string.");
            
            /* Input must be a row vector. */
            if (mxGetM(prhs[0]) != 1)
                mexErrMsgTxt("Input must be a row vector.");
            
            /* Get the length of the input string. */
            buflen = (mxGetM(prhs[1]) * mxGetN(prhs[1])) + 1;
            
            /* Allocate memory for input and output strings. */
            input_buf = (char*) mxCalloc(buflen, sizeof(char));
            
            /* Copy the string data from prhs[0] into a C string
             * input_buf. */
            status = mxGetString(prhs[1], input_buf, buflen);
            if (status != 0)
                mexWarnMsgTxt("Not enough space. String is truncated.");
            
            std::string s(static_cast<const char*>(input_buf), buflen);
            writeSerial(s);
            
            return;
        } else if ( !strcmp("readSerial", cmd) ) {
            
            int size = 0;
            void *yp;
            uint8_t *serialData = readSerial(&size);
            
            serialData[size] = '\0';
            plhs[0] = mxCreateString((char *) serialData);
            
            return;
        } else if ( !strcmp("sendAudio", cmd) ) {
            
            short columns = mxGetN(prhs[1]);
            long long rows = mxGetM(prhs[1]);
            int16_t *data = (int16_t *)mxGetData(prhs[1]);
            columns = 2;
            
            sendAudio(data, rows * 2);
            
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
