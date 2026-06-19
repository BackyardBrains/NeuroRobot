#ifndef AUDIO_SAMPLE_H
#define AUDIO_SAMPLE_H

#include <stdint.h>

// All PCM data is 16-bit signed (int16_t), 22050 Hz mono.
// pcm is void* so the struct compiles regardless of the source array type,
// but the ISR always reads it as (const int16_t*).
typedef struct {
    const void*  pcm;       // → const int16_t*  (16-bit signed PCM)
    uint16_t     length;    // samples (not bytes)
    uint16_t     loopStart;
    uint16_t     loopEnd;   // 0 = play to end once (vocal); >0 = loop here (instrument)
} audioSample;

#endif