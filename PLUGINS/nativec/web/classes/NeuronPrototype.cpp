#ifdef __EMSCRIPTEN__
    #include <emscripten/bind.h>
    using namespace emscripten;
    #include <emscripten.h>
    #include <wasm_simd128.h>
#endif
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
#ifdef __EMSCRIPTEN__
#else
    #include "include/dart_api.h"
    #include "include/dart_native_api.h"
    #include "include/dart_api_dl.h"

#endif         


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
#ifdef __EMSCRIPTEN__
#else

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
#endif         


// C++ to Flutter

// MAIN CODE
std::thread simulatorThread;
// std::mutex mtx;

bool isThreadRunning = true;
short ms_per_step = 30;
short steps_per_loop = 200;
short intended_timer_period = ms_per_step/1000;

bool isSelected,isRecreatingNeurons, isDebugNewNeurons;
double *a,*b, *v, *u,*i,*w;
// short *c,*d,*i,*w,isPlaying=-1, idxSelected;
short *c,*d,isPlaying=-1, idxSelected;
short *neuronCircles;
short *positions;
int32_t lvl,totalNumOfNeurons, prevTotalNumOfNeurons, envSize,bufSize;
const uint32_t bigBufferLength = 30 * 200;
// double *v_traces1;
// double *v_traces2;
double **v_traces;
double *canvasBuffer;
double **connectome;
int *nps;

// double **v_step;
int epochs = ms_per_step;

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
    srand((unsigned) time(NULL));    
    return (double) rand() / RAND_MAX * 1;
    // short negative = 1;
    // float randomNumber = rand() / (RAND_MAX + 1.0);
    // // Multiply the random number by 2 and subtract 1.
    // int randomNegativeOrPositiveNumber = 2 * randomNumber - 1;    
    // if (randomNegativeOrPositiveNumber < 0) {
    //     negative = -1;
    // } else {
    //     negative = 1;
    // }    
    // return (double) rand() / RAND_MAX * negative;    
}

double matrixMultiply(){
    return (double)rand() / RAND_MAX; // for generating random points between 0 to 1
}

int main()
{
    srand((unsigned) time(NULL));
    return 0;
}

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE short stopThreadProcess(short _idxSelected){
    isThreadRunning = false;
    isThreadCreated = -1;

    return idxSelected;
}
#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE short changeIdxSelectedProcess(short _idxSelected){
    if (_idxSelected == -1){
        isSelected = false;
    }else{
        isSelected = true;
        idxSelected = _idxSelected;
    }
    return idxSelected;
}

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
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

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE double passPointers(double *_canvasBuffer, short *_positions, short *_neuronCircle,int *_nps){
    canvasBuffer = _canvasBuffer;
    positions = _positions;
    neuronCircles = _neuronCircle;        
    nps = _nps;    
    return 1.0;
}
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, double *_w, double *canvasBuffer, double *canvasBuffer2, uint16_t *_positions,double *_connectome,
//     int *_nps,short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif    
EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, double *_i, double *_w, double *_connectome,
    short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){      
    // debug_print("changeNeuronSimulatorProcess 0");

    a=_a;
    b=_b;
    c=_c;
    d=_d;
    i=_i;
    w=_w;
    v=new double[_neuronLength];
    u=new double[_neuronLength];

    #ifdef __EMSCRIPTEN__
        EM_ASM({
            console.log('a : ',  $0 , ', ' , ($1));
        }, a[0], _a[0]);
        EM_ASM({
            console.log('b : ',  $0 , ', ' , ($1));
        }, b[0], _b[0]);
        EM_ASM({
            console.log('c : ',  $0 , ', ' , ($1));
        }, c[0], _c[0]);
        EM_ASM({
            console.log('d : ',  $0 , ', ' , ($1));
        }, d[0], _d[0]);

    #endif

    // v_step = new double*[_neuronLength];
    connectome = new double*[_neuronLength];
    int ctr = 0;
    for (int i = 0; i < _neuronLength; i++){
        connectome[i] = new double[_neuronLength]();
        for (int j = 0; j < _neuronLength; j++){
            connectome[i][j] = _connectome[ctr++];
        }

    }

    double rand = 1;
    for (short neuronIndex = 0 ; neuronIndex < _neuronLength; neuronIndex++){
        rand = i_rand * randoms();
        v[neuronIndex]= c[neuronIndex] + rand;
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

        // debug_print("v_traces");
        v_traces = new double*[_neuronLength];
        for (int idx = 0; idx<_neuronLength; idx++){
            v_traces[idx] = new double[bigBufferLength]();
        }
        // debug_print("t detach 0");
        simulatorThread = std::thread([&]() {
            double rand;
            int32_t currentStep = 0;
            // debug_print("t created");

            int32_t threadInitialTotalNumOfNeurons = totalNumOfNeurons;
            auto start = std::chrono::high_resolution_clock::now();
            auto elapsed = std::chrono::high_resolution_clock::now() - start;
            long long microseconds = 0;
            bool isNeuronPerSecond = true;
            while(isThreadRunning){
                // mtx.lock();

                int32_t threadTotalNumOfNeurons = totalNumOfNeurons;
                short isSpiking[threadTotalNumOfNeurons];
                short isStepSpiking[threadTotalNumOfNeurons];

                double tI[threadTotalNumOfNeurons];
                if (isPlaying == -1 || isThreadCreated == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                }
                std::vector<double*> v_step = std::vector<double*>();

                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    isStepSpiking[neuronIndex] = 0;
                }
                start = std::chrono::high_resolution_clock::now();
                for (uint32_t t = 0; t < epochs; t++) {
                    std::vector<int> spikingNow = std::vector<int>();
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        #ifdef __EMSCRIPTEN__
                            tI[neuronIndex] = i[neuronIndex] * (1.3 *randoms());
                        #else
                            tI[neuronIndex] = i[neuronIndex] * (1.3 *randoms());

                        #endif                        
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
                        // Propagate v  
                        v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);
                        // Adjust for continuous time
                        v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);
                        //Update u
                        u[neuronIndex] = u[neuronIndex] + a[neuronIndex] * (b[neuronIndex]*v[neuronIndex] - u[neuronIndex]);
                    }

                }
                if (isNeuronPerSecond){
                    isNeuronPerSecond = false;
                    elapsed = std::chrono::high_resolution_clock::now() - start;
                    microseconds = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
                    // int microtime = microseconds;
                    nps[0] = microseconds;
                }
                // debug_print( (std::to_string(microseconds)+" microseconds" ).c_str());
                // mtx.unlock();

                std::string str = "S|";
                short isFlagSpikingNow = 0;
                #ifdef __EMSCRIPTEN__
                    for (unsigned idx=0; idx<threadTotalNumOfNeurons; idx++){
                        neuronCircles[idx] = isStepSpiking[idx];
                    }
                #else
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
                        #ifdef __EMSCRIPTEN__
                        #else
                            debug_print(str.c_str());
                        #endif                        
                    }else{
                        prevFlagSpiking = isFlagSpikingNow;
                        #ifdef __EMSCRIPTEN__
                        #else
                            debug_print(str.c_str());
                        #endif                        
                    }

                #endif  

                short startPos = (currentStep) * ms_per_step ;
                // for (int idx = 0; idx < v_step.size(); idx++) {
                for (int idx = 0; idx < epochs; idx++) {
                    // for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        v_traces[neuronIndex][startPos + idx] = (v_step[idx][neuronIndex]);
                    }
                }

                positions[0] = startPos + epochs;


                // debug_print( (std::to_string(positions[0])+" | " ).c_str());

                // for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                //     positions[neuronIndex] = startPos + epochs;
                // }
                currentStep++;
                if (currentStep >= steps_per_loop){
                    currentStep = 0;            
                }

                if (isSelected){
                    // debug_print( (std::to_string(idxSelected) + " | " +std::to_string(threadTotalNumOfNeurons)).c_str());
                    // if (idxSelected < threadTotalNumOfNeurons){
                        std::copy(&v_traces[idxSelected][0], &v_traces[idxSelected][0] + bigBufferLength, canvasBuffer);
                    // }
                }

            }
            if (!isThreadRunning){
                // delete[] (a);
                // delete[] (b);
                // delete[] (c);
                // delete[] (d);
                // delete[] (i);
                // delete[] (w);
                delete[] (v);
                delete[] (u);
                delete[] (connectome);
                for (unsigned idx=0; idx<threadInitialTotalNumOfNeurons; idx++){
                    delete[] (v_traces[idx]);
                }
                delete[] v_traces;
                #ifdef __EMSCRIPTEN__
                    std::terminate();
                #endif
            }

        });        

        simulatorThread.detach();
        isThreadRunning = true;
        // debug_print("t detach");

    }
    return 0.0;
}

#ifdef __EMSCRIPTEN__
EMSCRIPTEN_BINDINGS(my_module) {
    function("changeIsPlayingProcess", &changeIsPlayingProcess);
//     function("changeNeuronSimulatorProcess", &changeNeuronSimulatorProcess);
//     // function("getCanvasBuffer", &getCanvasBuffer);
//     // function("getCurrentPosition", &getCurrentPosition);
//     // function("getNeuronCircles", &getNeuronCircles);
    function("stopThreadProcess", &stopThreadProcess);
    function("changeIdxSelectedProcess", &changeIdxSelectedProcess);
//     // function("applyLowPassFilter", &applyLowPassFilter);
//     // register_vector<short>("vector<short>");
//     // register_vector<short>("LowPassList");
}
#endif


// EXTERNC double createFilters(){
//     return 30;
// }
#endif
