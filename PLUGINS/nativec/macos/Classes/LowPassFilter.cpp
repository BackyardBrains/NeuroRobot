//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//
#ifndef SPIKE_RECORDER_ANDROID_LOWPASSFILTER
#define SPIKE_RECORDER_ANDROID_LOWPASSFILTER
// https://www.howtogeek.com/297721/how-to-create-and-use-symbolic-links-aka-symlinks-on-a-mac/
#include "FilterBase.cpp"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include<stdint.h>

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

class LowPassFilter : public FilterBase {
public:
    // LowPassFilter(){};
    LowPassFilter() = default;
    double myCreateLowPassFilter(int16_t channelCount, double sampleRate, double cutOff, double q){
        return 1;
    }

    void calculateCoefficients() {
        if ((cornerFrequency != 0.0f) && (Q != 0.0f)) {
            intermediateVariables(cornerFrequency, Q);


            a0 = 1 + alpha;
            b0 = ((1 - omegaC) / 2) / a0;
            b1 = ((1 - omegaC)) / a0;
            b2 = ((1 - omegaC) / 2) / a0;
            a1 = (-2 * omegaC) / a0;
            a2 = (1 - alpha) / a0;

            setCoefficients();
        }
    }

    void setCornerFrequency(double newCornerFrequency) {
        cornerFrequency = newCornerFrequency;
        calculateCoefficients();
    }

    void setQ(double newQ) {
        Q = newQ;
        calculateCoefficients();
    }
    double cornerFrequency = 0;
    double Q = 0;

protected:
private:
};

int logIdx = -1;
// 
// LowPassFilter* lowPassFilters;
LowPassFilter lowPassFilters[6];

EXTERNC FUNCTION_ATTRIBUTE double createLowPassFilter(int16_t channelCount, double sampleRate, double cutOff, double q){
    // lowPassFilters = new LowPassFilter[channelCount];
    // int sum = 0;
    for( int i = 0; i < channelCount; i++ )
    {
        // LowPassFilter lowPassFilter = LowPassFilter();
        lowPassFilters[i] = LowPassFilter();
        // LowPassFilter lowPassFilter = lowPassFilters[i];
        lowPassFilters[i].initWithSamplingRate(sampleRate);
        if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
        lowPassFilters[i].setCornerFrequency(cutOff);
        lowPassFilters[i].setQ(q);
        
        // lowPassFilters[i] = lowPassFilter;
    }
    // return lowPassFilters[0].cornerFrequency;
    return 1;
    // return 2 * M_PI * cutOff / sampleRate;
    // return q;
}

EXTERNC FUNCTION_ATTRIBUTE double initLowPassFilter(int16_t channelCount, double sampleRate, double cutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // LowPassFilter lowPassFilter = lowPassFilters[i];
        lowPassFilters[i].initWithSamplingRate(sampleRate);
        if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
        lowPassFilters[i].setCornerFrequency(cutOff);
        lowPassFilters[i].setQ(q);
    }
    return lowPassFilters[0].omega;
}

EXTERNC FUNCTION_ATTRIBUTE double applyLowPassFilter(int16_t channelIdx, int16_t *data, int32_t sampleCount){
    if (lowPassFilters[channelIdx].omega != 0){
        lowPassFilters[channelIdx].filter(data, sampleCount, false);
    }else{
        // return -1;
        return lowPassFilters[channelIdx].omega;
    }
    
    // return -1.0;
    // for( int i = 0; i < sampleCount; ++i )
    // {
    //     data[i] = -3000;
    // }
    // logIdx++;
    // // return logIdx;
    // if (logIdx == 0){
    //     // return lowPassFilters[channelIdx].coefficients[0];
    //     return -1;
    // }else
    // if (logIdx == 1){
    //     // return lowPassFilters[channelIdx].coefficients[1];
    //     return -1;
    // }else
    // if (logIdx == 2){
    //     // return lowPassFilters[channelIdx].coefficients[2];
    //     return -1;
    // }else
    // if (logIdx == 3){    
    //     // return lowPassFilters[channelIdx].coefficients[3];
    //     return -1;
    // }else
    // if (logIdx == 4){   
    //     // return lowPassFilters[channelIdx].omega;
    //     return -1;
    // }else
    // if (logIdx == 5){
    //     // return lowPassFilters[channelIdx].omegaS;
    //     return -100000000;
    // }else
    // if (logIdx == 6){
    //     return lowPassFilters[channelIdx].gOutputKeepBuffer[0];
    //     // return lowPassFilters[channelIdx].omegaC;
    // }else
    // if (logIdx == 7){
    //     return lowPassFilters[channelIdx].gOutputKeepBuffer[1];
    //     // return lowPassFilters[channelIdx].alpha;
    // }else
    // if (logIdx == 8){
    //     return lowPassFilters[channelIdx].gInputKeepBuffer[0];
    // }else
    // if (logIdx == 9){
    //     logIdx = -1;
    //     return lowPassFilters[channelIdx].gInputKeepBuffer[1];
    // }
    return -1;


}


// EXTERNC double createFilters(){
//     return 30;
// }
#endif
