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

bool isThreadRunning = true;
short ms_per_step = 30;
short steps_per_loop = 200;

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
short vis_prefs_count = 7;
const short ncam = 2;
// std::vector<std::vector<int>> vis_pref_vals(vis_pref_count, std::vector<int>(ncam));
short *visPrefs;
double *vis_pref_vals;
// double **temp_vis_pref_vals;
double *vis_I;
short frameSize = 130;
short frameSizeWidth = 260;
short frameSizeHeight = 240;

// std::vector<int> vis_I(1,0);
// short *firing = new short[totalNumOfNeurons];
short** spikes_step;
short *firing;


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
short *dist_I;
short *dist_prefs;


double dist_short = 0;
double dist_medium = 0;
double dist_long = 0;

double sensor_distance = 0;
