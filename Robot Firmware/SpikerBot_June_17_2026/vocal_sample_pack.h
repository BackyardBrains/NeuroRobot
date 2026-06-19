#ifndef VOCAL_SAMPLE_PACK_H
#define VOCAL_SAMPLE_PACK_H

#include <stdint.h>
#include "audio_sample.h"

extern const int16_t ciao[];
extern const int16_t uh_oh[];  // 16-bit (SRAM)
extern const int16_t mhmm[];
extern const int16_t hmm[];   // 16-bit 22050Hz (SRAM)
extern const int16_t snore[];   // 16-bit (SRAM)
extern const uint8_t crunch[];
extern const int16_t yeehaw[];
extern const int16_t bark[];
extern const int16_t meow[];
extern const int16_t magic_sfx[];

extern const audioSample vocalSamplePack[10];

#endif
