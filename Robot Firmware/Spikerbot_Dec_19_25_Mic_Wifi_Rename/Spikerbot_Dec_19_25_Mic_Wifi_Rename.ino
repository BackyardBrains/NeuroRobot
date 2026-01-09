// Spikerbot firmware Nov 26. 2025
// Made for BYB ESP32 S3 & Spikerbot Chassis Motherborad V3
// Programmed by selecting "ESP32S3 Dev Module" in Arduino
// set board parameters in Arduino IDE:
// PSRAM: OPI PSRAM
// Flash mode: OPI 80Mhz
// Written by Stanislav Mircic, Alex Hatch
// Backyard Brains


#include "esp_camera.h"
#include <WiFi.h>
#include <ESP32Servo.h>
#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <vl53l4cd_class.h>
#include <arduinoFFT.h>
#include <Preferences.h>

Preferences preferences;

#define USE_LEDS 1
#define USE_DISTANCE_SENSOR 1
#define USE_MOTORS 1
#define USE_SPEAKER 1
#define USE_MIC 1
#define MAKE_AP 1
#define USE_BATTERY_MEASUREMENT 1
// #define USE_INERTIAL 1
#define SEND_MM_FOR_DISTANCE 1

//free pin that can be used for debug IO1
#define DEBUG_PIN 1

#if defined(USE_BATTERY_MEASUREMENT)
  #define BATTERY_PIN 4
  int batteryCounter = 0;
  //make measurement every 2 seconds (1second = 200 loops approx.)
  #define BATTERY_MEASUREMENTS_PERIOD (400)
#endif




#if defined(USE_SPEAKER)

    //change this acording to the absolute path to your esp32 library
    //Alex's paths
    #include "/Users/hatch/Library/Arduino15/packages/esp32/hardware/esp32/2.0.11/tools/sdk/esp32s3/include/hal/include/hal/timer_types.h"// find this two header files in the tools/sdk/esp32s2/** directories, should be in similar places
    #include "/Users/hatch/Library/Arduino15/packages/esp32/hardware/esp32/2.0.11/tools/sdk/esp32s3/include/driver/include/driver/timer.h"// possibly usable just by including last two path names?
    //Stan's paths 
    //#include "C:/Users/Admin/AppData/Local/Arduino15/packages/esp32/hardware/esp32/2.0.14/tools/sdk/esp32s3/include/hal/include/hal/timer_types.h"// find this two header files in the tools/sdk/esp32s2/** directories, should be in similar places
    //#include "C:/Users/Admin/AppData/Local/Arduino15/packages/esp32/hardware/esp32/2.0.14/tools/sdk/esp32s3/include/driver/include/driver/timer.h"// possibly usable just by including last two path names?
    #include <stdio.h>
    #include "esp_types.h"
    #include "driver/timer.h"
    #include "esp_intr_alloc.h"
    #include "esp_task_wdt.h"
    #include "driver/periph_ctrl.h"
    #include "vocal_sample_pack.h"
    #include "instrument_sample_pack.h"

    #define TIMER_DIVIDER         80  //  Hardware timer clock divider
    #define TIMER_SCALE           (TIMER_BASE_CLK / TIMER_DIVIDER)  // convert counter value to seconds
    #define PCM_SAMPLE_RATE_HZ 22050  // double 11025 audio sample rate for sudo polyphony effect (duophonic)
    #define TIMER_TICKS_PER_SAMPLE (TIMER_BASE_CLK / TIMER_DIVIDER / PCM_SAMPLE_RATE_HZ)
    #define TIMER_INTERVAL0_SEC (1.0 / PCM_SAMPLE_RATE_HZ)
    #define SELECTED_TIMER_GROUP TIMER_GROUP_1
    #define SELECTED_TIMER_INDEX TIMER_0
    #define SPEAKER_PIN 14
    #define AUDIO_CHANNEL 4  // Needed for ledcWrite
    #define AUDIO_TIMER LEDC_TIMER_1
    #define MAX_POLYPHONY 2
    #define PITCH_SHIFT_SCALE 256  // Q8.8 fixed-point scale

    const uint16_t semitoneStepSizeTable[25] = {
      0x0040, 0x0044, 0x0048, 0x004C, 0x0051, 0x0055, 0x005A, 0x005F, 0x0065,
      0x006B, 0x0071, 0x0078, 0x0080, 0x0088, 0x008F, 0x0098, 0x00A1, 0x00AA,
      0x00B4, 0x00BF, 0x00CA, 0x00D6, 0x00E2, 0x00EF, 0x0100
    };

    portMUX_TYPE audioMux = portMUX_INITIALIZER_UNLOCKED;

    typedef struct {
      volatile const uint8_t* pcm = nullptr;
      volatile uint16_t index = 0;
      volatile uint16_t length = 0;
      volatile uint8_t repeatFactor = 1;
      volatile uint8_t repeatCounter = 1;
      volatile bool active = false;
    } PCMVoice;

    PCMVoice voices[MAX_POLYPHONY];
    volatile bool tick = false; // flip-flop interlace toggle
    volatile bool audioProcessingRequired = false;
    uint8_t instrumentAgeCounter = 0;

    typedef struct {
      const audioSample* instrument;
      uint32_t index;           // Q8.8 phase accumulator
      uint16_t stepSize;        // Q8.8 step per sample
      uint8_t loopCount;
      bool active;
      bool hasLoopedOnce;
      uint8_t age;
      int8_t semitoneOffset;
    } InstrumentVoice;

    InstrumentVoice instrumentVoices[MAX_POLYPHONY];

    bool isAnyAudioPlaying() {
      return voices[0].active || voices[1].active ||
            instrumentVoices[0].active || instrumentVoices[1].active;
    }

    bool isVoiceAudiblyActive(const InstrumentVoice& v) {
      return v.active && v.index < v.instrument->length; // Use -> for pointer access
    }

#endif

#if defined(USE_MIC)
  #include "driver/i2s.h"
  #include <arduinoFFT.h>

  // I2S configuration for the microphone
  #define I2S_NUM           I2S_NUM_0  // I2S port number
  #define I2S_SAMPLE_RATE   16000      // Sampling rate (16 kHz)
  #define I2S_SAMPLE_BITS   I2S_BITS_PER_SAMPLE_16BIT // 16-bit samples
  #define I2S_DMA_BUF_LEN   1024       // DMA buffer length
  #define FFT_SAMPLES       256        // Number of samples for FFT (must be a power of 2)

  // PDM microphone pins
  #define I2S_PIN_CLK       40         // I2S clock pin (CLK)
  #define I2S_PIN_DATA      41         // I2S data pin (DAT)

  // Buffer for microphone data
  int16_t micBuffer[I2S_DMA_BUF_LEN];
  double vReal[FFT_SAMPLES];
  double vImag[FFT_SAMPLES];
  // If we want to put it in psram
// EXT_RAM_ATTR int16_t micBuffer[I2S_DMA_BUF_LEN];
// EXT_RAM_ATTR double vReal[FFT_SAMPLES];
// EXT_RAM_ATTR double vImag[FFT_SAMPLES];

  ArduinoFFT<double> FFT = ArduinoFFT<double>();
  String micOutputStr = "0"; // String to store the microphone output
#endif

#if defined(USE_DISTANCE_SENSOR)
  #define I2C_SDA 45
  #define I2C_SCL 21
  #define DEV_I2C Wire
  TwoWire I2CSensors = TwoWire(0);
  VL53L4CD sensor_vl53l4cd_sat(&DEV_I2C, 42);
  int reportedDistance = 0;
#endif


#if defined(USE_INERTIAL)
  #include <LSM6DSOSensor.h>

  // I2C Configuration for ESP32 Cam
  #define SDA_PIN 45  // Pin 26
  #define SCL_PIN 21  // Pin 23

  // Create I2C interface
  TwoWire I2CLSM(0);  // Use I2C bus 0

  // Create sensor
  LSM6DSOSensor AccGyr(&I2CLSM, LSM6DSO_I2C_ADD_L);
#endif


#define CAMERA_MODEL_BYBV1 // Has PSRAM
#include "camera_pins.h"

#if defined(MAKE_AP)
  #define ROBOT_NAME_AP "Spikerbot"
  String tempNameOfAP, nameOfAP;
  #define DEFAULT_WIFI_CHANNEL 6
  #define RANDOMIZE_WIFI_CHANNEL 1
#else
  const char* ssid = "bfd52a";
  const char* password = "282875063";
#endif

// Select camera model

#define SIZE_OF_COMMAND_BUFFER 256
char commandBuffer[256];
bool sendVersionString = false;

#if defined(USE_LEDS)
  #define LED_PIN   13
  #define LED_COUNT 4
  volatile int diodeCommand = 0;
  Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
  uint32_t colorBlue = (0,0,255);
  uint32_t colorGreen = (0,255,0);
  bool shouldSetGreen = false;
#endif

#if defined(USE_MOTORS)
  Servo servo1;
  Servo servo2;
  int pos = 90;
  int motorSpeedLeft;
  int motorSpeedRight;
  int rServoPin = 5; //
  int lServoPin = 2; //
#endif

int this_speed = 0;
int io_command[] = {0, 0, 0, 0, 0};
long duration;
long distance = 0;
long battery = 0;
int this_tone = 0;
int micPin = 0;

int micVal = 0;
int toneVal = 0;

void startCameraServer();
void sendDataViaSocket(char * dataToSend, int lengthOfData);

#if defined(USE_LEDS)
  void turnOffLEDs()
  {
  strip.setPixelColor(0, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(1, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(2, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(3, strip.Color(  0,   0,   0)); 
  strip.show();
  }
#endif

#if defined(USE_SPEAKER)
    bool speakerActive = false;
    int halfPeriodTone = 0;
    int fullPeriodTone = 0;
    int counterForTone = 0;

    //Sound command example s:440;
    //  s - sound command name
    //  : - separator between name and value
    //  440 - frequency of sound in Hz
    //  ; - end of the command (separator)

    void playInstrumentSample(const audioSample& sample, int8_t semitoneOffset, uint8_t loopCount = 1) {
      
      ledcAttachPin(SPEAKER_PIN, AUDIO_CHANNEL);

      // Clamp semitoneOffset to range -24 to 0
      if (semitoneOffset > 0) semitoneOffset = 0;
      if (semitoneOffset < -24) semitoneOffset = -24;

      uint8_t tableIndex = semitoneOffset + 24; // Convert -24..0 to 0..24
      uint16_t stepSize = semitoneStepSizeTable[tableIndex];

      instrumentAgeCounter++;
      portENTER_CRITICAL(&audioMux);

      for (int i = 0; i < MAX_POLYPHONY; i++) {
        auto& v = instrumentVoices[i];
        if (v.active && v.instrument == &sample && v.semitoneOffset == semitoneOffset) {
          if (loopCount > 0) {
            v.loopCount = loopCount;
            v.stepSize = stepSize;
            v.hasLoopedOnce = false;
            v.age = instrumentAgeCounter;
          }
          portEXIT_CRITICAL(&audioMux);
          return;
        }
      }

      int chosenIndex = -1;
      for (int i = 0; i < MAX_POLYPHONY; i++) {
        if (!instrumentVoices[i].active) {
          chosenIndex = i;
          break;
        }
      }
      if (chosenIndex == -1) {
        chosenIndex = (instrumentVoices[0].age <= instrumentVoices[1].age) ? 0 : 1;
      }

      auto& v = instrumentVoices[chosenIndex];
      v.instrument = &sample;
      v.index = 0;
      v.stepSize = stepSize;
      v.loopCount = loopCount;
      v.active = true;
      v.hasLoopedOnce = false;
      v.age = instrumentAgeCounter;
      v.semitoneOffset = semitoneOffset;

      portEXIT_CRITICAL(&audioMux);
    }

    void applyLoopBlend(uint8_t* data, uint16_t loopStart, uint16_t loopEnd, uint8_t repeatFactor) {
      if (loopEnd - loopStart < 10) return;
      for (int i = 0; i < 5; i++) {
        int16_t from = data[loopEnd - 5 + i];
        int16_t to = data[loopStart + i];
        data[loopStart + i] = (from * (5 - i) + to * i) / 5;
      }
    }

    void setToneOnSpeaker(int toneFrequency) {
      
      if (toneFrequency < 1) {
        // Ignore silence commands while PCM is playing
        if (isAnyAudioPlaying()) return;
        speakerActive = false;
        halfPeriodTone = 0;
        fullPeriodTone = 0;
        counterForTone = 0;
        ledcDetachPin(SPEAKER_PIN);         // FULL SILENCE
        pinMode(SPEAKER_PIN, OUTPUT);
        digitalWrite(SPEAKER_PIN, LOW);
      } 
      else if (toneFrequency >= 500) {
        // Ignore tone commands while PCM is playing
        if (isAnyAudioPlaying()) return;
        float calc = 0.5 * ((1.0 / (float)toneFrequency) / TIMER_INTERVAL0_SEC);
        halfPeriodTone = calc;
        fullPeriodTone = halfPeriodTone * 2;
        counterForTone = 0;
        speakerActive = true;
        ledcAttachPin(SPEAKER_PIN, AUDIO_CHANNEL);  // Re-enable
      } 
      else {
        switch (toneFrequency) {  // speccific frequency values trigger sample playback from pcm_samples.h raw sample data in pcm_samples.cpp

          // vocal samples - emotional phrases
          case 31:  playInstrumentSample(vocalSamplePack[0], -12, 0); break;
          case 32:  playInstrumentSample(vocalSamplePack[1], -12, 0);  break;
          case 33:  playInstrumentSample(vocalSamplePack[2], -12, 0); break;
          case 34:  playInstrumentSample(vocalSamplePack[3], -12, 0); break;
          case 35:  playInstrumentSample(vocalSamplePack[4], -12, 0); break;
          case 36:  playInstrumentSample(vocalSamplePack[5], -12, 0); break;
          case 37:  playInstrumentSample(vocalSamplePack[6], -12, 0); break;
          case 38:  playInstrumentSample(vocalSamplePack[7], -12, 0); break;
          case 39:  playInstrumentSample(vocalSamplePack[8], -12, 0); break;
          case 40:  playInstrumentSample(vocalSamplePack[9], -12, 0); break;
          
          // demung tones
          case 71:  playInstrumentSample(instrumentSamplePack[4], -14, 0); break;
          case 72:  playInstrumentSample(instrumentSamplePack[4], -10, 0); break;
          case 73:  playInstrumentSample(instrumentSamplePack[4],  -8, 0); break;
          case 74:  playInstrumentSample(instrumentSamplePack[4],  -7, 0); break;
          case 75:  playInstrumentSample(instrumentSamplePack[4],  -3, 0); break;
          case 76:  playInstrumentSample(instrumentSamplePack[4],  -2, 0); break;
          case 77:  playInstrumentSample(instrumentSamplePack[4],  -0, 0); break;

          // choir ahh
          case 128: playInstrumentSample(instrumentSamplePack[1], -24, 1); break;
          case 129: playInstrumentSample(instrumentSamplePack[1], -23, 1); break;
          case 130: playInstrumentSample(instrumentSamplePack[1], -22, 1); break;
          case 131: playInstrumentSample(instrumentSamplePack[1], -21, 1); break;
          case 132: playInstrumentSample(instrumentSamplePack[1], -20, 1); break;
          case 133: playInstrumentSample(instrumentSamplePack[1], -19, 1); break;
          case 134: playInstrumentSample(instrumentSamplePack[1], -18, 1); break;
          case 135: playInstrumentSample(instrumentSamplePack[1], -17, 1); break;
          case 136: playInstrumentSample(instrumentSamplePack[1], -16, 1); break;
          case 137: playInstrumentSample(instrumentSamplePack[1], -15, 1); break;
          case 138: playInstrumentSample(instrumentSamplePack[1], -14, 1); break;
          case 139: playInstrumentSample(instrumentSamplePack[1], -13, 1); break;
          case 140: playInstrumentSample(instrumentSamplePack[1], -12, 1); break;
          case 141: playInstrumentSample(instrumentSamplePack[1], -11, 1); break;
          case 142: playInstrumentSample(instrumentSamplePack[1], -10, 1); break;
          case 143: playInstrumentSample(instrumentSamplePack[1],  -9, 1); break;
          case 144: playInstrumentSample(instrumentSamplePack[1],  -8, 1); break;
          case 145: playInstrumentSample(instrumentSamplePack[1],  -7, 1); break;
          case 146: playInstrumentSample(instrumentSamplePack[1],  -6, 1); break;
          case 147: playInstrumentSample(instrumentSamplePack[1],  -5, 1); break;
          case 148: playInstrumentSample(instrumentSamplePack[1],  -4, 1); break;
          case 149: playInstrumentSample(instrumentSamplePack[1],  -3, 1); break;
          case 150: playInstrumentSample(instrumentSamplePack[1],  -2, 1); break;
          case 151: playInstrumentSample(instrumentSamplePack[1],  -1, 1); break;
          case 152: playInstrumentSample(instrumentSamplePack[1],   0, 1); break;

          // string pluck
          case 228: playInstrumentSample(instrumentSamplePack[2], -24, 0); break;
          case 229: playInstrumentSample(instrumentSamplePack[2], -23, 0); break;
          case 230: playInstrumentSample(instrumentSamplePack[2], -22, 0); break;
          case 231: playInstrumentSample(instrumentSamplePack[2], -21, 0); break;
          case 232: playInstrumentSample(instrumentSamplePack[2], -20, 0); break;
          case 233: playInstrumentSample(instrumentSamplePack[2], -19, 0); break;
          case 234: playInstrumentSample(instrumentSamplePack[2], -18, 0); break;
          case 235: playInstrumentSample(instrumentSamplePack[2], -17, 0); break;
          case 236: playInstrumentSample(instrumentSamplePack[2], -16, 0); break;
          case 237: playInstrumentSample(instrumentSamplePack[2], -15, 0); break;
          case 238: playInstrumentSample(instrumentSamplePack[2], -14, 0); break;
          case 239: playInstrumentSample(instrumentSamplePack[2], -13, 0); break;
          case 240: playInstrumentSample(instrumentSamplePack[2], -12, 0); break;
          case 241: playInstrumentSample(instrumentSamplePack[2], -11, 0); break;
          case 242: playInstrumentSample(instrumentSamplePack[2], -10, 0); break;
          case 243: playInstrumentSample(instrumentSamplePack[2],  -9, 0); break;
          case 244: playInstrumentSample(instrumentSamplePack[2],  -8, 0); break;
          case 245: playInstrumentSample(instrumentSamplePack[2],  -7, 0); break;
          case 246: playInstrumentSample(instrumentSamplePack[2],  -6, 0); break;
          case 247: playInstrumentSample(instrumentSamplePack[2],  -5, 0); break;
          case 248: playInstrumentSample(instrumentSamplePack[2],  -4, 0); break;
          case 249: playInstrumentSample(instrumentSamplePack[2],  -3, 0); break;
          case 250: playInstrumentSample(instrumentSamplePack[2],  -2, 0); break;
          case 251: playInstrumentSample(instrumentSamplePack[2],  -1, 0); break;
          case 252: playInstrumentSample(instrumentSamplePack[2],   0, 0); break;

          // trombone
          case 328: playInstrumentSample(instrumentSamplePack[3], -24, 2); break;
          case 329: playInstrumentSample(instrumentSamplePack[3], -23, 2); break;
          case 330: playInstrumentSample(instrumentSamplePack[3], -22, 2); break;
          case 331: playInstrumentSample(instrumentSamplePack[3], -21, 2); break;
          case 332: playInstrumentSample(instrumentSamplePack[3], -20, 2); break;
          case 333: playInstrumentSample(instrumentSamplePack[3], -19, 2); break;
          case 334: playInstrumentSample(instrumentSamplePack[3], -18, 2); break;
          case 335: playInstrumentSample(instrumentSamplePack[3], -17, 2); break;
          case 336: playInstrumentSample(instrumentSamplePack[3], -16, 2); break;
          case 337: playInstrumentSample(instrumentSamplePack[3], -15, 2); break;
          case 338: playInstrumentSample(instrumentSamplePack[3], -14, 2); break;
          case 339: playInstrumentSample(instrumentSamplePack[3], -13, 2); break;
          case 340: playInstrumentSample(instrumentSamplePack[3], -12, 2); break;
          case 341: playInstrumentSample(instrumentSamplePack[3], -11, 2); break;
          case 342: playInstrumentSample(instrumentSamplePack[3], -10, 2); break;
          case 343: playInstrumentSample(instrumentSamplePack[3],  -9, 2); break;
          case 344: playInstrumentSample(instrumentSamplePack[3],  -8, 2); break;
          case 345: playInstrumentSample(instrumentSamplePack[3],  -7, 2); break;
          case 346: playInstrumentSample(instrumentSamplePack[3],  -6, 2); break;
          case 347: playInstrumentSample(instrumentSamplePack[3],  -5, 2); break;
          case 348: playInstrumentSample(instrumentSamplePack[3],  -4, 2); break;
          case 349: playInstrumentSample(instrumentSamplePack[3],  -3, 2); break;
          case 350: playInstrumentSample(instrumentSamplePack[3],  -2, 2); break;
          case 351: playInstrumentSample(instrumentSamplePack[3],  -1, 2); break;
          case 352: playInstrumentSample(instrumentSamplePack[3],   0, 2); break;

          // triangle wave synth
          case 428: playInstrumentSample(instrumentSamplePack[0], -24, 1); break;
          case 429: playInstrumentSample(instrumentSamplePack[0], -23, 1); break;
          case 430: playInstrumentSample(instrumentSamplePack[0], -22, 1); break;
          case 431: playInstrumentSample(instrumentSamplePack[0], -21, 1); break;
          case 432: playInstrumentSample(instrumentSamplePack[0], -20, 1); break;
          case 433: playInstrumentSample(instrumentSamplePack[0], -19, 1); break;
          case 434: playInstrumentSample(instrumentSamplePack[0], -18, 1); break;
          case 435: playInstrumentSample(instrumentSamplePack[0], -17, 1); break;
          case 436: playInstrumentSample(instrumentSamplePack[0], -16, 1); break;
          case 437: playInstrumentSample(instrumentSamplePack[0], -15, 1); break;
          case 438: playInstrumentSample(instrumentSamplePack[0], -14, 1); break;
          case 439: playInstrumentSample(instrumentSamplePack[0], -13, 1); break;
          case 440: playInstrumentSample(instrumentSamplePack[0], -12, 1); break;
          case 441: playInstrumentSample(instrumentSamplePack[0], -11, 1); break;
          case 442: playInstrumentSample(instrumentSamplePack[0], -10, 1); break;
          case 443: playInstrumentSample(instrumentSamplePack[0],  -9, 1); break;
          case 444: playInstrumentSample(instrumentSamplePack[0],  -8, 1); break;
          case 445: playInstrumentSample(instrumentSamplePack[0],  -7, 1); break;
          case 446: playInstrumentSample(instrumentSamplePack[0],  -6, 1); break;
          case 447: playInstrumentSample(instrumentSamplePack[0],  -5, 1); break;
          case 448: playInstrumentSample(instrumentSamplePack[0],  -4, 1); break;
          case 449: playInstrumentSample(instrumentSamplePack[0],  -3, 1); break;
          case 450: playInstrumentSample(instrumentSamplePack[0],  -2, 1); break;
          case 451: playInstrumentSample(instrumentSamplePack[0],  -1, 1); break;
          case 452: playInstrumentSample(instrumentSamplePack[0],   0, 1); break;
        }
      }
    }

    timer_config_t tconfig = {
        .alarm_en=TIMER_ALARM_EN,//enable timer alarm
        .counter_en=TIMER_START,//starts counting counter once timer_init called
        .intr_type=TIMER_INTR_MAX,
        .counter_dir=TIMER_COUNT_UP,//counts from 0 to counter value
        .auto_reload=TIMER_AUTORELOAD_EN,// reloads counter automatically
        .divider=TIMER_DIVIDER   
    };
        
    timer_idx_t timer_idx = SELECTED_TIMER_INDEX;

    void IRAM_ATTR timer_group_isr(void *para) {
      timer_group_clr_intr_status_in_isr(SELECTED_TIMER_GROUP, SELECTED_TIMER_INDEX);
      tick = !tick;

      uint16_t mixed = 0;
      uint8_t activeCount = 0;

      for (int i = 0; i < MAX_POLYPHONY; i++) {
        auto& v = instrumentVoices[i];
        if (!v.active) continue;

        uint16_t sampleIndex = v.index >> 8;
        if (sampleIndex < v.instrument->length) {
          mixed += v.instrument->pcm[sampleIndex];
          activeCount++;
        }

        v.index += v.stepSize;
        sampleIndex = v.index >> 8;

        if (sampleIndex >= v.instrument->loopEnd) {
          if (v.loopCount > 0) {
            v.loopCount--;
            if (v.hasLoopedOnce) {
              applyLoopBlend((uint8_t*)v.instrument->pcm, v.instrument->loopStart, v.instrument->loopEnd, 1);
            }
            v.hasLoopedOnce = true;
            v.index = v.instrument->loopStart << 8;
          } else {
            v.active = false;
          }
        }

        if (sampleIndex >= v.instrument->length) {
          v.active = false;
        }
      }

      if (activeCount > 0) {
        ledcWrite(AUDIO_CHANNEL, mixed / activeCount);
      } else {
        ledcWrite(AUDIO_CHANNEL, 128); // silence
      }

      timer_group_enable_alarm_in_isr(SELECTED_TIMER_GROUP, SELECTED_TIMER_INDEX);
      esp_task_wdt_reset();
    }

    void handleAudioProcessing() {
      if (!audioProcessingRequired) return;
      audioProcessingRequired = false;

      uint16_t mixed = 0;
      uint8_t activeCount = 0;
      static uint8_t lastOutput = 128;

      for (int i = 0; i < MAX_POLYPHONY; i++) {
        auto& v = instrumentVoices[i];
        if (!v.active) continue;

        uint16_t sampleIndex = v.index >> 8;
        if (sampleIndex < v.instrument->length) {
          mixed += v.instrument->pcm[sampleIndex];
          activeCount++;
        }

        v.index += v.stepSize;
        sampleIndex = v.index >> 8;

        if (sampleIndex >= v.instrument->loopEnd) {
          if (v.loopCount > 0) {
            v.loopCount--;
            if (v.hasLoopedOnce) {
              applyLoopBlend((uint8_t*)v.instrument->pcm, v.instrument->loopStart, v.instrument->loopEnd, 1);
            }
            v.hasLoopedOnce = true;
            v.index = v.instrument->loopStart << 8;
          } else {
            v.active = false;
          }
        }

        if (sampleIndex >= v.instrument->length) {
          v.active = false;
        }
      }

      uint8_t outputValue = 128;
      if (activeCount > 0) {
        outputValue = mixed / activeCount;
        lastOutput = outputValue;
      } else {
        if (lastOutput > 128) lastOutput--;
        else if (lastOutput < 128) lastOutput++;
        outputValue = lastOutput;
      }

      ledcWrite(AUDIO_CHANNEL, outputValue);
    }


#endif

//
//Diode command d:[index],[red],[green],[blue];
//example d:2,200,128,240;
//  d - diode command name
//  : - separator between name and value
//  2 - index of diode 3rd diode (1-4)
//  200 - value of intensity of red color (0-255)
//  128 - value of intensity of green color (0-255)
//  240 - value of intensity blue color (0-255)
//  ; - separator between commands

#if defined(USE_LEDS)

  void executeRGBDiodeCommand(int* diodeParameters)
  {
    int LEDIndex = diodeParameters[0]; //0-3
    if (LEDIndex < 0)
    {
      return;
    }
    if (LEDIndex >=LED_COUNT)
    {
      return;
    }

    uint32_t color = strip.Color(diodeParameters[1], diodeParameters[2], diodeParameters[3]);
    uint32_t gammaCorrectedColor = strip.gamma32(color);
    strip.setPixelColor(LEDIndex, gammaCorrectedColor);
    strip.show();
  }

#endif

void newDataArrivedFromSocket(char * data, int lengthOfData) {
    // breaks string str into a series of tokens using delimiter ";"
    // Namely split strings into commands
    char* command = strtok(data, ";");
    while (command != 0)
    {
      // Split the command in 2 parts: name and value
      char* separator = strchr(command, ':');
      if (separator != 0)
      {
        // Actually split the string in 2: replace ':' with 0
        *separator = 0;
        --separator;
        if (*separator == 'l') //command for left motor
        {
          separator = separator + 2;
          #if defined(USE_MOTORS)
              motorSpeedLeft = atoi(separator);//read speed
              if (motorSpeedLeft > 255)
              {
                motorSpeedLeft = 255;
              }
              if (motorSpeedLeft < -255)
              {
                motorSpeedLeft = -255;
              }
              motorSpeedLeft = motorSpeedLeft*2+1500;

              servo1.write(motorSpeedLeft); 
              //Serial.println(motorSpeedLeft);
          #endif
        }
        if (*separator == 'r') //command for right motor
        {
          separator = separator + 2;
          #if defined(USE_MOTORS)
              motorSpeedRight = atoi(separator);//read speed
              if (motorSpeedRight > 255)
              {
                motorSpeedRight = 255;
              }
              if (motorSpeedRight < -255)
              {
                motorSpeedRight = -255;
              }
              motorSpeedRight = motorSpeedRight*2+1500;

              servo2.write(motorSpeedRight); 
              //Serial.println(motorSpeedRight);
          #endif
        }
        //d:2,200,128,200;
        if (*separator == 'd') //command for LED diode
        {
          separator = separator + 2;
          #if defined(USE_LEDS)
            char tempBuffer[4];
            int diodeParameters[4];
            int parameterIndex = 0;
            int characterIndex = 0;
            int foundEndOfTheCommand = 0;
            while(characterIndex<15)
            {
                int tempBufferIndex = 0;
                while(tempBufferIndex<4)
                {
                    if(separator[characterIndex]==',' || separator[characterIndex]==';' || separator[characterIndex]==0)
                    {
                        tempBuffer[tempBufferIndex] = 0;
                        diodeParameters[parameterIndex] = atoi(tempBuffer);
                        parameterIndex++;
                        if(separator[characterIndex]==';' || separator[characterIndex]==0)
                        {
                          foundEndOfTheCommand =1;
                        }
                        characterIndex++;
                        break;
                    }
                    else
                    {
                        tempBuffer[tempBufferIndex] = separator[characterIndex];
                        characterIndex++;
                        tempBufferIndex++;
                    }
                }
                if(foundEndOfTheCommand)
                {
                  foundEndOfTheCommand = 0;
                  break;
                }
            }
            if(parameterIndex>=4)
            {
              executeRGBDiodeCommand(diodeParameters);
            }
          #endif
        }
        if (*separator == 's') //command for sound generator
        {
          separator = separator + 2;
          this_tone = atoi(separator);//read frequency 
          #if defined(USE_SPEAKER)
            setToneOnSpeaker(this_tone);
          #endif
        }
        if (*separator == 'n') //command for renaming SSID
        {
          separator = separator + 2;
          String newName = String(separator);
          if (newName.length() > 0 && newName.length() < 32) {
             Serial.println("Updating SSID and Rebooting...");
             delay(100); 
             
             // Disable audio timer to prevent ISR crash during flash write
             #if defined(USE_SPEAKER)
                timer_pause(SELECTED_TIMER_GROUP, SELECTED_TIMER_INDEX);
             #endif
             
             preferences.begin("bot_config", false);
             preferences.putString("ssid", "Spikerbot " + newName);
             preferences.end();
             
             ESP.restart();
          }
        }
        if (*separator == 'v') //get version of firmware
        {
          separator = separator + 2;
          sendVersionString = true;
        }
      }
      // Find the next command in input string
      command = strtok(0, ";");
    }//end of while
}

uint32_t getUniqueNumber() {
    uint32_t id = 0;
    for(int i=0; i<17; i=i+8) 
    {
      id |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
    }
    return id;
}

void setup() {

    pinMode (DEBUG_PIN, OUTPUT);
    digitalWrite(DEBUG_PIN,LOW);
    //set Power down pin on camera to HIHG. BYB board has inverse logic in comparison with ESP32-CAM
    pinMode (39, OUTPUT);
    digitalWrite(39,LOW);

    #if defined(USE_BATTERY_MEASUREMENT)
      //set ADC for battery monitoring 
      pinMode(BATTERY_PIN,INPUT);
      analogReadResolution(10);
      battery = analogRead(BATTERY_PIN);
    #endif

    Serial.begin(115200);
    Serial.setDebugOutput(true);
    Serial.println();

    #if defined(USE_LEDS)
      strip.begin();
      strip.show();
      strip.setBrightness(25);
      strip.setPixelColor(0, colorBlue);
      strip.setPixelColor(1, colorBlue);
      strip.setPixelColor(2, colorBlue);
      strip.setPixelColor(3, colorBlue);
      strip.show();
    #endif

      camera_config_t config;
      config.ledc_channel = LEDC_CHANNEL_0;
      config.ledc_timer = LEDC_TIMER_0;
      config.pin_d0 = Y2_GPIO_NUM;
      config.pin_d1 = Y3_GPIO_NUM;
      config.pin_d2 = Y4_GPIO_NUM;
      config.pin_d3 = Y5_GPIO_NUM;
      config.pin_d4 = Y6_GPIO_NUM;
      config.pin_d5 = Y7_GPIO_NUM;
      config.pin_d6 = Y8_GPIO_NUM;
      config.pin_d7 = Y9_GPIO_NUM;
      config.pin_xclk = XCLK_GPIO_NUM;
      config.pin_pclk = PCLK_GPIO_NUM;
      config.pin_vsync = VSYNC_GPIO_NUM;
      config.pin_href = HREF_GPIO_NUM;
      config.pin_sscb_sda = SIOD_GPIO_NUM;
      config.pin_sscb_scl = SIOC_GPIO_NUM;
      config.pin_pwdn = PWDN_GPIO_NUM;
      config.pin_reset = RESET_GPIO_NUM;
      config.xclk_freq_hz = 10000000;
      config.pixel_format = PIXFORMAT_JPEG;
      config.frame_size = FRAMESIZE_QVGA;
      config.jpeg_quality = 12;
      config.fb_count = 1;
      config.fb_location = CAMERA_FB_IN_PSRAM;

      //camera init
      esp_err_t err = esp_camera_init(&config);
      Serial.println("Camera Init");
      if (err != ESP_OK) {
        Serial.printf("Camera init failed with error 0x%x", err);
        return;
      }

      sensor_t * s = esp_camera_sensor_get();

      s->set_whitebal(s, 1); // 1 = auto white balance ON
      s->set_exposure_ctrl(s, 1);   // Auto exposure control ON
      s->set_gain_ctrl(s, 1);       // Auto gain control ON
      s->set_saturation(s, 2);      // Adjust saturation (-2 to 2)
      s->set_brightness(s, 0);      // Adjust brightness (-2 to 2)
      s->set_contrast(s, 1);        // Adjust contrast (-2 to 2)

      // Optimizations for color detection
      s->set_lenc(s, 1);            // Lens correction
      s->set_awb_gain(s, 1);        // Auto White Balance Gain
      s->set_aec2(s, 1);            // Auto Exposure Control DSP
      s->set_dcw(s, 1);             // Downsize enable
      s->set_wb_mode(s, 0);         // Auto White Balance Mode
      s->set_ae_level(s, -1);       // Auto Exposure Level (-2 to 2) -2 for darker image/better saturation
      s->set_special_effect(s, 0);  // Ensure no special effects


    #if defined(USE_MOTORS)
      ESP32PWM::allocateTimer(0);
      ESP32PWM::allocateTimer(1);
      ESP32PWM::allocateTimer(2);
      ESP32PWM::allocateTimer(3);
      servo1.setPeriodHertz(50);  // standard 50 hz servo
      servo2.setPeriodHertz(50);
      servo1.attach(rServoPin, 1000, 2000);
      servo2.attach(lServoPin, 1000, 2000);
    #endif

    #if defined(USE_DISTANCE_SENSOR)
      DEV_I2C.begin(I2C_SDA, I2C_SCL, 100000);
      sensor_vl53l4cd_sat.begin();
      Serial.println("Found Vl53L4CD");
      sensor_vl53l4cd_sat.VL53L4CD_Off();
      sensor_vl53l4cd_sat.InitSensor();
      sensor_vl53l4cd_sat.VL53L4CD_SetRangeTiming(80, 0);
      sensor_vl53l4cd_sat.VL53L4CD_StartRanging();
      Serial.println("VL53L4CD initialized");
    #endif

    #if defined(USE_INERTIAL)
        Serial.println("\n\nStarting LSM6DSO initialization...");
    
        // Initialize I2C with your specific pins
        I2CLSM.begin(SDA_PIN, SCL_PIN, 100000);  // SDA, SCL, Frequency (400kHz)
        
        delay(100);
        
        // Initialize sensor
        if (!AccGyr.begin()) {
            Serial.println("   LSM6DSO NOT found! Check wiring and I2C address.");
            Serial.println("   Expected I2C address: 0x6A (or 0x6B if SDO pulled high)");
            while (1) {
                delay(1000);
            }
        }
        
        Serial.println("✓ LSM6DSO initialized successfully!");
        
        // Enable accelerometer and gyroscope
        AccGyr.Enable_X();  // Enable accelerometer
        AccGyr.Enable_G();  // Enable gyroscope
        
        Serial.println("Accelerometer and Gyroscope enabled!");
        Serial.println("\nStarting sensor readings...\n");
    #endif




    #if defined(MAKE_AP)

      // Initialize Preferences
      preferences.begin("bot_config", false);
      String storedSSID = preferences.getString("ssid", "");
      preferences.end();
      
      if (storedSSID.length() > 0) {
        nameOfAP = storedSSID;
      } else {
        tempNameOfAP = String(ROBOT_NAME_AP);
        nameOfAP = tempNameOfAP +" " +getUniqueNumber();
      }
      
      int channel = DEFAULT_WIFI_CHANNEL;
      #if defined(RANDOMIZE_WIFI_CHANNEL)
        channel = random(13)+1;
      #endif
      


      WiFi.softAP(nameOfAP.c_str(), NULL, channel);
      IPAddress IP = WiFi.softAPIP();
      Serial.print("Use 'http://");
      Serial.print(IP);
      Serial.println("' to connect");
    #else
      WiFi.begin(ssid, password);
      while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
      }
      Serial.println("");
      Serial.println("WiFi connected");
      
      Serial.print("Use 'http://")
      Serial.print(WiFi.localIP());
      Serial.println("' to connect");
    #endif
      startCameraServer();
      Serial.println("Camera Ready!");


   
    #if defined(USE_MOTORS)
      servo1.write(1500);
      servo2.write(1500);
    #endif
   
    #if defined(USE_SPEAKER)
      ledcSetup(AUDIO_CHANNEL, 50000, 8);    // 50 kHz, 8-bit
      ledcAttachPin(SPEAKER_PIN, AUDIO_CHANNEL);
      ledcWrite(AUDIO_CHANNEL, 0);

      timer_init(SELECTED_TIMER_GROUP,SELECTED_TIMER_INDEX,&tconfig);// call init before setting counters
      timer_set_counter_value(SELECTED_TIMER_GROUP, timer_idx ,0x00000000ULL);// sets counter value to 0, counters up to alarm value because .counter_dir counts up
      timer_set_alarm_value(SELECTED_TIMER_GROUP, timer_idx, TIMER_TICKS_PER_SAMPLE);
      timer_enable_intr(SELECTED_TIMER_GROUP, timer_idx);// enable interrupts for selected group and timer
      intr_handle_t handle;

      err = timer_isr_register(
          SELECTED_TIMER_GROUP,
          timer_idx,
          timer_group_isr,
          (void *) timer_idx,
          ESP_INTR_FLAG_IRAM | ESP_INTR_FLAG_LEVEL3,
          &handle
      );

      if (err != ESP_OK) {
          Serial.println("Failed to register timer ISR");
      }

      esp_task_wdt_init(5, true); // 5 second timeout
      esp_task_wdt_add(NULL);     // Add current task

      // --- BEGIN PLAY TEST PCM SAMPLE AT STARTUP ---
      playInstrumentSample(vocalSamplePack[0], -12, 0);
      unsigned long t0 = millis();
      while (millis() - t0 < vocalSamplePack[0].length * 2 * TIMER_INTERVAL0_SEC * 1000) {
          handleAudioProcessing();
      }
      ledcDetachPin(SPEAKER_PIN);
      pinMode(SPEAKER_PIN, OUTPUT);
      digitalWrite(SPEAKER_PIN, LOW);
    #endif

   
    #if defined(USE_MIC)
      Serial.println("Initializing PDM microphone...");

      // Configure I2S
      i2s_config_t i2s_config = {
          .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX | I2S_MODE_PDM), // Master, RX, PDM mode
          .sample_rate = I2S_SAMPLE_RATE,
          .bits_per_sample = I2S_SAMPLE_BITS,
          .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT, // Mono
          .communication_format = I2S_COMM_FORMAT_I2S_MSB, // MSB alignment
          .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,    // Interrupt level 1
          .dma_buf_count = 4,                          // Number of DMA buffers
          .dma_buf_len = I2S_DMA_BUF_LEN,              // DMA buffer length
          .use_apll = false,
          .tx_desc_auto_clear = false,
          .fixed_mclk = 0
      };

      // Configure I2S pins
      i2s_pin_config_t pin_config = {
          .bck_io_num = -1,          // Bit clock (not used in PDM mode)
          .ws_io_num = I2S_PIN_CLK,  // Word select (PDM clock)
          .data_out_num = -1,        // Not used
          .data_in_num = I2S_PIN_DATA // Data input
      };

      // Install and start I2S driver
      if (i2s_driver_install(I2S_NUM, &i2s_config, 0, NULL) != ESP_OK) {
          Serial.println("Failed to install I2S driver!");
          while (1);
      }

      if (i2s_set_pin(I2S_NUM, &pin_config) != ESP_OK) {
          Serial.println("Failed to set I2S pins!");
          while (1);
      }
      Serial.println("PDM microphone initialized.");
    #endif
    
    //setToneOnSpeaker(100);
}//end of setup


void loop() 
{
  
  digitalWrite(DEBUG_PIN,HIGH);

  #if defined(USE_BATTERY_MEASUREMENT)
    batteryCounter++;
    if(batteryCounter>BATTERY_MEASUREMENTS_PERIOD)
    {
      battery = analogRead(BATTERY_PIN);
      batteryCounter = 0;
    }

  #endif

  #if defined(USE_DISTANCE_SENSOR)
    uint8_t NewDataReady = 0;
    VL53L4CD_Result_t results;
    uint8_t status;
    char report[64];


    status = sensor_vl53l4cd_sat.VL53L4CD_CheckForDataReady(&NewDataReady);

    if ((!status) && (NewDataReady != 0)) {
      // (Mandatory) Clear HW interrupt to restart measurements
      sensor_vl53l4cd_sat.VL53L4CD_ClearInterrupt();
      // Read measured distance. RangeStatus = 0 means valid data
      sensor_vl53l4cd_sat.VL53L4CD_GetResult(&results);
      //          results.range_status
      //          results.distance_mm
      //          results.signal_per_spad_kcps

      if(results.distance_mm <= 700) {
        // for distances closer than 70cm, update only if status bit yields valid mesaurement (ignore spotty data)
         if(results.range_status == 0) {
          //convert mm measurements to cm
          reportedDistance = results.distance_mm*0.1;
         }
      } else {
        //longer distances always reported as data not as precise, allows near targets to be triggered only when reliable.
        reportedDistance = results.distance_mm*0.1;
      }
    }

    #if defined(SEND_MM_FOR_DISTANCE)
      distance = reportedDistance;
    #endif
  #endif

  #if defined(USE_SPEAKER)
    esp_task_wdt_reset();
  #endif


  #if  defined (USE_INERTIAL)
  
  // Read accelerometer (in mg - milligravity)
    int32_t accelerometer[3] = {0, 0, 0};
    AccGyr.Get_X_Axes(accelerometer);
    
    // Read gyroscope (in mdps - millidegrees per second)
    int32_t gyroscope[3] = {0, 0, 0};
    AccGyr.Get_G_Axes(gyroscope);
    
    // Convert to standard units (g and dps)
    float accel_x = accelerometer[0] / 1000.0f;
    float accel_y = accelerometer[1] / 1000.0f;
    float accel_z = accelerometer[2] / 1000.0f;
    
    float gyro_x = gyroscope[0] / 1000.0f;
    float gyro_y = gyroscope[1] / 1000.0f;
    float gyro_z = gyroscope[2] / 1000.0f;
    
    // Print formatted output
    Serial.printf("Accel(g):  X=%+7.3f  Y=%+7.3f  Z=%+7.3f  |  ", 
                  accel_x, accel_y, accel_z);
    Serial.printf("Gyro(dps): X=%+7.1f  Y=%+7.1f  Z=%+7.1f\n", 
                  gyro_x, gyro_y, gyro_z);
    


  #endif

  int peakFreq = 0;
  int volRMS = 0;
  #if defined(USE_MIC)
    // Read data from the microphone
    size_t bytesRead;
    i2s_read(I2S_NUM, micBuffer, sizeof(micBuffer), &bytesRead, portMAX_DELAY);

    // Prepare the data for FFT
    int samples = bytesRead / sizeof(int16_t);
    int64_t sumSquares = 0;
    for (int i = 0; i < FFT_SAMPLES; i++) {
        if (i < samples) {
            vReal[i] = micBuffer[i]; // Copy microphone data to the real part
        } else {
            vReal[i] = 0; // Zero-pad the remaining samples
        }
        vImag[i] = 0; // Imaginary part is zero
    }
    
    // Calculate RMS over the whole buffer (or as much as we have)
    for(int i=0; i<samples; i++) {
       sumSquares += ((int64_t)micBuffer[i] * micBuffer[i]);
    }
    if(samples > 0) {
       volRMS = sqrt(sumSquares / samples);
    }

    // Perform FFT
    FFT.windowing(vReal, FFT_SAMPLES, FFT_WIN_TYP_HAMMING, FFT_FORWARD); // Apply a Hamming window
    FFT.compute(vReal, vImag, FFT_SAMPLES, FFT_FORWARD); // Compute the FFT
    FFT.complexToMagnitude(vReal, vImag, FFT_SAMPLES); // Compute magnitudes

    //Frequency resolution = sample rate / size of window => 16000Hz/256 = 62.5Hz

    // Find the peak frequency
    double peakFrequency = FFT.majorPeak(vReal, FFT_SAMPLES, I2S_SAMPLE_RATE);
    peakFreq =  (int) peakFrequency;
    if (peakFreq < 0) {
        peakFreq = 0;
    }
  #endif

  //send distance to host computer via Socket
  String distanceStr = String(distance); // micOutputStr; // Use microphone output instead of distance
  String batteryStr =  String(battery); 
  String peakFreqStr = String(peakFreq);
  String volRMSStr = String(volRMS);
  //Serial.println(String(distance));
  String messageToSendInString;
  if(sendVersionString)
  {
    sendVersionString = false;
    messageToSendInString = String("V1.0.0");
  }
  else
  {
    // Format: [PeakFreq], [Volume], [Distance], [Battery]
    messageToSendInString =  peakFreqStr + "," + volRMSStr + "," + distanceStr + "," + batteryStr + ", ";
  }
  messageToSendInString.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
  int lengthOfIncommingMessage = messageToSendInString.length();
  commandBuffer[lengthOfIncommingMessage] = 0;
  sendDataViaSocket(commandBuffer, lengthOfIncommingMessage);
  
  #if defined(USE_LEDS)
    #if defined(MAKE_AP)
      if(WiFi.softAPgetStationNum()==0)
      {

          strip.setBrightness(25);
          strip.setPixelColor(0, colorBlue);
          strip.setPixelColor(1, colorBlue);
          strip.setPixelColor(2, colorBlue);
          strip.setPixelColor(3, colorBlue);
          strip.show();
          shouldSetGreen = true;
      }
      else
      {
        if(shouldSetGreen)
        {
          shouldSetGreen = false;
          strip.setBrightness(25);
          strip.setPixelColor(0, 0,255,0);
          strip.setPixelColor(1, 0,255,0);
          strip.setPixelColor(2, 0,255,0);
          strip.setPixelColor(3, 0,255,0);
          strip.show();
        }
      }
    #endif
  #endif
  digitalWrite(DEBUG_PIN,LOW);
}
