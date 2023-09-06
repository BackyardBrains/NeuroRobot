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
short ms_per_step = 30;
short steps_per_loop = 200;
short intended_timer_period = ms_per_step/1000;

double *a,*b, *v, *u;
short *c,*d,*i,*w, isPlaying=-1;
uint16_t *positions;
int32_t lvl,len, envSize,bufSize;
const uint32_t bigBufferLength = 30 * 200;
double *v_traces1;
double *v_traces2;

short prevFlagSpiking = -1;
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


EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, short *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,short _level, int32_t _length, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
    // debug_print("changeNeuronSimulatorProcess 0");

    int32_t length = _length;
    a=new double[length];
    b=new double[length];
    c=new short[length];
    d=new short[length];
    i=new short[length];
    w=new short[length];
    v=new double[length];
    u=new double[length];
    if (isThreadCreated==-1){
        positions = _positions;
        debug_print("v_traces");
        v_traces1 = canvasBuffer1;
        v_traces2 = canvasBuffer2;
    }

    double rand = 1;
    for (short ch = 0 ; ch < length; ch++){
        a[ch]=_a[ch];
        b[ch]=_b[ch];
        c[ch]=_c[ch];
        d[ch]=_d[ch];
        i[ch]=_i[ch];
        w[ch]=_w[ch];
        rand = i_rand * randoms();
                            // debug_print("Found Spike");
                            // debug_print(std::to_string(c[ch]).c_str());

        v[ch]= c[ch] + rand;
        // v[ch]= c[ch] +  (double) (i_rand * rand() / RAND_MAX);
        u[ch]= b[ch] * v[ch];
    }
    lvl = _level;
    len = _length;
    envSize = _envelopeSize;
    bufSize = _bufferSize;
    isPlaying = _isPlaying;
    // debug_print(std::to_string(a[0]).c_str());
    if (isThreadCreated==-1){
        isThreadCreated=1;

        std::thread simulatorThread([&]() {
            double rand;
            int32_t currentStep = 0;
            short isSpiking[len];
            short isStepSpiking[len];
            while(true){
                double tI[len];
                if (isPlaying == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }
                // debug_print("changeNeuronSimulatorProcess --1");

                // size_t sz = static_cast<size_t>(len);
                // const sz = len;
                std::vector<double*> v_step = std::vector<double*>();


                for (short ch = 0; ch < len; ch++) {
                    isStepSpiking[ch] = 0;

                }
        
                for (short t = 0; t < ms_per_step; t++) {
                    std::vector<int> spikingNow = std::vector<int>();
                    // double tempV[len];
                    for (short ch = 0; ch < len; ch++) {
                        tI[ch] = i[ch] * randoms();
                        
                        //find spiking neurons
                        isSpiking[ch] = 0;
                        if (v[ch] >= 30) {
                            isSpiking[ch] = 1;
                            isStepSpiking[ch] = 1;
                            spikingNow.push_back(ch);
                        }
                    }
                    // insert old data in timeline
                    // double *copyV = new double[len];
                    // std::copy(v, v+len, copyV);
                    // v_step.push_back(copyV);
                    short n = spikingNow.size();
                    for (short idx = 0; idx < n; idx++){
                        short ch = spikingNow[idx];
                        //Reset spiking v to c
                        v[ch] = c[ch];
                        //Adjust spiking u to d
                        u[ch] = u[ch] + d[ch];
                    }
                    double *copyV = new double[len];
                    std::copy(v, v+len, copyV);
                    v_step.push_back(copyV);
                    
                    //Add spiking synaptic weights to neuronal inputs
                    for (short idx = 0; idx < n; idx++){
                        short ch = spikingNow[idx];
                        tI[ch] += w[ch];
                    }
                    for (short ch = 0; ch < len; ch++) {

                        // v[ch] += 0.5 * randoms();  

                        // Propagate v  
                        v[ch] += 0.5 * (0.04 * pow(v[ch],2) + 5 * v[ch] + 140 - u[ch] + tI[ch]);
                        // Adjust for continuous time
                        v[ch] += 0.5 * (0.04 * pow(v[ch],2) + 5 * v[ch] + 140 - u[ch] + tI[ch]);

                        // if (std::isnan(v[ch])){
                        //     if (std::isnan(c[ch])){
                        //         v[ch] = 0;
                        //     }else{
                        //         v[ch] = c[ch];
                        //     }
                        // }
                        //Update u
                        u[ch] = u[ch] + a[ch] * (b[ch]*v[ch] - u[ch]);

                    }
                        // tempV[ch] = v[ch];
                }
                if (isStepSpiking[0]==1 && isStepSpiking[1]==1){
                    std::string str = "S|1|1";
                    // for (unsigned idx=0; idx<len; idx++){
                    //     str.append(std::to_string(isSpiking[idx]).c_str());
                    //     if (idx < len-1) str.append("|");
                    // }
                    prevFlagSpiking = 1;
                    debug_print(str.c_str());
                }else
                if (isStepSpiking[0]==1 && isStepSpiking[1]==0){
                    std::string str = "S|1|0";
                    prevFlagSpiking = 1;
                    debug_print(str.c_str());
                }else
                if (isStepSpiking[0]==0 && isStepSpiking[1]==1){
                    std::string str = "S|0|1";
                    prevFlagSpiking = 1;
                    debug_print(str.c_str());
                }else{
                    if (prevFlagSpiking == 1){
                        std::string str = "S|0|0";
                        debug_print(str.c_str());
                        prevFlagSpiking = 0;
                    }
                    // debug_print("test");
                }

                // auto is_nan = [](float value) { return std::isnan(value); };
                // auto is_nan = [](const auto& value) { return std::isnan(value); };
                // v_step.erase(std::remove_if(v_step.begin(), v_step.end(), is_nan), v_step.end());
                // v_step.erase(std::remove_if(v_step.begin(),
                //                     v_step.end(),
                //                     is_nan),
                //         v_step.end());                
                // for (auto it = v_step.begin(); it != v_step.end(); it++) {
                //     if (*it == NAN) {
                //         *it = 0;
                //     }
                // }                
                short startPos = (currentStep) * ms_per_step ;
                // debug_print(std::to_string(startPos).c_str());

                for (int idx = 0; idx < v_step.size(); idx++) {
                    for (short ch = 0; ch < len; ch++) {
                        if (ch % 2 == 0){
                            v_traces1[startPos + idx] = (v_step[idx][ch]);
                        }else{
                            v_traces2[startPos + idx] = (v_step[idx][ch]);
                        }
                    }
                }
                for (short ch = 0; ch < len; ch++) {
                    positions[ch] = startPos + v_step.size();
                }
                currentStep++;
                if (currentStep >= steps_per_loop){
                    // debug_print(std::to_string(currentStep).c_str());
                    currentStep = 0;            
                }
                // for (short ch = 0; ch < bigBufferLength; ch++) {
                //     v_traces2[ch] = randoms() *10;
                // }
                // v_traces2[0] = 0;

            }


        });        
        simulatorThread.detach();
    }
    return 1.0;
}




// EXTERNC double createFilters(){
//     return 30;
// }
#endif
