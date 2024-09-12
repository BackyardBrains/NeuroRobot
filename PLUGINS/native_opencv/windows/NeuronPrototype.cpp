#ifdef __EMSCRIPTEN__
    #include <emscripten/bind.h>
    using namespace emscripten;
    #include <emscripten.h>
    #include <wasm_simd128.h>
#endif
// #ifndef NEURO_ROBOT_SIMULATOR
// #define NEURO_ROBOT_SIMULATOR
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
#include <bitset>
// C++ to FLUTTER
#ifdef __EMSCRIPTEN__
#else
    // #include "include/dart_api.h"
    // #include "include/dart_native_api.h"
    // #include "include/dart_api_dl.h"

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
    // void debug_print(const char *fmt, ...) {
    //     va_list args;
    //     va_start(args, fmt);
    // #ifdef __ANDROID__
    //     __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
    // #elif defined(IS_WIN32)
    //     char *buf = new char[4096];
    //     std::fill_n(buf, 4096, '\0');
    //     _vsprintf_p(buf, 4096, fmt, args);
    //     OutputDebugStringA(buf);
    //     delete[] buf;
    // #else
    //     vprintf(fmt, args);
    // #endif
    //     va_end(args);
    // }

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
#endif         

#include "NeuronPrototype.h"
#include "GuidedList.cpp"

// #include "NeuronPrototypeHeader.cpp"
// #include "native_opencv.cpp"
// C++ to Flutter

// MAIN CODE

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE void nativeSimulationCallback(void (*onRequest)(const char*)) {
    onCallback = onRequest;
}


std::thread simulatorThread;
std::thread guidedQueueThread;


void setSimulationMatrixValue(double *arr, short pi, short pj, short per_row, double value){
    arr[ pi * per_row + pj] =  value;
}

double getSimulationMatrixValue(double *arr, short pi, short pj, int32_t per_row){
    return arr[ pi * per_row + pj];
}

short getSimulationMatrixValue(short *arr, short pi, short pj, int32_t per_row){
    return arr[ pi * per_row + pj];
}

double randoms(){
    // srand((unsigned) time(NULL));    
    return ( (double) rand() / RAND_MAX * 1);
    // short negative = 1;
    // double randomNumber = rand() / (RAND_MAX + 1.0);
    // // Multiply the random number by 2 and subtract 1.
    // int randomNegativeOrPositiveNumber = 2 * static_cast<int>(randomNumber) - 1;    
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
void initializeConstant(int neuronLength){
    totalNeuron = neuronLength;
    intended_timer_period = ms_per_step/1000;
    epochs = ms_per_step;
    vis_I = new double[neuronLength];
    dist_I = new double[neuronLength];

}

double brainSigmoid(double xx, double cc, double aa) {
    return 1.0 / (1.0 + exp(-aa * (xx - cc)));
}


int main()
{
    srand((unsigned) time(NULL));
    return 0;
}
EXTERNC void platform_log(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    // __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
#elif defined(IS_WIN32)
    char *buf = new char[4096];
    std::fill_n(buf, 4096, '\0');
    _vsprintf_p(buf, 4096, fmt, args);
    OutputDebugStringA(buf);
    delete[] buf;
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}

std::string decimalToBinaryString(int decimal) {
    // std::string str = std::bitset<4>(decimal).to_string();
    // platform_log("str\n");
    // platform_log(str.c_str());
    // platform_log("\n");
    // return str; // Adjust bit width as needed
    return std::bitset<4>(decimal).to_string();
}


#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE short initialize(){
    // temp_vis_pref_vals = new double*[vis_prefs_count];
    // for (short featureIdx = 0; featureIdx < vis_prefs_count; featureIdx++){
    //     temp_vis_pref_vals[featureIdx] = new double[ncam];
    //     temp_vis_pref_vals[featureIdx][0] = 0;
    //     temp_vis_pref_vals[featureIdx][1] = 0;
    // }

    // vis_pref_vals = new double*[vis_prefs_count];
    // for (short featureIdx = 0; featureIdx < vis_prefs_count; featureIdx++){
    //     vis_pref_vals[featureIdx] = new double[ncam];
    //     vis_pref_vals[featureIdx][0] = 0;
    //     vis_pref_vals[featureIdx][1] = 0;
    // }
    return 1;
}


#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif

EXTERNC FUNCTION_ATTRIBUTE short stopThreadProcess(short _idxSelected){
    short delayTime = 0;
    for (int idx = 0; idx < totalNeuron; idx++){
        if (guidedDelayList[idx].mode == 1){
            guidedDelayList[idx].isInterrupted = true;
            delayTime = std::max(delayTime,mapDelayNeuron[idx]);
        }
        guidedDelayList[idx].isDecayInterrupted = true;
    }
    if (delayTime > 0){
        std::this_thread::sleep_for(std::chrono::milliseconds(delayTime *3/4 ));
    }

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
EXTERNC FUNCTION_ATTRIBUTE double passPointers(double *_canvasBuffer, short *_positions, short *_neuronCircle,int *_nps, int *p_state_buf, short *p_vis_prefs, double *p_vis_pref_vals, uint8_t *p_motor_command_message,double *p_neuron_contacts, short *p_dist_prefs, short *p_speaker_buf, short *p_microphone_buf, short *p_led_buf, short *p_led_pos_buf){
    canvasBuffer = _canvasBuffer;
    positions = _positions;
    neuronCircles = _neuronCircle;        
    nps = _nps;

    state_buf = p_state_buf;
    visPrefs = p_vis_prefs;
    vis_pref_vals = p_vis_pref_vals;
    motor_command_message = p_motor_command_message;
    neuron_contacts = p_neuron_contacts;
    dist_prefs = p_dist_prefs;

    speaker_buf = p_speaker_buf;
    microphone_buf = p_microphone_buf;
    led_buf = p_led_buf;
    led_pos_buf = p_led_pos_buf;

    return 1.0;
}

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
EXTERNC FUNCTION_ATTRIBUTE double passInput(double *p_sensor_distance){
    sensor_distance = p_sensor_distance;
    return 1.0;
}


// void compareLinkedList(GuidedList* glSrc, GuidedList* glDest){
    // Node* srcTail = glSrc->getList().tail;
    // Node* destTail = glSrc->getList().tail;
void compareLinkedList(Node* srcTail, Node*  destTail){
    std::string srcString = "Source: ";
    std::string destString = "Destination: ";
    while ( true ){
        if (srcTail->prev != nullptr){
            srcString = srcString + std::to_string(srcTail->data) +",";
            destString = destString + std::to_string(destTail->data) +",";
            srcTail = srcTail->prev;
            destTail = destTail->prev;
        }else{
            break;
        }
    }
    platform_log(srcString.c_str());
    platform_log("\n");
    platform_log(destString.c_str());
    platform_log("\n");
}

void getLinkedListValue(GuidedList* psrcHead, GuidedList* psrcTail, int listSize){
    std::string srcString = "Source: ";
    int counter = 0;
    // Node* srcHead = psrcHead[13].getList().head;
    while ( counter< 5 ){
        // if (srcHead->next != psrcTail){
            srcString = srcString + std::to_string(123) +",";
            // srcHead = srcHead->next;
        // }else{
        // }
        counter++;
    }
    // delete srcHead;
    platform_log(srcString.c_str());
    platform_log("\n");
    platform_log("\n");
}
// EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, short *_i, double *_w, double *canvasBuffer, double *canvasBuffer2, uint16_t *_positions,double *_connectome,
//     int *_nps,short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, double *_i, double *_w, double *_connectome,
    short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying, short *vis_prefs, double *_motor_command, double *_neuronContacts,
    short* p_mapNeuronType, short* p_mapDelayNeuron, short* p_mapRhytmicNeuron, short* p_mapCountingNeuron
    ){
    // platform_log("changeNeuronSimulatorProcess 0");
    initializeConstant(_neuronLength);

    a=_a;
    b=_b;
    c=_c;
    d=_d;
    i=_i;
    w=_w;
    v=new double[_neuronLength];
    u=new double[_neuronLength];
    motor_command = _motor_command;

    // neuronDelayTime = new long long[_neuronLength];
    // neuronRhytmicTime = new long long[_neuronLength];
    // neuronCountingTime = new long long[_neuronLength];
    // delayLinkedList = new DoublyLinkedList[_neuronLength];
    // delayValueLinkedList = new DoublyLinkedList[_neuronLength];
    guidedDelayList = new GuidedList[_neuronLength];
    maxV = new double[_neuronLength];
    maxU = new double[_neuronLength];

    // v_step = new double*[_neuronLength];
    connectome = new double*[_neuronLength];
    inhibitionArray = new double[_neuronLength];
    // visPrefs = new short*[_neuronLength];
    // neuron_contacts = new double*[_neuronLength];
    mapNeuronType = p_mapNeuronType;

    mapDelayNeuron = p_mapDelayNeuron;
    mapRhytmicNeuron = p_mapRhytmicNeuron;
    mapCountingNeuron = p_mapCountingNeuron;
    
    // mapAdditionalNeuronTypes = new short*[_neuronLength];

    int ctr = 0;
    double flagcounter = 0;
    for (int ii = 0; ii < _neuronLength; ii++){
        short neuronType = mapNeuronType[ii];
        bool isInhibited = false;
        inhibitionArray[ii] = 0;
        // if (neuronType >= 1000){
        //     isInhibitor = true;
        //     neuronType %= 1000;
        // }

        // delayLinkedList[ii] = DoublyLinkedList();
        // delayValueLinkedList[ii] = DoublyLinkedList();
        // guidedDelayList[ii].setParameters(ii, delayLinkedList, neuronType, isInhibited, mapDelayNeuron[ii], delayValueLinkedList);
        guidedDelayList[ii].setParameters(ii, neuronType, isInhibited, mapDelayNeuron[ii]);

        // neuronDelayTime[ii] = 0;
        // neuronRhytmicTime[ii] = 0;
        // neuronCountingTime[ii] = 0;
        connectome[ii] = new double[_neuronLength]();

        // mapAdditionalNeuronTypes[ii] = new short[_neuronLength];
        // visPrefs[ii] = new short[_neuronLength]();
        // neuron_contacts[ii] = new double[_neuronLength]();
        for (int j = 0; j < _neuronLength; j++){
            connectome[ii][j] = _connectome[ctr];
            if (vis_prefs[ctr]>-1){
                flagcounter++;
            }

            ctr++;
        }
    }
    // PUSHING AND POPPING DATA FROM THREAD IS WORKING!
    // guidedDelayList[0].startDelayThread();
    // while (guidedDelayList[0].isWaiting != 3){
    //     platform_log( (std::to_string(guidedDelayList[0].isWaiting)+" iswaiting\n" ).c_str());    
    //     guidedDelayList[0].push_front(23);
    //     guidedDelayList[0].push_front(81);
    //     guidedDelayList[0].push_front(82);
    //     guidedDelayList[0].push_front(83);
    //     guidedDelayList[0].push_front(87);
    // }
    // short idx = 0;
    // Node* tail = guidedDelayList[idx].list.tail;
    // while (tail != nullptr){
    //     platform_log( ( std::to_string(tail->data)+" - " ).c_str()); 
    //     tail = tail->prev;
    // }
    

    // platform_log( (std::to_string(guidedDelayList[0].isWaiting)+" result iswaiting\n" ).c_str());    

    // // // std::this_thread::sleep_for(std::chrono::milliseconds(2000));

    // short tempData = guidedDelayList[0].pop_back();
    // tempData = guidedDelayList[0].pop_back();

    // platform_log( (std::to_string(tempData)+" tempdata\n" ).c_str());    
    // return 1;

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
        // platform_log2("v_traces");
        v_traces = new double*[_neuronLength];

        for (short idx = 0; idx<_neuronLength; idx++){
            v_traces[idx] = new double[bigBufferLength]();
        }

        // debug_print("t detach 0");
        simulatorThread = std::thread([&]() {
            // double rand;
            int32_t currentStep = 0;

            // platform_log2("t created");

            int32_t threadInitialTotalNumOfNeurons = totalNumOfNeurons;
            spikes_step = new short*[threadInitialTotalNumOfNeurons];
            auto start = std::chrono::high_resolution_clock::now();
            short *switchSkipDelay= new short[threadInitialTotalNumOfNeurons];

            for (short iStep = 0; iStep < threadInitialTotalNumOfNeurons; iStep++){
                spikes_step[iStep] = new short[epochs];
                switchSkipDelay[iStep] = -1;

                // neuronDelayTime[iStep] = start.time_since_epoch().count()/1000000;
                // neuronRhytmicTime[iStep] = neuronDelayTime[iStep];
                // neuronCountingTime[iStep] = neuronDelayTime[iStep];
            }

            auto elapsed = std::chrono::high_resolution_clock::now() - start;
            // long long microseconds = 0;

            double left_backward = 0;
            double left_forward = 0;
            double right_backward = 0;
            double right_forward = 0;
            int left_torque = 0;
            int left_torque_mem = 0;
            int left_dir = 0;

            int right_torque = 0;
            int right_torque_mem = 0;
            int right_dir = 0;

            int r_torque = 0;
            int r_dir = 0;
            int l_torque = 0;
            int l_dir = 0;

            /* what being pushed and popped is the same values
            int listSize = INT32_MAX;
            int counterListPush = 0;
            int counterListPop = 0;
            std::string strPush = "";
            std::string strPop = "";
            int exiter = 0;
            */

            short isSmartNeuronReady = 0;
            while(isThreadRunning){
                int32_t threadTotalNumOfNeurons = totalNumOfNeurons;
                short *isSpiking = new short[threadTotalNumOfNeurons];
                short *isStepSpiking = new short[threadTotalNumOfNeurons];

                double *tI = new double[threadTotalNumOfNeurons];
                if (isPlaying == -1 || isThreadCreated == -1){
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                    continue;
                }else{
                    // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step*2));
                    // std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step * 2));
                    std::this_thread::sleep_for(std::chrono::milliseconds(ms_per_step * 1));
                }
                // start = std::chrono::high_resolution_clock::now();
                double *arrFreshDelayedValue = new double[threadTotalNumOfNeurons];
                // bool delayRemoveInitial[threadTotalNumOfNeurons];
                

                // get distance
                for (short iStep = 0; iStep < threadInitialTotalNumOfNeurons; iStep++){
                    for (short jStep = 0; jStep < epochs; jStep++){
                        spikes_step[iStep][jStep] = 0;
                    }
                    vis_I[iStep] = 0;
                    dist_I[iStep] = 0;

                    if (dist_prefs[iStep] == 0){
                        // dist_I[iStep] = (brainSigmoid(sensor_distance[0], dist_short, -10) * 50);
                        dist_I[iStep] = sensor_distance[0] < 30 ? 50:0;
                    } else 
                    if (dist_prefs[iStep] == 1){
                        dist_I[iStep] = sensor_distance[0] >= 30 && sensor_distance[0] < 60 ? 50 : 0;
                        // dist_I[iStep] = (brainSigmoid(sensor_distance[0], dist_medium, -10) * 50);
                    } else 
                    if (dist_prefs[iStep] == 2){
                        dist_I[iStep] = sensor_distance[0] >= 60 ? 50 : 0;
                        // dist_I[iStep] = (brainSigmoid(sensor_distance[0], dist_long, -10) * 50);
                    }

                }

                // VISUAL INPUT
                for (short ii = normalNeuronFirstIndex; ii < threadInitialTotalNumOfNeurons; ii++){
                    sumVisPrefVals = 0;
                    // for (short jj = 0; jj < threadInitialTotalNumOfNeurons; jj++){
                    for (short jj = 0; jj < normalNeuronFirstIndex; jj++){
                        // if (visPrefs[jj][ii] > -1){ // selected Color detection
                        short k = getSimulationMatrixValue(visPrefs, jj, ii, (threadInitialTotalNumOfNeurons));

                        if (k > -1){ // selected Color detection

                            if (jj == 1){
                                // double val1 = getSimulationMatrixValue(vis_pref_vals, 0, k, 7);
                                double val1 = getSimulationMatrixValue(vis_pref_vals, 0, k, vis_prefs_count);
                                sumVisPrefVals += val1;
                            }else{
                                double val2 = getSimulationMatrixValue(vis_pref_vals, 1, k, vis_prefs_count);
                                sumVisPrefVals += val2;
                            }
                        }
                    }
                    vis_I[ii] = vis_I[ii] + sumVisPrefVals;
                }

                

                std::vector<double*> v_step = std::vector<double*>();

                for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                    isStepSpiking[neuronIndex] = 0;
                    // delayRemoveInitial[neuronIndex] = 0;
                    
                }

                // start = std::chrono::high_resolution_clock::now();
                // auto duration = start.time_since_epoch();
                // microseconds = std::chrono::duration_cast<std::chrono::microseconds>(duration).count();
                // platform_log( (std::to_string(microseconds)+" STARTmicroseconds\n" ).c_str());

                for (int t = 0; t < epochs; t++) {
                    // start = std::chrono::high_resolution_clock::now();

                    std::vector<int> spikingNow = std::vector<int>();
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        #ifdef __EMSCRIPTEN__
                            tI[neuronIndex] = i[neuronIndex] * (1.3 *randoms());
                        #else
                            tI[neuronIndex] = i[neuronIndex] * (1.5 *randoms());

                        #endif                        
                        //find spiking neurons
                        guidedDelayList[neuronIndex].isSpiking = 0;

                        isSpiking[neuronIndex] = 0;
                        arrFreshDelayedValue[neuronIndex] = 0;
                        isSmartNeuronReady = 0;
                        if (guidedDelayList[neuronIndex].neuronType == configDelayNeuron){
                            // check if it get activated in each mode
                            
                            if (guidedDelayList[neuronIndex].mode == 3){// this mode started 3000556 microseconds after start thread log
                                double freshDelayedValue = guidedDelayList[neuronIndex].pop_back();
                                double freshDelayedData = guidedDelayList[neuronIndex].pop_value_back();
                                arrFreshDelayedValue[neuronIndex] = freshDelayedData;
                                // platform_log( ("NeuronSmart Spike Data : " + std::to_string(freshDelayedData)+"\nSmartNeuron Val: "+ std::to_string(freshDelayedValue)+"\n" ).c_str());
                                // elapsed = std::chrono::high_resolution_clock::now() - start;
                                // long long microseconds = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
                                // platform_log( (std::to_string(microseconds)+" microseconds\n" ).c_str());
                                // isThreadRunning = false;

                                if (freshDelayedValue == 1){
                                    isSmartNeuronReady = 2;
                                }else{
                                    isSmartNeuronReady = 1;
                                }

                                // short iidx = 13;
                                // Node* tail = guidedDelayList[iidx].valueList.tail;
                                // for (short ii =0; ii < guidedDelayList[iidx].valueListSize; ii++) {
                                //     platform_log( ( std::to_string(tail->data)+" - " ).c_str()); 
                                //     tail = tail->prev;
                                // }
                                // platform_log( "\n"); 
                                // isThreadRunning = false;

                            }else
                            if (guidedDelayList[neuronIndex].mode == 2){
                                double freshDelayedValue = guidedDelayList[neuronIndex].pop_back();
                                freshDelayedValue;
                                double freshDelayedData = guidedDelayList[neuronIndex].pop_value_back();
                                arrFreshDelayedValue[neuronIndex] = freshDelayedData;

                                // platform_log( ("===Delay Neuron SPIKE Mode 0 : " + std::to_string(v[neuronIndex])+"\n" ).c_str());
                                if (guidedDelayList[neuronIndex].isSpiking){
                                    guidedDelayList[neuronIndex].mode = 3;
                                    isSmartNeuronReady = 10;
                                }else{
                                    isSmartNeuronReady = 1;
                                }
                            } else 
                            if (guidedDelayList[neuronIndex].mode == 1){
                                isSmartNeuronReady = 1;
                            }else{ // mode == 0
                                isSmartNeuronReady = 1;
                            }

                        }
                        // if (guidedDelayList[neuronIndex].isInhibited){
                        //     isSmartNeuronReady = -1;
                        // }
                        short srcNeuronType = mapNeuronType[neuronIndex];

                        if (srcNeuronType >= 1000) {
                            if ( v[neuronIndex] >= 30 ) {
                                // platform_log( ("NeuronSmart Spike : " + std::to_string(neuronIndex)+"\nSmartNeuron: "+ std::to_string(v[neuronIndex])+"\n" ).c_str());
                                inhibitionArray[neuronIndex] = 1;
                                isSpiking[neuronIndex] = 1;
                                isStepSpiking[neuronIndex] = 1;
                                spikingNow.push_back(neuronIndex);
                                spikes_step[neuronIndex][t] = 1;
                            }else{
                                isSpiking[neuronIndex] = 0;
                                isStepSpiking[neuronIndex] = 0;
                                spikes_step[neuronIndex][t] = 0;
                            }
                        }else                       
                        if (isSmartNeuronReady == 10){ // SMART NEURON mode =10 SPIKING
                            if (srcNeuronType >= configDelayNeuron && srcNeuronType <= configCountingNeuron){
                                isSpiking[neuronIndex] = 1;
                                isStepSpiking[neuronIndex] = 1;
                                spikingNow.push_back(neuronIndex);
                                spikes_step[neuronIndex][t] = 1;
                                guidedDelayList[neuronIndex].isSpiking = 1;
                            }                        
                        }else
                        if (isSmartNeuronReady == 1){ // SMART NEURON mode =0 OR mode =1


                        }else
                        if (isSmartNeuronReady == 2){
                        }else //NON SMART NEURON
                        if ( (v[neuronIndex] >= 30 && isSmartNeuronReady == 0) ) {
                            isSpiking[neuronIndex] = 1;
                            isStepSpiking[neuronIndex] = 1;
                            spikingNow.push_back(neuronIndex);
                            spikes_step[neuronIndex][t] = 1;
                        }
                    }

                    // insert old data in timeline
                    double *copyV = new double[threadTotalNumOfNeurons];
                    std::copy(v, v+threadTotalNumOfNeurons, copyV);
                    // Hijack displaying the default value while delaying it.
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++) {
                        if (guidedDelayList[idx].neuronType == configDelayNeuron){
                            if (guidedDelayList[idx].isWaiting == 3) {
                                copyV[idx] = arrFreshDelayedValue[idx];
                            } else {
                                copyV[idx] = c[idx] + randoms();
                            }
                        }
                    }
                    v_step.push_back(copyV);
                    
                    short numberOfSpikingNow = static_cast<short>(spikingNow.size());
                    // initialize v & u
                    for (short idx = 0; idx < numberOfSpikingNow; idx++){
                        int neuronIndex = spikingNow[idx];
                        //Reset spiking v to c
                        v[neuronIndex] = c[neuronIndex];
                        //Adjust spiking u to d
                        u[neuronIndex] = u[neuronIndex] + d[neuronIndex];
                    }

                    double *sumConnectome = new double[threadTotalNumOfNeurons]();
                    // Sum Connectome
                    
                    double *sumInhibition = new double[threadInitialTotalNumOfNeurons];
                    double *sumDelayedSignals = new double[threadInitialTotalNumOfNeurons];
                    for (short idx=0; idx < threadTotalNumOfNeurons ; idx++) {
                        sumInhibition[idx] = 0;
                        sumDelayedSignals[idx] = 0;
                    }                    
                    for (short idx=0; idx < threadTotalNumOfNeurons ; idx++) {
                        // if (inhibitionArray[j] > 0){
                        for ( short j=0; j < threadTotalNumOfNeurons ; j++ ) {
                            // short colIdx = j;
                            sumInhibition[idx] += (inhibitionArray[j] * connectome[j][idx]);
                            if (guidedDelayList[idx].neuronType == configDelayNeuron && arrFreshDelayedValue[idx]>=30){
                                if (connectome[idx][j] > 0){
                                    sumDelayedSignals[j] += connectome[idx][j];
                                }
                            }
                        }
                        inhibitionArray[idx] *= 0.994;
                        if (inhibitionArray[idx] <= 0.01) {
                            inhibitionArray[idx] = 0;
                        }
                    }
                    
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++){
                        if (isSpiking[idx] == 1){

                            short spikingNeuronIndex = idx;
                            bool isSourceInhibitor = false;
                            short srcNeuronType = mapNeuronType[spikingNeuronIndex];
                            // platform_log( ("Source inhibition type : " + std::to_string(srcNeuronType)+"\n" ).c_str());
                            if (srcNeuronType >= 1000){ // if spikingNeuron is inhibitor
                                isSourceInhibitor = true;
                                srcNeuronType %= 1000;
                                guidedDelayList[idx].isInhibited = true;
                            }

                            for ( short j=0; j < threadTotalNumOfNeurons ; j++ ){
                                if (connectome[spikingNeuronIndex][j] > 0){
                                    if (isSourceInhibitor) {
                                        guidedDelayList[j].isInhibited = true;
                                    }
                                    if (srcNeuronType<configDelayNeuron){
                                        sumConnectome[j] += (connectome[spikingNeuronIndex][j]);
                                    }
                                }
                                // the line above is saying add weight from a spiking neuron to target neuron 
                            }                        
                        }
                    }

                    // if isInhibited - it will reset everything before pushing anything
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++){
                        // tI[idx] += (sumConnectome[idx] + sumInhibition[idx]);
                        tI[idx] += (sumConnectome[idx] + sumInhibition[idx] + sumDelayedSignals[idx]);
                    }
                    delete[](sumConnectome);
                    delete[] sumInhibition;
                    delete[] sumDelayedSignals;

                    // VISUAL INPUT
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++){
                        tI[idx] += (vis_I[idx] + dist_I[idx]);
                    }

                    // update v & u
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                            if (guidedDelayList[neuronIndex].neuronType == configDelayNeuron){
                                // platform_log( ("targetNeuron Spikes2 : " + std::to_string(guidedDelayList[neuronIndex].isSpiking)+"\n" ).c_str());
                                /* 
                                    STATE :
                                    0. Buffer full, we still need to calculate the 
                                    1. if the delay neuron is spiking,
                                        start delaying
                                    2. if iswaiting == 3
                                */
                                if (guidedDelayList[neuronIndex].isWaiting < 3){
                                    // short idx = neuronIndex;
                                    // v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                    v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                    // Adjust for continuous time
                                    v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                }else
                                if (guidedDelayList[neuronIndex].isWaiting == 3){
                                    if (guidedDelayList[neuronIndex].isSpiking == 1000){
                                        v[neuronIndex] = 70; 
                                        u[neuronIndex] = b[neuronIndex] * v[neuronIndex];
                                    }else{
                                        // v[neuronIndex] = c[neuronIndex];
                                        if (isinf(v[neuronIndex])){
                                            v[neuronIndex] = c[neuronIndex];
                                            u[neuronIndex] = b[neuronIndex] * v[neuronIndex];
                                        }else
                                        if (v[neuronIndex] == v[neuronIndex]) {
                                            v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                            // Adjust for continuous time
                                            v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                        }else{
                                            v[neuronIndex] = c[neuronIndex];
                                            u[neuronIndex] = b[neuronIndex] * v[neuronIndex];
                                        }
                                    }
                                }
                            }else{
                                // Propagate v  
                                v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                // Adjust for continuous time
                                v[neuronIndex] = v[neuronIndex] + (0.5 * (0.04 * pow(v[neuronIndex],2) + 5 * v[neuronIndex] + 140 - u[neuronIndex] + tI[neuronIndex]));
                                //Update u
                            }

                            maxV[neuronIndex] = v[neuronIndex];
                            maxU[neuronIndex] = u[neuronIndex];
                        /*
                        }
                        */

                        u[neuronIndex] = u[neuronIndex] + a[neuronIndex] * (b[neuronIndex]*v[neuronIndex] - u[neuronIndex]);

                    }

                    // Process Smart Neuron
                    for (short idx = 0; idx < threadTotalNumOfNeurons; idx++){
                        if (guidedDelayList[idx].isInhibited && guidedDelayList[idx].neuronType == configDelayNeuron){
                            guidedDelayList[idx].processInhibition(true);// need to clear linkedlist reset timer
                            // previously we inject a value to be low --> to prevent spiking we still need to clear 
                        }else
                        if (guidedDelayList[idx].neuronType == configDelayNeuron){ //delay neuron
                            if (switchSkipDelay[idx] == -1) {
                                platform_log( ("List Size2xyz: "+ std::to_string(guidedDelayList[idx].listSize)+"\n" ).c_str());

                                switchSkipDelay[idx] = 40;
                                if (v[idx] >= 30){
                                    if (guidedDelayList[idx].mode > 0){
                                        v[idx] = c[idx];
                                        //Adjust spiking u to d
                                        u[idx] = u[idx] + d[idx];
                                    }
                                }else{
                                    guidedDelayList[idx].push_front(0);
                                    guidedDelayList[idx].push_value_front(v[idx]);                                    
                                }
                                
                                // START THREAD
                                short neuronIndex = idx;
                                if (guidedDelayList[neuronIndex].isWaiting == 0){
                                    guidedDelayList[neuronIndex].isWaiting = 1; // prepare to start the thread, 2-If it has invoked
                                    v[neuronIndex] = c[neuronIndex];
                                    u[neuronIndex]= b[neuronIndex] * v[neuronIndex];
                                }

                                if (guidedDelayList[neuronIndex].mode == 0 && guidedDelayList[neuronIndex].isWaiting == 1){
                                    guidedDelayList[neuronIndex].isWaiting = 2;
                                    guidedDelayList[neuronIndex].mode = 1;
                                    platform_log( ("START THREAD\n" ));
                                    guidedDelayList[neuronIndex].startDelayThread();
                                }                                
                                
                            }else
                            if (switchSkipDelay[idx] == 0) {
                                if (v[idx] >= 30){
                                    guidedDelayList[idx].isSpiking = 1;
                                    guidedDelayList[idx].push_front(1);
                                    guidedDelayList[idx].push_value_front(v[idx]);
                                    if (guidedDelayList[idx].mode == 2 || guidedDelayList[idx].mode == 3){
                                        v[idx] = c[idx];
                                        //Adjust spiking u to d
                                        u[idx] = u[idx] + d[idx];
                                    } else
                                    if (guidedDelayList[idx].mode > 0){
                                        v[idx] = c[idx];
                                        //Adjust spiking u to d
                                        u[idx] = u[idx] + d[idx];
                                    }
                                }else{
                                    guidedDelayList[idx].push_front(0);
                                    guidedDelayList[idx].push_value_front(v[idx]);
                                }
                            }else{
                                switchSkipDelay[idx]--;
                                if (v[idx] >= 30){
                                    v[idx] = c[idx];
                                    //Adjust spiking u to d
                                    u[idx] = u[idx] + d[idx];                                    
                                }else{
                                }
                            }
                        }
                    }
                }


                short startPos = static_cast<short>( (currentStep) * ms_per_step );

                for (short idx = 0; idx < static_cast<short>(epochs); idx++) {
                    for (short neuronIndex = 0; neuronIndex < threadTotalNumOfNeurons; neuronIndex++) {
                        v_traces[neuronIndex][startPos + idx] = (v_step[idx][neuronIndex]);
                    }
                    delete v_step[idx];
                }
                positions[0] = startPos + static_cast<short>(epochs);
                currentStep++;
                if (currentStep >= steps_per_loop){
                    currentStep = 0;            
                }

                if (isSelected){
                    if (idxSelected < threadTotalNumOfNeurons){
                        std::copy(&v_traces[idxSelected][0], &v_traces[idxSelected][0] + bigBufferLength, canvasBuffer);
                    }
                    // platform_log( ("VTRACES : " + std::to_string(isSelected)+"\n" ).c_str());

                }

                // UPDATE MOTORS

                for (short idx=0; idx<5; idx++){
                    motor_command[idx] = 0;
                }

                left_backward = 0;
                left_forward = 0;
                right_backward = 0;
                right_forward = 0;

                
                short speaker_connection_count = 0;
                short speaker_connection_sum = 0;
                short isRedLed = -1;
                short isGreenLed = -1;
                short isBlueLed = -1;
                short colorSum[4][3]= {{0}};
                short colorCount[4][3]= {{0}};
                std::string binaryString = "";
                short tempWeight = 0;
                std::string spikingMessage = "";
                for (short iStep = normalNeuronFirstIndex; iStep < threadTotalNumOfNeurons;iStep++){
                    short isNeuronSpiking = isStepSpiking[iStep];
                    short isDelayedSpiking = isNeuronSpiking;
                    if (guidedDelayList[iStep].neuronType == configDelayNeuron){
                        if (arrFreshDelayedValue[iStep] >= 30){
                            isDelayedSpiking = 1;
                            isNeuronSpiking = 1;
                        }
                    }
                    // neuronCircles[iStep] = isSpiking % 100;
                    // neuronCircles[iStep] = isNeuronSpiking;

                    spikingMessage = spikingMessage + std::to_string(isDelayedSpiking) + "|" ;
                    // platform_log( ("isSmartNeuronReady : " + std::to_string(isNeuronSpiking)+"\n" ).c_str());
                    if ( isNeuronSpiking == 1 ){
                        // short speaker_val = getSimulationMatrixValue(speaker_buf, ii, jj, (threadInitialTotalNumOfNeurons));
                        short speaker_val = getSimulationMatrixValue(speaker_buf, iStep, neuronSpeakerIdx, (threadInitialTotalNumOfNeurons));
                        if (speaker_val > -1){
                            speaker_connection_sum += speaker_val;
                            speaker_connection_count++;
                        }

                        isRedLed = getSimulationMatrixValue(led_pos_buf, iStep, neuronLedRedIdx, (threadInitialTotalNumOfNeurons));
                        if (isRedLed > -1){ // red
                            binaryString = decimalToBinaryString(isRedLed);
                            if (binaryString[0] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedRedIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[0][0] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[0][0]++;
                            }
                            if (binaryString[1] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedRedIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[1][0] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[1][0]++;
                            }
                            if (binaryString[2] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedRedIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[2][0] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[2][0]++;
                            }
                            if (binaryString[3] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedRedIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[3][0] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[3][0]++;
                            }
                        }

                        isGreenLed= getSimulationMatrixValue(led_pos_buf, iStep, neuronLedGreenIdx, (threadInitialTotalNumOfNeurons));
                        if (isGreenLed > -1 ) { // green
                            binaryString = decimalToBinaryString(isGreenLed);
                            if (binaryString[0] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedGreenIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[0][1] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[0][1]++;
                            }
                            if (binaryString[1] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedGreenIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[1][1] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[1][1]++;
                            }
                            if (binaryString[2] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedGreenIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[2][1] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[2][1]++;
                            }
                            if (binaryString[3] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedGreenIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[3][1] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[3][1]++;
                            }

                        }

                        isBlueLed = getSimulationMatrixValue(led_pos_buf, iStep, neuronLedBlueIdx, (threadInitialTotalNumOfNeurons));
                        if (isBlueLed > -1 ) {
                            binaryString = decimalToBinaryString(isBlueLed);
                            // platform_log("there is blue \n");
                            // platform_log(binaryString.c_str());
                            // platform_log("\n");
                            if (binaryString[0] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedBlueIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[0][2] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[0][2]++;
                            }
                            if (binaryString[1] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedBlueIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[1][2] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[1][2]++;
                            }
                            if (binaryString[2] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedBlueIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[2][2] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[2][2]++;
                            }
                            if (binaryString[3] == '1'){
                                tempWeight = getSimulationMatrixValue(led_buf, iStep, neuronLedBlueIdx, (threadInitialTotalNumOfNeurons));
                                colorSum[3][2] += static_cast<short>(floor(tempWeight * 255 / 100));
                                colorCount[3][2]++;
                            }
                        }

                        left_forward += ( getSimulationMatrixValue( neuron_contacts, iStep, 6, threadTotalNumOfNeurons));
                        left_backward += ( getSimulationMatrixValue( neuron_contacts, iStep, 4, threadTotalNumOfNeurons));

                        right_forward += ( getSimulationMatrixValue( neuron_contacts, iStep, 3, threadTotalNumOfNeurons));
                        right_backward += ( getSimulationMatrixValue( neuron_contacts, iStep, 5, threadTotalNumOfNeurons));

                    }
                }
                if (!spikingMessage.empty()) {
                    spikingMessage = spikingMessage.substr(0, spikingMessage.size()-1);
                    spikingMessage = "n:" + spikingMessage + ";";

                }

                // scale
                left_forward *= 2.5;
                right_forward *= 2.5;
                left_backward *= 2.5;
                right_backward *= 2.5;

                left_torque = static_cast<int>(left_forward - left_backward);
                left_torque_mem = left_torque;
                left_dir = 0;

                short sign = 0;
                if (left_torque == 0) {
                    sign = 0;
                    left_dir = 1;
                }else
                if (left_torque > 0) {
                    sign = 1;
                    left_dir = 1;
                } else {
                    sign = -1;
                    left_dir = 2;
                }                

                left_torque = std::abs(left_torque); // pin 15
                // if (left_torque > 250) left_torque = 250;
                // else                
                // if (left_torque < -250) left_torque = -250;
                if (left_torque > 500) left_torque = 500;
                else                
                if (left_torque < -500) left_torque = -500;
                // left_torque(left_torque > 250) = 250;
                motor_command[2] = left_torque;
                motor_command[3] = left_dir;
                
                right_torque = static_cast<int>(right_forward - right_backward);
                right_torque_mem = right_torque;
                right_dir = 0;
                if (right_torque == 0) {
                    sign = 0;
                    right_dir = 1;
                }else
                if (right_torque > 0) {
                    sign = 1;
                    right_dir = 1;
                } else {
                    sign = -1;
                    right_dir = 2;

                }
                // right_dir = std::max(1 - sign *(right_torque), 1);
                right_torque = std::abs(right_torque); // pin 14
                if (right_torque > 500) right_torque = 500;
                else
                if (right_torque < -500) right_torque = -500;
                motor_command[0] = right_torque;
                motor_command[1] = right_dir;
                // platform_log("std::to_string(right_torque).c_str()");
                // platform_log(std::to_string(right_torque).c_str());

                if ( (currentStep * pulse_period) < init_motor_block_in_s ){
                    motor_command[0] = 0;
                    motor_command[1] = 0;
                    motor_command[2] = 0;
                    motor_command[3] = 0;
                    motor_command[4] = 1000;
                }
                motor_command[5] = motorCounter;
                motorCounter++;
                motorCounter %= 100;



                // // String message = "l:${l_torque * l_dir};r:${r_torque * r_dir};";
                r_torque = static_cast<int>(motor_command[0]);
                r_dir = static_cast<int>(motor_command[1]);
                if (r_dir == 2) {
                //     r_dir = 1;
                // }else{
                    r_dir = -1;
                }

                l_torque = static_cast<int>(motor_command[2]);
                l_dir = static_cast<int>(motor_command[3]);
                if (l_dir == 2) {
                //     l_dir = 1;
                // }else{
                    l_dir = -1;

                }
                
                int speaker_tone = 0;
                if (speaker_connection_count > 0){
                    speaker_tone = (speaker_connection_sum / speaker_connection_count);
                }
                // short speaker_tone = 0;
                // SPIKING MESSAGE IS NEEDED TO BLINK NEURON
                message = "l:" + std::to_string(l_torque * l_dir) + ";r:" + std::to_string(r_torque * r_dir) + ";s:" + std::to_string(speaker_tone) + ";" + spikingMessage;

                // if not spiking turn off
                if (isRedLed == -1 && isGreenLed == -1 && isBlueLed == -1){
                    message += offLEDCmd;
                }else{
                    std::string colorMsg = "";
                    int red = 0;
                    int green = 0;
                    int blue = 0;
                    int redCount = 0;
                    int greenCount = 0;
                    int blueCount = 0;
                    for (int ledIdx = 0; ledIdx < 4; ledIdx++){
                        redCount = colorCount[ledIdx][0];
                        greenCount = colorCount[ledIdx][1];
                        blueCount = colorCount[ledIdx][2];
                        if (redCount == 0) {
                            redCount = 1;
                        }
                        if (greenCount == 0) {
                            greenCount = 1;
                        }
                        if (blueCount == 0) {
                            blueCount = 1;
                        }
                        red = static_cast<short>(floor(colorSum[ledIdx][0] / redCount));
                        green = static_cast<short>(floor(colorSum[ledIdx][1] / greenCount));
                        blue = static_cast<short>(floor(colorSum[ledIdx][2] / blueCount));
                        if (red> 255) red = 255;
                        if (green> 255) green = 255;
                        if (blue> 255) blue = 255;

                        if (red< 0) red = 0;
                        if (green< 0) green = 0;
                        if (blue < 0) blue = 0;

                        colorMsg += "d:" + std::to_string(ledIdx) + "," + std::to_string(red) + "," + std::to_string(green) + "," + std::to_string(blue)+";";
                    }
                    message += colorMsg;
                }



                #ifdef __EMSCRIPTEN__
                    std::fill(motor_command_message, motor_command_message + 300, 0);
                    for (std::size_t i = 0; i < message.length(); ++i) {
                        motor_command_message[i] = static_cast<uint8_t>(message[i]);
                    }
                    state_buf[4]= message.length();
                    char *cstr = new char[message.length() + 1];
                    strcpy(cstr, message.c_str());                

                    EM_ASM({
                        updateMotorCommand($0, UTF8ToString($1), $2, $3);
                    // }, state_buf, motor_command_message, state_buf[4]);
                    }, state_buf, cstr, state_buf[4], motor_command_message);
                #else
                    // if ( (l_torque * l_dir) != 0 || (r_torque * r_dir) != 0){
                    // if (prevMessage != message){
                        prevMessage = message;
                        // platform_log( "Spiking message : \n");
                        // platform_log( prevMessage.c_str() );
                        // platform_log( "\n");

                        // platform_log("COLORMSG\n");
                        // platform_log(message.c_str());
                        // platform_log("\n");
                        onCallback(prevMessage.c_str());
                    // }

                    // }

                #endif                        

                delete[] isSpiking;
                delete[] isStepSpiking;
                delete[] tI;
                delete[] arrFreshDelayedValue;
            }
            if (!isThreadRunning){
                delete[] (v);
                delete[] (u);

                for (short iStep = 0; iStep < threadInitialTotalNumOfNeurons; iStep++){
                    delete[] spikes_step[iStep];
                    delete[] (connectome[iStep]);
                    // delete[] (neuron_contacts[i]);
                }
                delete[] spikes_step;
                delete[] connectome;

                for (int32_t idx=0; idx <threadInitialTotalNumOfNeurons; idx++){
                    delete[] (v_traces[idx]);
                }
                delete[] v_traces;
                delete[] vis_I;
                delete[] dist_I;

                // for (int32_t idx=0; idx <threadInitialTotalNumOfNeurons; idx++){
                //     delayLinkedList[idx].clear();
                //     delayValueLinkedList[idx].clear();
                // }

                // delete[] delayLinkedList;
                // delete[] delayValueLinkedList;

                for (int32_t idx=0; idx <threadInitialTotalNumOfNeurons; idx++){
                    guidedDelayList[idx].clearAll();
                }

                // delete[] guidedDelayList;

                #ifdef __EMSCRIPTEN__
                    std::terminate();
                #endif
            }

        });        

        simulatorThread.detach();

        isThreadRunning = true;

    }
    return flagcounter;
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
// #endif
