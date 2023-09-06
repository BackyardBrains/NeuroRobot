#include <emscripten/bind.h>
using namespace emscripten;

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
#include <stdint.h>

#include <iostream>
#include <array>
#include <functional>
#include <vector>

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
    return lowPassFilters[0].getSamplingRate();
    // return 1;
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

EXTERNC FUNCTION_ATTRIBUTE auto applyLowPassFilter(int16_t channelIdx, const val &data, int32_t sampleCount){
    std::vector<short> raw = convertJSArrayToNumberVector<short>(data); 
    if (lowPassFilters[channelIdx].omega != 0){
        lowPassFilters[channelIdx].filter(raw.data(), sampleCount, false);
        // std::vector<short> output(raw.size());
        val view{ typed_memory_view(raw.size(), raw.data()) };
        auto result = val::global("Int16Array").new_(raw.size());
        result.call<void>("set", view);

        return result;
    }else{
        val view{ typed_memory_view(raw.size(), raw.data()) };
        auto result = val::global("Int16Array").new_(raw.size());
        result.call<void>("set", view);

        return result;
        // return lowPassFilters[channelIdx].omega;
        // return data;
    }

    // // auto x = reinterpret_cast<short*>( data["ptr"].as<short>() );
    // // std::vector<short> nums(x, x + sampleCount);
    // std::vector<short> rv;

    // const auto l = data["length"].as<unsigned>();
    // rv.resize(l);

    // emscripten::val memoryView{emscripten::typed_memory_view(l, rv.data())};
    // memoryView.call<void>("set", data);

    // if (lowPassFilters[channelIdx].omega != 0){
    //     // std::vector<short> vec = vecFromJSArray<short>(data);
    //     lowPassFilters[channelIdx].filter(rv.data(), sampleCount, false);

    //     return rv;
    // }else{
    //     return rv;
    //     // return lowPassFilters[channelIdx].omega;
    //     // return data;
    // }
}
// // EXTERNC FUNCTION_ATTRIBUTE 
// template<typename T> std::vector<T> applyLowPassFilter(int16_t channelIdx,const val& data, int32_t sampleCount){
//     std::vector<T> vec = vecFromJSArray<T>(data);
//     if (lowPassFilters[channelIdx].omega != 0){
//         lowPassFilters[channelIdx].filter(vec.data(), sampleCount, false);
//         return vec;
//     }else{
//         return vec;
//     }

//     return vec;    
// }


// EXTERNC double createFilters(){
//     return 30;
// }
#endif

EMSCRIPTEN_BINDINGS(my_module) {
  class_<LowPassFilter>("LowPassFilter")
    .constructor()
    .function("calculateCoefficients", &LowPassFilter::calculateCoefficients)
    .function("setCornerFrequency", &LowPassFilter::setCornerFrequency)
    .function("setQ", &LowPassFilter::setQ)
    ;
    function("createLowPassFilter", &createLowPassFilter);
    function("initLowPassFilter", &initLowPassFilter);
    function("applyLowPassFilter", &applyLowPassFilter);
    register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}