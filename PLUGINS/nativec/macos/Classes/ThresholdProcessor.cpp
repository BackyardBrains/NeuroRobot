#ifndef SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H
#define SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H

#include <algorithm>
#include <thread>
#include <chrono>
#include <cmath>
#include <climits>
#include "Processor.cpp"
#include "HeartbeatHelper.cpp"
#include <string>
// C++ to FLUTTER
// #include "include/dart_api.h"
// #include "include/dart_native_api.h"
// #include "include/dart_api_dl.h"
#include <mutex>    
#include <condition_variable>

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
// static Dart_Port_DL dart_port = 0;

// char* debug_print(const char *message)
// {
//     if (!dart_port)
//         return (char*) "wrong port"; 
//     // as_array.values = new _Dart_CObject[2];
//     // Dart_CObject c_request_arr[2];
//     // c_request_arr[0] = Dart_CObject();
//     // c_request_arr[0].type = Dart_CObject_kInt32;
//     // c_request_arr[0].value.as_int32 = 12;

//     // c_request_arr[1] = Dart_CObject();
//     // c_request_arr[1].type = Dart_CObject_kInt32;
//     // c_request_arr[1].value.as_int32 = 1;

//     // Dart_CObject* requestArr[]={&c_request_arr[0],&c_request_arr[1],&c_request_arr[2],&c_request_arr[3]};

//     Dart_CObject msg ;
//     // msg.type = Dart_CObject_kArray;
//     // msg.value.as_array.values = requestArr;
//     // msg.value.as_array.length = sizeof(c_request_arr) / sizeof(c_request_arr[0]);

//     msg.type = Dart_CObject_kString;
//     // msg.value.as_string = (char *) "tessstt print debug";
//     msg.value.as_string = (char *) message;
//     // printf(msg.value.as_string);
//     // The function is thread-safe; you can call it anywhere on your C++ code
//     try{
//         Dart_PostCObject_DL(dart_port, &msg);
//         return (char *) "success";
//     }catch(...){
//         return (char *) "failed";
//     }   
    
// }
//C++ to flutter


class HeartbeatListener : public OnHeartbeatListener {
public:
    HeartbeatListener() = default;

    ~HeartbeatListener() = default;

    void onHeartbeat(int bmp) override {
        // transferArray()
        // backyardbrains::utils::JniHelper::invokeStaticVoid(vm, "onHeartbeat", "(I)V", bmp);
    }
};

const float timeSpan = 10.0f;
class ThresholdProcessor : public Processor {
public:
    bool thresholdHit = false;

    // const char *TAG = "ThresholdProcessor";
    // static constexpr int DEFAULT_SAMPLE_COUNT = static_cast<const int>(timeSpan * 44100.0f);
    ThresholdProcessor(){}
    // ThresholdProcessor(OnHeartbeatListener *listener){
    ThresholdProcessor(int channelCount, int sampleRate){
        setChannelCount(channelCount);
        setSampleRate(sampleRate);
        // heartbeatHelper = new HeartbeatHelper(getSampleRate(), listener);

        // we need to initialize initial trigger values and local buffer because they depend on channel count
        triggerValue = new float[getChannelCount()];
        for (int i = 0; i < getChannelCount(); i++) {
            triggerValue[i] = INT_MAX;
        }
        lastTriggeredValue = new float[getChannelCount()]{0};

        init(true);
    }

    ~ThresholdProcessor() = default;

    // Returns the number of sample sequences that should be summed to get the average spike value.
    int getAveragedSampleCount() {
        return averagedSampleCount;
    }

    // Sets the number of sample sequences that should be summed to get the average spike value.
    void setAveragedSampleCount(double _averagedSampleCount) {
        // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "setAveragedSampleCount(%d)", averagedSampleCount);

        if (_averagedSampleCount <= 0 || averagedSampleCount == _averagedSampleCount) return;
        averagedSampleCount = (int) _averagedSampleCount;
    }

    // Sets the sample frequency threshold.
    void setThreshold(double threshold) {
        triggerValue[getSelectedChannel()] = (float)threshold;
    }
    // Resets all the fields used for calculations when next batch comes
    void resetThreshold() {
        resetOnNextBatch = true;
    }

    void setPaused(bool _paused) {
        if (paused == _paused) return;

        paused = _paused;
    }

    // Returns current averaging trigger type
    int getTriggerType() {
        return triggerType;
    }

    // Sets current averaging trigger type
    void setTriggerType(int _triggerType) {
        if (triggerType == _triggerType) return;
        triggerType = _triggerType;
        // debug_print("SET TRIGGER TYPE C++" );
        // debug_print(std::to_string(triggerType).c_str() );

    }

    // Starts/stops processing heartbeat
    void setBpmProcessing(bool _processBpm) {
        if (processBpm == _processBpm) return;

        // reset BPM if we stopped processing heartbeat
        if (!_processBpm) resetBpm();

        processBpm = _processBpm;
    }

//     void process(short *outSamples, int outSamplesCounts, short *inSamples,
//                                     const int inSampleCounts,
//                                     const int selectedChannel,
//                                     const int *inEventIndices, const int *inEvents, const int inEventCount) {
//         if (paused) return;

//         bool shouldReset = false;
//         bool shouldResetLocalBuffer = false;
//         // int selectedChannel = getSelectedChannel();
//         // reset buffers if selected channel has changed
//         if (lastSelectedChannel != selectedChannel) {
//             // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel has changed");
//             lastSelectedChannel = selectedChannel;
//             shouldReset = true;
//         }
//         // reset buffers if threshold changed
//         if (lastTriggeredValue[selectedChannel] != triggerValue[selectedChannel]) {
//             //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because trigger value has changed");
//             lastTriggeredValue[selectedChannel] = triggerValue[selectedChannel];
//             shouldReset = true;
//         }
//         // reset buffers if averages sample count changed
//         if (lastAveragedSampleCount != averagedSampleCount) {
//             //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because last averaged sample count has changed");
//             lastAveragedSampleCount = averagedSampleCount;
//             shouldReset = true;
//         }
//         // reset buffers if sample rate changed
//         if (lastSampleRate != getSampleRate()) {
//             //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because sample rate has changed");
//             lastSampleRate = getSampleRate();
//             shouldReset = true;
//             shouldResetLocalBuffer = true;
//         }
//         // let's save last channel count so we can use it to delete all the arrays
//         int channelCount = getChannelCount();
//         int tmpLastChannelCount = lastChannelCount;
//         if (lastChannelCount != channelCount) {
//             //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel count has changed");
//             lastChannelCount = channelCount;
//             shouldReset = true;
//             shouldResetLocalBuffer = true;
//         }
//         if (shouldReset || resetOnNextBatch) {
//             // reset rest of the data
//             clean(tmpLastChannelCount, shouldResetLocalBuffer);
//             init(shouldResetLocalBuffer);
//             resetOnNextBatch = false;
//         }

//         int tmpInSampleCount;
//         short *tmpInSamples;
//         int copyFromIncoming, copyFromBuffer;
//         // int i;
//         int i = selectedChannel;
//         short **tmpSamples;
//         int *tmpSamplesCounts;
//         short *tmpSamplesRow;
//         int *tmpSummedSampleCounts;
//         int *tmpSummedSamples;
//         short *tmpAveragedSamples;
//         int samplesToCopy;
//         int j, k;
//         int kStart, kEnd;

//         // for (i = 0; i < channelCount; i++) {
//             tmpInSampleCount = inSampleCounts;
//             tmpInSamples = inSamples;
//             tmpSamples = samplesForCalculation[i];
//             tmpSamplesCounts = samplesForCalculationCounts[i];
//             tmpSummedSampleCounts = summedSamplesCounts[i];
//             tmpSummedSamples = summedSamples[i];


//             std::string str = std::to_string(tmpSamplesCounts);
//             char* mychar = &str[0];
//         debug_print(mychar);
//         return;

//             // append unfinished sample buffers with incoming samples
//             for (j = 0; j < samplesForCalculationCount[i]; j++) {
//                 tmpSamplesRow = tmpSamples[j];
//                 kStart = tmpSamplesCounts[j];

//                 // we just need to append enough to fill the unfinished rows till end (sampleCount)
//                 samplesToCopy = std::min(sampleCount - kStart, tmpInSampleCount);
//                 std::copy(tmpInSamples, tmpInSamples + samplesToCopy, tmpSamplesRow + kStart);

//                 kEnd = kStart + samplesToCopy;
//                 for (k = kStart; k < kEnd; k++) {
//                     // add new value and increase summed samples count for current position
//                     tmpSummedSamples[k] += tmpSamplesRow[k];
//                     tmpSummedSampleCounts[k]++;
//                 }
//                 tmpSamplesCounts[j] = kEnd;
//             }
// //        }


//         short currentSample;
//         // loop through incoming samples and listen for the threshold hit
//         for (i = 0; i < inSampleCounts; i++) {
//             // currentSample = inSamples[selectedChannel][i];
//             currentSample = inSamples[i];

//             // heartbeat processing Can't add incoming to buffer, it's larger then buffer
//             if (processBpm && triggerType == TRIGGER_ON_THRESHOLD) {
//                 sampleCounter++;
//                 lastTriggerSampleCounter++;

//                 // check if minimum BPM reset period passed after last threshold hit and reset if necessary
//                 if (lastTriggerSampleCounter > minBpmResetPeriodCount) resetBpm();
//             }
//             // end of heartbeat processing

//             if (triggerType == TRIGGER_ON_THRESHOLD) { // triggering by a threshold value
//                 if (!inDeadPeriod) {
//                     // check if we hit the threshold
//                     if ((triggerValue[selectedChannel] >= 0 && currentSample > triggerValue[selectedChannel] &&
//                             prevSample <= triggerValue[selectedChannel]) ||
//                         (triggerValue[selectedChannel] < 0 && currentSample < triggerValue[selectedChannel] &&
//                             prevSample >= triggerValue[selectedChannel])) {
//                         // we hit the threshold, turn on dead period of 5ms
//                         inDeadPeriod = true;

//                         // create new samples for current threshold
//                         // for (j = 0; j < channelCount; j++) {
//                         //     prepareNewSamples(inSamples, inSampleCounts, j, i);
//                         // }
//                         prepareNewSamples(inSamples, inSampleCounts, selectedChannel, i);

//                         // heartbeat processingA
//                         if (processBpm) {
//                             // pass data to heartbeat helper
//                             heartbeatHelper->beat(sampleCounter);
//                             // reset the last triggered sample counter
//                             // and start counting for next heartbeat reset period
//                             lastTriggerSampleCounter = 0;
//                         }
//                         // end of heartbeat processing
//                     }
//                 } else {
//                     if (++deadPeriodSampleCounter > deadPeriodCount) {
//                         deadPeriodSampleCounter = 0;
//                         inDeadPeriod = false;
//                     }
//                 }
//             } else if (inEventCount > 0) { // triggering on events
//                 // for (j = 0; j < inEventCount; j++) {
//                 //     if (triggerType == TRIGGER_ON_EVENTS) {
//                 //         if (i == inEventIndices[j]) {
//                 //             // create new samples for current threshold
//                 //             for (k = 0; k < channelCount; k++) {
//                 //                 prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
//                 //             }
//                 //         }
//                 //     } else {
//                 //         if (i == inEventIndices[j] && triggerType == inEvents[j]) {
//                 //             // create new samples for current threshold
//                 //             for (k = 0; k < channelCount; k++) {
//                 //                 prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
//                 //             }
//                 //         }
//                 //     }
//                 // }
//             }

//             prevSample = currentSample;
//         }

//         // for (i = 0; i < channelCount; i++) {
//             i = selectedChannel;
//             tmpInSampleCount = inSampleCounts;
//             tmpInSamples = inSamples;

//             // add samples to local buffer
//             copyFromBuffer = std::max(bufferSampleCount - tmpInSampleCount, 0);
//             copyFromIncoming = std::min(bufferSampleCount - copyFromBuffer, tmpInSampleCount);
//             if (copyFromBuffer > 0)
//                 std::copy(buffer[i] + tmpInSampleCount, buffer[i] + bufferSampleCount, buffer[i]);
//             std::copy(tmpInSamples, tmpInSamples + copyFromIncoming,
//                         buffer[i] + bufferSampleCount - copyFromIncoming);
//         // }

//         int *counts = new int[averagedSampleCount]{0};
//         // for (i = 0; i < channelCount; i++) {
//         i = selectedChannel;

//             tmpSummedSampleCounts = summedSamplesCounts[i];
//             tmpSummedSamples = summedSamples[i];
//             tmpAveragedSamples = averagedSamples[i];

//             // calculate the averages for all channels
//             for (j = 0; j < sampleCount; j++)
//                 if (tmpSummedSampleCounts[j] != 0)
//                     tmpAveragedSamples[j] = (short) (tmpSummedSamples[j] / tmpSummedSampleCounts[j]);
//                 else
//                     tmpAveragedSamples[j] = 0;
//             std::copy(tmpAveragedSamples, tmpAveragedSamples + sampleCount, outSamples);
//             outSamplesCounts = sampleCount;
//         // }
//         delete[] counts;
//     }    
    int isThresholded = 0;

    void process(short **outSamples, int *outSamplesCounts, short **inSamples,
                                    const int *inSampleCounts,
                                    // const short *inEventIndices, const short *inEvents, const short inEventCount) {
                                    const short inEventIndices, const short inEvents, const short inEventCount) {
        if (paused) return;

        bool shouldReset = false;
        bool shouldResetLocalBuffer = false;
        int selectedChannel = getSelectedChannel();
        // reset buffers if selected channel has changed
        if (lastSelectedChannel != selectedChannel) {
            // debug_print("Resetting because channel has changed");

            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel has changed");
            lastSelectedChannel = selectedChannel;
            shouldReset = true;
        }
        // reset buffers if threshold changed
        if (lastTriggeredValue[selectedChannel] != triggerValue[selectedChannel]) {
            // debug_print("1");
            // debug_print(std::to_string(lastTriggeredValue[selectedChannel]).c_str() );
            // debug_print(std::to_string(triggerValue[selectedChannel]).c_str() );
            // debug_print("--------------");
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because trigger value has changed");
            lastTriggeredValue[selectedChannel] = triggerValue[selectedChannel];
            shouldReset = true;
        }
        // reset buffers if averages sample count changed
        if (lastAveragedSampleCount != averagedSampleCount) {
            // debug_print("2");            
            // debug_print(std::to_string(lastAveragedSampleCount).c_str() );
            // debug_print(std::to_string(averagedSampleCount).c_str() );
            // debug_print("--------------");
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because last averaged sample count has changed");
            lastAveragedSampleCount = averagedSampleCount;
            shouldReset = true;
        }
        // reset buffers if sample rate changed
        if (lastSampleRate != getSampleRate()) {
            // debug_print("PRINT 3");
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because sample rate has changed");
            lastSampleRate = getSampleRate();
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        // let's save last channel count so we can use it to delete all the arrays
        int channelCount = getChannelCount();

        int tmpLastChannelCount = lastChannelCount;
        if (lastChannelCount != channelCount) {
            // debug_print("4");
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel count has changed");
            lastChannelCount = channelCount;
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        if (shouldReset || resetOnNextBatch) {
            // debug_print("PRINT  5");
            // reset rest of the data
            clean(tmpLastChannelCount, shouldResetLocalBuffer);
            init(shouldResetLocalBuffer);
            resetOnNextBatch = false;
        }

        int tmpInSampleCount;
        short *tmpInSamples;
        int copyFromIncoming, copyFromBuffer;
        int i;
        // int c, i;
        short **tmpSamples;
        int *tmpSamplesCounts;
        short *tmpSamplesRow;
        int *tmpSummedSampleCounts;
        int *tmpSummedSamples;
        short *tmpAveragedSamples;
        int samplesToCopy;
        int j, k;
        int kStart, kEnd;

        // std::string cc = std::string(channelCount);
        // char* ch=cc.c_str();

        for (i = 0; i < channelCount; i++) {
            tmpInSampleCount = inSampleCounts[i];
            tmpInSamples = inSamples[i];
            tmpSamples = samplesForCalculation[i];
            tmpSamplesCounts = samplesForCalculationCounts[i];
            tmpSummedSampleCounts = summedSamplesCounts[i];
            tmpSummedSamples = summedSamples[i];

            // append unfinished sample buffers with incoming samples
            for (j = 0; j < samplesForCalculationCount[i]; j++) {
                tmpSamplesRow = tmpSamples[j];
                kStart = tmpSamplesCounts[j];

                // we just need to append enough to fill the unfinished rows till end (sampleCount)
                samplesToCopy = std::min(sampleCount - kStart, tmpInSampleCount);
                std::copy(tmpInSamples, tmpInSamples + samplesToCopy, tmpSamplesRow + kStart);

                kEnd = kStart + samplesToCopy;
                for (k = kStart; k < kEnd; k++) {
                    // add new value and increase summed samples count for current position
                    tmpSummedSamples[k] += tmpSamplesRow[k];
                    tmpSummedSampleCounts[k]++;
                }
                tmpSamplesCounts[j] = kEnd;
            }
        }


        short currentSample;
        // short isEventMarkerFound = 0;
        // loop through incoming samples and listen for the threshold hit
        // for (i = 0; i < inSampleCounts[selectedChannel]; i++) {
        //     currentSample = inSamples[selectedChannel][i];
        // debug_print("Channel Count");
        // debug_print(std::to_string(channelCount).c_str() );

        // for (c = 0; c < channelCount; c++) {
            // for (i = 0; i < inSampleCounts[c]; i++) {
            for (i = 0; i < inSampleCounts[selectedChannel]; i++) {
                currentSample = inSamples[selectedChannel][i];

                // heartbeat processing Can't add incoming to buffer, it's larger then buffer
                /*
                if (processBpm && triggerType == TRIGGER_ON_THRESHOLD) {
                    sampleCounter++;
                    lastTriggerSampleCounter++;

                    // check if minimum BPM reset period passed after last threshold hit and reset if necessary
                    if (lastTriggerSampleCounter > minBpmResetPeriodCount) resetBpm();
                }
                */
                // end of heartbeat processing
                
                // if (triggerType == 0){
                //     debug_print("Event Trigger TYPE");
                //     debug_print(std::to_string(triggerType).c_str() );
                //     debug_print(std::to_string(inEventCount).c_str() );
                // }

                // if (triggerType == -1 && c == selectedChannel) { //TRIGGER_ON_THRESHOLD // triggering by a threshold value
                if (triggerType == -1) { //TRIGGER_ON_THRESHOLD // triggering by a threshold value
                    if (!inDeadPeriod) {
                        // check if we hit the threshold
                        if ((triggerValue[selectedChannel] >= 0 && currentSample > triggerValue[selectedChannel] &&
                                prevSample <= triggerValue[selectedChannel]) ||
                            (triggerValue[selectedChannel] < 0 && currentSample < triggerValue[selectedChannel] &&
                                prevSample >= triggerValue[selectedChannel])) {
                            // we hit the threshold, turn on dead period of 5ms
                            inDeadPeriod = true;
                            thresholdHit = true;

                            // create new samples for current threshold

                            // if (isThresholded == 0){
                            //     isThresholded = 1;
                                for (j = 0; j < channelCount; j++) {                                    
                                    prepareNewSamples(inSamples[j], inSampleCounts[j], j, i);
                                }
                            // }

                            // heartbeat processingA
                            if (processBpm) {
                                // pass data to heartbeat helper
                                // heartbeatHelper->beat(sampleCounter);
                                // reset the last triggered sample counter
                                // and start counting for next heartbeat reset period
                                lastTriggerSampleCounter = 0;
                            }
                            // end of heartbeat processing
                        }
                    } else {
                        if (++deadPeriodSampleCounter > deadPeriodCount) {
                            deadPeriodSampleCounter = 0;
                            inDeadPeriod = false;
                        }
                    }

                    // prevSample = currentSample;

                } else if (inEventCount > 0) { // triggering on events
                        // debug_print("Event Trigger");
                        // debug_print("Index Iteration");
                        // debug_print(std::to_string(i).c_str() );
                    // if (isEventMarkerFound == 0){
                        // if (i == inEventIndices) {
                        //     if (triggerType == inEvents){
                        //         debug_print("triggerType == inevents");

                        //     }else{
                        //         debug_print("Index equal inEventIndices !triggerType");
                        //         debug_print(std::to_string(triggerType).c_str() );
                        //         debug_print(std::to_string(inEvents).c_str() );

                        //     }
                        // }else
                        // if (inEvents == 0){ // TRIGGER_ON_EVENTS
                            // debug_print(std::to_string(triggerType).c_str() );
                            // debug_print(std::to_string(inEvents).c_str() );

                        // }


                        // for (j = 0; j < inEventCount; j++) {
                            if (inEvents == 0) {// TRIGGER_ON_EVENTS
                                // if (i == inEventIndices[j]) {
                                if (i == inEventIndices) {
                                    // create new samples for current threshold
                                    for (k = 0; k < channelCount; k++) {
                                        prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                                    }

                                        // prepareNewSamples(inSamples[c], inSampleCounts[c], c, i);
                                }
                            } else {
                                if (i == inEventIndices && inEvents > 0) {
                                    // debug_print("123----------");
                                    // debug_print(std::to_string(i).c_str() );
                                    // debug_print(std::to_string(inSampleCounts[0]).c_str() );
                                    // create new samples for current threshold
                                    for (k = 0; k < channelCount; k++) {
                                        prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                                    }
                                        // prepareNewSamples(inSamples[c], inSampleCounts[c], c, i);
                                    // isEventMarkerFound = 1;
                                    // break;
                                }
                            }
                        // }
                    // }else{
                    //     break;
                    // }
                }


                prevSample = currentSample;
            }
        // }

        for (i = 0; i < channelCount; i++) {
            tmpInSampleCount = inSampleCounts[i];
            tmpInSamples = inSamples[i];

            // add samples to local buffer
            copyFromBuffer = std::max(bufferSampleCount - tmpInSampleCount, 0);
            copyFromIncoming = std::min(bufferSampleCount - copyFromBuffer, tmpInSampleCount);
            if (copyFromBuffer > 0)
                std::copy(buffer[i] + tmpInSampleCount, buffer[i] + bufferSampleCount, buffer[i]);
            std::copy(tmpInSamples, tmpInSamples + copyFromIncoming,
                        buffer[i] + bufferSampleCount - copyFromIncoming);
            // debug_print("  1  - copy sample");
            // debug_print("channelIndex");
            // debug_print(std::to_string(floor(i)).c_str());
            // debug_print(std::to_string(floor(copyFromBuffer)).c_str());
            // debug_print(std::to_string(floor(copyFromIncoming)).c_str());
            // debug_print(std::to_string(floor(sampleIndex)).c_str());

        }

        int *counts = new int[averagedSampleCount]{0};
        for (i = 0; i < channelCount; i++) {
            tmpSummedSampleCounts = summedSamplesCounts[i];
            tmpSummedSamples = summedSamples[i];
            tmpAveragedSamples = averagedSamples[i];

            // calculate the averages for all channels
            for (j = 0; j < sampleCount; j++)
                if (tmpSummedSampleCounts[j] != 0)
                    tmpAveragedSamples[j] = (short) (tmpSummedSamples[j] / tmpSummedSampleCounts[j]);
                else
                    tmpAveragedSamples[j] = 0;
            std::copy(tmpAveragedSamples, tmpAveragedSamples + sampleCount, outSamples[i]);
            outSamplesCounts[i] = sampleCount;
            // debug_print("outSamples");

        }
        delete[] counts;
    }
    // void appendIncomingSamples(short **inSamples, int *inSampleCounts) {
    void appendIncomingSamples(short *inSamples, int inSampleCounts, int channelIdx) {
        bool shouldReset = false;
        bool shouldResetLocalBuffer = false;
        int selectedChannel = getSelectedChannel();
        // reset buffers if selected channel has changed
        if (lastSelectedChannel != selectedChannel) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel has changed");
            lastSelectedChannel = selectedChannel;
            shouldReset = true;
        }
        // reset buffers if threshold changed
        if (lastTriggeredValue[selectedChannel] != triggerValue[selectedChannel]) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because trigger value has changed");
            lastTriggeredValue[selectedChannel] = triggerValue[selectedChannel];
            shouldReset = true;
        }
        // reset buffers if averages sample count changed
        if (lastAveragedSampleCount != averagedSampleCount) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because last averaged sample count has changed");
            lastAveragedSampleCount = averagedSampleCount;
            shouldReset = true;
        }
        // reset buffers if sample rate changed
        if (lastSampleRate != getSampleRate()) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because sample rate has changed");
            lastSampleRate = getSampleRate();
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        // let's save last channel count so we can use it to delete all the arrays
        int channelCount = getChannelCount();
        int tmpLastChannelCount = lastChannelCount;
        if (lastChannelCount != channelCount) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel count has changed");
            lastChannelCount = channelCount;
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        if (shouldReset || resetOnNextBatch) {
            // reset rest of the data
            clean(tmpLastChannelCount, shouldResetLocalBuffer);
            init(shouldResetLocalBuffer);
            resetOnNextBatch = false;
        }

        int tmpInSampleCount;
        short *tmpInSamples;
        int copyFromIncoming, copyFromBuffer;
        int i = channelIdx;

        // in case we don't need to average let's just add incoming samples to local buffer
        // for (i = 0; i < channelCount; i++) {
            // tmpInSampleCount = inSampleCounts[i];
            // tmpInSamples = inSamples[i];
            tmpInSampleCount = inSampleCounts;
            tmpInSamples = inSamples;

            // add samples to local buffer
            copyFromBuffer = std::max(bufferSampleCount - tmpInSampleCount, 0);
            copyFromIncoming = std::min(bufferSampleCount - copyFromBuffer, tmpInSampleCount);
            if (copyFromBuffer > 0)
                std::copy(buffer[i] + tmpInSampleCount, buffer[i] + bufferSampleCount, buffer[i]);
            std::copy(tmpInSamples, tmpInSamples + copyFromIncoming,
                        buffer[i] + bufferSampleCount - copyFromIncoming);
        // }
    }
    int getChannelsCount(){
        return getChannelCount();
    }

    void doClean(int channelCount, bool resetLocalBuffer){
        clean(channelCount, resetLocalBuffer);
    }
private:
    static const char *TAG;

    // We shouldn't process more than 2.4 seconds of samples in any given moment
    // static constexpr float MAX_PROCESSED_SECONDS = 2.0f;
    // static constexpr float MAX_PROCESSED_SECONDS = timeSpan;
    // When threshold is hit we should have a dead period of 5ms before checking for next threshold hit
    static constexpr float DEAD_PERIOD_SECONDS = 0.005f;
    // Default number of samples that needs to be summed to get the averaged sample
    static constexpr int DEFAULT_AVERAGED_SAMPLE_COUNT = 1;
    // Minimum number of seconds without a heartbeat before resetting the heartbeat helper
    static constexpr double DEFAULT_MIN_BPM_RESET_PERIOD_SECONDS = 3;

    // Constants that define we are currently averaging when threshold is hit
    static constexpr int TRIGGER_ON_THRESHOLD = -1;
    // Constants that define we are currently averaging on all events
    static constexpr int TRIGGER_ON_EVENTS = 0;

    // Prepares new sample collection for averaging
    void prepareNewSamples(const short *inSamples, int length, int channelIndex, int sampleIndex){
        short **tmpSamples = samplesForCalculation[channelIndex];
        int *tmpSamplesCounts = samplesForCalculationCounts[channelIndex];
        int *tmpSummedSamples = summedSamples[channelIndex];
        int *tmpSummedSamplesCounts = summedSamplesCounts[channelIndex];
        short *tmpSamplesRowZero;

        // create new sample row
        auto *newSampleRow = new short[sampleCount]{0};
        int copyFromIncoming, copyFromBuffer;
        copyFromBuffer = std::max(bufferSampleCount - sampleIndex, 0);
        copyFromIncoming = std::min(sampleCount - copyFromBuffer, length);
        if (copyFromBuffer > 0) {
            std::copy(buffer[channelIndex] + sampleIndex, buffer[channelIndex] + bufferSampleCount, newSampleRow);
        }
        std::copy(inSamples, inSamples + copyFromIncoming, newSampleRow + copyFromBuffer);
        // debug_print("channelIndex");
        // debug_print(std::to_string(floor(channelIndex)).c_str());
        // debug_print(std::to_string(floor(copyFromBuffer)).c_str());
        // debug_print(std::to_string(floor(copyFromIncoming)).c_str());
        // debug_print(std::to_string(floor(sampleIndex)).c_str());


        tmpSamplesRowZero = tmpSamples[0];
        int copySamples = copyFromBuffer + copyFromIncoming;
        bool shouldDeleteOldestRow = samplesForCalculationCount[channelIndex] >= averagedSampleCount;
        int len = shouldDeleteOldestRow ? tmpSamplesCounts[0] : copySamples;
        int i;
        for (i = 0; i < len; i++) {
            // subtract the value and decrease summed samples count for current position
            if (shouldDeleteOldestRow) {
                tmpSummedSamples[i] -= tmpSamplesRowZero[i];
                tmpSummedSamplesCounts[i]--;
            }
            if (i < copySamples) {
                // add new value and increase summed samples count for current position
                tmpSummedSamples[i] += newSampleRow[i];
                tmpSummedSamplesCounts[i]++;
            }
        }

        // remove oldest sample row if we're full
        if (shouldDeleteOldestRow) {
            // delete the oldest sample row
            delete[] tmpSamples[0];
            // shift rest of the filled sample rows to left
            std::move(tmpSamples + 1, tmpSamples + samplesForCalculationCount[channelIndex], tmpSamples);
            std::move(tmpSamplesCounts + 1, tmpSamplesCounts + samplesForCalculationCount[channelIndex],
                        tmpSamplesCounts);
            samplesForCalculationCount[channelIndex]--;
        }
        // add new sample row
        tmpSamples[samplesForCalculationCount[channelIndex]] = newSampleRow;
        tmpSamplesCounts[samplesForCalculationCount[channelIndex]++] = copySamples;

    }        

    // Creates and initializes all the fields used for calculations
    void init(bool resetLocalBuffer) {
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "init()");
        float sampleRate = getSampleRate();
        int channelCount = getChannelCount();

        // sampleCount = static_cast<int>(sampleRate * MAX_PROCESSED_SECONDS);
        sampleCount = static_cast<int>(sampleRate * timeSpan);
        bufferSampleCount = sampleCount / 2;

        if (resetLocalBuffer)buffer = new short *[channelCount];
        samplesForCalculationCount = new int[channelCount]{0};
        samplesForCalculationCounts = new int *[channelCount];
        samplesForCalculation = new short **[channelCount];
        summedSamplesCounts = new int *[channelCount];
        summedSamples = new int *[channelCount];
        averagedSamples = new short *[channelCount];
        for (int i = 0; i < channelCount; i++) {
            if (resetLocalBuffer) buffer[i] = new short[bufferSampleCount];
            samplesForCalculationCounts[i] = new int[averagedSampleCount]{0};
            samplesForCalculation[i] = new short *[averagedSampleCount];
            summedSamplesCounts[i] = new int[sampleCount]{0};
            summedSamples[i] = new int[sampleCount]{0};
            averagedSamples[i] = new short[sampleCount]{0};
        }

        deadPeriodCount = static_cast<int>(sampleRate * DEAD_PERIOD_SECONDS);
        deadPeriodSampleCounter = 0;
        inDeadPeriod = false;

        prevSample = 0;

        // heartbeatHelper->reset();
        // heartbeatHelper->setSampleRate(sampleRate);
        minBpmResetPeriodCount = (int) (sampleRate * DEFAULT_MIN_BPM_RESET_PERIOD_SECONDS);
        lastTriggerSampleCounter = 0;
        sampleCounter = 0;
    }

    // Deletes all array fields used for calculations
    void clean(int channelCount, bool resetLocalBuffer){
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "clean()");
        for (int i = 0; i < channelCount; i++) {
            if (resetLocalBuffer) delete[] buffer[i];
            delete[] samplesForCalculationCounts[i];
            if (samplesForCalculationCount[i] > 0) {
                for (int j = 0; j < samplesForCalculationCount[i]; j++) {
                    delete[] samplesForCalculation[i][j];
                }
            }
            delete[] samplesForCalculation[i];
            delete[] summedSamplesCounts[i];
            delete[] summedSamples[i];
            delete[] averagedSamples[i];
        }
        if (resetLocalBuffer) delete[] buffer;
        delete[] samplesForCalculationCount;
        delete[] samplesForCalculationCounts;
        delete[] samplesForCalculation;
        delete[] summedSamplesCounts;
        delete[] averagedSamples;
        delete[] summedSamples;
    }
    // Resets all local variables used for the heartbeat processing
    void resetBpm(){
        // heartbeatHelper->reset();
        sampleCounter = 0;
        lastTriggerSampleCounter = 0;
            
    }

    // Number of samples that we collect for one sample stream
    int sampleCount = 0;
    // Used to check whether channel has changed since the last incoming sample batch
    int lastSelectedChannel = 0;
    // Threshold value that triggers the averaging
    float *triggerValue;
    // Used to check whether threshold trigger value has changed since the last incoming sample batch
    float *lastTriggeredValue;
    // Number of samples that needs to be summed to get the averaged sample
    int averagedSampleCount = DEFAULT_AVERAGED_SAMPLE_COUNT;
    // Used to check whether number of averages samples has changed since the last incoming sample batch
    int lastAveragedSampleCount = 0;
    // Used to check whether sample rate has changed since the last incoming sample batch
    float lastSampleRate = 0;
    // Used to check whether chanel count has changed since the last incoming sample batch
    int lastChannelCount = 0;
    // Whether buffers need to be reset before processing next batch
    bool resetOnNextBatch = false;

    // We need to buffer half of samples total count up to the sample that hit's threshold
    int bufferSampleCount = sampleCount / 2;
    // Buffer that holds most recent 1.2 ms of audio so we can prepend new sample buffers when threshold is hit
    short **buffer;
    // Holds number of sample rows that have been averaged
    int *samplesForCalculationCount;
    // Holds number of samples in each sample row
    int **samplesForCalculationCounts;
    // Holds sample rows
    short ***samplesForCalculation;
    // Holds number of samples that have been summed at specified position
    int **summedSamplesCounts;
    // Holds sums of all the samples at specified position
    int **summedSamples;
    // Holds averages of all the samples at specified position
    short **averagedSamples;

    // Dead period when we don't check for threshold after hitting one
    int deadPeriodCount = 0;
    // Counts samples between two dead periods
    int deadPeriodSampleCounter;
    // Whether we are currently in dead period (not listening for threshold hit)
    bool inDeadPeriod;

    // Holds previously processed sample so we can compare whether we have a threshold hit
    short prevSample;

    // Whether threshold is currently paused or not. If paused, processing returns values as if the threshold is always reset.
    bool paused = false;

    // Current type of trigger we're averaging on
    int triggerType = TRIGGER_ON_THRESHOLD;

    // Holds reference to HeartbeatHelper that processes threshold hits as heart beats
    HeartbeatHelper *heartbeatHelper;
    // Period without heartbeat that we wait for before resetting the heartbeat helper
    int minBpmResetPeriodCount = 0;
    // Index of the sample that triggered the threshold hit
    int lastTriggerSampleCounter;
    // Counts samples between two resets that need to be passed to heartbeat helper
    int sampleCounter;
    // Whether BPM should be processed or not
    bool processBpm = false;
};




// Ensure that the function is not-mangled; exported as a pure C function
// C++ to Flutter
// EXTERNC FUNCTION_ATTRIBUTE void set_dart_port(Dart_Port_DL port)
// {
//     dart_port = port;
// }
// C++ to Flutter


// Sample usage of Dart_PostCObject_DL to post message to Flutter side

// char* transferArray(int* arr, int sampleCount)
// {
//     if (!dart_port)
//         return (char*) "wrong port"; 
//     // as_array.values = new _Dart_CObject[2];
//     Dart_CObject* c_request_arr = new Dart_CObject[sampleCount];
//     Dart_CObject* requestArr[sampleCount];
//     for (int i = 0; i < sampleCount; i++){
//         // c_request_arr[i] = Dart_CObject();
//         c_request_arr[i].type = Dart_CObject_kInt32;
//         c_request_arr[i].value.as_int32 = arr[i];
//         requestArr[i] = &c_request_arr[i];
//     }
//     // Dart_CObject* requestArr= &c_request_arr;
//     Dart_CObject msg ;
//     msg.type = Dart_CObject_kArray;
//     msg.value.as_array.values = requestArr;
//     // msg.value.as_array.length = sizeof(c_request_arr) / sizeof(c_request_arr[0]);
//     msg.value.as_array.length = sampleCount;

//     // msg.type = Dart_CObject_kString;
//     // msg.value.as_string = (char *) "tessstt print debug";
//     // printf(msg.value.as_string);
//     // The function is thread-safe; you can call it anywhere on your C++ code
//     try{
//         Dart_PostCObject_DL(dart_port, &msg);
//         return (char *) "success";
//     }catch(...){
//         return (char *) "failed";
//     }   
    
// }




// HighPassFilter* highPassFilters;
ThresholdProcessor thresholdProcessor[1];
// double gSampleRate = 44100.0;


// int count = (int) 2.0f * thresholdProcessor[0].getSampleRate();
// // debug_print( "count!!" );
// // debug_print(std::to_string(count).c_str() );
// // int count = (int) 2.0f * thresholdProcessor[0].getSampleRate();
// // int count = (int) 2.0f * gSampleRate;
// short **outSamplesPtr = new short*[1];
// int *outSampleCounts = new int[1];
// short *outEventIndicesPtr = new short[1];
// std::string *outEventNamesPtr = new std::string[1];


// outSamplesPtr[0] = new short[count];
// // outSamplesPtr[1] = new short[count];
// outSampleCounts[0]=count;
// // outSampleCounts[1]=0;

// thresholdProcessor[0].setThreshold(_threshold);
// thresholdProcessor[0].setAveragedSampleCount(_averagedSampleCount);
// // thresholdProcessor[0].appendIncomingSamples(data, sampleCount, channelIdx);
// int layers = ((int)_averagedSampleCount);


// short **inSamplesPtr = new short*[1];
// int *inSampleCounts = new int[1];

int count;
short ***envelopes = new short**[6];
short **outSamplesPtr = new short*[6];
short **tempSamplesPtr = new short*[6];
int *outSampleCounts = new int[6];
short *outEventIndicesPtr = new short[1];
std::string *outEventNamesPtr = new std::string[1];

short **inSamplesPtr = new short*[6];
int *inSampleCounts = new int[6];

const int SIZE_LOGS2 = 10;
float envelopeSizes[SIZE_LOGS2];
int forceLevel = 9;
short channelCount;
double sampleRate;
const int skipCounts[10] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512};
double divider = 6;
int current_start = 0;
short *tempData;
int isAlreadyCreated = 0;


void resetOutSamples(short channelIdx, short **outSamples, int outSampleCount){
    
    std::fill(outSamples[channelIdx], outSamples[channelIdx] + outSampleCount, 0);
    // memset(envelopes[forceLevel],0,sizeOfEnvelope*sizeof(envelopes[forceLevel]));
}

EXTERNC FUNCTION_ATTRIBUTE double createThresholdProcess(short _channelCount, uint32_t _sampleRate, short averagedSampleCount, short threshold){
    // highPassFilters = new HighPassFilter[channelCount];
    // count = (int) 2.0f * sampleRate;
    // debug_print("create1");
    sampleRate = (double) _sampleRate;

    channelCount = _channelCount;

    count = (int) timeSpan * sampleRate;
    // for (uint32_t c = 0 ; c < channelCount; c++){
    for (uint32_t c = 0 ; c < 6; c++){
        if (isAlreadyCreated == 1){
        // if (outSamplesPtr[c] != NULL){
        //     debug_print("outSamplesPtr");
            // delete[] outSamplesPtr[c];
            // delete[] tempSamplesPtr[c];
        // //     isAlreadyCreated = 1;
        }
        inSamplesPtr[c] = new short[1000];
        inSampleCounts[c] = 0;
        outSamplesPtr[c] = new short[count * 1];
        tempSamplesPtr[c] = new short[count * 1];
        outSampleCounts[c]=count;
        resetOutSamples(c, outSamplesPtr,outSampleCounts[c]);
    }
    // tempData = new short[ count * 2];

    // debug_print("create2");

    // for( int32_t i = 0; i < channelCount; i++ )
    for( int32_t i = 0; i < 1; i++ )
    {
        // HeartbeatListener* hb = (new HeartbeatListener());
        if (isAlreadyCreated == 1){
            int prevChannelCount = thresholdProcessor[i].getChannelsCount();
            thresholdProcessor[i].doClean(prevChannelCount, true);
        }
        thresholdProcessor[i] = ThresholdProcessor( channelCount, sampleRate );
        float sr = (float) sampleRate;
        // std::string dbg = "test sample rate";
        // debug_print(dbg.c_str());
        // debug_print(std::to_string(sampleRate).c_str());
        // debug_print(dbg.c_str());
        // debug_print(std::to_string(averagedSampleCount).c_str());
        // debug_print(dbg.c_str());
        // debug_print(std::to_string(threshold).c_str());
        thresholdProcessor[i].setSampleRate(sr);
        thresholdProcessor[i].setAveragedSampleCount(averagedSampleCount);
        thresholdProcessor[i].setThreshold(threshold);
        thresholdProcessor[i].setChannelCount(channelCount);
        // gSampleRate = sampleRate;
        // HighPassFilter highPassFilter = HighPassFilter();
        // highPassFilters[i].initWithSamplingRate(sampleRate);
        // if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        // highPassFilters[i].setCornerFrequency(highCutOff);
        // highPassFilters[i].setQ(q);
        // highPassFilters[i] = highPassFilter;
    }

    sampleRate = _sampleRate;

    // for (int i = 0; i < _channelCount; i++){
    for (int i = 0; i < 6; i++){
        envelopes[i] = new short*[10];
    }

    const int NUMBER_OF_SEGMENTS = timeSpan;
    double SEGMENT_SIZE = sampleRate;
    double SIZE = (NUMBER_OF_SEGMENTS * SEGMENT_SIZE);

    double size = SIZE * 4;
    for (int i = 0; i < SIZE_LOGS2; i++) {
        for (int j = 0 ; j < 6 ; j++){
            if (isAlreadyCreated == 1){
                // debug_print("delete envelopes?");
                // delete[] envelopes[j][i];
            }
            envelopes[j][i] = new short[size];
        }
        size /= 2;
        envelopeSizes[i] = (size);
    }

    // inSamplesPtr[0] = new short[500];

    // thresholdProcessor[0].appendIncomingSamples(data, sampleCount, channelIdx);
    
    // thresholdProcessor[0].setSampleRate((float) sampleRate);
    // debug_print("create3");
    isAlreadyCreated = 1;

    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double initThresholdProcess(short channelCount, double sampleRate, double highCutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // HighPassFilter highPassFilter = highPassFilters[i];
        // highPassFilters[i].initWithSamplingRate(sampleRate);
        // if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        // highPassFilters[i].setCornerFrequency(highCutOff);
        // highPassFilters[i].setQ(q);
    }
    return 1;
}


EXTERNC FUNCTION_ATTRIBUTE double setTriggerTypeProcess(short channelIdx, short triggerType){
    thresholdProcessor[channelIdx].setTriggerType(triggerType);
    // debug_print("getTriggerType" );
    // debug_print(std::to_string(triggerType).c_str() );
    // debug_print(std::to_string(thresholdProcessor[channelIdx].getTriggerType()).c_str() );
    return triggerType;
}

EXTERNC FUNCTION_ATTRIBUTE double setThresholdParametersProcess(short _channelCount, short _forceLevel, double _sampleRate, double _divider, int _current_start){
    channelCount = _channelCount;
    forceLevel = _forceLevel;
    divider = _divider;
    current_start = _current_start;
    // debug_print("setThresholdParameters");
    if (sampleRate != _sampleRate){
        sampleRate = _sampleRate;

        // debug_print("setThresholdParameters 1");
        for (int i = 0; i < _channelCount; i++){
            envelopes[i] = new short*[10];
        }
        // debug_print("setThresholdParameters 2");

        const int NUMBER_OF_SEGMENTS = timeSpan;
        double SEGMENT_SIZE = sampleRate;
        double SIZE = (NUMBER_OF_SEGMENTS * SEGMENT_SIZE);
        // debug_print("setThresholdParameters 3");

        double size = SIZE * 2;
        for (int i = 0; i < SIZE_LOGS2; i++) {
            envelopeSizes[i] = (size);
            for (int j = 0 ; j < channelCount ; j++){
                envelopes[j][i] = new short[size];
            }
            size /= 2;
        }

    }
    // debug_print("setThresholdParameters 4");

    return 1;
}

int* nullData;
void resetEnvelope(short channelIdx, short **envelopes, int forceLevel){
    int sizeOfEnvelope = floor(2*envelopeSizes[forceLevel]);
    std::fill(envelopes[forceLevel], envelopes[forceLevel] + sizeOfEnvelope, 0);
    // memset(envelopes[forceLevel],0,sizeOfEnvelope*sizeof(envelopes[forceLevel]));
}
//resetOutSamples(0, outSamplesPtr,outSampleCounts);

// void envelopingSamples2(int _head, int sample, short **_envelopes, int SIZE_LOGS2, int forceLevel) {
//     int j = forceLevel;
//     short skipCount = skipCounts[j];
//     int envelopeSampleIndex = floor(_head / skipCount);
//     int interleavedSignalIdx = envelopeSampleIndex * 2;
//     if (_head % skipCount == 0) {
//     } else {
//         if (sample < _envelopes[j][interleavedSignalIdx]) {
//         }
        
//         if (sample > _envelopes[j][interleavedSignalIdx + 1]) {
//         }
//     }
// }

void envelopingSamples(int _head, int sample, short **_envelopes, int SIZE_LOGS2, int forceLevel) {
    // for (int j = 0; j < SIZE_LOGS2; j++) {
        // if (forceLevel > -1 && j!=forceLevel) continue;
        int j = forceLevel;
        short skipCount = skipCounts[j];
        int envelopeSampleIndex = floor(_head / skipCount);
        int interleavedSignalIdx = envelopeSampleIndex * 2;
        
        if (_head % skipCount == 0) {
            _envelopes[j][interleavedSignalIdx] = sample; 
            _envelopes[j][interleavedSignalIdx + 1] = sample;
        } else {
            if (sample < _envelopes[j][interleavedSignalIdx]) {
                _envelopes[j][interleavedSignalIdx] = sample;
            }
            
            if (sample > _envelopes[j][interleavedSignalIdx + 1]) {
                _envelopes[j][interleavedSignalIdx + 1] = sample;
            }
        }
    // }  
}

/*
    This function called when it is paused
    Copy the current threshold buffer so it won't overwritten
    C++ envelope sizes is defaulted to 10s
    Dart envelope sizes is defaulted to 60s
*/
EXTERNC FUNCTION_ATTRIBUTE double getSamplesThresholdProcess(short channelIdx, short *data, short forceLevel,double _divider, int currentStart, int sampleNeeded){

    divider = _divider;
    current_start = floor(currentStart);
    int sizeOfEnvelope = sampleNeeded;
    int rawSizeOfEnvelope = floor(sampleNeeded/2) * skipCounts[forceLevel];
    // int sizeOfEnvelope = floor(envelopeSizes[forceLevel]/(divider / 6));
    // int rawSizeOfEnvelope = floor(envelopeSizes[forceLevel]/2/(divider / 6) * skipCounts[forceLevel]);
    // // int maxEnvelopeSize = floor(envelopeSizes[0]/2);
    int maxEnvelopeSize = floor(envelopeSizes[0]/2);
    int samplesLength = rawSizeOfEnvelope;
    int sampleStart = 0;
    int sampleEnd = samplesLength;

    std::copy(outSamplesPtr[channelIdx], outSamplesPtr[channelIdx] + maxEnvelopeSize, tempSamplesPtr[channelIdx]);
    // if (current_start != 0){
    //     int sampleStart = floor(envelopeSizes[0]/2) - current_start;
    //     if (sampleStart > floor(envelopeSizes[0]/2)) {
    //         sampleStart = floor(envelopeSizes[0]/2);
    //     }


    // }

    // return 0;

    try{
        for( int32_t i = 0; i < channelCount; i++ )
        {
            if (i == channelIdx){
                // int samplesLength = outSampleCounts[i];
                // for( int32_t j = 0; j < samplesLength; j++ ){
                // int samplesLength = current_start + rawSizeOfEnvelope;
                // for( int32_t j = current_start; j < samplesLength; j++ ){
                    
                sampleStart = 0;
                sampleEnd = samplesLength;
                if (current_start != 0){
                    sampleStart = abs(current_start);
                    if (sampleStart <0) {
                        sampleStart = 0;
                    }
                    sampleEnd = sampleStart + samplesLength;
                    if (sampleEnd > maxEnvelopeSize){
                    //     sampleEnd = maxEnvelopeSize;
                        // debug_print("sampleNeeded");
                        // debug_print(std::to_string(floor(sampleNeeded)).c_str());
                        // debug_print("sampleStart");
                        // debug_print(std::to_string(floor(sampleStart)).c_str());
                        // debug_print("sampleEnd");
                        // debug_print(std::to_string(floor(sampleEnd)).c_str());
                        // debug_print("sampleLength");
                        // debug_print(std::to_string(floor(samplesLength)).c_str());
                    //     debug_print("currentStart");
                    }
                }
                int j = 0;
                // resetEnvelope(channelIdx, envelopes[channelIdx], forceLevel);

                for( int32_t jj = sampleStart; jj < sampleEnd; jj++ ){
                    envelopingSamples(j,tempSamplesPtr[i][jj], envelopes[i], SIZE_LOGS2, forceLevel);
                    j++;
                }                

                // debug_print("forceLevel");
                // debug_print(std::to_string(floor(forceLevel)).c_str());
                // debug_print("forceLevel");
                // debug_print(std::to_string(floor(envelopeSizes[forceLevel])).c_str());
                // debug_print("sampleStart");
                // debug_print(std::to_string(floor(sampleStart)).c_str());
                // debug_print("sampleEnd");
                // debug_print(std::to_string(floor(sampleEnd)).c_str());
                // debug_print("sampleLength");
                // debug_print(std::to_string(floor(samplesLength)).c_str());
                // debug_print("currentStart");
                // debug_print(std::to_string(floor(current_start)).c_str());

                // for( int j = 0; j < rawSizeOfEnvelope; j++ ){
                //     // envelopingSamples(j,outSamplesPtr[i][j], envelopes[i], SIZE_LOGS2, forceLevel);
                //     int sample = envelopes[0][0][j];
                //     // debug_print(std::to_string(sample).c_str());
                //     if (forceLevel != 0){
                //         // envelopingSamples(int _head, int sample, short **_envelopes, int SIZE_LOGS2, int forceLevel) {
                //         envelopingSamples(j,sample,envelopes[0],  SIZE_LOGS2, forceLevel);
                //     }
                // }
            }
        }
        // int envelopeCurrentStart = floor(current_start / skipCounts[forceLevel]);
        std::copy(envelopes[channelIdx][forceLevel], envelopes[channelIdx][forceLevel] + sizeOfEnvelope, data);    
        resetEnvelope(channelIdx, envelopes[channelIdx], forceLevel);
        return sizeOfEnvelope;

    }catch(...){
        // debug_print("errror");
        return 0;
    }   

}

short initial = 1;

void task1()
{
    initial = 3;
    while (initial % 2 == 1 ){
        // t1::sleep_for(std::chrono::milliseconds(250));
        std::this_thread::sleep_for(std::chrono::milliseconds(250));

    }
}

void task2()
{
    while (initial == 3){
        initial = 5;
    }
        // debug_print("channelCount0" );
    while (initial % 2 == 1){
        // debug_print("channelCount" );
        // debug_print(std::to_string(initial).c_str() );
        // std::this_thread::sleep_for(std::chrono::milliseconds(50));
        // t2::sleep_for(std::chrono::milliseconds(250));
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        
    }
}

EXTERNC FUNCTION_ATTRIBUTE int getThresholdHitProcess(){
    std::thread t1(task1);
        // debug_print("channelCount0000" );
    std::thread t2(task2);

    // // Wait for t1 to finish
    t1.detach();
    std::this_thread::sleep_for(std::chrono::milliseconds(2500));
    t2.detach();
    // if (thresholdProcessor[0].thresholdHit == true){
    //     thresholdProcessor[0].thresholdHit = false;
    //     return 1;
    // }
    return 0;

/*
    int someInt = 5;
    std::thread t([&]() {
        while (true)
        {
            if (someInt == 5){
                someInt = 7;// 7 only 3 times then 0 and 1

            }
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
        }
    });

    t.detach();

    std::thread t2([&]() {
        while (true)
        {
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
            debug_print("channelCount" );
            debug_print(std::to_string(someInt).c_str() );
            // someInt *= 2;

        }
    });
    std::this_thread::sleep_for(std::chrono::milliseconds(1250));
    t2.detach();
*/    
    return 0;


}


EXTERNC FUNCTION_ATTRIBUTE double getAllChannelsData(
    short *data, uint32_t sampleCount, short *data2, uint32_t sampleCount2, short *data3, uint32_t sampleCount3, short *data4, uint32_t sampleCount4, short *data5, uint32_t sampleCount5, short *data6,  uint32_t sampleCount6, 
    short _channelCount, short _forceLevel, double divider, int currentStart, int sampleNeeded
){
    // debug_print("channelCount" );
    // debug_print(std::to_string(channelCount).c_str() );
    
    if (_channelCount != channelCount){
        channelCount = _channelCount;
        thresholdProcessor[0].setChannelCount(channelCount);        
    }else{
    }
    forceLevel = _forceLevel;

    current_start = currentStart;

    
    int rawSizeOfEnvelope = floor(sampleNeeded * skipCounts[forceLevel] / 2) ;
    //need to divide by 2 because Threshold data is not interleaved
    int maxEnvelopeSize = floor(envelopeSizes[0]/2);
    //need to divide by 2 because envelope sizes expanded by 2 to prevent jaggies signal
    int samplesLength = rawSizeOfEnvelope;
    int sampleStart = 0;
    int sampleEnd = samplesLength;
    int sizeOfEnvelope = floor(sampleNeeded);

    for( int32_t i = 0; i < channelCount; i++ )
    {
        int channelIdx = i;
        sampleStart = 0;
        sampleEnd = samplesLength;
        if (current_start != 0){
            sampleStart = floor(maxEnvelopeSize / 2 - samplesLength / 2);
            sampleEnd = floor(maxEnvelopeSize / 2 + samplesLength / 2)-1;

        }
        int j = 0;
        for( int32_t jj = sampleStart; jj < sampleEnd; jj++ ){
            envelopingSamples(j,outSamplesPtr[i][jj], envelopes[i], SIZE_LOGS2, forceLevel);
            j++;
        }

        int envelopeCurrentStart = 0;
        if (i==0){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data);
            }else{
                // std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data);
                // debug_print("SET TRIGGER TYPE ChannelIdx" );
                // debug_print(std::to_string(channelIdx).c_str() );
                // debug_print(std::to_string(forceLevel).c_str() );
                // return -1;
                std::copy(envelopes[channelIdx][forceLevel], envelopes[channelIdx][forceLevel] + sizeOfEnvelope, data);
            }
        }else
        if (i==1){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data2);
            }else{
                std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data2);
            }
        }else
        if (i==2){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data3);
            }else{
                std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data3);
            }            
        }else
        if (i==3){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data4);
            }else{
                std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data4);
            }            
        }else
        if (i==4){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data5);
            }else{
                std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data5);
            }            
        }else
        if (i==5){
            if (current_start < 0){
                int difPos = 0;
                std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data6);
            }else{
                std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data6);
            }            
        }

    }
    return sizeOfEnvelope;
}

EXTERNC FUNCTION_ATTRIBUTE double appendSamplesThresholdProcess(short _averagedSampleCount, short _threshold, short selectedChannel, short *data, uint32_t sampleCount, short *data2, uint32_t sampleCount2, short *data3, uint32_t sampleCount3, short *data4, uint32_t sampleCount4, short *data5, uint32_t sampleCount5, short *data6, uint32_t sampleCount6, short _channelCount, short _forceLevel, double divider, int currentStart, int sampleNeeded, 
    // short* eventIndices, short* events, short eventCount){
    short eventIndices, short events, short eventCount){
    // int sums[2]{0};

    if (_channelCount != channelCount){
        channelCount = _channelCount;
        thresholdProcessor[0].setChannelCount(channelCount);        
    }else{
        // channelCount = _channelCount;
    }
    forceLevel = _forceLevel;

    // debug_print("appendSamples1");
        
    current_start = currentStart;
    // int layers = ((int)_averagedSampleCount);
    // inSamplesPtr[0] = new short[sampleCount];
    inSampleCounts[0] = sampleCount;
    if (channelCount > 1){
        // inSamplesPtr[1] = new short[sampleCount2];
        inSampleCounts[1] = sampleCount2;
    }
    if (channelCount > 2){
        // inSamplesPtr[2] = new short[sampleCount3];
        inSampleCounts[2] = sampleCount3;
    }

    if (channelCount > 3){
        // inSamplesPtr[3] = new short[sampleCount4];
        inSampleCounts[3] = sampleCount4;
    }

    if (channelCount > 4){
        // inSamplesPtr[4] = new short[sampleCount5];
        inSampleCounts[4] = sampleCount5;
    }

    if (channelCount > 5){
        // inSamplesPtr[5] = new short[sampleCount6];
        inSampleCounts[5] = sampleCount6;
    }
    // debug_print("appendSamples2");
    // inSampleCounts[1] = sampleCount;
    thresholdProcessor[0].setThreshold(_threshold);
    thresholdProcessor[0].setAveragedSampleCount(_averagedSampleCount);
    // for (int c=0; c < channelCount; c++){
    //     resetOutSamples(c, outSamplesPtr,outSampleCounts[c]);
    // }
    // short *eventIndices = new short[eventCount];    
    // short *events = new short[eventCount];    
    // debug_print("appendSamples3");

// ****
    std::copy(data, data + sampleCount, inSamplesPtr[0]);
    if (channelCount > 1) std::copy(data2, data2 + sampleCount2, inSamplesPtr[1]);
    if (channelCount > 2) std::copy(data3, data3 + sampleCount3, inSamplesPtr[2]);
    if (channelCount > 3) std::copy(data4, data4 + sampleCount4, inSamplesPtr[3]);
    if (channelCount > 4) std::copy(data5, data5 + sampleCount5, inSamplesPtr[4]);
    if (channelCount > 5) std::copy(data6, data6 + sampleCount6, inSamplesPtr[5]);
    // std::copy(event, data + sampleCount, inSamplesPtr[0]);
    // std::copy(data, data + sampleCount, inSamplesPtr[0]);
    // debug_print("trying to envelope5");

// ****
    // std::copy(data, data + sampleCount, outSamplesPtr[0] + 10000);

    // std::copy(data, data + sampleCount, inSamplesPtr[1]);

    // debug_print((char *)"!!! inSamples");

    // debug_print("Threshold Process2 ");
    // thresholdProcessor[0].process(outSamplesPtr, layers, data, sampleCount, channelIdx, nullData,nullData,0);
    
// ****
    // void process(short **outSamples, int *outSamplesCounts, short **inSamples,
    //                                 const int *inSampleCounts,
    //                                 // const short *inEventIndices, const short *inEvents, const short inEventCount) {
    //                                 const short inEventIndices, const short inEvents, const short inEventCount) {

    // debug_print("selectedChannel");
    // debug_print(std::to_string(floor(selectedChannel)).c_str());

    thresholdProcessor[0].setSelectedChannel(selectedChannel);
    thresholdProcessor[0].process(outSamplesPtr,outSampleCounts, inSamplesPtr, inSampleCounts, eventIndices, events, eventCount);
    // debug_print("appendSamples4");

// ****

    // for (short i = 0;i<count ; i++){
    //     data[i] = i;
    // }
    // debug_print((char *)"!!! end process");
    // short results[sampleCount];
    // for( int32_t i = 0; i < channelCount; i++ )
    // debug_print("trying to envelope");

    // int rawSizeOfEnvelope = floor(envelopeSizes[forceLevel]/2/(divider / 6) * skipCounts[forceLevel]);
    // debug_print("channelCount");
    // debug_print(std::to_string(floor(channelCount)).c_str());

    // debug_print("sampleLength");
    // debug_print(std::to_string(floor(samplesLength)).c_str());
    // debug_print("sampleNeeded");
    // debug_print(std::to_string(floor(sampleNeeded)).c_str());
    // debug_print("sampleRawNeeded");
    // debug_print(std::to_string(floor(sampleNeeded * skipCounts[forceLevel])).c_str());
    // debug_print("maxEnvelopeSize");
    // debug_print(std::to_string(floor(maxEnvelopeSize)).c_str());
    // debug_print("samplerate * timespance");
    // debug_print(std::to_string(floor(sampleRate * timeSpan)).c_str());

    // int sizeOfEnvelope = floor(envelopeSizes[forceLevel]/(divider/6));
    int sizeOfEnvelope = floor(sampleNeeded);
    return sizeOfEnvelope;

    
    // delete[] inSamplesPtr[0];
    // if (channelCount > 1) delete[] inSamplesPtr[1];
    // if (channelCount > 2) delete[] inSamplesPtr[2];
    // if (channelCount > 3) delete[] inSamplesPtr[3];
    // if (channelCount > 4) delete[] inSamplesPtr[4];
    // if (channelCount > 5) delete[] inSamplesPtr[5];

    // return sizeOfEnvelope;

    // debug_print(std::to_string(outSampleCounts[0]).c_str());
    // debug_print("trying to envelope2");
    
//  ****
    // std::copy(outSamplesPtr[channelIdx], outSamplesPtr[channelIdx] + count, data);   

/*  more than one channel fixes
    int sizeOfEnvelope = floor(envelopeSizes[forceLevel]/(divider/6));
    std::fill(envelopes[channelIdx][forceLevel]+ sizeOfEnvelope, envelopes[channelIdx][forceLevel] + sizeOfEnvelope * 2, 0);
    int envelopeCurrentStart = 0;
    // debug_print(std::to_string(sizeOfEnvelope).c_str() );
    if (current_start < 0){
    //     // short *tempData = new short[floor(envelopeSizes[forceLevel] * 2)];
        int skipCount = skipCounts[forceLevel];
        // int difPos = floor( (abs(current_start) * 2 / skipCount)/2 );
        int difPos = 0;
    //     // int resSampleStart = 0;
    //     // int resSampleLength = sizeOfEnvelope;
    //     std::fill(tempData, tempData + sizeOfEnvelope * 2, 0);        
    //     std::copy(envelopes[channelIdx][forceLevel], envelopes[channelIdx][forceLevel]+sizeOfEnvelope, tempData + difPos);
    //     std::copy(tempData + difPos, tempData + difPos + sizeOfEnvelope, data);
        std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data);
    //     // delete tempData;
    }else{
        std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data);
    }
*/
    // resetEnvelope(channelIdx, envelopes[0], forceLevel);
//  ****

    // std::copy(outSamplesPtr[channelIdx], outSamplesPtr[channelIdx] + count, data);



    // std::copy(inSamplesPtr[0], inSamplesPtr[0] + sampleCount, data);

    // delete[] outSamplesPtr[0];
    // // delete[] outSamplesPtr[1];
    // delete[] outSampleCounts;

    // // delete[] inSamplesPtr[1];
    // delete[] inSampleCounts;

    // return results;
    // highPassFilters[channelIdx].filter(data, sampleCount, false);
    // debug_print("APPLYING THRESHOLD ");
    // delete[] inSamplesPtr[0];
    // return sizeOfEnvelope;
}


//Namespac
// namespace dart {

////////////////////////////////////////////////////////////////////////////////
// Initialize `dart_api_dl.h`
// intptr_t (*my_callback_blocking_fp_)(intptr_t);
// Dart_Port my_callback_blocking_send_port_;

// // static void FreeFinalizer(void*, void* value) {
// //   free(value);
// // }

// DART_EXPORT intptr_t InitDartApiDL(void* data) {
// C++ to Flutter
// EXTERNC FUNCTION_ATTRIBUTE intptr_t InitDartApiDL(void* data) {
//   return Dart_InitializeApiDL(data);
// // return 1;
// }

// // void NotifyDart(Dart_Port send_port) {
// // //   printf("C   :  Posting message (port: %" Px64 ", work: %" Px ").\n",
// // //          send_port, work_addr);

// //   Dart_CObject dart_object;
// //   dart_object.type = Dart_CObject_kInt64;
// // //   dart_object.value.as_int64 = work_addr;

// //   const bool result = Dart_PostCObject_DL(send_port, &dart_object);
// //   if (!result) {
// //     // FATAL("C   :  Posting message to port failed.");
// //   }
// // }

// intptr_t MyCallbackBlocking(intptr_t a) {
//   std::mutex mutex;
//   std::unique_lock<std::mutex> lock(mutex);
//   intptr_t result = 2;
// //   auto callback = my_callback_blocking_fp_;  // Define storage duration.
//   std::condition_variable cv;
// //   bool notified = false;
// //   const Work work = [a, &result, callback, &cv, &notified]() {
// //     result = callback(a);
// //     printf("C Da:     Notify result ready.\n");
// //     notified = true;
// //     cv.notify_one();
// //   };
// //   const Work* work_ptr = new Work(work);  // Copy to heap.
// //   NotifyDart(my_callback_blocking_send_port_);
//   printf("C   :  Waiting for result.\n");
// //   while (!notified) {
// //     cv.wait(lock);
// //   }
//   printf("C   :  Received result.\n");
//   return result;
// }

// DART_EXPORT void RegisterMyCallbackBlocking(Dart_Port send_port,
//                                             intptr_t (*callback1)(intptr_t)) {
//   my_callback_blocking_fp_ = callback1;
//   my_callback_blocking_send_port_ = send_port;
//   my_callback_blocking_fp_(123);
//   Dart_CObject dart_object;
//   dart_object.type = Dart_CObject_kInt64;
//   dart_object.value.as_int64 = work_addr;

//   const bool result = Dart_PostCObject_DL(send_port, &dart_object);
//   if (!result) {
//     FATAL("C   :  Posting message to port failed.");
//   }  
// }

// }
//Namespac
    // void envelope(short **outSamples, int *outSampleCount, float *outEventIndices,
    //                             int &outEventIndicesCount, short **inSamples, int channelCount,
    //                             const int *inEventIndices, int inEventIndicesCount, int fromSample, int toSample,
    //                             int drawSurfaceWidth) {
    //     int drawSamplesCount = toSample - fromSample;
    //     if (drawSamplesCount < drawSurfaceWidth) drawSurfaceWidth = drawSamplesCount;

    //     short sample;
    //     short min = SHRT_MAX, max = SHRT_MIN;
    //     int samplesPerPixel = drawSamplesCount / drawSurfaceWidth;
    //     int samplesPerPixelRest = drawSamplesCount % drawSurfaceWidth;
    //     int samplesPerEnvelope = samplesPerPixel * 2; // multiply by 2 because we save min and max
    //     int envelopeCounter = 0, sampleIndex = 0, eventCounter = 0, eventIndex = 0;
    //     bool eventsProcessed = false;

    //     int from = fromSample;
    //     int to = fromSample + drawSamplesCount;
    //     for (int i = 0; i < channelCount; i++) {
    //         for (int j = from; j < to; j++) {
    //             sample = inSamples[i][j];
    //             if (!eventsProcessed) {
    //                 for (int k = 0; k < inEventIndicesCount; k++) {
    //                     if (j == inEventIndices[k]) {
    //                         eventCounter++;
    //                     } else {
    //                         if (j < inEventIndices[k]) break;
    //                     }
    //                 }
    //             }

    //             // if (samplesPerPixel == 1 && samplesPerPixelRest == 0) {
    //             //     if (eventCounter > 0) {
    //             //         for (int k = 0; k < eventCounter; k++) {
    //             //             outEventIndices[eventIndex++] = sampleIndex;
    //             //         }
    //             //     }
    //             //     outSamples[i][sampleIndex++] = sample;

    //             //     eventCounter = 0;
    //             // } else {
    //                 if (sample > max) max = sample;
    //                 if (sample < min) min = sample;
    //                 if (envelopeCounter == samplesPerEnvelope) {
    //                     if (eventCounter > 0) {
    //                         for (int k = 0; k < eventCounter; k++) {
    //                             outEventIndices[eventIndex++] = sampleIndex;
    //                         }
    //                     }
    //                     outSamples[i][sampleIndex++] = max;
    //                     outSamples[i][sampleIndex++] = min;

    //                     envelopeCounter = 0;
    //                     min = SHRT_MAX;
    //                     max = SHRT_MIN;
    //                     eventCounter = 0;
    //                 }

    //                 envelopeCounter++;
    //             // }
    //         }

    //         outSampleCount[i] = sampleIndex;
    //         if (!eventsProcessed) outEventIndicesCount = eventIndex;

    //         eventsProcessed = true;
    //         sampleIndex = 0;
    //         eventIndex = 0;
    //         envelopeCounter = 0;
    //         min = SHRT_MAX;
    //         max = SHRT_MIN;
    //     }
    // }

#endif



