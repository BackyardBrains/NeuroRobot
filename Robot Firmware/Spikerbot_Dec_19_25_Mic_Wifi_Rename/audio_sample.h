#ifndef AUDIO_SAMPLE_H
#define AUDIO_SAMPLE_H

#include <stdint.h>

typedef struct {
    const uint8_t* pcm;
    uint16_t length;
    uint16_t loopStart;
    uint16_t loopEnd;
} audioSample;

#endif