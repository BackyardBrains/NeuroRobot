#include <emscripten/bind.h>
using namespace emscripten;

#ifndef NEURO_ROBOT_SIMULATOR
#define NEURO_ROBOT_SIMULATOR

#include <emscripten.h>
#include <iostream>

#include <wasm_simd128.h>
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

#include <array>
#include <functional>
#include <vector>

// C++ to FLUTTER
// #include "include/dart_api.h"
// #include "include/dart_native_api.h"
// #include "include/dart_api_dl.h"


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

// MAIN CODE
std::thread simulatorThread;
std::mutex mtx;

bool isThreadRunning = true;
EMSCRIPTEN_KEEPALIVE short ms_per_step = 30;
EMSCRIPTEN_KEEPALIVE short steps_per_loop = 200;
EMSCRIPTEN_KEEPALIVE short intended_timer_period = ms_per_step/1000;

EMSCRIPTEN_KEEPALIVE int32_t lvl,totalNumOfNeurons, envSize,bufSize;

EMSCRIPTEN_KEEPALIVE bool isSelected;
EMSCRIPTEN_KEEPALIVE double *a,*b, *v, *u;
EMSCRIPTEN_KEEPALIVE short *c,*d,*i,*w, isPlaying=-1, idxSelected;
EMSCRIPTEN_KEEPALIVE uint16_t *positions;

EMSCRIPTEN_KEEPALIVE uint32_t bigBufferLength = 30 * 200;
EMSCRIPTEN_KEEPALIVE double **v_traces;
EMSCRIPTEN_KEEPALIVE double *canvasBuffer;
EMSCRIPTEN_KEEPALIVE double **connectome;
EMSCRIPTEN_KEEPALIVE int *canvasPointers;
EMSCRIPTEN_KEEPALIVE short *neuronCircles;

EMSCRIPTEN_KEEPALIVE short prevFlagSpiking = -1;
EMSCRIPTEN_KEEPALIVE short isThreadCreated=-1;
// a = 0.02;
// b = 0.18;
// c = -65;
// d = 2;
// i = 5;
// w = 2;
EMSCRIPTEN_KEEPALIVE double *v0= new double[3];
EMSCRIPTEN_KEEPALIVE double **v2= new double*[2];

double i_rand = 5;

double randoms(){
    return (double) rand() / RAND_MAX * 1;
}

double matrixMultiply(){
    return (double)rand() / RAND_MAX; // for generating random points between 0 to 1
}

EMSCRIPTEN_KEEPALIVE int main()
{
    srand((unsigned) time(NULL));
    return 0;
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
}

// EXTERNC FUNCTION_ATTRIBUTE auto appendSamplesThresholdProcess(short _averagedSampleCount, short _threshold, short channelIdx, const val &data, uint32_t sampleCount, double divider, int currentStart, int sampleNeeded){
EXTERNC FUNCTION_ATTRIBUTE auto getCanvasBuffer(short _channel){
    val view{ typed_memory_view(bigBufferLength, v_traces[_channel]) };
    auto result = val::global("Float64Array").new_(bigBufferLength);
    // auto result = val::global("Int16Array").new_(bigBufferLength);
    result.call<void>("set", view);
    return result;
}

EXTERNC FUNCTION_ATTRIBUTE auto getNeuronCircles(short neuronSize){
    val view{ typed_memory_view(neuronSize, neuronCircles) };
    auto result = val::global("Int16Array").new_(neuronSize);
    result.call<void>("set", view);
    return result;    
}

EXTERNC FUNCTION_ATTRIBUTE uint16_t getCurrentPosition(short _channel){
    // EM_ASM({
    //     console.log('pos: ');
    //     console.log('Idx: ',  $0 , ', ' , ($1));
    // }, positions[_channel], 4);
    
    return positions[_channel];
}

EXTERNC FUNCTION_ATTRIBUTE uint16_t passPointer(double *_canvasBuffer, short *neuronCircle){
    // EM_ASM({
    //     console.log('pos: ');
    //     console.log('Idx: ',  $0 , ', ' , ($1));
    // }, positions[_channel], 4);

    canvasBuffer = _canvasBuffer;
    neuronCircles = neuronCircle;

    return 0;
}
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, short *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, double *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,double *_connectome,
//     short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){

// EXTERNC FUNCTION_ATTRIBUTE auto applyLowPassFilter(int16_t channelIdx, const val &data, int32_t sampleCount){
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess2(const val &__a, const val &__b, const val &__c, const val &__d, const val &__i, const val &__w, const val &__canvasPointers, const val &__positions, const val &__connectome, 
EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(const val &__a, const val &__b, const val &__c, const val &__d, const val &__i, const val &__w, const val &__canvasPointers, const val &__positions, const val &__connectome, 
    short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
    std::vector<double> _a = convertJSArrayToNumberVector<double>(__a); 
    std::vector<double> _b = convertJSArrayToNumberVector<double>(__b); 
    std::vector<short> _c = convertJSArrayToNumberVector<short>(__c); 
    std::vector<short> _d = convertJSArrayToNumberVector<short>(__d); 
    std::vector<short> _i = convertJSArrayToNumberVector<short>(__i); 
    std::vector<double> _w = convertJSArrayToNumberVector<double>(__w); 
    std::vector<uint16_t> _positions = convertJSArrayToNumberVector<uint16_t>(__positions); 
    std::vector<double> _connectome = convertJSArrayToNumberVector<double>(__connectome); 
    // std::vector<int> _canvasPointers = convertJSArrayToNumberVector<int>(__canvasPointers); 
    

    // mtx.lock();
    a=new double[_neuronLength];
    b=new double[_neuronLength];
    c=new short[_neuronLength];
    d=new short[_neuronLength];
    i=new short[_neuronLength];
    w=new short[_neuronLength];
    v=new double[_neuronLength];
    u=new double[_neuronLength];
    if (isThreadCreated==-1){
        positions = new uint16_t[_neuronLength];
    }

    // canvasPointers = new int[_neuronLength];
    // neuronCircles = new int[_neuronLength];
    connectome = new double*[_neuronLength];
    short ctr = 0;
    for (short i = 0; i < _neuronLength; i++){
        connectome[i] = new double[_neuronLength]();
        for (short j = 0; j < _neuronLength; j++){
            connectome[i][j] = _connectome[ctr++];
        }

    }
    
    double rand = 1;
    for (short neuronIndex = 0 ; neuronIndex < _neuronLength; neuronIndex++){
        positions[neuronIndex] = _positions[neuronIndex];
        a[neuronIndex]=_a[neuronIndex];
        b[neuronIndex]=_b[neuronIndex];
        c[neuronIndex]=_c[neuronIndex];
        d[neuronIndex]=_d[neuronIndex];
        i[neuronIndex]=_i[neuronIndex];
        w[neuronIndex]=_w[neuronIndex];
        // canvasPointers[neuronIndex] = _canvasPointers[neuronIndex];
        neuronCircles[neuronIndex] = 0;
        rand = i_rand * randoms();

        v[neuronIndex]= c[neuronIndex] + rand;
        // v[ch]= c[ch] +  (double) (i_rand * rand() / RAND_MAX);
        u[neuronIndex]= b[neuronIndex] * v[neuronIndex];
    }

    lvl = _level;
    totalNumOfNeurons = _neuronLength;
    envSize = _envelopeSize;
    bufSize = _bufferSize;
    isPlaying = _isPlaying;
    // mtx.unlock();

    if (isThreadCreated==-1){
        isThreadCreated=1;
        v_traces = new double*[_neuronLength];

        for (short idx = 0; idx<_neuronLength; idx++){
            v_traces[idx] = new double[bigBufferLength];
        }       

        simulatorThread = std::thread([&]() {
            double rand;
            int32_t currentStep = 0;
            int32_t threadInitialTotalNumOfNeurons = totalNumOfNeurons;
            
            while(isThreadRunning){
                // mtx.lock();

                int32_t threadTotalNumOfNeurons = totalNumOfNeurons;
                short isSpiking[threadTotalNumOfNeurons];
                short isStepSpiking[threadTotalNumOfNeurons];

                double tI[threadTotalNumOfNeurons];

                // if (w[0] != connectome[0][1] || w[1] != connectome[1][0]){
                //     connectome[0][0] = 0.0; // w_init = 2
                //     connectome[0][1] = w[0]; // w_init = 2
                //     connectome[1][0] = w[1]; // w_init = 2
                //     connectome[1][1] = 0.0; // w_init = 2
                // }
                if (isPlaying == -1 || isThreadCreated == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    // std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }

                std::vector<double*> v_step = std::vector<double*>();

                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    isStepSpiking[neuronIndex] = 0;
                }

                for (short t = 0; t < ms_per_step; t++) {
                    std::vector<int> spikingNow = std::vector<int>();
                    // double tempV[threadTotalNumOfNeurons];
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        tI[neuronIndex] = i[neuronIndex] * (1.3 * randoms());
                        
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
                    // double *copyV = new double[threadTotalNumOfNeurons];
                    // std::copy(v, v+threadTotalNumOfNeurons, copyV);
                    // v_step.push_back(copyV);
        
                    
                    //Add spiking synaptic weights to neuronal inputs
                    double *sumConnectome = new double[threadTotalNumOfNeurons]();
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        short spikingNeuronIndex = spikingNow[idx];

                        for ( short j=0; j < threadTotalNumOfNeurons ; j++ ){
                            sumConnectome[j] += connectome[spikingNeuronIndex][j];
                        }
                        // short neuronIndex = spikingNow[idx];
                        // short inverseNeuronIndex = threadTotalNumOfNeurons - 1 - neuronIndex;
                        // tI[inverseNeuronIndex] += w[inverseNeuronIndex];
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
                // mtx.unlock();

                // std::string str = "S|";
                // short isFlagSpikingNow = 0;
                for (unsigned idx=0; idx<threadTotalNumOfNeurons; idx++){
                    neuronCircles[idx] = isStepSpiking[idx];
                    // str.append(std::to_string(isStepSpiking[idx]).c_str());
                    // if (idx < threadTotalNumOfNeurons-1) str.append("|");
                    // if (isStepSpiking[idx] == 1){
                    //     isFlagSpikingNow = 1;
                    // }
                }
                // if (prevFlagSpiking == 0 && isFlagSpikingNow == 0){
                // }else
                // if (prevFlagSpiking == 1 && isFlagSpikingNow == 1){
                //     debug_print(str.c_str());
                // }else{
                //     prevFlagSpiking = isFlagSpikingNow;
                //     debug_print(str.c_str());
                // }

                short startPos = (currentStep) * ms_per_step ;

                for (int idx = 0; idx < v_step.size(); idx++) {
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        v_traces[neuronIndex][startPos + idx] = (v_step[idx][neuronIndex]);
                    }
                }
                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    positions[neuronIndex] = startPos + v_step.size();
                }

                currentStep++;
                if (currentStep >= steps_per_loop){
                    currentStep = 0;            
                }

                if (isSelected){
                    // for (short i = 0; i < bigBufferLength; i++) {
                    //     canvasBuffer[i]=v_traces[idxSelected][i];
                    //     // positions[neuronIndex] = startPos + v_step.size();
                    // }

                    std::copy(&v_traces[idxSelected][0], &v_traces[idxSelected][0] + bigBufferLength, canvasBuffer);
                    canvasBuffer[0] = 123456;
                    // EM_ASM({
                    //     console.log("C++ read", $0, $1);
                    //     console.log( HEAPF64.subarray($1 >> 3, ($1+80)>>3));
                    // }, 1, canvasBuffer);
                }
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
                delete[] (positions);
                for (unsigned idx=0; idx<threadInitialTotalNumOfNeurons; idx++){
                    delete[] (v_traces[idx]);
                }
                delete[] v_traces;

                std::terminate();
            }            
        });        
        simulatorThread.detach();
    }
    return 0;
}

EMSCRIPTEN_BINDINGS(my_module) {
    function("changeIsPlayingProcess", &changeIsPlayingProcess);
    function("changeNeuronSimulatorProcess", &changeNeuronSimulatorProcess);
    function("getCanvasBuffer", &getCanvasBuffer);
    function("getCurrentPosition", &getCurrentPosition);
    function("getNeuronCircles", &getNeuronCircles);
    function("stopThreadProcess", &stopThreadProcess);
    function("changeIdxSelectedProcess", &changeIdxSelectedProcess);
    // function("applyLowPassFilter", &applyLowPassFilter);
    // register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}


// EXTERNC double createFilters(){
//     return 30;
// }
#endif
