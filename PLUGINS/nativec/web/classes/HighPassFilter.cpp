#include <emscripten/bind.h>
using namespace emscripten;

//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//
#ifndef SPIKE_RECORDER_ANDROID_HIGHPASSFILTER
#define SPIKE_RECORDER_ANDROID_HIGHPASSFILTER

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


class HighPassFilter : public FilterBase {
public:
    // LowPassFilter(){};
    HighPassFilter() = default;
    void calculateCoefficients() {
        if ((cornerFrequency != 0.0f) && (Q != 0.0f)) {
            intermediateVariables(cornerFrequency, Q);


            a0 = 1 + alpha;
            b0 = ((1 + omegaC) / 2) / a0;
            b1 = (-1 * (1 + omegaC)) / a0;
            b2 = ((1 + omegaC) / 2) / a0;
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
protected:
    double cornerFrequency;
    double Q;
private:
};

// HighPassFilter* highPassFilters;
HighPassFilter highPassFilters[6];
EXTERNC FUNCTION_ATTRIBUTE double createHighPassFilter(short channelCount, double sampleRate, double highCutOff, double q){
    // highPassFilters = new HighPassFilter[channelCount];
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // HighPassFilter highPassFilter = HighPassFilter();
        highPassFilters[i].initWithSamplingRate(sampleRate);
        if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        highPassFilters[i].setCornerFrequency(highCutOff);
        highPassFilters[i].setQ(q);
        // highPassFilters[i] = highPassFilter;
    }
    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double initHighPassFilter(short channelCount, double sampleRate, double highCutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // HighPassFilter highPassFilter = highPassFilters[i];
        highPassFilters[i].initWithSamplingRate(sampleRate);
        if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        highPassFilters[i].setCornerFrequency(highCutOff);
        highPassFilters[i].setQ(q);
    }
    return 1;
}


EXTERNC FUNCTION_ATTRIBUTE auto applyHighPassFilter(int16_t channelIdx, const val &data, int32_t sampleCount){
    std::vector<short> raw = convertJSArrayToNumberVector<short>(data); 
    if (highPassFilters[channelIdx].omega != 0){
        highPassFilters[channelIdx].filter(raw.data(), sampleCount, false);
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
    }
}
#endif


EMSCRIPTEN_BINDINGS(my_module) {
  class_<HighPassFilter>("HighPassFilter")
    .constructor()
    .function("calculateCoefficients", &HighPassFilter::calculateCoefficients)
    .function("setCornerFrequency", &HighPassFilter::setCornerFrequency)
    .function("setQ", &HighPassFilter::setQ)
    ;
    function("createHighPassFilter", &createHighPassFilter);
    function("initHighPassFilter", &initHighPassFilter);
    function("applyHighPassFilter", &applyHighPassFilter);
    // register_vector<short>("HighPassList");

}