#ifndef NEURO_ROBOT_SIMULATOR
#define NEURO_ROBOT_SIMULATOR
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <stdint.h>
#include <thread>
#include <chrono>
#include <vector>
// C++ to FLUTTER
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "include/dart_api_dl.h"


#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#if defined(__GNUC__)
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
    #define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

// C++ TO FLUTTER
static Dart_Port_DL dart_port = 0;
char* debug_print(const char *message)
{
    if (!dart_port)
        return (char*) "wrong port"; 

    Dart_CObject msg ;
    msg.type = Dart_CObject_kString;
    msg.value.as_string = (char *) message;
    // Dart_CObject c_event_code;
    // c_event_code.type = Dart_CObject_kInt32;
    // c_event_code.value.as_int32 = 1;
    // Dart_CObject* c_request_arr[] = {&c_event_code};
    // c_request.type = Dart_CObject_kArray;
    // c_request.value.as_array.values = c_request_arr;
    // c_request.value.as_array.length = sizeof(c_request_arr) / sizeof(c_request_arr[0]);

    try{
        Dart_PostCObject_DL(dart_port, &msg);
        return (char *) "success";
    }catch(...){
        return (char *) "failed";
    }   
    
}

// C++ to Flutter
EXTERNC FUNCTION_ATTRIBUTE void set_dart_port(Dart_Port_DL port)
{
    dart_port = port;
}
// C++ to Flutter
EXTERNC FUNCTION_ATTRIBUTE intptr_t InitDartApiDL(void* data) {
  return Dart_InitializeApiDL(data);
// return 1;
}
// C++ to Flutter

// MAIN CODE
std::thread simulatorThread;
// std::mutex mtx;

bool isThreadRunning = true;
short ms_per_step = 30;
short steps_per_loop = 200;
short intended_timer_period = ms_per_step/1000;

bool isSelected,isRecreatingNeurons, isDebugNewNeurons;
double *a,*b, *v, *u;
short *c,*d,*i,*w, isPlaying=-1, idxSelected;
uint16_t *positions;
int32_t lvl,totalNumOfNeurons, prevTotalNumOfNeurons, envSize,bufSize;
const uint32_t bigBufferLength = 30 * 200;
// double *v_traces1;
// double *v_traces2;
double **v_traces;
double *canvasBuffer;
double **connectome;

short prevFlagSpiking = 0;
short isThreadCreated=-1;
// a = 0.02;
// b = 0.18;
// c = -65;
// d = 2;
// i = 5;
// w = 2;

double i_rand = 5;

double randoms(){
    return (double) rand() / RAND_MAX * 1;
}

double matrixMultiply(){
    return (double)rand() / RAND_MAX; // for generating random points between 0 to 1
}

int main()
{

}

EXTERNC FUNCTION_ATTRIBUTE short stopThreadProcess(short _idxSelected){
    isThreadRunning = false;
    isThreadCreated = -1;

    return idxSelected;
}
EXTERNC FUNCTION_ATTRIBUTE short changeIdxSelectedProcess(short _idxSelected){
    if (_idxSelected == -1){
        isSelected = false;
    }else{
        isSelected = true;
        idxSelected = _idxSelected;
    }
    return idxSelected;
}


EXTERNC FUNCTION_ATTRIBUTE short changeIsPlayingProcess(short _isPlaying){
    isPlaying = _isPlaying;
    return isPlaying;
    // if (isPlaying == -1){
    //     isPlaying = 1;
    // }else{
    //     isPlaying = -1;
    // }
    // return isPlaying;
}


EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, double *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,double *_connectome,
    short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
    
    debug_print("changeNeuronSimulatorProcess 0");

    // int32_t length = _neuronLength;
    //Free variable;
    if (isThreadCreated != -1){
        // if (_neuronLength != totalNumOfNeurons){
        //     // debug_print("isRecreatingNeurons 0");
        //     isDebugNewNeurons = true;
        //     isRecreatingNeurons = true;
        //     positions = _positions;
        //     canvasBuffer = canvasBuffer1;

        //     v_traces = new double*[totalNumOfNeurons];

        //     for (short idx = 0; idx<totalNumOfNeurons; idx++){
        //         v_traces[idx] = new double[totalNumOfNeurons]();
        //     }       
            
        // }
        // free(a);
        // free(b);
        // free(c);
        // free(d);
        // free(i);
        // free(w);
        // free(v);
        // free(u);
        // free(connectome);
    }

    // mtx.lock();

    a=new double[_neuronLength];
    b=new double[_neuronLength];
    c=new short[_neuronLength];
    d=new short[_neuronLength];
    i=new short[_neuronLength];
    w=new short[_neuronLength];
    v=new double[_neuronLength];
    u=new double[_neuronLength];
    connectome = new double*[_neuronLength];
    short ctr = 0;
    for (short i = 0; i < _neuronLength; i++){
        connectome[i] = new double[_neuronLength]();
        for (short j = 0; j < _neuronLength; j++){
            connectome[i][j] = _connectome[ctr++];
        }

    }

    if (isThreadCreated==-1){
        positions = _positions;
        debug_print("v_traces");
        canvasBuffer = canvasBuffer1;
        v_traces = new double*[_neuronLength];

        for (short idx = 0; idx<_neuronLength; idx++){
            v_traces[idx] = new double[bigBufferLength]();
        }

        // v_traces = canvasBuffer1;
        // v_traces2 = canvasBuffer2;
    }

    double rand = 1;
    for (short neuronIndex = 0 ; neuronIndex < _neuronLength; neuronIndex++){
        a[neuronIndex]=_a[neuronIndex];
        b[neuronIndex]=_b[neuronIndex];
        c[neuronIndex]=_c[neuronIndex];
        d[neuronIndex]=_d[neuronIndex];
        i[neuronIndex]=_i[neuronIndex];
        w[neuronIndex]=_w[neuronIndex];
        rand = i_rand * randoms();
                            // debug_print("Found Spike");
                            // debug_print(std::to_string(c[neuronIndex]).c_str());

        v[neuronIndex]= c[neuronIndex] + rand;
        // v[neuronIndex]= c[neuronIndex] +  (double) (i_rand * rand() / RAND_MAX);
        u[neuronIndex]= b[neuronIndex] * v[neuronIndex];
    }
    lvl = _level;
    totalNumOfNeurons = _neuronLength;
    envSize = _envelopeSize;
    bufSize = _bufferSize;
    isPlaying = _isPlaying;
    // mtx.unlock();
    // isPlaying = -1;
    // debug_print(std::to_string(a[0]).c_str());
    if (isThreadCreated==-1){
        isThreadCreated=1;

        debug_print("t detach 0");
        simulatorThread = std::thread([&]() {
            double rand;
            int32_t currentStep = 0;
            // short isStepSpiking[threadTotalNumOfNeurons];
            // double connectome[threadTotalNumOfNeurons][threadTotalNumOfNeurons];
            debug_print("t created");

            int32_t threadInitialTotalNumOfNeurons = totalNumOfNeurons;
            // uint32_t neuronsCount = 0;
            // long totalSecond = 0;
            // long prevTotalSecond = 0;
            // auto start = std::chrono::steady_clock::now();
            // auto elapsed = std::chrono::steady_clock::now() - start;
            // long milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();

            while(isThreadRunning){
                // mtx.lock();

                int32_t threadTotalNumOfNeurons = totalNumOfNeurons;
                short isSpiking[threadTotalNumOfNeurons];
                short isStepSpiking[threadTotalNumOfNeurons];

                double tI[threadTotalNumOfNeurons];
                // debug_print("while");
                // if (isRecreatingNeurons){
                //     // debug_print("isRecreatingNeurons");
                //     delete[] (isSpiking);
                //     isRecreatingNeurons = false;

                //     isSpiking = new short[threadTotalNumOfNeurons]();
                // }
                if (isPlaying == -1 || isThreadCreated == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                }
                // debug_print("changeNeuronSimulatorProcess --1");

                // size_t sz = static_cast<size_t>(threadTotalNumOfNeurons);
                // const sz = threadTotalNumOfNeurons;
                std::vector<double*> v_step = std::vector<double*>();

                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    isStepSpiking[neuronIndex] = 0;
                }

                // auto neuronsCount+=threadTotalNumOfNeurons;
                // auto start = std::chrono::steady_clock::now();
                for (uint32_t t = 0; t < ms_per_step; t++) {
                    std::vector<int> spikingNow = std::vector<int>();
                    // double tempV[threadTotalNumOfNeurons];

                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        tI[neuronIndex] = i[neuronIndex] * (1.3 *randoms());
                        
                        //find spiking neurons
                        isSpiking[neuronIndex] = 0;
                        if (v[neuronIndex] >= 30) {
                            isSpiking[neuronIndex] = 1;
                            isStepSpiking[neuronIndex] = 1;
                            spikingNow.push_back(neuronIndex);
                        }
                    }

                    // insert old data in timeline

                    double *copyV = new double[threadTotalNumOfNeurons];
                    std::copy(v, v+threadTotalNumOfNeurons, copyV);
                    v_step.push_back(copyV);
                    
                    short numberOfSpikingNow = spikingNow.size();
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        short neuronIndex = spikingNow[idx];
                        //Reset spiking v to c
                        v[neuronIndex] = c[neuronIndex];
                        //Adjust spiking u to d
                        u[neuronIndex] = u[neuronIndex] + d[neuronIndex];
                    }

                    double *sumConnectome = new double[threadTotalNumOfNeurons]();
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        short spikingNeuronIndex = spikingNow[idx];

                        for ( short j=0; j < threadTotalNumOfNeurons ; j++ ){
                            sumConnectome[j] += connectome[spikingNeuronIndex][j];
                        }
                    }
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++){
                        tI[idx] += sumConnectome[idx];
                    }
                    delete[](sumConnectome);

                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {

                        // v[neuronIndex] += 0.5 * randoms();  

                        // Propagate v  
                        v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);
                        // Adjust for continuous time
                        v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);

                        // if (std::isnan(v[neuronIndex])){
                        //     if (std::isnan(c[neuronIndex])){
                        //         v[neuronIndex] = 0;
                        //     }else{
                        //         v[neuronIndex] = c[neuronIndex];
                        //     }
                        // }
                        //Update u
                        u[neuronIndex] = u[neuronIndex] + a[neuronIndex] * (b[neuronIndex]*v[neuronIndex] - u[neuronIndex]);

                    }

                        // tempV[neuronIndex] = v[neuronIndex];
                }
                // auto elapsed = std::chrono::steady_clock::now() - start;
                // long milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
                // // totalSecond += milliseconds;
                // debug_print("std::to_string(milliseconds).c_str()");
                // debug_print(std::to_string(milliseconds).c_str());
                // return;

                // if (milliseconds>1000){
                //     prevTotalSecond = totalSecond;
                //     std::string str = "Neuron per second : ";
                //     str.append(std::to_string(neuronsCount));
                //     str.append(" in ");
                //     str.append(std::to_string(milliseconds));
                //     debug_print(str.c_str());
                //     start = std::chrono::steady_clock::now();
                //     neuronsCount = 0;

                // }
                
                // mtx.unlock();

                // if (isStepSpiking[0] == 1){
                //     str="S|1";
                //     // if (prevFlagSpiking == -1){
                //     prevFlagSpiking = 1;
                //     debug_print(str.c_str());
                //     // }
                // }else{
                //     if (prevFlagSpiking == 1){
                //         std::string str = "S|0";
                //         debug_print(str.c_str());
                //         prevFlagSpiking = 0;
                //     }
                // }

                // if (isStepSpiking[0]==1 && isStepSpiking[1]==1){
                //     std::string str = "S|1|1";
                //     // for (unsigned idx=0; idx<len; idx++){
                //     //     str.append(std::to_string(isSpiking[idx]).c_str());
                //     //     if (idx < len-1) str.append("|");
                //     // }
                //     prevFlagSpiking = 1;
                //     debug_print(str.c_str());
                // }else
                // if (isStepSpiking[0]==1 && isStepSpiking[1]==0){
                //     std::string str = "S|1|0";
                //     prevFlagSpiking = 1;
                //     debug_print(str.c_str());
                // }else
                // if (isStepSpiking[0]==0 && isStepSpiking[1]==1){
                //     std::string str = "S|0|1";
                //     prevFlagSpiking = 1;
                //     debug_print(str.c_str());
                // }else{
                //     if (prevFlagSpiking == 1){
                //         std::string str = "S|0|0";
                //         debug_print(str.c_str());
                //         prevFlagSpiking = 0;
                //     }
                //     // debug_print("test");
                // }        

                std::string str = "S|";
                short isFlagSpikingNow = 0;
                for (unsigned idx=0; idx<threadTotalNumOfNeurons; idx++){
                    str.append(std::to_string(isStepSpiking[idx]).c_str());
                    if (idx < threadTotalNumOfNeurons-1) str.append("|");
                    if (isStepSpiking[idx] == 1){
                        isFlagSpikingNow = 1;
                    }
                }
                if (prevFlagSpiking == 0 && isFlagSpikingNow == 0){
                }else
                if (prevFlagSpiking == 1 && isFlagSpikingNow == 1){
                    debug_print(str.c_str());
                }else{
                    prevFlagSpiking = isFlagSpikingNow;
                    debug_print(str.c_str());
                }
                short startPos = (currentStep) * ms_per_step ;
                // debug_print(std::to_string(startPos).c_str());

                for (int idx = 0; idx < v_step.size(); idx++) {
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        v_traces[neuronIndex][startPos + idx] = (v_step[idx][neuronIndex]);
                        // if (neuronIndex % 2 == 0){
                        //     v_traces[startPos + idx] = (v_step[idx][neuronIndex]);
                        // }else{
                        //     v_traces2[startPos + idx] = (v_step[idx][neuronIndex]);
                        // }
                    }
                }
                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    positions[neuronIndex] = startPos + v_step.size();
                }
                currentStep++;
                if (currentStep >= steps_per_loop){
                    // debug_print(std::to_string(currentStep).c_str());
                    currentStep = 0;            
                }

                if (isSelected){
                    // debug_print("COPY");
                    std::copy(&v_traces[idxSelected][0], &v_traces[idxSelected][0] + bigBufferLength, canvasBuffer);
                }
                // debug_print(std::to_string(v_traces[idxSelected][0]).c_str());
                // debug_print(std::to_string(positions[0]).c_str());
                
                // for (short neuronIndex = 0; neuronIndex < bigBufferLength; neuronIndex++) {
                //     v_traces2[neuronIndex] = randoms() *10;
                // }
                // v_traces2[0] = 0;

            }
            if (!isThreadRunning){
                delete[] (a);
                delete[] (b);
                delete[] (c);
                delete[] (d);
                delete[] (i);
                delete[] (w);
                delete[] (v);
                delete[] (u);
                delete[] (connectome);
                for (unsigned idx=0; idx<threadInitialTotalNumOfNeurons; idx++){
                    delete[] (v_traces[idx]);
                }
                delete[] v_traces;

                // std::terminate();
            }

        });        

        simulatorThread.detach();
        isThreadRunning = true;
        debug_print("t detach");

    }
    return 1.0;
}




// EXTERNC double createFilters(){
//     return 30;
// }
#endif
