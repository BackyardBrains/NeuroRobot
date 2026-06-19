#include "Spikerbot_IMU.h"

// Essential Registers
#define WHO_AM_I 0x0F
#define CTRL1_XL 0x10
#define TAP_CFG0 0x56
#define TAP_CFG1 0x57
#define TAP_CFG2 0x58
#define TAP_THS_6D 0x59
#define INT_DUR2 0x5A
#define WAKE_UP_THS 0x5B
#define WAKE_UP_DUR 0x5C
#define TAP_SRC 0x1C
#define WAKE_UP_SRC 0x1B
#define OUTX_L_A 0x28
#define OUTX_H_A 0x29
#define OUTY_L_A 0x2A
#define OUTY_H_A 0x2B
#define OUTZ_L_A 0x2C
#define OUTZ_H_A 0x2D
#define PIN_CTRL 0x02

Spikerbot_IMU::Spikerbot_IMU(uint8_t address) {
  _address = address;
  _tapSensitivity = 1;
  _motionThreshold = 300;
  _tiltThreshold = 250;
  _holdFrames = 10;
  
  _tapHoldCounter = 0;
  _motionHoldCounter = 0;
  _baselineZ = 0;
  _baselineSet = false;
  _lastX = 0; _lastY = 0; _lastZ = 0;
  _filteredZ = 0.0f;
  
  _tapOut = false;
  _motionOut = false;
  _tiltOut = false;
}

void Spikerbot_IMU::writeRegister(uint8_t reg, uint8_t value) {
  Wire.beginTransmission(_address);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}

uint8_t Spikerbot_IMU::readRegister(uint8_t reg) {
  Wire.beginTransmission(_address);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)_address, (uint8_t)1);
  if (Wire.available()) {
    return Wire.read();
  }
  return 0;
}

int16_t Spikerbot_IMU::read16(uint8_t regL, uint8_t regH) {
  uint8_t l = readRegister(regL);
  uint8_t h = readRegister(regH);
  return (int16_t)((h << 8) | l);
}

bool Spikerbot_IMU::begin() {
  // --- HARDWARE FIX ---
  // Enable the internal pull-up on the floating SDO/SA0 pin!
  // Writing 0x40 to PIN_CTRL (0x02) sets the sdo_pu_en bit to 1.
  writeRegister(PIN_CTRL, 0x40);
  delay(10);
  
  uint8_t who = readRegister(WHO_AM_I);
  if (who != 0x6C) {
    return false;
  }
  
  // 1. Initialize Accelerometer (104Hz, 2g scale)
  writeRegister(CTRL1_XL, 0x40); // ODR=104Hz, FS=2g
  
  // 2. Configure Tap Detection (X, Y, Z directions)
  writeRegister(TAP_CFG0, 0x0E); // Enable tap on X, Y, Z
  setTapSensitivity(_tapSensitivity); // Sets thresholds for X, Y, and Z
  writeRegister(INT_DUR2, 0x06); // Duration, Quiet, Shock windows
  
  // 3. Configure Motion / Wake-up Detection (Hardware baseline)
  writeRegister(WAKE_UP_THS, 0x01); 
  writeRegister(WAKE_UP_DUR, 0x00); 
  
  delay(200); // Let filters settle
  return true;
}

void Spikerbot_IMU::setTapSensitivity(uint8_t sensitivity) {
  _tapSensitivity = sensitivity & 0x1F; // Ensure it's 5 bits max (0-31)
  
  // The LSM6DSO has separate threshold registers for X, Y, and Z!
  writeRegister(TAP_CFG1, _tapSensitivity);               // X threshold
  writeRegister(TAP_CFG2, 0x80 | _tapSensitivity);        // Y threshold + enable interrupt (bit 7)
  writeRegister(TAP_THS_6D, _tapSensitivity);             // Z threshold
}

void Spikerbot_IMU::setMotionSensitivity(int deltaThreshold) {
  _motionThreshold = deltaThreshold;
}

void Spikerbot_IMU::setTiltThreshold(int zDeltaThreshold) {
  _tiltThreshold = zDeltaThreshold;
}

void Spikerbot_IMU::setHoldFrames(int frames) {
  _holdFrames = frames;
}

void Spikerbot_IMU::resetTiltBaseline() {
  _baselineSet = false;
}

void Spikerbot_IMU::update() {
  // --- 1. Tap Detection ---
  uint8_t tapSrc = readRegister(TAP_SRC);
  bool isTap = (tapSrc & 0x20) > 0;
  if (isTap) _tapHoldCounter = _holdFrames;
  
  // --- 2. Motion Detection ---
  uint8_t wakeSrc = readRegister(WAKE_UP_SRC);
  bool isWakeHardware = (wakeSrc & 0x08) > 0;
  
  int16_t xAccel = read16(OUTX_L_A, OUTX_H_A);
  int16_t yAccel = read16(OUTY_L_A, OUTY_H_A);
  int16_t zAccel = read16(OUTZ_L_A, OUTZ_H_A);
  
  int accelDelta = abs(xAccel - _lastX) + abs(yAccel - _lastY) + abs(zAccel - _lastZ);
  _lastX = xAccel; _lastY = yAccel; _lastZ = zAccel;
  
  if (isWakeHardware || accelDelta > _motionThreshold) {
    _motionHoldCounter = _holdFrames;
  }
  
  // --- 3. Tilt / Level Detection ---
  if (!_baselineSet && zAccel != 0) {
    _baselineZ = zAccel;
    _filteredZ = zAccel; // Initialize filter to baseline
    _baselineSet = true;
  }
  
  // Apply a strong low-pass filter (EMA) to ignore high-frequency tap spikes!
  _filteredZ = (_filteredZ * 0.9f) + (zAccel * 0.1f);
  
  bool isTilt = false;
  if (_baselineSet && abs(_filteredZ - _baselineZ) > _tiltThreshold) {
    isTilt = true;
  }
  
  // --- Calculate outputs ---
  _tapOut = (_tapHoldCounter > 0);
  _motionOut = (_motionHoldCounter > 0);
  _tiltOut = isTilt;
  
  if (_tapHoldCounter > 0) _tapHoldCounter--;
  if (_motionHoldCounter > 0) _motionHoldCounter--;
}

bool Spikerbot_IMU::getTap() { return _tapOut; }
bool Spikerbot_IMU::getMotion() { return _motionOut; }
bool Spikerbot_IMU::getTilt() { return _tiltOut; }
