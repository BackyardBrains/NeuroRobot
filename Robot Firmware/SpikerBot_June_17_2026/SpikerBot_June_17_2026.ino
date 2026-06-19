// Spikerbot firmware June 17th 2026
// Made for BYB ESP32 S3 & Spikerbot Chassis Motherborad V3
// Programmed by selecting "ESP32S3 Dev Module" in Arduino
// set board parameters in Arduino IDE:
// PSRAM: OPI PSRAM
// Flash mode: OPI 80Mhz
// Written by Stanislav Mircic, Alex Hatch
// Backyard Brains


#include "esp_camera.h"
#include <WiFi.h>
#include "esp_wifi.h"  // For esp_wifi_set_ps(WIFI_PS_NONE)
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
#define USE_INERTIAL 1
#define SEND_MM_FOR_DISTANCE 1

//free pin that can be used for debug IO1
#define DEBUG_PIN 1

#if defined(USE_BATTERY_MEASUREMENT)
#define BATTERY_PIN 6
int batteryCounter = 0;
//make measurement every 2 seconds (1second = 200 loops approx.)
#define BATTERY_MEASUREMENTS_PERIOD (400)

// EMA (Exponential Moving Average) filter parameters
#define BAT_EMA_ALPHA 0.1f
float smoothed_battery_adc = 0;
bool first_battery_reading = true;
#endif

// === Power Button & Gate ===
// Button on GPIO 4: pulled LOW, goes HIGH when pressed.
// Gate on GPIO 38: HIGH = system on, LOW = system off.
// Hold button 3 seconds to power down (must release after boot first).
#define POWER_BUTTON_PIN 4
#define POWER_GATE_PIN 38
#define POWER_HOLD_MS 3000  // hold duration to trigger shutdown

bool powerButtonReleasedOnce = false;     // arm shutdown only after first release
unsigned long powerButtonPressStart = 0;  // millis() when button was first pressed
bool powerButtonWasPressed = false;       // previous loop's button state
bool shutdownTriggered = false;           // set true after 3s hold, awaiting release




#if defined(USE_SPEAKER)

// ESP-IDF 5.x / Arduino Core 3.x: legacy driver/timer.h, driver/i2s.h,
// and driver/periph_ctrl.h are removed. Use the new channel-based I2S API.
#include <stdio.h>
#include "esp_types.h"
#include "driver/i2s_std.h"
#include "esp_intr_alloc.h"
#include "esp_task_wdt.h"
#include "vocal_sample_pack.h"
#include "instrument_sample_pack.h"

#define PCM_SAMPLE_RATE_HZ 22051  // Matches actual ISR rate (80MHz/2/1814 = 22050.72 Hz). \
                                  // DAC at 22051 Hz: drift = -0.28 samples/sec (ring slowly \
                                  // empties, never overflows). Pitch offset: 0.0045% (inaudible).
#define TIMER_INTERVAL0_SEC (1.0 / PCM_SAMPLE_RATE_HZ)
  // MAX98357A I2S DAC pins
#define I2S_DAC_NUM I2S_NUM_1
#define I2S_DAC_BCLK_PIN 47
#define I2S_DAC_DATA_PIN 48
#define I2S_DAC_LRC_PIN 14     // Word-select (LRC). Wire SD_MODE on MAX98357A to 3.3V.
#define MAX_POLYPHONY 4        // simultaneous instrument voices (ISR loops this many times)
#define PITCH_SHIFT_SCALE 256  // Q8.8 fixed-point scale

// Step-size table: Q8.8 fixed point, 37 entries for semitones -36..0
//   index = semitoneOffset + 36
//   stepSize = 256 * 2^(semitone/12)
//   -36 = 0.125x speed (3 octaves down), 0 = 1.0x speed (44100 Hz native)
const uint16_t semitoneStepSizeTable[37] = {
  // -36  -35    -34    -33    -32    -31    -30    -29    -28    -27    -26    -25
  0x0020, 0x0022, 0x0024, 0x0026, 0x0028, 0x002B, 0x002D, 0x0030, 0x0033, 0x0036, 0x0039, 0x003C,
  // -24  -23    -22    -21    -20    -19    -18    -17    -16    -15    -14    -13
  0x0040, 0x0044, 0x0048, 0x004C, 0x0051, 0x0055, 0x005A, 0x005F, 0x0065, 0x006B, 0x0071, 0x0078,
  // -12  -11    -10    -9     -8     -7     -6     -5     -4     -3     -2     -1      0
  0x0080, 0x0088, 0x008F, 0x0098, 0x00A1, 0x00AA, 0x00B4, 0x00BF, 0x00CA, 0x00D6, 0x00E2, 0x00EF, 0x0100
};

portMUX_TYPE audioMux = portMUX_INITIALIZER_UNLOCKED;

static volatile uint32_t audioDmaStalls = 0;  // i2s_write returned 0 bytes

// I2S DAC channel handle (new ESP-IDF 5.x channel-based API)
static i2s_chan_handle_t i2s_dac_tx_handle = NULL;
static TaskHandle_t audioFeedTaskHandle = NULL;

uint8_t audioVolume = 255;  // Maximum. Tune down with o:NNN; if clipping occurs.
uint8_t instrumentAgeCounter = 0;

typedef struct {
  const audioSample* instrument;
  uint32_t index;     // Q8.8 phase accumulator
  uint16_t stepSize;  // Q8.8 step per sample
  uint8_t loopCount;
  bool active;
  bool hasLoopedOnce;
  uint8_t age;
  int8_t semitoneOffset;
} InstrumentVoice;

InstrumentVoice instrumentVoices[MAX_POLYPHONY];

bool isAnyAudioPlaying() {
  return instrumentVoices[0].active || instrumentVoices[1].active;
}

bool isVoiceAudiblyActive(const InstrumentVoice& v) {
  return v.active && v.index < v.instrument->length;  // Use -> for pointer access
}

#endif

#if defined(USE_MIC)
#include "driver/i2s_pdm.h"
#include <arduinoFFT.h>

// I2S PDM microphone channel handle (new ESP-IDF 5.x channel-based API)
static i2s_chan_handle_t i2s_mic_rx_handle = NULL;

// I2S configuration for the microphone
#define I2S_NUM I2S_NUM_0                          // I2S port number
#define I2S_SAMPLE_RATE 16000                      // Sampling rate (16 kHz)
#define I2S_SAMPLE_BITS I2S_BITS_PER_SAMPLE_16BIT  // 16-bit samples
#define I2S_DMA_BUF_LEN 512                        // Half-window hop: 512 new samples per read (32ms at 16kHz) \
                                                   // Combined with micRing[1024] → 50% overlapped FFT: \
                                                   // full 15.6 Hz/bin resolution at ~20 Hz update rate
#define FFT_SAMPLES 1024                           // FFT window size — change to 256/512/1024 to trade latency vs pitch resolution \
                                                   // 1024 @ 16kHz = 64ms window, 15.6 Hz/bin, separates notes from C4 (261Hz) upward

// Bark-scale cochlear band model
// 24 log-spaced bands from 100 Hz to 5000 Hz (17.6 Bark units — full musical cochlear range)
#define BARK_BANDS 24
#define BARK_FREQ_MIN 100.0f
#define BARK_FREQ_MAX 5000.0f

// PDM microphone pins
#define I2S_PIN_CLK 40   // I2S clock pin (CLK)
#define I2S_PIN_DATA 41  // I2S data pin (DAT)

// Buffer for microphone data
// micBuffer holds the latest 512 new samples (half-window hop).
// micRing holds the last full 1024-sample window for FFT (50% overlap).
int16_t micBuffer[I2S_DMA_BUF_LEN];
static int16_t micRing[FFT_SAMPLES];  // rolling 1024-sample window, zero-init at boot
double vReal[FFT_SAMPLES];
double vImag[FFT_SAMPLES];

// Band boundary indices into the FFT output array (computed once in setup)
uint16_t barkBandStart[BARK_BANDS];
uint16_t barkBandEnd[BARK_BANDS];
uint8_t barkBandLevel[BARK_BANDS];  // normalised 0-255 per band, sent in h: telemetry field

ArduinoFFT<double> FFT = ArduinoFFT<double>();
String micOutputStr = "0";  // String to store the microphone output
#endif

#if defined(USE_DISTANCE_SENSOR)
#define I2C_SDA 45
#define I2C_SCL 21
#define DEV_I2C Wire  // Shared I2C bus 0 with camera SCCB
VL53L4CD sensor_vl53l4cd_sat(&DEV_I2C, 42);
int reportedDistance = 0;
#endif


#if defined(USE_INERTIAL)
#include "Spikerbot_IMU.h"

// Instantiate our custom IMU library. 
// 0x6B is the locked address we are forcing via the software hardware-fix
Spikerbot_IMU imu(0x6B);
#endif


#define CAMERA_MODEL_BYBV1  // Has PSRAM
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
#define LED_PIN 13
#define LED_COUNT 4
volatile int diodeCommand = 0;
Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
uint32_t colorBlue = (0, 0, 255);
uint32_t colorGreen = (0, 255, 0);
bool shouldSetGreen = false;
#endif

#if defined(USE_MOTORS)
// All three servos use direct LEDC API — ESP32Servo.h removed.
// Camera XCLK owns LEDC channel 0 / timer 0 — channels 4-6 are safe.
#define SERVO_LEDC_FREQ       50   // Standard servo 50 Hz
#define SERVO_LEDC_RESOLUTION 14   // 14-bit (0-16383)
#define RIGHT_SERVO_PIN       2
#define RIGHT_LEDC_CHANNEL    4
#define LEFT_SERVO_PIN        5
#define LEFT_LEDC_CHANNEL     5
#define AUX_SERVO_PIN         1
#define AUX_LEDC_CHANNEL      6
int pos = 90;
int motorSpeedLeft;
int motorSpeedRight;
int motorSpeedAux;

// Helper: write microseconds (1000-2000) to any servo pin via raw LEDC
void servoWriteMicroseconds(int pin, int us) {
  if (us < 1000) us = 1000;
  if (us > 2000) us = 2000;
  // duty = us / period * max_duty  (period = 1/50Hz = 20000us, max_duty = 2^14 = 16384)
  uint32_t duty = (uint32_t)((uint64_t)us * 16384 / 20000);
  ledcWrite(pin, duty);  // v3.x API: ledcWrite takes the PIN
}
#endif

int this_speed = 0;
int io_command[] = { 0, 0, 0, 0, 0 };
long duration;
long distance = 0;
long battery = 0;
int this_tone = 0;
int micPin = 0;

int micVal = 0;
int toneVal = 0;

void startCameraServer();
void sendDataViaSocket(char* dataToSend, int lengthOfData);

#if defined(USE_LEDS)
void turnOffLEDs() {
  strip.setPixelColor(0, strip.Color(0, 0, 0));
  strip.setPixelColor(1, strip.Color(0, 0, 0));
  strip.setPixelColor(2, strip.Color(0, 0, 0));
  strip.setPixelColor(3, strip.Color(0, 0, 0));
  strip.show();
}
#endif

#if defined(USE_SPEAKER)

// Write one 16-bit PCM sample to the MAX98357A (stereo frame, L=R).
// ONLY_LEFT mode injects zeros every other frame (22050 Hz alias crackle) —
// using RIGHT_LEFT with duplicate data is reliable with the legacy ESP32 I2S driver.
inline void audioWriteI2S(int16_t sample16) {
  int32_t scaled = ((int32_t)sample16 * audioVolume) / 255;
  scaled = constrain(scaled, -32768, 32767);
  int16_t s = (int16_t)scaled;
  uint32_t frame = ((uint32_t)(uint16_t)s << 16) | (uint16_t)s;  // L=R
  size_t written;
  i2s_channel_write(i2s_dac_tx_handle, &frame, 4, &written, 0);  // non-blocking
}

// Generate CHUNK samples from all active voices and write directly to I2S DMA.
// Called from audioFeedTask (task context) — no ISR timing budget, PSRAM reads OK.
// Rate: I2S TX_DONE fires every 11.6ms (256 samples @ 22051 Hz).
// No ring buffer needed — generation rate = consumption rate by construction.
static void generateAndFeedAudio() {
  const int CHUNK = 256;
  static uint32_t txBuf[CHUNK];

  for (int s = 0; s < CHUNK; s++) {
    int32_t mixed = 0;
    uint8_t activeCount = 0;

    for (int i = 0; i < MAX_POLYPHONY; i++) {
      auto& v = instrumentVoices[i];
      if (!v.active) continue;

      uint32_t sampleIndex = v.index >> 8;
      if (sampleIndex < v.instrument->length) {
        mixed += (int32_t)((const int16_t*)v.instrument->pcm)[sampleIndex];
        activeCount++;
      }
      v.index += v.stepSize;
      sampleIndex = v.index >> 8;

      if (sampleIndex >= v.instrument->loopEnd) {
        if (v.loopCount > 0) {
          v.loopCount--;
          v.hasLoopedOnce = true;
          v.index = v.instrument->loopStart << 8;
        } else {
          v.active = false;
        }
      } else if (sampleIndex >= v.instrument->length) {
        v.active = false;
      }
    }

    // Additive mixing: sum the signals instead of averaging.
    // If the sum exceeds the 16-bit range, clip it hard.
    int32_t out = mixed;
    out = (out * audioVolume) / 255;
    if (out > 32767) out = 32767;
    if (out < -32768) out = -32768;
    int16_t pcm = (int16_t)out;
    txBuf[s] = ((uint32_t)(uint16_t)pcm << 16) | (uint16_t)pcm;
  }

  size_t written = 0;
  i2s_channel_write(i2s_dac_tx_handle, txBuf, CHUNK * 4, &written, pdMS_TO_TICKS(12));
  if (written == 0) audioDmaStalls++;
}

// Hard audio reset: deactivate all voices, flush ring buffer, clear DMA.
// Call this if corruption is detected or on demand via r:1; command.
void resetAudio() {
  portENTER_CRITICAL(&audioMux);
  for (int i = 0; i < MAX_POLYPHONY; i++) instrumentVoices[i].active = false;
  audioDmaStalls = 0;
  portEXIT_CRITICAL(&audioMux);
  i2s_channel_disable(i2s_dac_tx_handle);
  i2s_channel_enable(i2s_dac_tx_handle);
  Serial.println("[AUDIO] Reset: all voices stopped, DMA cleared");
}

// Task-based audio generation — wakes on I2S TX_DONE, generates 256 samples,
// writes directly to DMA. No timer ISR, no ring buffer, no rate mismatch.
// Running at priority 18 on Core 1: preempts camera (prio ~15), never Core 0.
// PSRAM reads are fine in task context — 11.6ms budget per 256-sample batch.
static void audioFeedTask(void* param) {
  uint32_t lastDiagMs = 0;
  while (true) {
    generateAndFeedAudio();
    vTaskDelay(pdMS_TO_TICKS(10));  // ~100 refills/sec — stays ahead of 22kHz DMA drain

    uint32_t now = millis();
    if (now - lastDiagMs >= 5000) {
      lastDiagMs = now;
      Serial.printf("[AUDIO] heap=%u  dma_stalls=%u\n",
                    (unsigned)heap_caps_get_free_size(MALLOC_CAP_DEFAULT),
                    (unsigned)audioDmaStalls);
      audioDmaStalls = 0;
    }
  }
}

//Sound command example s:NNN;
//  s - sound command name
//  : - separator between name and value
//  NNN - numeric code selecting vocal or instrument sample
//  ; - end of the command (separator)

void playInstrumentSample(const audioSample& sample, int8_t semitoneOffset, uint8_t loopCount = 1) {

  // All samples are 16-bit signed PCM. No 8-bit path.
  // Clamp to -36..0 (table has 37 entries covering 3 octaves down)
  if (semitoneOffset > 0) semitoneOffset = 0;
  if (semitoneOffset < -36) semitoneOffset = -36;

  uint8_t tableIndex = semitoneOffset + 36;
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
    // Evict the oldest (lowest age counter) active voice
    chosenIndex = 0;
    for (int i = 1; i < MAX_POLYPHONY; i++) {
      if (instrumentVoices[i].age < instrumentVoices[chosenIndex].age)
        chosenIndex = i;
    }
  }

  // Was any OTHER voice active before we claim this slot?
  // (must check before setting v.active=true to get the "before" state)
  bool wasAnyActive = false;
  for (int i = 0; i < MAX_POLYPHONY; i++) {
    if (i != chosenIndex && instrumentVoices[i].active) {
      wasAnyActive = true;
      break;
    }
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

  if (!wasAnyActive) {
    // Transitioning from silence → audio: flush stale zeros so sound starts instantly.
    // Skip when adding to polyphony — flushing kills other voices' queued audio.
    // (ring buffer removed — i2s_zero_dma_buffer used for clean start if needed)
  }

  portEXIT_CRITICAL(&audioMux);
}

// IRAM_ATTR: called from the hardware timer ISR.
void IRAM_ATTR applyLoopBlend(uint8_t* data, uint16_t loopStart, uint16_t loopEnd, uint8_t repeatFactor) {
  if (loopEnd - loopStart < 10) return;
  for (int i = 0; i < 5; i++) {
    int16_t from = data[loopEnd - 5 + i];
    int16_t to = data[loopStart + i];
    data[loopStart + i] = (from * (5 - i) + to * i) / 5;
  }
}

void setToneOnSpeaker(int toneFrequency) {
  // Silence command: ignore while audio is already playing.
  // tx_desc_auto_clear=true will hold the DAC at 0V when no samples are pushed.
  if (toneFrequency < 1) {
    return;  // let the ring buffer drain naturally
  }
  // Raw-frequency tone (>=500) removed — ignore.
  else if (toneFrequency >= 500) {
    return;
  } else {
    switch (toneFrequency) {  // numeric codes trigger sample playback

      // vocal samples - emotional phrases
      case 31: playInstrumentSample(vocalSamplePack[0], 0, 0); break;  // ciao — semitone 0 = natural pitch at 22050 Hz ISR
      case 32:
        playInstrumentSample(vocalSamplePack[1], 0, 0);
        break;  // uhoh 16-bit
      case 33:  playInstrumentSample(vocalSamplePack[2], 0, 0); break;
      case 34: playInstrumentSample(vocalSamplePack[3], 0, 0); break;  // hmm — 16-bit 22050 Hz
      case 35: playInstrumentSample(vocalSamplePack[4], 0, 0); break;  // snore 16-bit
      case 36:
        playInstrumentSample(vocalSamplePack[5], 0, 0);
        break;  // nom 16-bit
      case 37:  playInstrumentSample(vocalSamplePack[6], 0, 0); break;
      case 38:  playInstrumentSample(vocalSamplePack[7], 0, 0); break;
      case 39:  playInstrumentSample(vocalSamplePack[8], 0, 0); break;
      case 40:  playInstrumentSample(vocalSamplePack[9], 0, 0); break;

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
      case 328: playInstrumentSample(instrumentSamplePack[3], -24, 0); break;
      case 329: playInstrumentSample(instrumentSamplePack[3], -23, 0); break;
      case 330: playInstrumentSample(instrumentSamplePack[3], -22, 0); break;
      case 331: playInstrumentSample(instrumentSamplePack[3], -21, 0); break;
      case 332: playInstrumentSample(instrumentSamplePack[3], -20, 0); break;
      case 333: playInstrumentSample(instrumentSamplePack[3], -19, 0); break;
      case 334: playInstrumentSample(instrumentSamplePack[3], -18, 0); break;
      case 335: playInstrumentSample(instrumentSamplePack[3], -17, 0); break;
      case 336: playInstrumentSample(instrumentSamplePack[3], -16, 0); break;
      case 337: playInstrumentSample(instrumentSamplePack[3], -15, 0); break;
      case 338: playInstrumentSample(instrumentSamplePack[3], -14, 0); break;
      case 339: playInstrumentSample(instrumentSamplePack[3], -13, 0); break;
      case 340: playInstrumentSample(instrumentSamplePack[3], -12, 0); break;
      case 341: playInstrumentSample(instrumentSamplePack[3], -11, 0); break;
      case 342: playInstrumentSample(instrumentSamplePack[3], -10, 0); break;
      case 343: playInstrumentSample(instrumentSamplePack[3],  -9, 0); break;
      case 344: playInstrumentSample(instrumentSamplePack[3],  -8, 0); break;
      case 345: playInstrumentSample(instrumentSamplePack[3],  -7, 0); break;
      case 346: playInstrumentSample(instrumentSamplePack[3],  -6, 0); break;
      case 347: playInstrumentSample(instrumentSamplePack[3],  -5, 0); break;
      case 348: playInstrumentSample(instrumentSamplePack[3],  -4, 0); break;
      case 349: playInstrumentSample(instrumentSamplePack[3],  -3, 0); break;
      case 350: playInstrumentSample(instrumentSamplePack[3],  -2, 0); break;
      case 351: playInstrumentSample(instrumentSamplePack[3],  -1, 0); break;
      case 352: playInstrumentSample(instrumentSamplePack[3],   0, 0); break;

      // triangle wave synth
      case 428: playInstrumentSample(instrumentSamplePack[0], -24, 200); break;
      case 429: playInstrumentSample(instrumentSamplePack[0], -23, 200); break;
      case 430: playInstrumentSample(instrumentSamplePack[0], -22, 200); break;
      case 431: playInstrumentSample(instrumentSamplePack[0], -21, 200); break;
      case 432: playInstrumentSample(instrumentSamplePack[0], -20, 200); break;
      case 433: playInstrumentSample(instrumentSamplePack[0], -19, 200); break;
      case 434: playInstrumentSample(instrumentSamplePack[0], -18, 200); break;
      case 435: playInstrumentSample(instrumentSamplePack[0], -17, 200); break;
      case 436: playInstrumentSample(instrumentSamplePack[0], -16, 200); break;
      case 437: playInstrumentSample(instrumentSamplePack[0], -15, 200); break;
      case 438: playInstrumentSample(instrumentSamplePack[0], -14, 200); break;
      case 439: playInstrumentSample(instrumentSamplePack[0], -13, 200); break;
      case 440: playInstrumentSample(instrumentSamplePack[0], -12, 200); break;
      case 441: playInstrumentSample(instrumentSamplePack[0], -11, 200); break;
      case 442: playInstrumentSample(instrumentSamplePack[0], -10, 200); break;
      case 443: playInstrumentSample(instrumentSamplePack[0], -9, 200); break;
      case 444: playInstrumentSample(instrumentSamplePack[0], -8, 200); break;
      case 445: playInstrumentSample(instrumentSamplePack[0], -7, 200); break;
      case 446: playInstrumentSample(instrumentSamplePack[0], -6, 200); break;
      case 447: playInstrumentSample(instrumentSamplePack[0], -5, 200); break;
      case 448: playInstrumentSample(instrumentSamplePack[0], -4, 200); break;
      case 449: playInstrumentSample(instrumentSamplePack[0], -3, 200); break;
      case 450: playInstrumentSample(instrumentSamplePack[0], -2, 200); break;
      case 451: playInstrumentSample(instrumentSamplePack[0], -1, 200); break;
      case 452: playInstrumentSample(instrumentSamplePack[0], 0, 200); break;
    }
  }
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

bool websocket_led_dirty = false;

void executeRGBDiodeCommand(int* diodeParameters) {
  int appIndex = diodeParameters[0];  //0-3
  
  // LED Physical Layout Swap Fix:
  // App sends: 0=FL, 1=FR, 2=RL, 3=RR
  // Physical is: P0=RL, P1=RR, P2=FL, P3=FR
  // So we swap 0 <-> 2 (FL/RL) and 1 <-> 3 (FR/RR)
  int LEDIndex = appIndex;
  if (appIndex == 0) LEDIndex = 2;
  else if (appIndex == 2) LEDIndex = 0;
  else if (appIndex == 1) LEDIndex = 3;
  else if (appIndex == 3) LEDIndex = 1;

  if (LEDIndex < 0) {
    return;
  }
  if (LEDIndex >= LED_COUNT) {
    return;
  }

  // sRGB gamma 2.2: perceptually linear fading
  auto srgbGamma = [](uint8_t x) -> uint8_t {
    float v = powf(x / 255.0f, 2.2f) * 255.0f + 0.5f;
    return (uint8_t)v;
  };
  uint32_t color = strip.Color(
    srgbGamma(diodeParameters[1]),
    srgbGamma(diodeParameters[2]),
    srgbGamma(diodeParameters[3]));
  strip.setPixelColor(LEDIndex, color);
  // Defer strip.show() to the throttled main loop to prevent IRQ blocking audio stalls
  websocket_led_dirty = true;
}

#endif


unsigned long lastSocketArrivalTime = 0;

void newDataArrivedFromSocket(char* data, int lengthOfData) {
  // If it's been more than 1 second since we last received data, we assume the user just hit "Play"
  if (lastSocketArrivalTime > 0 && (millis() - lastSocketArrivalTime > 1000)) {
#if defined(USE_INERTIAL)
    imu.resetTiltBaseline(); // Auto-recalibrate the "level" ground when simulation starts
#endif
  }
  
  lastSocketArrivalTime = millis();  // Track the latest valid app communication

  // breaks string str into a series of tokens using delimiter ";"
  // Namely split strings into commands
  char* command = strtok(data, ";");
  while (command != 0) {
    // Split the command in 2 parts: name and value
    char* separator = strchr(command, ':');
    if (separator != 0) {
      // Actually split the string in 2: replace ':' with 0
      *separator = 0;
      --separator;

      if (*separator == 'l')  //command for left motor
      {
        separator = separator + 2;
#if defined(USE_MOTORS)
        motorSpeedLeft = atoi(separator);  //read speed
        if (motorSpeedLeft > 255) {
          motorSpeedLeft = 255;
        }
        if (motorSpeedLeft < -255) {
          motorSpeedLeft = -255;
        }
        motorSpeedLeft = motorSpeedLeft * 2 + 1500;

        servoWriteMicroseconds(RIGHT_SERVO_PIN, motorSpeedLeft);
        //Serial.println(motorSpeedLeft);
#endif
      }
      if (*separator == 'r')  //command for right motor
      {
        separator = separator + 2;
#if defined(USE_MOTORS)
        motorSpeedRight = atoi(separator);  //read speed
        if (motorSpeedRight > 255) {
          motorSpeedRight = 255;
        }
        if (motorSpeedRight < -255) {
          motorSpeedRight = -255;
        }
        motorSpeedRight = motorSpeedRight * 2 + 1500;

        servoWriteMicroseconds(LEFT_SERVO_PIN, motorSpeedRight);
        //Serial.println(motorSpeedRight);
#endif
      }
      if (*separator == 'a')  //command for aux motor
      {
        separator = separator + 2;
#if defined(USE_MOTORS)
        motorSpeedAux = atoi(separator);  //read speed
        if (motorSpeedAux > 255) {
          motorSpeedAux = 255;
        }
        if (motorSpeedAux < -255) {
          motorSpeedAux = -255;
        }
        motorSpeedAux = motorSpeedAux * 2 + 1500;

        servoWriteMicroseconds(AUX_SERVO_PIN, motorSpeedAux);
#endif
      }
      //d:2,200,128,200;
      if (*separator == 'd')  //command for LED diode
      {
        separator = separator + 2;
#if defined(USE_LEDS)
        char tempBuffer[4];
        int diodeParameters[4];
        int parameterIndex = 0;
        int characterIndex = 0;
        int foundEndOfTheCommand = 0;
        while (characterIndex < 15) {
          int tempBufferIndex = 0;
          while (tempBufferIndex < 4) {
            if (separator[characterIndex] == ',' || separator[characterIndex] == ';' || separator[characterIndex] == 0) {
              tempBuffer[tempBufferIndex] = 0;
              diodeParameters[parameterIndex] = atoi(tempBuffer);
              parameterIndex++;
              if (separator[characterIndex] == ';' || separator[characterIndex] == 0) {
                foundEndOfTheCommand = 1;
              }
              characterIndex++;
              break;
            } else {
              tempBuffer[tempBufferIndex] = separator[characterIndex];
              characterIndex++;
              tempBufferIndex++;
            }
          }
          if (foundEndOfTheCommand) {
            foundEndOfTheCommand = 0;
            break;
          }
        }
        if (parameterIndex >= 4) {
          executeRGBDiodeCommand(diodeParameters);
        }
#endif
      }
      if (*separator == 's')  //command for sound generator
      {
        separator = separator + 2;
        this_tone = atoi(separator);  //read frequency
#if defined(USE_SPEAKER)
        setToneOnSpeaker(this_tone);
#endif
      }
      if (*separator == 'n')  //command for renaming SSID
      {
        separator = separator + 2;
        String newName = String(separator);
        if (newName.length() > 0 && newName.length() < 32) {
          Serial.println("Updating SSID and Rebooting...");
          delay(100);

// Disable audio timer to prevent ISR crash during flash write
#if defined(USE_SPEAKER)
          // timer_pause removed — no hardware timer in task-based architecture
#endif

          preferences.begin("bot_config", false);
          preferences.putString("ssid", "Spikerbot " + newName);
          preferences.end();

          ESP.restart();
        }
      }
      if (*separator == 'v')  //get version of firmware
      {
        separator = separator + 2;
        sendVersionString = true;
      }
      if (*separator == 'x')  // audio reset — x:1; flushes ring, DMA, stops all voices
      {
#if defined(USE_SPEAKER)
        resetAudio();
#endif
      }
      if (*separator == 'o')  //output volume  e.g. o:200;
      {
        separator = separator + 2;
#if defined(USE_SPEAKER)
        int vol = atoi(separator);
        if (vol < 0) vol = 0;
        if (vol > 255) vol = 255;
        audioVolume = (uint8_t)vol;
#endif
      }
    }
    // Find the next command in input string
    command = strtok(0, ";");
  }  //end of while
}

uint32_t getUniqueNumber() {
  uint32_t id = 0;
  for (int i = 0; i < 17; i = i + 8) {
    id |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }
  return id;
}

void setup() {

  // === POWER GATE: latch on immediately so user can release button ===
  pinMode(POWER_GATE_PIN, OUTPUT);
  digitalWrite(POWER_GATE_PIN, HIGH);
  pinMode(POWER_BUTTON_PIN, INPUT);  // external pull-down, HIGH when pressed

  pinMode(DEBUG_PIN, OUTPUT);
  digitalWrite(DEBUG_PIN, LOW);
  // Camera power regulator enable (GPIO 39): CAM PWR net
  // HIGH = enable regulator = camera powered
  pinMode(39, OUTPUT);
  digitalWrite(39, HIGH);
  delay(150);  // Let regulator stabilize before SCCB probe

#if defined(USE_BATTERY_MEASUREMENT)
    //set ADC for battery monitoring
  pinMode(BATTERY_PIN, INPUT);
  analogSetAttenuation(ADC_11db);
  analogReadResolution(12);
  
  // Take an initial synchronous average to prevent starting at 0%
  for (int i = 0; i < 8; i++) {
    smoothed_battery_adc += analogRead(BATTERY_PIN);
    delay(2);
  }
  smoothed_battery_adc /= 8.0f;
  first_battery_reading = false;
  
  // Down-sample and mathematically shift to the format the Dart app expects
  battery = (int)(smoothed_battery_adc * 1.1f * 1023.0f / 4095.0f);
#endif

  Serial.begin(115200);  // 115200 is more reliable for USB CDC on ESP32-S3
  Serial.setDebugOutput(true);
  Serial.println();

#if defined(USE_LEDS)
  strip.begin();
  strip.show();
  strip.setBrightness(255);
  strip.setPixelColor(0, 0);
  strip.setPixelColor(1, 0);
  strip.setPixelColor(2, 0);
  strip.setPixelColor(3, 0);
  strip.show();
#endif

  // ===== LED Diagnostic Flash System =====
  // On failure, blinks all 4 LEDs RED a specific number of times.
  // On success, normal startup (ciao + blue fade) plays as usual.
  //
  // Error codes (Nx RED blinks, repeated 3x with pauses):
  //   1 RED  = Camera init failed
  //   2 RED  = I2S DAC (speaker) init failed
  //   3 RED  = I2S PDM Mic init failed
  //   4 RED  = WiFi AP failed
  //   5 RED  = Distance sensor failed

  // PSRAM diagnostic — critical for camera framebuffers
  Serial.printf("PSRAM found: %s, size: %u bytes, free: %u bytes\n",
                psramFound() ? "YES" : "NO",
                (unsigned)ESP.getPsramSize(),
                (unsigned)ESP.getFreePsram());

  camera_config_t config;  // NOT zero-init — matches official CameraWebServer example
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
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;       // 20MHz — matches official example
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_QVGA;
  config.grab_mode = CAMERA_GRAB_LATEST;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 10;
  config.fb_count = 2;

  //camera init
  esp_err_t err = esp_camera_init(&config);
  Serial.println("Camera Init");
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
#if defined(USE_LEDS)
    // ERROR CODE 1: Camera — 1 red blink, repeated 3x
    for (int rep = 0; rep < 3; rep++) {
      uint32_t red = strip.Color(50, 0, 0);
      strip.setPixelColor(0, red);
      strip.setPixelColor(1, red);
      strip.setPixelColor(2, red);
      strip.setPixelColor(3, red);
      strip.show();
      delay(300);
      strip.setPixelColor(0, 0);
      strip.setPixelColor(1, 0);
      strip.setPixelColor(2, 0);
      strip.setPixelColor(3, 0);
      strip.show();
      delay(700);
    }
    delay(1000);
#endif
    // Don't return — continue init so other peripherals can still work
  } else {
    Serial.println("Camera OK");
  }

  sensor_t* s = esp_camera_sensor_get();

  if (s != NULL) {
    s->set_whitebal(s, 0);       // 0 = Auto White Balance OFF (Prevents background hue shifting)
    s->set_exposure_ctrl(s, 1);  // Auto exposure control ON
    s->set_gain_ctrl(s, 1);      // Auto gain control ON
    s->set_saturation(s, 2);     // Adjust saturation (-2 to 2)
    s->set_brightness(s, 0);     // Adjust brightness (-2 to 2)
    s->set_contrast(s, 1);       // Adjust contrast (-2 to 2)

    // Optimizations for color detection
    s->set_lenc(s, 1);            // Lens correction
    s->set_whitebal(s, 1);        // Auto White Balance 0=disable, 1=enable
    s->set_awb_gain(s, 1);        // Auto White Balance Gain 0=disable, 1=enable
    s->set_wb_mode(s, 0);         // Auto White Balance Mode
    s->set_aec2(s, 1);            // Auto Exposure Control DSP
    s->set_dcw(s, 1);             // Downsize enable
    s->set_ae_level(s, -1);       // Auto Exposure Level (-2 to 2) -2 for darker image/better saturation
    s->set_special_effect(s, 0);  // Ensure no special effects
  } else {
    Serial.println("Camera sensor NULL — skipping sensor config");
  }

  // === ISOLATION TEST: capture BEFORE any servo/audio/mic init ===
  Serial.println("\n=== CAMERA ISOLATION TEST ===");
  delay(500);  // Let camera settle
  camera_fb_t* iso_fb = esp_camera_fb_get();
  if (iso_fb) {
    Serial.printf("ISOLATION CAPTURE OK: %dx%d, %u bytes, format=%d\n",
                  iso_fb->width, iso_fb->height, iso_fb->len, iso_fb->format);
    esp_camera_fb_return(iso_fb);
  } else {
    Serial.println("ISOLATION CAPTURE FAILED — camera broken before servos/audio!");
  }
  // Try a second capture
  iso_fb = esp_camera_fb_get();
  if (iso_fb) {
    Serial.printf("ISOLATION CAPTURE 2 OK: %dx%d, %u bytes\n",
                  iso_fb->width, iso_fb->height, iso_fb->len);
    esp_camera_fb_return(iso_fb);
  } else {
    Serial.println("ISOLATION CAPTURE 2 FAILED");
  }
  Serial.println("=== END ISOLATION TEST ===\n");

#if defined(USE_MOTORS)
  // All servos: direct LEDC with explicit channel assignment.
  // Camera XCLK owns channel 0 / timer 0 — we use channels 4, 5, 6.
  ledcAttachChannel(RIGHT_SERVO_PIN, SERVO_LEDC_FREQ, SERVO_LEDC_RESOLUTION, RIGHT_LEDC_CHANNEL);
  ledcAttachChannel(LEFT_SERVO_PIN,  SERVO_LEDC_FREQ, SERVO_LEDC_RESOLUTION, LEFT_LEDC_CHANNEL);
  ledcAttachChannel(AUX_SERVO_PIN,   SERVO_LEDC_FREQ, SERVO_LEDC_RESOLUTION, AUX_LEDC_CHANNEL);
  servoWriteMicroseconds(RIGHT_SERVO_PIN, 1500);  // Center on boot
  servoWriteMicroseconds(LEFT_SERVO_PIN,  1500);
  servoWriteMicroseconds(AUX_SERVO_PIN,   1500);
#endif

#if defined(USE_DISTANCE_SENSOR)
  // Camera uses its own SCCB, NOT Arduino Wire — must init Wire explicitly
  Wire.begin(I2C_SDA, I2C_SCL);
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

  Wire.begin(45, 21); // SDA, SCL
  delay(50); // Let I2C bus stabilize
  
  if (!imu.begin()) {
    Serial.println("WARNING: IMU not found! Check wiring.");
  } else {
    Serial.println("IMU initialized successfully at 0x6B!");
  }

  // --- IMU Configurations ---
  imu.setTapSensitivity(1);      // 1 (most sensitive) to 31 (least sensitive)
  imu.setMotionSensitivity(300); // Frame-to-frame raw acceleration delta
  imu.setTiltThreshold(250);     // 250 units = ~10 degrees off baseline
  imu.setHoldFrames(10);         // Hold signals high for 10 frames (~200ms)
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
    nameOfAP = tempNameOfAP + " " + getUniqueNumber();
  }

  int channel = DEFAULT_WIFI_CHANNEL;
#if defined(RANDOMIZE_WIFI_CHANNEL)
  channel = random(13) + 1;
#endif



  WiFi.softAP(nameOfAP.c_str(), NULL, channel);
  WiFi.setSleep(false);  // keep radio hot — prevents 100ms+ power-save latency spikes on TX
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

  // Disable WiFi power-save mode.
  // Without this, the WiFi driver lowers the APB clock after ~5min of steady activity.
  // Lower APB = slower hardware timer = lower ISR sample rate = audio corruption.
  esp_wifi_set_ps(WIFI_PS_NONE);
  Serial.println("WiFi power-save disabled (audio timer stability).");


#if defined(USE_MOTORS)
  servoWriteMicroseconds(RIGHT_SERVO_PIN, 1500);
  servoWriteMicroseconds(LEFT_SERVO_PIN,  1500);
#endif

#if defined(USE_SPEAKER)
  // --- MAX98357A I2S DAC (I2S_NUM_1, Standard TX) ---
  // BCLK→pin47, DATA→pin48, LRC→pin14. Wire SD_MODE on MAX98357A to 3.3V.
  // ESP-IDF 5.x channel-based I2S API.
  {
    bool dac_ok = true;
    i2s_chan_config_t dac_chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_1, I2S_ROLE_MASTER);
    dac_chan_cfg.dma_desc_num = 32;
    dac_chan_cfg.dma_frame_num = 256;  // 32×256 = 8192-frame DMA buffer (~371ms at 22050Hz)
    dac_chan_cfg.auto_clear = true;    // output silence when buffer empty

    if (i2s_new_channel(&dac_chan_cfg, &i2s_dac_tx_handle, NULL) != ESP_OK) {
      Serial.println("FAIL: i2s_new_channel (DAC)");
      dac_ok = false;
    }

    if (dac_ok) {
      i2s_std_config_t dac_std_cfg = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(PCM_SAMPLE_RATE_HZ),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
          .mclk = I2S_GPIO_UNUSED,
          .bclk = (gpio_num_t)I2S_DAC_BCLK_PIN,
          .ws = (gpio_num_t)I2S_DAC_LRC_PIN,
          .dout = (gpio_num_t)I2S_DAC_DATA_PIN,
          .din = I2S_GPIO_UNUSED,
          .invert_flags = { .mclk_inv = false, .bclk_inv = false, .ws_inv = false },
        },
      };
      if (i2s_channel_init_std_mode(i2s_dac_tx_handle, &dac_std_cfg) != ESP_OK) {
        Serial.println("FAIL: i2s_channel_init_std_mode (DAC)");
        dac_ok = false;
      }
    }
    if (dac_ok && i2s_channel_enable(i2s_dac_tx_handle) != ESP_OK) {
      Serial.println("FAIL: i2s_channel_enable (DAC)");
      dac_ok = false;
    }

    if (!dac_ok) {
#if defined(USE_LEDS)
      // ERROR CODE 2: I2S DAC — 2 red blinks
      for (int rep = 0; rep < 3; rep++) {
        for (int i = 0; i < 2; i++) {
          uint32_t red = strip.Color(50, 0, 0);
          strip.setPixelColor(0, red);
          strip.setPixelColor(1, red);
          strip.setPixelColor(2, red);
          strip.setPixelColor(3, red);
          strip.show();
          delay(200);
          strip.setPixelColor(0, 0);
          strip.setPixelColor(1, 0);
          strip.setPixelColor(2, 0);
          strip.setPixelColor(3, 0);
          strip.show();
          delay(200);
        }
        delay(800);
      }
#endif
    } else {
      Serial.println("MAX98357A I2S DAC initialized.");
    }
  }

  // --- Audio feed task: generates samples directly into I2S DMA ---
  // Priority 18 (above camera ~15). Core 1. No hardware timer ISR needed.
  xTaskCreatePinnedToCore(
    audioFeedTask, "audioFeed", 4096, NULL, 18, &audioFeedTaskHandle, 1  // Core 1 prio 18 > camera(~15): audio preempts JPEG encode briefly (1ms/11.6ms), Core 0 untouched
  );


  // ESP-IDF 5.x WDT: reconfigure (it's auto-initialized in Core 3.x)
  esp_task_wdt_config_t wdt_config = {
    .timeout_ms = 5000,
    .idle_core_mask = (1 << 0) | (1 << 1),
    .trigger_panic = true
  };
  esp_task_wdt_reconfigure(&wdt_config);
  esp_task_wdt_add(NULL);  // Add current task

  // --- Startup Sequence (Fade & Chime) ---
  unsigned long voiceDurationMs = (unsigned long)(vocalSamplePack[0].length * TIMER_INTERVAL0_SEC * 1000) + 200;
  unsigned long totalFadeMs = 1000;
  unsigned long startVoiceTime = 0;
  if (totalFadeMs > voiceDurationMs) {
    startVoiceTime = totalFadeMs - voiceDurationMs;
  }

  unsigned long t0 = millis();
  bool voicePlayed = false;

  while (millis() - t0 < totalFadeMs) {
    esp_task_wdt_reset();
    vTaskDelay(1);  // yield: audioFeedTask drains ring buffer → DMA

    if (!voicePlayed && (millis() - t0 >= startVoiceTime)) {
      playInstrumentSample(vocalSamplePack[0], 0, 0);  // semitone 0
      voicePlayed = true;
    }

    static unsigned long last_led_update = 0;
    if (millis() - last_led_update > 15) {
      last_led_update = millis();
      float progress = (millis() - t0) / (float)totalFadeMs;
      if (progress > 1.0f) progress = 1.0f;
      uint8_t currentB = 25 * progress;  // Capped to match idle glow
      uint32_t c = strip.Color(0, 0, currentB);
      strip.setPixelColor(0, c);
      strip.setPixelColor(1, c);
      strip.setPixelColor(2, c);
      strip.setPixelColor(3, c);
      strip.show();
    }
  }
  if (!voicePlayed) {
    playInstrumentSample(vocalSamplePack[0], 0, 0);
    vTaskDelay(voiceDurationMs);
  }
#endif


#if defined(USE_MIC)
  Serial.println("Initializing PDM microphone...");

  // ESP-IDF 5.x channel-based PDM I2S API
  {
    bool mic_ok = true;
    int mic_fail_step = 0;  // 1=new_channel, 2=init_pdm_rx, 3=enable
    esp_err_t mic_err;

    i2s_chan_config_t mic_chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    mic_chan_cfg.dma_desc_num = 4;
    mic_chan_cfg.dma_frame_num = I2S_DMA_BUF_LEN;

    mic_err = i2s_new_channel(&mic_chan_cfg, NULL, &i2s_mic_rx_handle);
    if (mic_err != ESP_OK) {
      Serial.printf("FAIL: i2s_new_channel (MIC) err=0x%x\n", mic_err);
      mic_ok = false;
      mic_fail_step = 1;
    }

    if (mic_ok) {
      i2s_pdm_rx_config_t pdm_rx_cfg = {
        .clk_cfg = I2S_PDM_RX_CLK_DEFAULT_CONFIG(I2S_SAMPLE_RATE),
        .slot_cfg = I2S_PDM_RX_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
          .clk = (gpio_num_t)I2S_PIN_CLK,
          .din = (gpio_num_t)I2S_PIN_DATA,
          .invert_flags = { .clk_inv = false },
        },
      };
      mic_err = i2s_channel_init_pdm_rx_mode(i2s_mic_rx_handle, &pdm_rx_cfg);
      if (mic_err != ESP_OK) {
        Serial.printf("FAIL: i2s_channel_init_pdm_rx_mode (MIC) err=0x%x\n", mic_err);
        mic_ok = false;
        mic_fail_step = 2;
      }
    }
    if (mic_ok) {
      mic_err = i2s_channel_enable(i2s_mic_rx_handle);
      if (mic_err != ESP_OK) {
        Serial.printf("FAIL: i2s_channel_enable (MIC) err=0x%x\n", mic_err);
        mic_ok = false;
        mic_fail_step = 3;
      }
    }

    if (!mic_ok) {
// ERROR CODE 3: I2S PDM Mic — 3 red blinks, repeated 3x
// Within each group, a BLUE blink indicates which sub-step failed:
//   1 blue = i2s_new_channel, 2 blue = init_pdm_rx, 3 blue = enable
#if defined(USE_LEDS)
      for (int rep = 0; rep < 3; rep++) {
        // Red error code: 3 blinks
        for (int i = 0; i < 3; i++) {
          uint32_t red = strip.Color(50, 0, 0);
          strip.setPixelColor(0, red);
          strip.setPixelColor(1, red);
          strip.setPixelColor(2, red);
          strip.setPixelColor(3, red);
          strip.show();
          delay(200);
          strip.setPixelColor(0, 0);
          strip.setPixelColor(1, 0);
          strip.setPixelColor(2, 0);
          strip.setPixelColor(3, 0);
          strip.show();
          delay(200);
        }
        delay(400);
        // Blue sub-step indicator
        for (int i = 0; i < mic_fail_step; i++) {
          uint32_t blue = strip.Color(0, 0, 50);
          strip.setPixelColor(0, blue);
          strip.setPixelColor(1, blue);
          strip.setPixelColor(2, blue);
          strip.setPixelColor(3, blue);
          strip.show();
          delay(150);
          strip.setPixelColor(0, 0);
          strip.setPixelColor(1, 0);
          strip.setPixelColor(2, 0);
          strip.setPixelColor(3, 0);
          strip.show();
          delay(150);
        }
        delay(1000);
      }
#endif
      Serial.printf("MIC INIT FAILED at step %d (err=0x%x)\n", mic_fail_step, mic_err);
    } else {
      Serial.println("PDM microphone initialized.");
    }
  }

  // Pre-compute Bark band bin boundaries (log-spaced from BARK_FREQ_MIN to BARK_FREQ_MAX).
  // Each band k spans FFT bins [barkBandStart[k], barkBandEnd[k]).
  for (int k = 0; k <= BARK_BANDS; k++) {
    float freq = BARK_FREQ_MIN * powf(BARK_FREQ_MAX / BARK_FREQ_MIN, (float)k / BARK_BANDS);
    uint16_t bin = (uint16_t)(freq * FFT_SAMPLES / I2S_SAMPLE_RATE + 0.5f);
    bin = constrain(bin, 1, FFT_SAMPLES / 2 - 1);
    if (k < BARK_BANDS) barkBandStart[k] = bin;
    if (k > 0) barkBandEnd[k - 1] = bin;
  }
  Serial.printf("Bark bands initialised: %d bands, %.0f-%.0f Hz\n",
                BARK_BANDS, BARK_FREQ_MIN, BARK_FREQ_MAX);
#endif

  //setToneOnSpeaker(100);
}  //end of setup


enum LEDState { WAITING_FOR_BLACK,
                IDLE_BLUE,
                DISCONNECTED_ALERT,
                CONNECTED_CONVERGING,
                CONNECTED_READY };
LEDState led_state = IDLE_BLUE;
unsigned long led_transition_start = 0;
bool soft_ap_was_connected = false;

void loop() {
#if defined(USE_INERTIAL)
  // Lightning-fast, non-blocking I2C register pulls
  imu.update();
#endif
  static bool first_loop = true;
  if (first_loop) {
    led_transition_start = millis();
    first_loop = false;
  }

  // === Power Button: non-blocking 3-second hold to shutdown ===
  {
    bool pressed = digitalRead(POWER_BUTTON_PIN) == HIGH;

    // Must release button at least once after boot before shutdown is armed
    if (!pressed && !shutdownTriggered) {
      powerButtonReleasedOnce = true;
    }

    // If shutdown already triggered, wait for button release then cut power
    if (shutdownTriggered) {
      if (!pressed) {
        // User released button — safe to cut power without re-triggering boot
        delay(50);                          // debounce
        digitalWrite(POWER_GATE_PIN, LOW);  // Cut power
        // If still running (USB powered), halt
        while (true) { delay(1000); }
      }
      // Still holding — keep waiting (animation already played)
    } else if (powerButtonReleasedOnce && pressed) {
      if (!powerButtonWasPressed) {
        // Button just pressed — start timer
        powerButtonPressStart = millis();
      } else if (millis() - powerButtonPressStart >= POWER_HOLD_MS) {
        // Held for 3 seconds — trigger shutdown
        Serial.println("Power button held 3s — shutting down.");
        shutdownTriggered = true;
#if defined(USE_LEDS)
        // Shutdown animation: fade LEDs red then off
        for (int brightness = 50; brightness >= 0; brightness -= 2) {
          uint32_t c = strip.Color(brightness, 0, 0);
          strip.setPixelColor(0, c);
          strip.setPixelColor(1, c);
          strip.setPixelColor(2, c);
          strip.setPixelColor(3, c);
          strip.show();
          delay(15);
        }
        strip.show();
#endif
        // Don't cut power yet — wait for button release in next loop iteration
      }
    } else if (!shutdownTriggered) {
      // Button released — reset timer
      powerButtonPressStart = 0;
    }
    powerButtonWasPressed = pressed;
  }

  digitalWrite(DEBUG_PIN, HIGH);

#if defined(USE_MOTORS)
  static unsigned long lastMotorFadeTime = 0;
  if (lastSocketArrivalTime > 0 && (millis() - lastSocketArrivalTime > 400)) {
    // No socket data for 400ms. Gradually brake the motors locally against runaway
    if ((motorSpeedLeft != 1500 || motorSpeedRight != 1500 || motorSpeedAux != 1500) && (millis() - lastMotorFadeTime > 50)) {
      lastMotorFadeTime = millis();
      float leftOffset = motorSpeedLeft - 1500;
      motorSpeedLeft = 1500 + round(leftOffset * 0.6f);
      if (abs(motorSpeedLeft - 1500) < 5) motorSpeedLeft = 1500;
      servoWriteMicroseconds(RIGHT_SERVO_PIN, motorSpeedLeft);

      float rightOffset = motorSpeedRight - 1500;
      motorSpeedRight = 1500 + round(rightOffset * 0.6f);
      if (abs(motorSpeedRight - 1500) < 5) motorSpeedRight = 1500;
      servoWriteMicroseconds(LEFT_SERVO_PIN, motorSpeedRight);

      float auxOffset = motorSpeedAux - 1500;
      motorSpeedAux = 1500 + round(auxOffset * 0.6f);
      if (abs(motorSpeedAux - 1500) < 5) motorSpeedAux = 1500;
      servoWriteMicroseconds(AUX_SERVO_PIN, motorSpeedAux);
    }
  }
#endif

#if defined(USE_BATTERY_MEASUREMENT)
  batteryCounter++;
  if (batteryCounter > BATTERY_MEASUREMENTS_PERIOD) {
    int current_adc = analogRead(BATTERY_PIN);
    if (first_battery_reading) {
      smoothed_battery_adc = current_adc;
      first_battery_reading = false;
    } else {
      smoothed_battery_adc = (BAT_EMA_ALPHA * current_adc) + ((1.0f - BAT_EMA_ALPHA) * smoothed_battery_adc);
    }
    
    // Scale 12-bit averaged ADC reading to the "fudged" 10-bit format the app expects
    // Real Voltage = (smoothed_battery_adc / 4095.0) * 3.3 * 2.2 
    // App Voltage = (fudged_adc / 1023.0) * 3.3 * 2.0
    // Setting Real == App and solving for fudged_adc:
    // fudged_adc = smoothed_battery_adc * (2.2 / 2.0) * (1023.0 / 4095.0)
    battery = (int)(smoothed_battery_adc * 1.1f * 1023.0f / 4095.0f);
    
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

    if (results.distance_mm <= 700) {
      // for distances closer than 70cm, update only if status bit yields valid mesaurement (ignore spotty data)
      if (results.range_status == 0) {
        //convert mm measurements to cm
        reportedDistance = results.distance_mm * 0.1;
      }
    } else {
      //longer distances always reported as data not as precise, allows near targets to be triggered only when reliable.
      reportedDistance = results.distance_mm * 0.1;
    }
  }

#if defined(SEND_MM_FOR_DISTANCE)
  distance = reportedDistance;
#endif
#endif

#if defined(USE_SPEAKER)
  esp_task_wdt_reset();
#endif



  int peakFreq = 0;
  int volRMS = 0;
#if defined(USE_MIC)
  // 50% overlapping FFT windows:
  // DMA delivers 512 new samples (hop = 32ms). micRing always holds the last 1024 samples.
  // Shift out oldest 512, shift in new 512, then FFT the full ring.
  // Result: 20 Hz updates at full 15.6 Hz/bin resolution — halved acoustic latency.
  size_t bytesRead = 0;
  i2s_channel_read(i2s_mic_rx_handle, micBuffer, sizeof(micBuffer), &bytesRead, 0);  // non-blocking

  if (bytesRead > 0) {
    int newSamples = bytesRead / sizeof(int16_t);  // should be I2S_DMA_BUF_LEN = 512

    // Shift ring left by newSamples (discard oldest), append new samples at end
    memmove(micRing, micRing + newSamples, (FFT_SAMPLES - newSamples) * sizeof(int16_t));
    memcpy(micRing + (FFT_SAMPLES - newSamples), micBuffer, newSamples * sizeof(int16_t));

    // Copy ring → vReal for FFT; compute RMS on whole ring
    int64_t sumSquares = 0;
    for (int i = 0; i < FFT_SAMPLES; i++) {
      vReal[i] = micRing[i];
      vImag[i] = 0;
      sumSquares += ((int64_t)micRing[i] * micRing[i]);
    }
    volRMS = (int)sqrt((double)(sumSquares / FFT_SAMPLES));

    // FFT
    FFT.windowing(vReal, FFT_SAMPLES, FFT_WIN_TYP_HAMMING, FFT_FORWARD);
    FFT.compute(vReal, vImag, FFT_SAMPLES, FFT_FORWARD);
    FFT.complexToMagnitude(vReal, vImag, FFT_SAMPLES);

    // --- Dominant pitch: majorPeak + parabolic interpolation for sub-bin accuracy ---
    double peakFrequency = FFT.majorPeak(vReal, FFT_SAMPLES, I2S_SAMPLE_RATE);
    peakFreq = (int)peakFrequency;
    // Parabolic refinement: fit a parabola through the peak bin and its two neighbours
    // to recover up to ~5x better frequency accuracy with no extra compute cost.
    {
      int peakBin = (int)(peakFrequency * FFT_SAMPLES / I2S_SAMPLE_RATE + 0.5);
      peakBin = constrain(peakBin, 1, FFT_SAMPLES / 2 - 2);
      double a = vReal[peakBin - 1], b = vReal[peakBin], c = vReal[peakBin + 1];
      if ((2.0 * b - a - c) > 1e-10) {  // guard against flat/zero spectrum
        double offset = 0.5 * (a - c) / (2.0 * b - a - c);
        peakFreq = (int)((peakBin + offset) * I2S_SAMPLE_RATE / FFT_SAMPLES);
      }
    }
    if (peakFreq < 0) peakFreq = 0;

    // --- 24-band Bark cochlear model ---
    // Sum squared magnitudes (power) per log-spaced band, normalise to 0-255.
    float maxPower = 1.0f;  // avoid div-by-zero
    float bandPower[BARK_BANDS];
    for (int k = 0; k < BARK_BANDS; k++) {
      float power = 0;
      int count = barkBandEnd[k] - barkBandStart[k];
      if (count < 1) count = 1;
      for (int b = barkBandStart[k]; b < barkBandEnd[k]; b++) {
        power += (float)(vReal[b] * vReal[b]);
      }
      bandPower[k] = power / count;  // average power per bin
      if (bandPower[k] > maxPower) maxPower = bandPower[k];
    }
    for (int k = 0; k < BARK_BANDS; k++) {
      barkBandLevel[k] = (uint8_t)min(255.0f, (bandPower[k] / maxPower) * 255.0f);
    }
  }
#endif

#if defined(USE_SPEAKER)
#endif

  //send distance to host computer via Socket
  // --- Telemetry rate limiter ---
  // Before (blocking i2s_read): loop ran at ~15 Hz naturally.
  // After (non-blocking read):  loop runs at 200-500 Hz, flooding WiFi and killing camera FPS.
  // Fix: send telemetry at most every 50ms (~20 Hz). Camera frames share the same WiFi TX queue.
  static unsigned long lastTelemetrySend = 0;
  unsigned long nowMs = millis();
  if (nowMs - lastTelemetrySend >= 50) {
    lastTelemetrySend = nowMs;

    if (sendVersionString) {
      sendVersionString = false;
      sendDataViaSocket("V1.0.0", 6);
    } else {
      // Build entire message with one snprintf — no String heap allocation.
      // Format: peakFreq,volRMS,distance,battery, h:b0,b1,...,b23 i:101
      char* p = commandBuffer;
      char* end = commandBuffer + SIZE_OF_COMMAND_BUFFER - 1;
      p += snprintf(p, end - p, "%d,%d,%d,%d,",
                    peakFreq, volRMS, (int)distance, (int)battery);
#if defined(USE_MIC)
      // h: field: 24 hex chars, one per Bark band, 0-F (4-bit log scale).
      // log2(v+1)*15/8 maps 0-255 -> 0-15 with equal perceptual (dB) spacing.
      // Fixed 24-char width, no commas. Example: "h:F84321000000000000000000"
      static const char kHexNibble[] = "0123456789ABCDEF";
      p += snprintf(p, end - p, " h:");
      for (int k = 0; k < BARK_BANDS && p < end - 2; k++) {
        uint8_t v = barkBandLevel[k];
        uint8_t level = (v == 0) ? 0 : (uint8_t)min(15.0f, log2f((float)v + 1.0f) * 15.0f / 8.0f);
        *p++ = kHexNibble[level];
      }
#endif
#if defined(USE_INERTIAL)
      p += snprintf(p, end - p, " i:%d%d%d", imu.getTap(), imu.getMotion(), imu.getTilt());
#endif
      if (p < end) *p++ = ' ';
      *p = '\0';
      sendDataViaSocket(commandBuffer, (int)(p - commandBuffer));
    }
  }

#if defined(USE_LEDS)
#if defined(MAKE_AP)
  bool current_soft_ap_connected = WiFi.softAPgetStationNum() > 0;
#else
  bool current_soft_ap_connected = (WiFi.status() == WL_CONNECTED);
#endif

  if (current_soft_ap_connected && !soft_ap_was_connected) {
    // Just connected! Wait until the breathing cycle hits absolute black before fading!
    led_state = WAITING_FOR_BLACK;  // Replaced WAITING_FOR_PEAK_BLUE
    soft_ap_was_connected = true;
  } else if (!current_soft_ap_connected && soft_ap_was_connected) {
    // Just disconnected! Flash red alert!
    led_state = DISCONNECTED_ALERT;
    led_transition_start = millis();
    soft_ap_was_connected = false;

#if defined(USE_MOTORS)
    // Rapidly fade motor movements to 0 globally upon signal loss
    servoWriteMicroseconds(RIGHT_SERVO_PIN, 1500);
    servoWriteMicroseconds(LEFT_SERVO_PIN,  1500);
    servoWriteMicroseconds(AUX_SERVO_PIN,   1500);
#endif
  }

  unsigned long t = millis() - led_transition_start;
  strip.setBrightness(255);  // cap brightness

  static unsigned long last_led_update = 0;
  if (!shutdownTriggered && millis() - last_led_update > 15) {
    last_led_update = millis();

    if (led_state == WAITING_FOR_BLACK) {
      // Breathing Blue via cosine wave — capped at brightness 25 for gentle idle glow
      float val = (cos((millis() - led_transition_start) / 636.6f) + 1.0f) / 2.0f;  // 4000ms period
      uint8_t breathB = (uint8_t)(25 * val);                                        // Max 25 instead of 255
      uint32_t c = strip.Color(0, 0, breathB);
      strip.setPixelColor(0, c);
      strip.setPixelColor(1, c);
      strip.setPixelColor(2, c);
      strip.setPixelColor(3, c);
      strip.show();

      if (val < 0.02f) {  // Reached absolute black ~0%
        led_state = CONNECTED_CONVERGING;
        led_transition_start = millis();
      }
    } else if (led_state == IDLE_BLUE) {
      // Breathing Blue via cosine wave — capped at brightness 25 for gentle idle glow
      float val = (cos((millis() - led_transition_start) / 636.6f) + 1.0f) / 2.0f;
      uint8_t breathB = (uint8_t)(25 * val);  // Max 25 instead of 255
      uint32_t c = strip.Color(0, 0, breathB);
      strip.setPixelColor(0, c);
      strip.setPixelColor(1, c);
      strip.setPixelColor(2, c);
      strip.setPixelColor(3, c);
      strip.show();
    } else if (led_state == DISCONNECTED_ALERT) {
      if (t < 600) {
        // 3 rapid red blinks — capped at brightness 25
        if ((t / 100) % 2 == 0) {
          uint32_t c = strip.Color(25, 0, 0);
          strip.setPixelColor(0, c);
          strip.setPixelColor(1, c);
          strip.setPixelColor(2, c);
          strip.setPixelColor(3, c);
        } else {
          strip.setPixelColor(0, 0);
          strip.setPixelColor(1, 0);
          strip.setPixelColor(2, 0);
          strip.setPixelColor(3, 0);
        }
        strip.show();
      } else if (t < 1600) {
        // Fade Red to Blue — capped at brightness 25
        float progress = (t - 600) / 1000.0f;
        uint8_t r = 25 * (1.0f - progress);
        uint8_t b = 25 * progress;
        uint32_t c = strip.Color(r, 0, b);
        strip.setPixelColor(0, c);
        strip.setPixelColor(1, c);
        strip.setPixelColor(2, c);
        strip.setPixelColor(3, c);
        strip.show();
      } else {
        led_state = IDLE_BLUE;
        led_transition_start = millis();  // Reset math to start at peak bright blue again
      }
    } else if (led_state == CONNECTED_CONVERGING) {
      // 2.0 second fade up from absolute black to solid green — capped at brightness 25
      if (t < 2000) {
        float progress = t / 2000.0f;
        float ease = (1.0f - cos(progress * 3.14159f)) / 2.0f;
        uint8_t currentG = 25 * ease;  // Capped at 25 for gentle transition glow
        uint32_t c = strip.Color(0, currentG, 0);
        strip.setPixelColor(0, c);
        strip.setPixelColor(1, c);
        strip.setPixelColor(2, c);
        strip.setPixelColor(3, c);
        strip.show();
      } else {
        led_state = CONNECTED_READY;
        led_transition_start = millis();
      }
    } else if (led_state == CONNECTED_READY) {
      // Fire Green once on transition, then never call strip.show() again
      // UNLESS we get explicit websocket commands, batched every 30ms max rate!
      if (t < 50) {
        uint32_t c = strip.Color(0, 25, 0);  // Capped to match idle glow
        strip.setPixelColor(0, c);
        strip.setPixelColor(1, c);
        strip.setPixelColor(2, c);
        strip.setPixelColor(3, c);
        strip.show();
        websocket_led_dirty = false;
      } else {
        if (websocket_led_dirty) {
          websocket_led_dirty = false;
          strip.show();
        }
      }
    }
  }
#endif
  digitalWrite(DEBUG_PIN, LOW);
}
