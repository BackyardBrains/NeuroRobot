#include <emscripten/bind.h>
using namespace emscripten;

#ifndef SPIKE_RECORDER_ANDROID_NOTCHFILTER
#define SPIKE_RECORDER_ANDROID_NOTCHFILTER
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

class NotchFilter : public FilterBase {
public:
    // NotchFilter(){}; 
    NotchFilter() = default;

    void calculateCoefficients() {
        if ((centerFrequency != 0.0f) && (Q != 0.0f)) {
            intermediateVariables(centerFrequency, Q);

            a0 = (1 + alpha);
            b0 = 1 / a0;
            b1 = (-2 * omegaC) / a0;
            b2 = 1 / a0;
            a1 = (-2 * omegaC) / a0;
            a2 = (1 - alpha) / a0;
            setCoefficients();
        }
    }

    void setCenterFrequency(double newCenterFrequency) {
        centerFrequency = newCenterFrequency;
        calculateCoefficients();
    }

    void setQ(double newQ) {
        Q = newQ;
        calculateCoefficients();
    }
    double centerFrequency = 0;
    double Q = 0;

protected:
private:
};

// 
NotchFilter NotchFilters50[6];
NotchFilter NotchFilters60[6];
int isNotch50 = 0;
int isNotch60 = 0;
EXTERNC FUNCTION_ATTRIBUTE double setNotch(int16_t _isNotch50, int16_t _isNotch60){
    isNotch50 = _isNotch50;
    isNotch60 = _isNotch60;
    return 1;
}


EXTERNC FUNCTION_ATTRIBUTE double createNotchPassFilter(int16_t _isNotch50, int16_t channelCount, double sampleRate, double cutOff, double q){
    // NotchFilters = new NotchFilter[channelCount];
    // int sum = 0;
    for( int i = 0; i < channelCount; i++ )
    {
        if (_isNotch50 == 1){
            NotchFilters50[i] = NotchFilter();
            // NotchFilter NotchFilter = NotchFilters[i];
            NotchFilters50[i].initWithSamplingRate(sampleRate);
            if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
            NotchFilters50[i].setCenterFrequency(cutOff);
            NotchFilters50[i].setQ(q);

        }else{
            NotchFilters60[i] = NotchFilter();
            // NotchFilter NotchFilter = NotchFilters[i];
            NotchFilters60[i].initWithSamplingRate(sampleRate);
            if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
            NotchFilters60[i].setCenterFrequency(cutOff);
            NotchFilters60[i].setQ(q);
        }
        // NotchFilter NotchFilter = NotchFilter();
    }
    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double initNotchPassFilter(int16_t _isNotch50, int16_t channelCount, double sampleRate, double cutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // NotchFilter NotchFilter = NotchFilters[i];
        if (_isNotch50 == 1){

            NotchFilters50[i].initWithSamplingRate(sampleRate);
            if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
            NotchFilters50[i].setCenterFrequency(cutOff);
            NotchFilters50[i].setQ(q);
        }else{
            NotchFilters60[i].initWithSamplingRate(sampleRate);
            if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
            NotchFilters60[i].setCenterFrequency(cutOff);
            NotchFilters60[i].setQ(q);
        }
    }
    return NotchFilters50[0].omega;
}

EXTERNC FUNCTION_ATTRIBUTE auto applyNotchPassFilter(int16_t _isNotch50, int16_t channelIdx, const val &data, int32_t sampleCount){
    if (_isNotch50 == 1){
        if (NotchFilters50[channelIdx].omega != 0){
            std::vector<short> raw = convertJSArrayToNumberVector<short>(data); 
            if (NotchFilters50[channelIdx].omega != 0){
                NotchFilters50[channelIdx].filter(raw.data(), sampleCount, false);
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

            // NotchFilters50[channelIdx].filter(data, sampleCount, false);
        }else{
            // return -1;
            auto result = val::global("Int16Array").new_(1);
            return result;

            // return NotchFilters50[channelIdx].omega;
        }
    }else{
        if (NotchFilters60[channelIdx].omega != 0){
            std::vector<short> raw = convertJSArrayToNumberVector<short>(data); 
            if (NotchFilters60[channelIdx].omega != 0){
                NotchFilters60[channelIdx].filter(raw.data(), sampleCount, false);
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

            // NotchFilters60[channelIdx].filter(data, sampleCount, false);
        }else{
            // return -1;
            // return NotchFilters60[channelIdx].omega;
            auto result = val::global("Int16Array").new_(1);
            return result;

        }

    }
    auto result = val::global("Int16Array").new_(1);
    return result;
}

#endif

EMSCRIPTEN_BINDINGS(my_module) {
  class_<NotchFilter>("NotchFilter")
    .constructor()
    .function("calculateCoefficients", &NotchFilter::calculateCoefficients)
    .function("setCenterFrequency", &NotchFilter::setCenterFrequency)
    .function("setQ", &NotchFilter::setQ)
    ;
    function("createNotchPassFilter", &createNotchPassFilter);
    function("initNotchPassFilter", &initNotchPassFilter);
    function("applyNotchPassFilter", &applyNotchPassFilter);
    // register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}