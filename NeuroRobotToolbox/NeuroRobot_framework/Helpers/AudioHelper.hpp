//
//  AudioHelper.hpp
//  NeuroRobot-Framework
//
//  Created by Djordje Jovic on 14/02/2020.
//  Copyright © 2020 Backyard Brains. All rights reserved.
//

#ifndef AudioHelper_hpp
#define AudioHelper_hpp

#include <iostream>

/// Helper for handling audio data
class AudioHelper
{
private:
    
    /// Convert the scaled magnitude to segment number.
    /// @param val Value to convert
    /// @param table All data
    /// @param size Size of table
    static int search(int val, int table[], int size)
    {
        for (int i = 0; i < size; i++) {
            if (val <= table[i]) {
                return i;
            }
        }
        return size;
    }
    
    /// Convert linear PCM audio chunk to ulaw format.
    /// @param pcmChunk One chunk of PCM audio data
    /// @return Converted chunk of audio data
    /// @see https://en.wikipedia.org/wiki/Μ-law_algorithm
    
    static uint8_t linear2ulaw(int pcmChunk)
    {
        int BIAS = 0x84;
        int seg_end[] = { 0xFF, 0x1FF, 0x3FF, 0x7FF, 0xFFF, 0x1FFF, 0x3FFF, 0x7FFF };
        
        int mask;
        int seg;
        char uval;
        
        /* Get the sign and the magnitude of the value. */
        if (pcmChunk < 0) {
            pcmChunk = BIAS - pcmChunk;
            mask = 0x7F;
        } else {
            pcmChunk += BIAS;
            mask = 0xFF;
        }
        
        /* Convert the scaled magnitude to segment number. */
        seg = search(pcmChunk, seg_end, 8);
        
        /*
         * Combine the sign, segment, quantization bits;
         * and complement the code word.
         */
        if (seg >= 8) /* out of range, return maximum value. */
            return (0x7F ^ mask);
        else {
            uval = (uint8_t)((seg << 4) | ((pcmChunk >> (seg + 3)) & 0xF));
            return (uval ^ mask);
        }
    }
    
public:
    
    /// Rapack forwarded audio data.
    /// It creates two channels from one and rapcks signed 16bit linear signal to unsigned 8bit ulaw signal.
    /// @param data One channel audio data
    /// @param totalBytes Total number of bytes of audio data
    /// @return Repacked two-channel audio data in `ulaw` format
    static uint8_t* repack(int16_t* data, size_t totalBytes)
    {
        unsigned short numberOfChannels = 2;
        size_t numberOfSamples_16bit = totalBytes / 2;
        
        // Creating two channels signal. LRLR patern
        int16_t* twoChannelsData = (int16_t*)malloc((size_t)(numberOfChannels * totalBytes));
        for (size_t i = 0; i < numberOfSamples_16bit; i++) {
            memcpy(&twoChannelsData[i * 2], &data[i], 2);
            memcpy(&twoChannelsData[i * 2 + 1], &data[i], 2);
        }
        
        // Repacking signed 16bit linear signal to unsigned 8bit ulaw signal
        uint8_t* PCM_Data = (uint8_t*)malloc((size_t)(numberOfChannels * numberOfSamples_16bit));
        for (size_t i = 0; i < numberOfSamples_16bit * numberOfChannels; i++) {
            PCM_Data[i] = linear2ulaw(twoChannelsData[i]);
        }
        free(twoChannelsData);
        return PCM_Data;
    }
};

#endif /* AudioHelper_hpp */
