//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "Macros.h"
#include "SharedMemory.cpp"
#include "VideoAndAudioObtainer.cpp"
#include "Socket.cpp"

#include <iostream>

/**
 Base RAK API class. It is intended to have only one statically allocated object of this class and all mex calls will be executed through that object.
 */
class RAK5206
{
private:
    
    SharedMemory *sharedMemory = new SharedMemory();
    VideoAndAudioObtainer *videoAndAudioObtainerObject;
    Socket *socketObject;
    
public:
    
    /**
     Inits video and audio obtainer object and socket object.
     */
    void init(std::string ipAddress, std::string port) 
    {
        videoAndAudioObtainerObject = new VideoAndAudioObtainer(sharedMemory, ipAddress);
        socketObject = new Socket(sharedMemory, ipAddress, port);
    }
    
    /**
     Starts the video, audio and serial data obtainers.
     */
    void start()
    {
        videoAndAudioObtainerObject->startThreaded();
        socketObject->startThreaded();
    }
    
    /**
     Reads audio from shared memory object.

     @param size Size of audio data which is forwarded parallel
     @return Audio data
     */
    int16_t *readAudio(int *size)
    {
        int16_t *reply = sharedMemory->readAudio(size);
        return reply;
    }
    
    /**
     Reads video frame from shared memory object.

     @return Video frame data
     */
    uint8_t *readVideo()
    {
        return sharedMemory->readVideoFrame();
    }
    
    /**
     Stops video, audio and serial data obtainers.
     */
    void stop()
    {
        videoAndAudioObtainerObject->stop();
        socketObject->stop();
    }
    
    /**
     Queries whether the video and audio obtainer is working.

     @return Is video and audio obtainer working
     */
    bool isRunning()
    {
        return videoAndAudioObtainerObject->isRunning();
    }
    
    /**
     Writes forwarded serial data.

     @param data Serial data
     */
    void writeSerial(std::string data)
    {
        socketObject->writeSerial(data);
    }
    
    /**
     Reads serial data from shared memory object.

     @param size Size of serial data which is forwarded parallel
     @return Serial data
     */
    uint8_t *readSerial(int *size)
    {
        return sharedMemory->readSerialRead(size);
    }
    
    /**
     Sends audio data through socket object.

     @param data Data to send
     @param numberOfBytes Number of bytes to send
     */
    void sendAudio(int16_t *data, long long numberOfBytes)
    {
        socketObject->sendAudio(data, numberOfBytes);
    }
    
#ifdef MATLAB
    
    /**
     Executing mex comamnd from MATLAB
     */
    void processMexCall( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
    {
        char cmd[64];
        
        // Gets the command string
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
            uint8_t *serialData = readSerial(&size);
            plhs[0] = mxCreateString((char *)serialData);
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

/**
 Standard MATLAB api for executing commands from it through mex.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    static RAK5206 rakObject;
    
    rakObject.processMexCall( nlhs, plhs, nrhs, prhs );
}
#endif
