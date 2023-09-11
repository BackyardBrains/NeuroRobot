// #ifndef NEURO_ROBOT_SIMULATOR
// #define NEURO_ROBOT_SIMULATOR
// #include <stdlib.h>
// #include <string.h>
// #include <stdio.h>
// #include <math.h>
// #include <algorithm>
// #include <cmath>
// #include <cstdlib>
// #include <cstring>
// #include <stdint.h>
// #include <thread>
// #include <chrono>
// #include <vector>
// // C++ to FLUTTER
// #include "include/dart_api.h"
// #include "include/dart_native_api.h"
// #include "include/dart_api_dl.h"


// #ifdef __cplusplus
// #define EXTERNC extern "C"
// #else
// #define EXTERNC
// #endif

// #if defined(__GNUC__)
//     #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
// #elif defined(_MSC_VER)
//     #define FUNCTION_ATTRIBUTE __declspec(dllexport)
// #endif

// // C++ TO FLUTTER
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

// // MAIN CODE
// short ms_per_step = 30;
// short steps_per_loop = 200;
// short intended_timer_period = ms_per_step/1000;

// double *a,*b, *v, *u;
// short *c,*d,*i,*w, isPlaying=-1;
// uint16_t *positions;
// int32_t lvl,totalNumOfNeurons, envSize,bufSize;
// const uint32_t bigBufferLength = 30 * 200;
// double *v_traces1;
// double *v_traces2;

// short prevFlagSpiking = -1;
// short isThreadCreated=-1;
// // a = 0.02;
// // b = 0.18;
// // c = -65;
// // d = 2;
// // i = 5;
// // w = 2;

// double i_rand = 5;

// double randoms(){
//     return (double) rand() / RAND_MAX * 1;
// }

// double matrixMultiply(){
//     return (double)rand() / RAND_MAX; // for generating random points between 0 to 1
// }

// int main()
// {

// }


// EXTERNC FUNCTION_ATTRIBUTE short changeIsPlayingProcess(short _isPlaying){
//     isPlaying = _isPlaying;
//     return isPlaying;
//     // if (isPlaying == -1){
//     //     isPlaying = 1;
//     // }else{
//     //     isPlaying = -1;
//     // }
//     // return isPlaying;
// }


// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, short *_w, double *canvasBuffer1, double *canvasBuffer2, uint16_t *_positions,short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
//     // debug_print("changeNeuronSimulatorProcess 0");

//     // int32_t length = _neuronLength;
//     a=new double[_neuronLength];
//     b=new double[_neuronLength];
//     c=new short[_neuronLength];
//     d=new short[_neuronLength];
//     i=new short[_neuronLength];
//     w=new short[_neuronLength];
//     v=new double[_neuronLength];
//     u=new double[_neuronLength];
//     if (isThreadCreated==-1){
//         positions = _positions;
//         debug_print("v_traces");
//         v_traces1 = canvasBuffer1;
//         v_traces2 = canvasBuffer2;
//     }

//     double rand = 1;
//     for (short neuronIndex = 0 ; neuronIndex < _neuronLength; neuronIndex++){
//         a[neuronIndex]=_a[neuronIndex];
//         b[neuronIndex]=_b[neuronIndex];
//         c[neuronIndex]=_c[neuronIndex];
//         d[neuronIndex]=_d[neuronIndex];
//         i[neuronIndex]=_i[neuronIndex];
//         w[neuronIndex]=_w[neuronIndex];
//         rand = i_rand * randoms();
//                             // debug_print("Found Spike");
//                             // debug_print(std::to_string(c[neuronIndex]).c_str());

//         v[neuronIndex]= c[neuronIndex] + rand;
//         // v[neuronIndex]= c[neuronIndex] +  (double) (i_rand * rand() / RAND_MAX);
//         u[neuronIndex]= b[neuronIndex] * v[neuronIndex];
//     }
//     lvl = _level;
//     totalNumOfNeurons = _neuronLength;
//     envSize = _envelopeSize;
//     bufSize = _bufferSize;
//     isPlaying = _isPlaying;
//     // debug_print(std::to_string(a[0]).c_str());
//     if (isThreadCreated==-1){
//         isThreadCreated=1;

//         std::thread simulatorThread([&]() {
//             double rand;
//             int32_t currentStep = 0;
//             short isSpiking[totalNumOfNeurons];
//             short isStepSpiking[totalNumOfNeurons];
//             double connectome[totalNumOfNeurons][totalNumOfNeurons];

//             while(true){
//                 if (w[0] != connectome[0][1] || w[1] != connectome[1][0]){
//                     connectome[0][0] = 0.0; // w_init = 2
//                     connectome[0][1] = w[0]; // w_init = 2
//                     connectome[1][0] = w[1]; // w_init = 2
//                     connectome[1][1] = 0.0; // w_init = 2
//                 }

//                 double tI[totalNumOfNeurons];
//                 if (isPlaying == -1){
//                     std::this_thread::sleep_for(std::chrono::seconds(1));
//                     continue;
//                 }else{
//                     // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
//                     std::this_thread::sleep_for(std::chrono::milliseconds(50));
//                 }
//                 // debug_print("changeNeuronSimulatorProcess --1");

//                 // size_t sz = static_cast<size_t>(totalNumOfNeurons);
//                 // const sz = totalNumOfNeurons;
//                 std::vector<double*> v_step = std::vector<double*>();


//                 for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
//                     isStepSpiking[neuronIndex] = 0;

//                 }
        
//                 for (short t = 0; t < ms_per_step; t++) {
//                     std::vector<int> spikingNow = std::vector<int>();
//                     // double tempV[totalNumOfNeurons];
//                     for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
//                         tI[neuronIndex] = i[neuronIndex] * (1.3 *randoms());
                        
//                         //find spiking neurons
//                         isSpiking[neuronIndex] = 0;
//                         if (v[neuronIndex] >= 30) {
//                             isSpiking[neuronIndex] = 1;
//                             isStepSpiking[neuronIndex] = 1;
//                             spikingNow.push_back(neuronIndex);
//                         }
//                     }
//                     // insert old data in timeline
//                     double *copyV = new double[totalNumOfNeurons];
//                     std::copy(v, v+totalNumOfNeurons, copyV);
//                     v_step.push_back(copyV);
//                     short numberOfSpikingNow = spikingNow.size();
//                     for (short idx = 0; idx < numberOfSpikingNow; idx++){
//                         short neuronIndex = spikingNow[idx];
//                         //Reset spiking v to c
//                         v[neuronIndex] = c[neuronIndex];
//                         //Adjust spiking u to d
//                         u[neuronIndex] = u[neuronIndex] + d[neuronIndex];
//                     }
//                     // double *copyV = new double[len];
//                     // std::copy(v, v+len, copyV);
//                     // v_step.push_back(copyV);
                    
//                     //Add spiking synaptic weights to neuronal inputs
//                     // for (short idx = 0; idx < n; idx++){
//                     //     short neuronIndex = spikingNow[idx];
//                     //     tI[neuronIndex] += w[neuronIndex];
//                     // }
//                     double *sumConnectome = new double[totalNumOfNeurons]();
//                     for (short idx = 0; idx < numberOfSpikingNow; idx++){
//                         short spikingNeuronIndex = spikingNow[idx];

//                         for ( short j=0; j < totalNumOfNeurons ; j++ ){
//                             sumConnectome[j] += connectome[spikingNeuronIndex][j];
//                         }
//                         // short neuronIndex = spikingNow[idx];
//                         // short inverseNeuronIndex = totalNumOfNeurons - 1 - neuronIndex;
//                         // tI[inverseNeuronIndex] += w[inverseNeuronIndex];
//                     }
//                     for (short idx = 0; idx < totalNumOfNeurons; idx++){
//                         tI[idx] += sumConnectome[idx];
//                     }
//                     free(sumConnectome);

//                     for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {

//                         // v[neuronIndex] += 0.5 * randoms();  

//                         // Propagate v  
//                         v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);
//                         // Adjust for continuous time
//                         v[neuronIndex] += 0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]);

//                         // if (std::isnan(v[neuronIndex])){
//                         //     if (std::isnan(c[neuronIndex])){
//                         //         v[neuronIndex] = 0;
//                         //     }else{
//                         //         v[neuronIndex] = c[neuronIndex];
//                         //     }
//                         // }
//                         //Update u
//                         u[neuronIndex] = u[neuronIndex] + a[neuronIndex] * (b[neuronIndex]*v[neuronIndex] - u[neuronIndex]);

//                     }
//                         // tempV[neuronIndex] = v[neuronIndex];
//                 }
//                 if (isStepSpiking[0]==1 && isStepSpiking[1]==1){
//                     std::string str = "S|1|1";
//                     // for (unsigned idx=0; idx<len; idx++){
//                     //     str.append(std::to_string(isSpiking[idx]).c_str());
//                     //     if (idx < len-1) str.append("|");
//                     // }
//                     prevFlagSpiking = 1;
//                     debug_print(str.c_str());
//                 }else
//                 if (isStepSpiking[0]==1 && isStepSpiking[1]==0){
//                     std::string str = "S|1|0";
//                     prevFlagSpiking = 1;
//                     debug_print(str.c_str());
//                 }else
//                 if (isStepSpiking[0]==0 && isStepSpiking[1]==1){
//                     std::string str = "S|0|1";
//                     prevFlagSpiking = 1;
//                     debug_print(str.c_str());
//                 }else{
//                     if (prevFlagSpiking == 1){
//                         std::string str = "S|0|0";
//                         debug_print(str.c_str());
//                         prevFlagSpiking = 0;
//                     }
//                     // debug_print("test");
//                 }

//                 // auto is_nan = [](float value) { return std::isnan(value); };
//                 // auto is_nan = [](const auto& value) { return std::isnan(value); };
//                 // v_step.erase(std::remove_if(v_step.begin(), v_step.end(), is_nan), v_step.end());
//                 // v_step.erase(std::remove_if(v_step.begin(),
//                 //                     v_step.end(),
//                 //                     is_nan),
//                 //         v_step.end());                
//                 // for (auto it = v_step.begin(); it != v_step.end(); it++) {
//                 //     if (*it == NAN) {
//                 //         *it = 0;
//                 //     }
//                 // }                
//                 short startPos = (currentStep) * ms_per_step ;
//                 // debug_print(std::to_string(startPos).c_str());

//                 for (int idx = 0; idx < v_step.size(); idx++) {
//                     for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
//                         if (neuronIndex % 2 == 0){
//                             v_traces1[startPos + idx] = (v_step[idx][neuronIndex]);
//                         }else{
//                             v_traces2[startPos + idx] = (v_step[idx][neuronIndex]);
//                         }
//                     }
//                 }
//                 for (short neuronIndex = 0; neuronIndex < totalNumOfNeurons; neuronIndex++) {
//                     positions[neuronIndex] = startPos + v_step.size();
//                 }
//                 currentStep++;
//                 if (currentStep >= steps_per_loop){
//                     // debug_print(std::to_string(currentStep).c_str());
//                     currentStep = 0;            
//                 }
//                 // for (short neuronIndex = 0; neuronIndex < bigBufferLength; neuronIndex++) {
//                 //     v_traces2[neuronIndex] = randoms() *10;
//                 // }
//                 // v_traces2[0] = 0;

//             }


//         });        
//         simulatorThread.detach();
//     }
//     return 1.0;
// }




// // EXTERNC double createFilters(){
// //     return 30;
// // }
// #endif
