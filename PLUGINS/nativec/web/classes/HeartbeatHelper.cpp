#include <string.h>

class OnHeartbeatListener {
public:
    virtual void onHeartbeat(int bmp) = 0;
};

class HeartbeatHelper {
public:
    char *TAG = strdup("HeartbeatHelper");
    // HeartbeatHelper(float sampleRate, OnHeartbeatListener *listener);
    HeartbeatHelper(float sampleRate, OnHeartbeatListener *_listener) {
        listener = _listener;

        setSampleRate(sampleRate);
    }

    // ~HeartbeatHelper();
    ~HeartbeatHelper() = default;    

    /**
     * "Pushes" a new beat that's triggered at {@code sampleIndex} sample.
     */
    // void beat(int sampleIndex);
    void beat(int sampleIndex) {
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "beat()");

        int diffFromPrevBeat = sampleIndex - prevSampleIndex;
        // we shouldn't process beat if dead period didn't pass
        if (diffFromPrevBeat < deadPeriodSampleCount) {
            // __android_log_print(ANDROID_LOG_DEBUG, TAG, "Difference between two beats is less than 0.2s");
            // __android_log_print(ANDROID_LOG_DEBUG, TAG, "CURRENT: %d, PREV: %d", sampleIndex, prevSampleIndex);
            // __android_log_print(ANDROID_LOG_DEBUG, TAG, "DIFF FROM PREV: %d, DEAD PERIOD: %d", diffFromPrevBeat,
            //                     deadPeriodSampleCount);
            return;
        }
        // we should reset if time difference between current and last beat is longer then required
        if (diffFromPrevBeat > maxDiffBetweenBeatsSampleCount) {
            // __android_log_print(ANDROID_LOG_DEBUG, TAG, "Difference between two beats is more than 2.5s");
            // reset all local variables so we can restart the calculation
            reset();
            // save current sample index for next calculation
            prevSampleIndex = sampleIndex;

            return;
        }

        // store difference between last two beats
    //    diffs.add(diffFromPrevBeat);
        diffs[diffsCounter++] = diffFromPrevBeat;
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "DIFFS COUNTER: %d", diffsCounter);
        // we need at least 2 beats to start calculation
        if (/*diffs.size()*/diffsCounter < MIN_NUMBER_OF_BEATS) {
            // __android_log_print(ANDROID_LOG_DEBUG, TAG, "There is less then 2 collected diffs");
            // we can just save difference because prevSampleIndex is 0
            sampleCount = diffFromPrevBeat;
            // save current sample index for next calculation
            prevSampleIndex = sampleIndex;
            // post to UI that we're still at 0 BPM
            listener->onHeartbeat(0);

            return;
        }

        int tmpSampleCount = sampleCount + diffFromPrevBeat;
        if (tmpSampleCount > maxSampleCount) {
            int counter = 0;
            while ((tmpSampleCount = tmpSampleCount - diffs[counter]/*diffs.get(counter)*/) > maxSampleCount) {
                counter++;
            }
    //        if (counter < diffs.size()) diffs = new ArrayList<>(diffs.subList(counter + 1, diffs.size()));
            if (counter < diffsCounter) {
                // std::move(diffs + counter + 1, diffs + diffsCounter, diffs);
                diffsCounter -= counter + 1;
            }
        }

        sampleCount = tmpSampleCount;
        int bpm = minute / (sampleCount / diffsCounter/*diffs.size()*/);
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "BPM: %d", bpm);
        // tell UI what is the current bpm
        listener->onHeartbeat(bpm);

        prevSampleIndex = sampleIndex;
    }


    /**
     * Sets the current sample rate.
     */
    // void setSampleRate(float sampleRate);
    void setSampleRate(float _sampleRate) {
        // __android_log_print(ANDROID_LOG_DEBUG, TAG, "SAMPLE RATE: %1f", sampleRate);

        if (sampleRate <= 0 || sampleRate == _sampleRate) return;

        sampleRate = _sampleRate;

        // sample rate is changed, we should reset
        reset();
    }


    /**
     * Resets all internal counters so processing can re-start. The caller that's "pushing" the beats should reset it's
     * own sample counter otherwise all future calculations from this moment on will be inaccurate.
     */
    // void reset();
    void reset() {
        maxSampleCount = (int) (sampleRate * DEFAULT_PROCESSING_SECONDS);
        deadPeriodSampleCount = (int) (sampleRate * DEFAULT_DEAD_PERIOD_SECONDS);
        maxDiffBetweenBeatsSampleCount = (int) (sampleRate * DEFAULT_MAX_DIFF_BETWEEN_BEATS_SECONDS);
        minute = (int) (sampleRate * 60);

        delete[] diffs;
        diffs = new int[DIFFS_COUNT]{0};
        diffsCounter = 0;
        sampleCount = 0;
        prevSampleIndex = 0;

        // we reset everything so tell UI that BPM is 0
        listener->onHeartbeat(0);
    }    

private:
    // static const char *TAG;

    // By default we shouldn't process more than 1 seconds of samples in any given moment
    static constexpr float DEFAULT_PROCESSING_SECONDS = 6.0f;
    // When one heartbeat ends by default we should have a dead period of 0.2s before checking for next heartbeat
    static constexpr float DEFAULT_DEAD_PERIOD_SECONDS = 0.2f;
    // If current heartbeat happens by default 2.5s after previous one we don't want to take it into account
    static constexpr float DEFAULT_MAX_DIFF_BETWEEN_BEATS_SECONDS = 2.5f;
    // Default sample rate we start with
    static constexpr float DEFAULT_SAMPLE_RATE = 44100.0f;
    // The minimum number of beats we want to have before start processing
    static const int MIN_NUMBER_OF_BEATS = 2;
    // Max number of diffs we save
    static const int DIFFS_COUNT = 100;

    // Listener that's being invoked every time bpm is triggered
    OnHeartbeatListener *listener;

    // Current sample rate
    float sampleRate = DEFAULT_SAMPLE_RATE;
    // Number of samples processed at once
    int maxSampleCount = (int) (sampleRate * DEFAULT_PROCESSING_SECONDS);
    // Number of samples we should skip processing (dead period)
    int deadPeriodSampleCount = (int) (sampleRate * DEFAULT_DEAD_PERIOD_SECONDS);
    // Number of samples between two consecutive beats
    int maxDiffBetweenBeatsSampleCount = (int) (sampleRate * DEFAULT_MAX_DIFF_BETWEEN_BEATS_SECONDS);
    // Number of samples in one minute
    int minute = (int) (sampleRate * 60);

    int *diffs = new int[DIFFS_COUNT]{0};
    int diffsCounter = 0;
    int sampleCount = 0;
    int prevSampleIndex = 0;
};








