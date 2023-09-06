#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
// #include "GainFilter.h"

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


// EXTERNC typedef struct {
//     const char* info;
// } MyStruct;

// EXTERNC MyStruct CreateStruct() {
//     // MyStruct test = new MyStruct();
//     // MyStruct.info = "Hello Dart!";
//     // return MyStruct;
//     // return {.info = "Hello Dart!"};

//     MyStruct test ={
//         // info: "Hello FFI"
//     };
//     return test;
// }

// EXTERNC FUNCTION_ATTRIBUTE const char* GetInfo(MyStruct* s) {
//     return s->info;
// }


double result;
EXTERNC FUNCTION_ATTRIBUTE double GainFilter(double sample, double multiplier){
    result = sample * multiplier;
    return result;
}

EXTERNC FUNCTION_ATTRIBUTE double ReturnGainFilter(double sample){
    return result * 80;
}


EXTERNC FUNCTION_ATTRIBUTE double CreateFilters2(){
    return 30;
    // filterBase = new FilterBase();
    // filterBase->initWithSamplingRate(4000);

    // return filterBase->getSamplingRate();
}

