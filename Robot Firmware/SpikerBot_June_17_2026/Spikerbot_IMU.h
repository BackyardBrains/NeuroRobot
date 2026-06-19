#ifndef SPIKERBOT_IMU_H
#define SPIKERBOT_IMU_H

#include <Arduino.h>
#include <Wire.h>

class Spikerbot_IMU {
  public:
    Spikerbot_IMU(uint8_t address = 0x6B);

    bool begin();

    void setTapSensitivity(uint8_t sensitivity = 1);
    void setMotionSensitivity(int deltaThreshold = 300);
    void setTiltThreshold(int zDeltaThreshold = 250);
    void setHoldFrames(int frames = 10);

    // Dynamically recalibrate the "level ground" baseline
    void resetTiltBaseline();

    void update();

    bool getTap();
    bool getMotion();
    bool getTilt();

  private:
    uint8_t _address;
    
    // Config thresholds
    uint8_t _tapSensitivity;
    int _motionThreshold;
    int _tiltThreshold;
    int _holdFrames;
    
    // Internal states
    int _tapHoldCounter;
    int _motionHoldCounter;
    int16_t _baselineZ;
    bool _baselineSet;
    int16_t _lastX, _lastY, _lastZ;
    float _filteredZ;
    
    // Outputs
    bool _tapOut;
    bool _motionOut;
    bool _tiltOut;

    // Helper functions
    void writeRegister(uint8_t reg, uint8_t value);
    uint8_t readRegister(uint8_t reg);
    int16_t read16(uint8_t regL, uint8_t regH);
};

#endif
