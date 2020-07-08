//
//  NeuroRobot_MatlabBridge.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 7/6/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#include "NeuroRobotManager.h"
#include <iostream>
#include <mex.h>

#include "matrix.h"

/**
 Base Neuro Robot API class. It is intended to have only one statically allocated object of this class and all mex calls will be executed through that object.
 */
class NeuroRobot_Matlab
{
private:
    NeuroRobotManager *robotObject = NULL;
    
public:
    
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
            
            robotObject = new NeuroRobotManager(ipAddressString, portString, nullptr, nullptr);
            return;
        } else if ( !strcmp("start", cmd) ) {
            
            robotObject->start();
            return;
        } else if ( !strcmp("readAudio", cmd) ) {
            size_t totalBytes = 0;
            unsigned short bytesPerSample = 0;
            
            void *audioData = robotObject->readAudio(&totalBytes, &bytesPerSample);
            
            plhs[0] = mxCreateNumericMatrix(1, totalBytes / bytesPerSample, mxSINGLE_CLASS, mxREAL);
            
            void *yp;
            yp  = (void*) mxGetData(plhs[0]);
            std::memcpy(yp, audioData, totalBytes);
            
            return;
        } else if ( !strcmp("readVideo", cmd) ) {
            
            uint8_t *videoData = robotObject->readVideoFrame();
            
            plhs[0] = mxCreateNumericMatrix(1, robotObject->videoFrameBytes(), mxUINT8_CLASS, mxREAL);
            uint8_t *yp;
            yp  = (uint8_t*) mxGetData(plhs[0]);
            std::memcpy(yp, videoData, robotObject->videoFrameBytes());
            
            return;
        } else if ( !strcmp("stop", cmd) ) {
            
            robotObject->stop();
            
            delete robotObject;
            return;
        } else if ( !strcmp("isRunning", cmd) ) {
            
           bool payload = robotObject->isRunning();

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
            robotObject->writeSerial(s.c_str());
            
            return;
        } else if ( !strcmp("readSerial", cmd) ) {
            size_t size = 0;
            char *serialData = robotObject->readSerial(&size);
            plhs[0] = mxCreateString(serialData);
            return;
        } else if ( !strcmp("sendAudio", cmd) ) {
            
            short columns = mxGetN(prhs[1]);
            long long rows = mxGetM(prhs[1]);
            int16_t *data = (int16_t *)mxGetData(prhs[1]);
            columns = 2;
            
            robotObject->sendAudio(data, rows * 2);
            
            return;
        } else if ( !strcmp("readStreamState", cmd) ) {
            
            StreamStateType error = robotObject->readStreamState();
            plhs[0] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
            uint8_t *yp;
            yp  = (uint8_t*) mxGetData(plhs[0]);
            std::memcpy(yp, &error, 1);
            return;
        } else if ( !strcmp("readSocketState", cmd) ) {
            
            SocketStateType error = robotObject->readSocketState();
            plhs[0] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
            uint8_t *yp;
            yp  = (uint8_t*) mxGetData(plhs[0]);
            std::memcpy(yp, &error, 1);
            return;
        } else if ( !strcmp("readAudioSampleRate", cmd) ) {
            
            int sampleRate = robotObject->audioSampleRate();
            plhs[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            int *yp;
            yp  = (int *) mxGetData(plhs[0]);
            std::memcpy(yp, &sampleRate, sizeof(int));
            return;
        } else if ( !strcmp("readVideoWidth", cmd) ) {
            
            int videoWidth = robotObject->videoWidth();
            plhs[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            int *yp;
            yp  = (int *) mxGetData(plhs[0]);
            std::memcpy(yp, &videoWidth, sizeof(int));
            return;
        } else if ( !strcmp("readVideoHeight", cmd) ) {
            
            int videoHeight = robotObject->videoHeight();
            plhs[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            int *yp;
            yp  = (int *) mxGetData(plhs[0]);
            std::memcpy(yp, &videoHeight, sizeof(int));
            return;
        }
    }
    
    static void streamCallback(StreamStateType error) {
        
//        auto stateString_ = getStreamStateMessage(error);
//
//        static char stateString[255];
//        std::memcpy(stateString, stateString_, 255);
//        mxArray *array[1], *output[1];
//        //         mxArray *output[1];
//        mxArray *input[1];
//
//
//        static char foo[] = "foo data";
//        array[0] = mxCreateString(foo);
//        output[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
//        input[0] = mxCreateNumericMatrix(1, 1000, mxINT64_CLASS, mxREAL);
//        int *yp  = (int *) mxGetData(output[0]);
//        std::memcpy(yp, &error, sizeof(int));
//
//        mexCallMATLAB(0, input, 0, &array[0], "NeuroRobot_StreamCallback");
//        //         mexCallMATLAB(1, input, 1, array, "NeuroRobot_StreamCallback");
//        //         mexCallMATLAB(1, input, 1, &array[0], "disp");
//        //         delete [] retVal;
//        //         mxDestroyArray(array[0]);
//        //         mxDestroyArray(output[0]);
//        //         mxDestroyArray(input[0]);
    }
};

/**
 Standard MATLAB api for executing commands from it through mex.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    static NeuroRobot_Matlab robotObject;
    
    robotObject.processMexCall( nlhs, plhs, nrhs, prhs );
}
