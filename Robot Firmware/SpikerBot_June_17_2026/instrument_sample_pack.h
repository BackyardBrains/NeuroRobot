#ifndef INSTRUMENT_SAMPLE_PACK_H
#define INSTRUMENT_SAMPLE_PACK_H

#include <stdint.h>
#include "audio_sample.h"

extern const int16_t triangle_C5[];  // 16-bit synthesized 882Hz triangle wave
extern const uint8_t voice_C4[];
extern const int16_t string_C4[];
extern const int16_t trumpet_C3[];
extern const uint8_t demung_C4[];

extern const audioSample instrumentSamplePack[5];

#endif