#include <emscripten/bind.h>
using namespace emscripten;

#ifndef SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H
#define SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H

#include <algorithm>
#include <cmath>
#include <climits>
#include "Processor.cpp"
#include "HeartbeatHelper.cpp"
#include <string>

// #include "include/dart_api.h"
// #include "include/dart_native_api.h"
// #include "include/dart_api_dl.h"
#include <mutex>    
#include <condition_variable>

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
    ThresholdProcessor(OnHeartbeatListener *listener){
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
    }

    // Starts/stops processing heartbeat
    void setBpmProcessing(bool _processBpm) {
        if (processBpm == _processBpm) return;

        // reset BPM if we stopped processing heartbeat
        if (!_processBpm) resetBpm();

        processBpm = _processBpm;
    }
    void process(short **outSamples, int *outSamplesCounts, short **inSamples,
                                    const int *inSampleCounts,
                                    const int *inEventIndices, const int *inEvents, const int inEventCount) {
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
        // loop through incoming samples and listen for the threshold hit
        for (i = 0; i < inSampleCounts[selectedChannel]; i++) {
            currentSample = inSamples[selectedChannel][i];

            // heartbeat processing Can't add incoming to buffer, it's larger then buffer
            if (processBpm && triggerType == TRIGGER_ON_THRESHOLD) {
                sampleCounter++;
                lastTriggerSampleCounter++;

                // check if minimum BPM reset period passed after last threshold hit and reset if necessary
                if (lastTriggerSampleCounter > minBpmResetPeriodCount) resetBpm();
            }
            // end of heartbeat processing

            if (triggerType == TRIGGER_ON_THRESHOLD) { // triggering by a threshold value
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
                        for (j = 0; j < channelCount; j++) {
                            prepareNewSamples(inSamples[j], inSampleCounts[j], j, i);
                        }

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
            } else if (inEventCount > 0) { // triggering on events
                // debug_print("Event Trigger");

                for (j = 0; j < inEventCount; j++) {
                    if (triggerType == TRIGGER_ON_EVENTS) {
                        if (i == inEventIndices[j]) {
                            // create new samples for current threshold
                            for (k = 0; k < channelCount; k++) {
                                prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                            }
                        }
                    } else {
                        if (i == inEventIndices[j] && triggerType == inEvents[j]) {
                            // create new samples for current threshold
                            for (k = 0; k < channelCount; k++) {
                                prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                            }
                        }
                    }
                }
            }

            prevSample = currentSample;
        }

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







ThresholdProcessor thresholdProcessor[6];


int count;
short ***envelopes = new short**[6];
short **outSamplesPtr = new short*[1];
short **tempSamplesPtr = new short*[1];
int *outSampleCounts = new int[1];
short *outEventIndicesPtr = new short[1];
std::string *outEventNamesPtr = new std::string[1];

short **inSamplesPtr = new short*[1];
int *inSampleCounts = new int[1];

const int SIZE_LOGS2 = 12;
float envelopeSizes[SIZE_LOGS2];
int forceLevel = 9;
short channelCount;
double sampleRate;
// const int skipCounts[10] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512};
//if isWeb
const int skipCounts[12] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048};

double divider = 6;
int current_start = 0;
short *tempData;

EXTERNC FUNCTION_ATTRIBUTE double createThresholdProcess(short _channelCount, uint32_t _sampleRate, short averagedSampleCount, short threshold){
    // highPassFilters = new HighPassFilter[channelCount];
    // count = (int) 2.0f * sampleRate;
    // debug_print("create1");
    sampleRate = (double) _sampleRate;

    channelCount = _channelCount;

    count = (int) timeSpan * sampleRate;
    outSamplesPtr[0] = new short[count * 2];
    tempSamplesPtr[0] = new short[count * 2];
    outSampleCounts[0]=count;

    for( int32_t i = 0; i < channelCount; i++ )
    {
        HeartbeatListener* hb = (new HeartbeatListener());
        thresholdProcessor[i] = ThresholdProcessor( hb );
        float sr = (float) sampleRate;
        thresholdProcessor[i].setSampleRate(sr);
        thresholdProcessor[i].setAveragedSampleCount(averagedSampleCount);
        thresholdProcessor[i].setThreshold(threshold);
    }

    sampleRate = _sampleRate;

    for (int i = 0; i < _channelCount; i++){
        envelopes[i] = new short*[SIZE_LOGS2];
    }

    const int NUMBER_OF_SEGMENTS = timeSpan;
    double SEGMENT_SIZE = sampleRate;
    double SIZE = (NUMBER_OF_SEGMENTS * SEGMENT_SIZE);

    double size = SIZE * 4;
    for (int i = 0; i < SIZE_LOGS2; i++) {
        for (int j = 0 ; j < channelCount ; j++){

            envelopes[j][i] = new short[size];
        }
        size /= 2;
        envelopeSizes[i] = (size);
    }

    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double initThresholdProcess(short channelCount, double sampleRate, double highCutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
    }
    return 1;
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
            envelopes[i] = new short*[SIZE_LOGS2];
        }
        // debug_print("setThresholdParameters 2");

        const int NUMBER_OF_SEGMENTS = timeSpan;
        double SEGMENT_SIZE = sampleRate;
        double SIZE = (NUMBER_OF_SEGMENTS * SEGMENT_SIZE);
        // debug_print("setThresholdParameters 3");

        double size = SIZE * 2;
        //if (isWeb)
        size = size / 4;
        for (int i = 0; i < SIZE_LOGS2; i++) {
            envelopeSizes[i] = (size);
            for (int j = 0 ; j < channelCount ; j++){

                envelopes[j][i] = new short[size];
            }
            size /= 2;
        }

    }

    return 1;
}

int* nullData;
void resetEnvelope(short channelIdx, short **envelopes, int forceLevel){
    int sizeOfEnvelope = floor(2*envelopeSizes[forceLevel]);
    std::fill(envelopes[forceLevel], envelopes[forceLevel] + sizeOfEnvelope, 0);
}
void resetOutSamples(short channelIdx, short **outSamples, int outSampleCount){
    
    std::fill(outSamples[channelIdx], outSamples[channelIdx] + outSampleCount, 0);
}


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
EXTERNC FUNCTION_ATTRIBUTE auto getSamplesThresholdProcess(short channelIdx, const val &data, short forceLevel,double _divider, int currentStart, int sampleNeeded){

    divider = _divider;
    current_start = floor(currentStart);
    int sizeOfEnvelope = sampleNeeded;
    int rawSizeOfEnvelope = floor(sampleNeeded/2) * skipCounts[forceLevel];

    int maxEnvelopeSize = floor(envelopeSizes[0]/2);
    int samplesLength = rawSizeOfEnvelope;
    int sampleStart = 0;
    int sampleEnd = samplesLength;

    std::copy(outSamplesPtr[channelIdx], outSamplesPtr[channelIdx] + maxEnvelopeSize, tempSamplesPtr[channelIdx]);



    try{
        for( int32_t i = 0; i < channelCount; i++ )
        {
            if (i == channelIdx){

                sampleStart = 0;
                sampleEnd = samplesLength;
                if (current_start != 0){
                    sampleStart = abs(current_start);
                    if (sampleStart <0) {
                        sampleStart = 0;
                    }
                    sampleEnd = sampleStart + samplesLength;
                    if (sampleEnd > maxEnvelopeSize){
                    }
                }
                int j = 0;
                resetEnvelope(channelIdx, envelopes[channelIdx], forceLevel);

                for( int32_t jj = sampleStart; jj < sampleEnd; jj++ ){
                    envelopingSamples(j,tempSamplesPtr[i][jj], envelopes[i], SIZE_LOGS2, forceLevel);
                    j++;
                }                
            }
        }
        // int envelopeCurrentStart = floor(current_start / skipCounts[forceLevel]);
        // std::copy(envelopes[channelIdx][forceLevel], envelopes[channelIdx][forceLevel] + sizeOfEnvelope, data);    
        val view{ typed_memory_view(sizeOfEnvelope, envelopes[channelIdx][forceLevel]) };
        auto result = val::global("Int16Array").new_(sizeOfEnvelope);
        result.call<void>("set", view);

        resetEnvelope(channelIdx, envelopes[channelIdx], forceLevel);
        
        return result;

    }catch(...){
        // debug_print("errror");
        auto result = val::global("Int16Array").new_(1);
        return result;
    }   

}

EXTERNC FUNCTION_ATTRIBUTE int getThresholdHitProcess(){
    if (thresholdProcessor[0].thresholdHit == true){
        thresholdProcessor[0].thresholdHit = false;
        return 1;
    }
    return 0;
}
EXTERNC FUNCTION_ATTRIBUTE auto appendSamplesThresholdProcess(short _averagedSampleCount, short _threshold, short channelIdx, const val &data, uint32_t sampleCount, double divider, int currentStart, int sampleNeeded){
    std::vector<short> raw = convertJSArrayToNumberVector<short>(data); 
    // val view{ typed_memory_view(raw.size(), raw.data()) };
    // auto result = val::global("Int16Array").new_(raw.size());
    // result.call<void>("set", view);

    current_start = currentStart;
    // inSamplesPtr[0] = new short[sampleCount];
    inSamplesPtr[0] = raw.data();
    inSampleCounts[0] = sampleCount;
    thresholdProcessor[0].setThreshold(_threshold);
    thresholdProcessor[0].setAveragedSampleCount(_averagedSampleCount);
    resetOutSamples(0, outSamplesPtr,outSampleCounts[0]);

    // std::copy(data, data + sampleCount, inSamplesPtr[0]);

    thresholdProcessor[0].process(outSamplesPtr,outSampleCounts, inSamplesPtr, inSampleCounts, nullData, nullData, 0);
    int rawSizeOfEnvelope = floor(sampleNeeded/2) * skipCounts[forceLevel];
    int maxEnvelopeSize = floor(envelopeSizes[0]/2);
    int samplesLength = rawSizeOfEnvelope;
    int sampleStart = 0;
    int sampleEnd = samplesLength;
    // debug_print("sampleLength");
    // debug_print(std::to_string(floor(samplesLength)).c_str());
    std::copy(outSamplesPtr[channelIdx], outSamplesPtr[channelIdx] + maxEnvelopeSize, tempSamplesPtr[channelIdx]);
    for( int32_t i = 0; i < channelCount; i++ )
    {
        if (i == channelIdx){
            sampleStart = 0;
            sampleEnd = samplesLength;

            if (current_start != 0){
                sampleStart = abs(current_start);
                if (sampleStart <0) {
                    sampleStart = 0;
                }
                sampleEnd = sampleStart + samplesLength;
                if (sampleEnd > maxEnvelopeSize){
                }
            }
            resetEnvelope(i,envelopes[i], forceLevel);
            int j = 0;
            for( int32_t jj = sampleStart; jj < sampleEnd; jj++ ){
                envelopingSamples(j,tempSamplesPtr[i][jj], envelopes[i], SIZE_LOGS2, forceLevel);
                j++;
            }

        }
    }
    // int sizeOfEnvelope = floor(envelopeSizes[forceLevel]/(divider/6));
    int sizeOfEnvelope = sampleNeeded;

    // suffix
    std::fill(envelopes[0][forceLevel]+ sizeOfEnvelope, envelopes[0][forceLevel] + sizeOfEnvelope * 2, 0);
    int envelopeCurrentStart = 0;
    // debug_print(std::to_string(sizeOfEnvelope).c_str() );
    if (current_start < 0){
        // std::fill(envelopes[0][forceLevel], envelopes[0][forceLevel]+sizeOfEnvelope, 1000);
        if (forceLevel == 4){
            std::fill(envelopes[0][forceLevel], envelopes[0][forceLevel]+sizeOfEnvelope, skipCounts[forceLevel]);
        }
        int skipCount = skipCounts[forceLevel];
        int difPos = 0;
        val view{ typed_memory_view(sizeOfEnvelope, envelopes[channelIdx][forceLevel]) };
        auto result = val::global("Int16Array").new_(sizeOfEnvelope);
        result.call<void>("set", view);
        // resetEnvelope(channelIdx, envelopes[0], forceLevel);
        delete[] inSamplesPtr[0];
        // return sizeOfEnvelope;
        return result;

        // std::copy(envelopes[channelIdx][forceLevel]+difPos, envelopes[channelIdx][forceLevel] + difPos + sizeOfEnvelope, data);
    }else{
        if (forceLevel == 4){
            std::fill(envelopes[0][forceLevel], envelopes[0][forceLevel]+sizeOfEnvelope, skipCounts[forceLevel]);
        }
        val view{ typed_memory_view(sizeOfEnvelope, envelopes[channelIdx][forceLevel]) };
        auto result = val::global("Int16Array").new_(sizeOfEnvelope);
        result.call<void>("set", view);
        // resetEnvelope(channelIdx, envelopes[0], forceLevel);
        delete[] inSamplesPtr[0];
        // return sizeOfEnvelope;
        return result;

        // std::copy(envelopes[channelIdx][forceLevel]-envelopeCurrentStart, envelopes[channelIdx][forceLevel] - envelopeCurrentStart + sizeOfEnvelope, data);
    }

}

#endif



EMSCRIPTEN_BINDINGS(my_module) {
  class_<ThresholdProcessor>("ThresholdProcessor")
    .constructor()
    // .function("calculateCoefficients", &ThresholdProcessor::calculateCoefficients)
    // .function("setCornerFrequency", &ThresholdProcessor::setCornerFrequency)
    // .function("setQ", &ThresholdProcessor::setQ)
    ;
    function("createThresholdProcess", &createThresholdProcess);
    function("initThresholdProcess", &initThresholdProcess);
    function("setThresholdParametersProcess", &setThresholdParametersProcess);
    function("getSamplesThresholdProcess", &getSamplesThresholdProcess);
    function("getThresholdHitProcess", &getThresholdHitProcess);
    function("appendSamplesThresholdProcess", &appendSamplesThresholdProcess);
    // register_vector<short>("vector<short>");
    // register_vector<short>("LowPassList");
}