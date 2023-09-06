//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//

// #include <FilterBase.h>
#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif

#ifndef SPIKE_RECORDER_ANDROID_FILTERBASE
#define SPIKE_RECORDER_ANDROID_FILTERBASE


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


class FilterBase {
public:
  int val;

    // FilterBase(){
    // }
    FilterBase() = default;

    double getSamplingRate(){
        return samplingRate;
    }

    void initWithSamplingRate(double sr) {
        samplingRate = sr;
        // omega = 0;
        // omegaS = 0;
        // omegaC = 0;
        // alpha = 0;
        // gInputKeepBuffer[0]=0;
        // gInputKeepBuffer[1]=0;
        // gOutputKeepBuffer[0]=0;
        // gOutputKeepBuffer[1]=0;
    // double gInputKeepBuffer[2];
    // double gOutputKeepBuffer[2];
    // double omega, omegaS, omegaC, alpha;
    // double coefficients[5];
    // double a0, a1, a2, b0, b1, b2;

        for (double &coefficient : coefficients) {
            coefficient = 0.0f;
        }

        gInputKeepBuffer[0] = 0.0f;
        gInputKeepBuffer[1] = 0.0f;
        gOutputKeepBuffer[0] = 0.0f;
        gOutputKeepBuffer[1] = 0.0f;

        one = 1.0f;
    }

    void setCoefficients() {
        coefficients[0] = b0;
        coefficients[1] = b1;
        coefficients[2] = b2;
        coefficients[3] = a1;
        coefficients[4] = a2;
    }
    void filter(int16_t *data, int32_t numFrames, bool flush) {
        auto *tempdoubleBuffer = (double *) std::malloc(numFrames * sizeof(double));
        for (int32_t i = numFrames - 1; i >= 0; i--) {
            tempdoubleBuffer[i] = (double) data[i];
        }
        filterContiguousData(tempdoubleBuffer, numFrames);
        if (flush) {
            for (int32_t i = numFrames - 1; i >= 0; i--) {
                data[i] = 0;
            }
        } else {
            for (int32_t i = numFrames - 1; i >= 0; i--) {
                data[i] = (int16_t) tempdoubleBuffer[i];
            }
        }
        free(tempdoubleBuffer);
    }

    void filterContiguousData(double *data, int32_t numFrames) {
        // Provide buffer for processing
        auto *tInputBuffer = (double *) std::malloc((numFrames + 2) * sizeof(double));
        auto *tOutputBuffer = (double *) std::malloc((numFrames + 2) * sizeof(double));

        // Copy the data
        memcpy(tInputBuffer, gInputKeepBuffer, 2 * sizeof(double));
        memcpy(tOutputBuffer, gOutputKeepBuffer, 2 * sizeof(double));
        memcpy(&(tInputBuffer[2]), data, numFrames * sizeof(double));

        // Do the processing
        // vDSP_deq22(tInputBuffer, 1, coefficients, tOutputBuffer, 1, numFrames);
        //https://developer.apple.com/library/ios/documentation/Accelerate/Reference/vDSPRef/index.html#//apple_ref/c/func/vDSP_deq22
        int n;
        for (n = 2; n < numFrames + 2; n++) {
            tOutputBuffer[n] = tInputBuffer[n] * coefficients[0] + tInputBuffer[n - 1] * coefficients[1] +
                                tInputBuffer[n - 2] * coefficients[2] - tOutputBuffer[n - 1] * coefficients[3] -
                                tOutputBuffer[n - 2] * coefficients[4];
        }

        // Copy the data
        memcpy(data, tOutputBuffer, numFrames * sizeof(double));
        memcpy(gInputKeepBuffer, &(tInputBuffer[numFrames]), 2 * sizeof(double));
        memcpy(gOutputKeepBuffer, &(tOutputBuffer[numFrames]), 2 * sizeof(double));

        free(tInputBuffer);
        free(tOutputBuffer);
    }
    void intermediateVariables(double Fc, double Q) {
        omega = 2 * M_PI * Fc / samplingRate;
        omegaS = sin(omega);
        omegaC = cos(omega);
        alpha = omegaS / (2 * Q);
    }

    double one;
    double samplingRate;
    double gInputKeepBuffer[2];
    double gOutputKeepBuffer[2];
    double omega, omegaS, omegaC, alpha;
    double coefficients[5];
    double a0, a1, a2, b0, b1, b2;

protected:

private:  
};






// EXTERNC double createFilters(){
//     return 30;
// }
#endif