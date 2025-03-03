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

#endif         

// void platform_log(const char *fmt, ...);

// MAIN CODE
// std::mutex mtx;
short configDelayNeuron = 6;
short configCountingNeuron = 10;
int totalNeuron = 0;
short normalNeuronFirstIndex = 13;
bool isThreadRunning = true;
short ms_per_step = 1;
short steps_per_loop = 10.5 * 200;

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
double *inhibitionArray;
int *nps;

// double **v_step;
short intended_timer_period;
int epochs;

short prevFlagSpiking = 0;
short isThreadCreated=-1;
// a = 0.02;
// b = 0.18;
// c = -65;
// d = 2;
// i = 5;
// w = 2;
double i_rand = 5;

// WASM
int *state_buf;
uint8_t *motor_command_message;


// OPENCV
// short vis_prefs_count = 7;
short vis_prefs_count = 22;
const short ncam = 2;
// std::vector<std::vector<int>> vis_pref_vals(vis_pref_count, std::vector<int>(ncam));
short *visPrefs;
double *vis_pref_vals;
// double **temp_vis_pref_vals;
double *vis_I;
short frameSize = 130;
short frameSizeWidth = 320;
short frameSizeHeight = 240;

// std::vector<int> vis_I(1,0);
// short *firing = new short[totalNumOfNeurons];
short** spikes_step;
short *firing;


// DELAY BUFFER
short delayInitialized = 1;
short delayTriggered = 2;
short delayBuffering = 3;
short delayFullBuffer = 4;

short delayModeNoSpike = 1;
short delayModeAccumulatingSpike = 2;
short delayModeTurnOffTimer = 3;

// MOTOR
double pulse_period = 0.1;
short init_motor_block_in_s = 1;
double *neuron_contacts;
double *motor_command;
// from neuron to sensory neuron
//neuron_contacts = zeros(nneurons, ncontacts);
// neuron_contacts = zeros(nneurons, ncontacts);
double sumVisPrefVals = 0;
short motorCounter = 0;
// CALLBACK
std::string message;
void (*onCallback)(const char*);


// DISTANCE
double *dist_I;
short *dist_prefs;


double dist_short = 50;
double dist_medium = 70;
double dist_long = 90;

double *sensor_distance;
short *sensor_min_limit;
short *sensor_max_limit;


// SPEAKER 
short *speaker_buf;
short neuronSpeakerIdx = 8;
// MICROPHONE
short *microphone_buf;

// LED
short *led_buf;
short *led_pos_buf;
short neuronLedRedIdx = 10;
short neuronLedGreenIdx = 11;
short neuronLedBlueIdx = 12;


double *visual_input_buf;
// std::string redLEDCmd = "d:111;d:211;d:311;d:411;d:511;d:611;"; // red
// std::string blueLEDCmd = "d:131;d:231;d:331;d:431;d:531;d:631;"; // blue
// std::string greenLEDCmd = "d:121;d:221;d:321;d:421;d:521;d:621;"; // green
// std::string offLEDCmd = "d:120;d:220;d:320;d:420;d:520;d:620;"; // off

// std::string redLEDCmd = "d:111;d:211;d:311;d:411;"; // red
// std::string blueLEDCmd = "d:131;d:231;d:331;d:431;"; // blue
// std::string greenLEDCmd = "d:121;d:221;d:321;d:421;"; // green
// std::string offLEDCmd = "d:120;d:220;d:320;d:420;"; // off

std::string redLEDCmd = "d:0,255,0,0;d:1,255,0,0;d:2,255,0,0;d:3,255,0,0;"; // red
std::string blueLEDCmd ="d:0,0,0,255;d:1,0,0,255;d:2,0,0,255;d:3,0,0,255;"; // blue
std::string greenLEDCmd ="d:0,0,255,0;d:1,0,255,0;d:2,0,255,0;d:3,0,255,0;"; // green
std::string offLEDCmd = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;"; // off

std::string prevMessage = "";


// CUSTOM NEURON TYPES
short* mapNeuronType;

short* mapDelayNeuron;
short* mapRhytmicNeuron;
short* mapCountingNeuron;
// short** mapAdditionalNeuronTypes;

short* isNeuronInhibitor;

double* decayMultipliers;
short countingTimeTrigger = 500;
// The rate of this decay determines how long the target neuron remains inhibited.

// std::chrono::milliseconds* neuronDelayTime;
long long* neuronDelayTime;
long long* neuronRhytmicTime;
long long* neuronCountingTime;


double* maxV;
double* maxU;

