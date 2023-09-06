#include <emscripten.h>
#include <iostream>
#include <thread>
#include <chrono>
#include <emscripten/bind.h>
#include <wasm_simd128.h>
using namespace emscripten;

#ifndef SPIKE_RECORDER_ANDROID_LOWPASSFILTER
#define SPIKE_RECORDER_ANDROID_LOWPASSFILTER

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
// std::vector<int> v0{ 1, 23 };
EM_JS(void, read_data, (int* data), {
    // console.log('Data: ' + data[0] + ', ' + data[1]);
    console.log('Data: ' + HEAP32[data>>2] + ', ' + HEAP32[(data+4)>>2]);
    // console.log('Data: ' + HEAP32[data>>2] + ', ' + HEAP32[(data+4)>>2]);
});            
EMSCRIPTEN_KEEPALIVE int *v0= new int[2];
EMSCRIPTEN_KEEPALIVE int main()
{

v0[0]=3; /// if 111 commented, it will result this 2 lines
v0[1]=7;
    int arg = 42;
    // int temp[2];
    // temp = &v0;
    // copy(v0.begin(),v0.end(),temp);
    // read_data(v0);
    // int carr[2] = { 16, 2};
    // std::vector<int> v{ 111, 221 };
    // int n = v.size();
    std::thread thread([&]() {
        // v0[0]=111; // THIS IS THE RESULT
        // v0[1]=777; // THIS IS THE RESULT
        while(true){
            std::this_thread::sleep_for(std::chrono::seconds(1));
            // int arr[2] = { 33, 45 };
            // int *arr = v.data(); //ERROR : can't reference to the outer memory
            // int arr[n];
            // copy(v0.begin(),v0.end(),arr); // must pass v as param when creating thread, if not copy can't be done multithread.worker.js:1 Uncaught RuntimeError: memory access out of bounds

            // int arr[2] = { 33, 45 };
            //int *arr = carr; // can't different pointer addres

            EM_ASM({
                console.log('Idx: ',  $0>>2 , ', ' , ($0+8)>>2);
                // console.log('Data: ' + HEAP32[$0>>2] + ', ' + HEAP32[($0+4)>>2]);
                // console.log("$0");
                console.log(HEAP32.subarray($0>>2, ($0 + 8) >> 2));
                // fillTypedarray(HEAP32.subarray($0, $0 + $1));
            }, v0, 2);
            // EM_ASM({
            //     console.log(Emval.fromHandle($0));
            // }, arr);
            // read_data(arr);
            // EM_ASM({
            // //     // EM_ASM(alert('hai'); alert('bai'));

            //     // fillTypedarray($0);
            //     console.log('Data: ' + HEAP32[$0>>2] + ', ' + HEAP32[($0+10)>>2]);
            //     // console.log('hai'); console.log('bai');
            // },carr);

            // emscripten_run_script("fillTypedarray(123)");
            // emscripten_run_script("console.log(this)");

        }
    });

    thread.detach();

    return 0;
}


EXTERNC FUNCTION_ATTRIBUTE EMSCRIPTEN_KEEPALIVE double createLowPassFilter(int16_t channelCount, double sampleRate, double cutOff, double q){


    return 0;

}
#endif


EMSCRIPTEN_BINDINGS(my_module) {
//   class_<LowPassFilter>("LowPassFilter")
//     .constructor()
//     .function("calculateCoefficients", &LowPassFilter::calculateCoefficients)
//     .function("setCornerFrequency", &LowPassFilter::setCornerFrequency)
//     .function("setQ", &LowPassFilter::setQ)
//     ;
    function("createLowPassFilter", &createLowPassFilter);
    // function("initLowPassFilter", &initLowPassFilter);
    // function("applyLowPassFilter", &applyLowPassFilter);
    // register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}