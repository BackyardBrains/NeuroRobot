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

// C++ TO FLUTTER
// static Dart_Port_DL dart_port = 0;
// char* debug_print(const char *message)
// {
//     if (!dart_port)
//         return (char*) "wrong port"; 

//     Dart_CObject msg ;
//     msg.type = Dart_CObject_kString;
//     msg.value.as_string = (char *) message;
//     // Dart_CObject c_event_code;
//     // c_event_code.type = Dart_CObject_kInt32;
//     // c_event_code.value.as_int32 = 1;
//     // Dart_CObject* c_request_arr[] = {&c_event_code};
//     // c_request.type = Dart_CObject_kArray;
//     // c_request.value.as_array.values = c_request_arr;
//     // c_request.value.as_array.length = sizeof(c_request_arr) / sizeof(c_request_arr[0]);

//     try{
//         Dart_PostCObject_DL(dart_port, &msg);
//         return (char *) "success";
//     }catch(...){
//         return (char *) "failed";
//     }   
    
// }

// // C++ to Flutter
// EXTERNC FUNCTION_ATTRIBUTE void set_dart_port(Dart_Port_DL port)
// {
//     dart_port = port;
// }
// // C++ to Flutter
// EXTERNC FUNCTION_ATTRIBUTE intptr_t InitDartApiDL(void* data) {
//   return Dart_InitializeApiDL(data);
// // return 1;
// }
// // C++ to Flutter

// MAIN CODE
EMSCRIPTEN_KEEPALIVE short ms_per_step = 30;
EMSCRIPTEN_KEEPALIVE short steps_per_loop = 200;
EMSCRIPTEN_KEEPALIVE short intended_timer_period = ms_per_step/1000;

EMSCRIPTEN_KEEPALIVE int32_t lvl,totalNumOfNeurons, envSize,bufSize;
EMSCRIPTEN_KEEPALIVE double *a,*b, *v, *u;
EMSCRIPTEN_KEEPALIVE short *c,*d,*i,*w, isPlaying=-1;
EMSCRIPTEN_KEEPALIVE uint16_t *positions;

EMSCRIPTEN_KEEPALIVE uint32_t bigBufferLength = 30 * 200;
EMSCRIPTEN_KEEPALIVE double **v_traces;
EMSCRIPTEN_KEEPALIVE int *canvasPointers;
EMSCRIPTEN_KEEPALIVE int *neuronCircles;

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
    // v0[0]= 3.0;
    // v0[1]= 7.0;
    // EM_ASM({
    //     console.log('0TESTTT: ');
    // });

    return 0;
}


EXTERNC FUNCTION_ATTRIBUTE short changeIsPlayingProcess(short _isPlaying){
    v0[0]= 12.0;
    v0[1]= 77.0;
    v0[2]= 47.0;

    // v2[0] = new double[3];
    // v2[1] = new double[3];
    // v2[0][0] = -10.1;
    // v2[0][1] = -10.2;
    // v2[0][2] = -10.3;
    // v2[1][0] = -20.1;
    // v2[1][1] = -20.2;
    // v2[1][2] = -20.3;

    // EM_ASM({
    //     console.log('TESTTT: ');
    //     console.log('Idx: ',  $0[0]>>3 , ', ' , ($0[0]+16)>>3);
    //     // console.log(HEAPF64.subarray($0>>3, ($0 + 24) >> 3));
    //     console.log(HEAPF64.subarray(($0 + 0)>>3, ($0 + 17 ) >> 3));
    //     console.log(HEAPF64.subarray(($0 + 16)>>3, ($0 + 16 + 24) >> 3));
    //     console.log(HEAPF64.subarray(($0 + 16 + 24 + 8 )>>3, ($0 + 48 + 24  ) >> 3));

    // }, v2, 4);
    // EM_ASM({
    //     console.log('TESTTT: ');
    //     console.log('Idx: ',  $0>>3 , ', ' , ($0+24)>>3);
    //     console.log(HEAPF64.subarray($0>>3, ($0 + 24) >> 3));

    // }, v0, 3);
    isPlaying = _isPlaying;
    return isPlaying;
    // if (isPlaying == -1){
    //     isPlaying = 1;
    // }else{
    //     isPlaying = -1;
    // }
    // return isPlaying;
}

// EM_JS(void, read_data, (double** data), {
//     // console.log('Data: ' + data[0] + ', ' + data[1]);
//     console.log('Data: ' + HEAPF64[data>>2] + ', ' + HEAPF64[(data+8)>>2]);
//     // console.log('Data: ' + HEAP32[data>>2] + ', ' + HEAP32[(data+4)>>2]);
// });            

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
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, short *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(const val &__a, const val &__b, const val &__c, const val &__d, const val &__i, const val &__w, const val &__positions, const val &__canvasPointers, short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
// EXTERNC FUNCTION_ATTRIBUTE auto applyLowPassFilter(int16_t channelIdx, const val &data, int32_t sampleCount){
    std::vector<double> _a = convertJSArrayToNumberVector<double>(__a); 
    std::vector<double> _b = convertJSArrayToNumberVector<double>(__b); 
    std::vector<short> _c = convertJSArrayToNumberVector<short>(__c); 
    std::vector<short> _d = convertJSArrayToNumberVector<short>(__d); 
    std::vector<short> _i = convertJSArrayToNumberVector<short>(__i); 
    std::vector<short> _w = convertJSArrayToNumberVector<short>(__w); 
    std::vector<uint16_t> _positions = convertJSArrayToNumberVector<uint16_t>(__positions); 
    std::vector<int> _canvasPointers = convertJSArrayToNumberVector<int>(__canvasPointers); 

//     if (lowPassFilters[channelIdx].omega != 0){
//         lowPassFilters[channelIdx].filter(raw.data(), sampleCount, false);
//         val view{ typed_memory_view(raw.size(), raw.data()) };
//         auto result = val::global("Int16Array").new_(raw.size());
//         result.call<void>("set", view);
//         return result;
//     }else{
//         val view{ typed_memory_view(raw.size(), raw.data()) };
//         auto result = val::global("Int16Array").new_(raw.size());
//         result.call<void>("set", view);
//         return result;
//     }

    // debug_print("changeNeuronSimulatorProcess 0");
    a=new double[_neuronLength];
    b=new double[_neuronLength];
    c=new short[_neuronLength];
    d=new short[_neuronLength];
    i=new short[_neuronLength];
    w=new short[_neuronLength];
    v=new double[_neuronLength];
    u=new double[_neuronLength];
    canvasPointers = new int[_neuronLength];
    neuronCircles = new int[_neuronLength];
    
    double rand = 1;
    for (short neuronIndex = 0 ; neuronIndex < _neuronLength; neuronIndex++){
        positions[neuronIndex] = _positions[neuronIndex];
        a[neuronIndex]=_a[neuronIndex];
        b[neuronIndex]=_b[neuronIndex];
        c[neuronIndex]=_c[neuronIndex];
        d[neuronIndex]=_d[neuronIndex];
        i[neuronIndex]=_i[neuronIndex];
        w[neuronIndex]=_w[neuronIndex];
        canvasPointers[neuronIndex] = _canvasPointers[neuronIndex];
        neuronCircles[neuronIndex] = 0;
        rand = i_rand * randoms();

        v[neuronIndex]= c[neuronIndex] + rand;
        // v[ch]= c[ch] +  (double) (i_rand * rand() / RAND_MAX);
        u[neuronIndex]= b[neuronIndex] * v[neuronIndex];
    }
    EM_ASM({
        console.log('a : ',  $0 , ', ' , ($1));
    }, a[0], a[1]);
    EM_ASM({
        console.log('b : ',  $0 , ', ' , ($1));
    }, b[0], b[1]);
    EM_ASM({
        console.log('c : ',  $0 , ', ' , ($1));
    }, c[0], c[1]);
    EM_ASM({
        console.log('d : ',  $0 , ', ' , ($1));
    }, d[0], d[1]);

    lvl = _level;
    totalNumOfNeurons = _neuronLength;
    envSize = _envelopeSize;
    bufSize = _bufferSize;
    isPlaying = _isPlaying;
    // debug_print(std::to_string(a[0]).c_str());
    if (isThreadCreated==-1){
        // debug_print("v_traces");
        v_traces = new double*[_neuronLength];

        for (short idx = 0; idx<_neuronLength; idx++){
            v_traces[idx] = new double[bigBufferLength];
        }       
        // v_traces1 = canvasBuffer1;
        // v_traces2 = canvasBuffer2;

        isThreadCreated=1;

        std::thread simulatorThread([&]() {
            double rand;
            int32_t currentStep = 0;
            short isSpiking[totalNumOfNeurons];
            short isStepSpiking[totalNumOfNeurons];
            double connectome[totalNumOfNeurons][totalNumOfNeurons];
            
            while(true){
                if (w[0] != connectome[0][1] || w[1] != connectome[1][0]){
                    connectome[0][0] = 0.0; // w_init = 2
                    connectome[0][1] = w[0]; // w_init = 2
                    connectome[1][0] = w[1]; // w_init = 2
                    connectome[1][1] = 0.0; // w_init = 2
                }

                double tI[totalNumOfNeurons];
                if (isPlaying == -1 || isThreadCreated == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    // std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }

                std::vector<double*> v_step = std::vector<double*>();

                for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
                    isStepSpiking[neuronIndex] = 0;
                }

                for (short t = 0; t < ms_per_step; t++) {
                    std::vector<int> spikingNow = std::vector<int>();
                    // double tempV[totalNumOfNeurons];
                    for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
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
                    double *copyV = new double[totalNumOfNeurons];
                    std::copy(v, v+totalNumOfNeurons, copyV);
                    v_step.push_back(copyV);

                    short numberOfSpikingNow = spikingNow.size();
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        short neuronIndex = spikingNow[idx];
                        //Reset spiking v to c
                        v[neuronIndex] = c[neuronIndex];
                        //Adjust spiking u to d
                        u[neuronIndex] = u[neuronIndex] + d[neuronIndex];
                    }
                    // double *copyV = new double[totalNumOfNeurons];
                    // std::copy(v, v+totalNumOfNeurons, copyV);
                    // v_step.push_back(copyV);
        
                    
                    //Add spiking synaptic weights to neuronal inputs
                    double *sumConnectome = new double[totalNumOfNeurons]();
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        short spikingNeuronIndex = spikingNow[idx];

                        for ( short j=0; j < totalNumOfNeurons ; j++ ){
                            sumConnectome[j] += connectome[spikingNeuronIndex][j];
                        }
                        // short neuronIndex = spikingNow[idx];
                        // short inverseNeuronIndex = totalNumOfNeurons - 1 - neuronIndex;
                        // tI[inverseNeuronIndex] += w[inverseNeuronIndex];
                    }
                    for (short idx = 0; idx < totalNumOfNeurons; idx++){
                        tI[idx] += sumConnectome[idx];
                    }
                    free(sumConnectome);

                    for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
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

                if (isStepSpiking[0]==1 && isStepSpiking[1]==1){
                    std::string str = "S|1|1";
                    // for (unsigned idx=0; idx<totalNumOfNeurons; idx++){
                    //     str.append(std::to_string(isSpiking[idx]).c_str());
                    //     if (idx < totalNumOfNeurons-1) str.append("|");
                    // }
                    neuronCircles[0]=1;
                    neuronCircles[1]=1;
                    prevFlagSpiking = 1;
                    // EM_ASM({
                    //     sabNumNeuronCircle[0] = 1;
                    //     sabNumNeuronCircle[1] = 1;
                    // });

                    // debug_print(str.c_str());
                }else
                if (isStepSpiking[0]==1 && isStepSpiking[1]==0){
                    std::string str = "S|1|0";
                    prevFlagSpiking = 1;
                    neuronCircles[0]=1;
                    neuronCircles[1]=0;
                    // EM_ASM({
                    //     sabNumNeuronCircle[0] = 1;
                    //     sabNumNeuronCircle[1] = 0;
                    // });

                    // debug_print(str.c_str());
                }else
                if (isStepSpiking[0]==0 && isStepSpiking[1]==1){
                    std::string str = "S|0|1";
                    neuronCircles[0]=0;
                    neuronCircles[1]=1;
                    prevFlagSpiking = 1;
                    // EM_ASM({
                    //     sabNumNeuronCircle[0] = 0;
                    //     sabNumNeuronCircle[1] = 1;
                    // });

                    // debug_print(str.c_str());
                }else{
                    if (prevFlagSpiking == 1){
                        std::string str = "S|0|0";
                        neuronCircles[0]=0;
                        neuronCircles[1]=0;
                        // EM_ASM({
                        //     sabNumNeuronCircle[0] = 0;
                        //     sabNumNeuronCircle[1] = 0;
                        // });

                        // debug_print(str.c_str());
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
                    for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
                        v_traces[neuronIndex][startPos + idx] = (v_step[idx][neuronIndex]);
                    }
                }
                for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
                    positions[neuronIndex] = startPos + v_step.size();
                }

                currentStep++;
                if (currentStep >= steps_per_loop){
                    currentStep = 0;            
                }
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
    // function("applyLowPassFilter", &applyLowPassFilter);
    // register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}


// EXTERNC double createFilters(){
//     return 30;
// }
#endif
