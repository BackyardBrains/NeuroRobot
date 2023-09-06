#ifndef SPIKE_RECORDER_ANDROID_PROCESSOR_H
#define SPIKE_RECORDER_ANDROID_PROCESSOR_H

class Processor {
public:
    Processor(float sampleRate, int channelCount, int bitsPerSample) {
        Processor::sampleRate = sampleRate;
        Processor::channelCount = channelCount;
        Processor::bitsPerSample = bitsPerSample;
        // Stev
        // createFilters(0, channelCount);

        initialized = true;
    }
    Processor() : Processor(DEFAULT_SAMPLE_RATE, DEFAULT_CHANNEL_COUNT, DEFAULT_BITS_PER_SAMPLE) {}

    virtual ~Processor() = default;

    virtual void setSampleRate(float _sampleRate) {
        // Stev
        // if (initialized) deleteFilters(channelCount);
        sampleRate = _sampleRate;
        // Stev
        // createFilters(sampleRate, channelCount);
    }

    virtual void setChannelCount(int _channelCount) {
        // if (initialized) deleteFilters(Processor::channelCount);
        channelCount = _channelCount;

        // createFilters(Processor::sampleRate, channelCount);
    }

    virtual void setBitsPerSample(int bitsPerSample){};

    void setSelectedChannel(int selectedChannel) {
        Processor::selectedChannel = selectedChannel;
    }

    // void setBandFilter(float lowCutOffFreq, float highCutOffFreq);

    // void setNotchFilter(float centerFreq);
    float getSampleRate() {
        return sampleRate;
    }

protected:

    int getChannelCount() {
        return channelCount;
    }

    int getBitsPerSample() {
        return bitsPerSample;
    }

    int getSelectedChannel() {
        return selectedChannel;
    }


    void setSampleRateAndChannelCount(float sampleRate, int _channelCount) {
        // __android_log_print(ANDROID_LOG_DEBUG, typeid(*this).name(), "SAMPLE RATE: %1f, CHANNEL COUNT: %1d",
                            // sampleRate, channelCount);

        // if (initialized) deleteFilters(Processor::channelCount);
        channelCount = _channelCount;

        // createFilters(Processor::sampleRate, channelCount);
    }

    void applyFilters(int channel, short *data, int sampleCount) {
        // if (lowPassFilteringEnabled) lowPassFilter[channel]->filter(data, sampleCount);
        // if (highPassFilteringEnabled) highPassFilter[channel]->filter(data, sampleCount);
        // if (notchFilteringEnabled) notchFilter[channel]->filter(data, sampleCount);
    }

private:
    // // Minimum cut-off frequency
    // static constexpr float MIN_FILTER_CUT_OFF = 0.0f;
    // // Maximum cut-off frequency
    // static constexpr float MAX_FILTER_CUT_OFF = 5000.0f;
    // Default sample rate we start with
    static constexpr float DEFAULT_SAMPLE_RATE = 44100.0f;
    // // Default channel count
    static constexpr int DEFAULT_CHANNEL_COUNT = 1;
    // Default number of bits  per sample
    static constexpr int DEFAULT_BITS_PER_SAMPLE = 16;

    // void createFilters(float sampleRate, int channelCount);

    // void deleteFilters(int channelCount);

    // typedef LowPassFilter *LowPassFilterPtr;
    // typedef HighPassFilter *HighPassFilterPtr;
    // typedef NotchFilter *NotchFilterPtr;

    // Flag that is set to true after initialization
    bool initialized = false;
    // Current sample rate
    float sampleRate = DEFAULT_SAMPLE_RATE;
    // Current channel count
    int channelCount = DEFAULT_CHANNEL_COUNT;
    // Current number of bits per sample
    int bitsPerSample = DEFAULT_BITS_PER_SAMPLE;
    // Index of currently selected channel
    int selectedChannel = 0;
    // Current low pass filter high cutoff frequency
    // float highCutOff = MAX_FILTER_CUT_OFF;
    // // Whether low pass filters should be applied
    // bool lowPassFilteringEnabled = false;
    // // Low pass filters for all channels
    // LowPassFilterPtr *lowPassFilter;
    // // Current high pass filter low cutoff frequency
    // float lowCutOff = MIN_FILTER_CUT_OFF;
    // // Whether high pass filters should be applied
    // bool highPassFilteringEnabled = false;
    // // High pass filters for all channels
    // HighPassFilterPtr *highPassFilter;
    // // Current notch filter center freq
    // float centerFrequency = MIN_FILTER_CUT_OFF;
    // // Whether notch filters should be applied
    // bool notchFilteringEnabled = false;
    // // Notch filters for all channels
    // NotchFilterPtr *notchFilter;
};


#endif