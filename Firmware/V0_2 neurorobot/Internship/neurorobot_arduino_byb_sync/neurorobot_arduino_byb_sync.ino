
// Vertebot Arduino Code (Motor Drivers and Ultrasonic Distance Sensor)
// Written by Christopher Harris at Backyard Brains, Inc.
// Last update: 5-May-2018


// Libraries
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_MS_PWMServoDriver.h"

// Variables
int this_speed = 0;
int motor_command[] = {0, 0, 0, 0};
long duration;
long distance;
int flag1;

// Constants
#define echoPin 3
#define trigPin 5
#define ledPin 10

// Motor shield setup
Adafruit_MotorShield AFMS = Adafruit_MotorShield(); 
Adafruit_DCMotor *motor1 = AFMS.getMotor(3);
Adafruit_DCMotor *motor2 = AFMS.getMotor(4);
Adafruit_DCMotor *motor3 = AFMS.getMotor(1);
Adafruit_DCMotor *motor4 = AFMS.getMotor(2);

// Initialize
void setup() {
  Serial.begin(115200);
  AFMS.begin();
  motor1->setSpeed(this_speed);
  motor1->run(FORWARD);
  motor1->run(RELEASE);
  motor2->setSpeed(this_speed);
  motor2->run(FORWARD);
  motor2->run(RELEASE);
  motor3->setSpeed(this_speed);
  motor3->run(FORWARD);
  motor3->run(RELEASE);
  motor4->setSpeed(this_speed);
  motor4->run(FORWARD);
  motor4->run(RELEASE);  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);  
  pinMode(ledPin, OUTPUT); 
}


// Main loop
void loop() {

  // 1) Wait for Matlab to send motor command
  flag1 = 0;
  while(flag1 == 0){
    if(Serial.available() >= 4) {
      
      // Use the last 4 bytes to populate motor_command
      while(Serial.available() > 4) {
        char t = Serial.read();
      }
      
      if(Serial.available() == 4) {
        motor_command[0] = Serial.read(); // Speed: right side wheels
        motor_command[1] = Serial.read(); // Direction: right side wheels (1 = forward, 2 = backward)
        motor_command[2] = Serial.read(); // Speed: left side wheels
        motor_command[3] = Serial.read(); // Direction: left side wheels (1 = forward, 2 = backward)
    
        // Update right side wheels
        if(motor_command[0] > 0){
          this_speed = motor_command[0];
          motor1->setSpeed(this_speed);
          motor2->setSpeed(this_speed);
          if(motor_command[1] == 1){
            motor1->run(FORWARD);
            motor2->run(FORWARD);
          }
          if(motor_command[1] == 2){
            motor1->run(BACKWARD);
            motor2->run(BACKWARD);
          }      
        }
        else {
          motor1->run(RELEASE);
          motor2->run(RELEASE);      
        }
    
        // Update left side wheels
        if(motor_command[2] > 0){
          this_speed = motor_command[2];
          motor3->setSpeed(this_speed);
          motor4->setSpeed(this_speed);
          if(motor_command[3] == 1){
            motor3->run(FORWARD);
            motor4->run(FORWARD);
          }
          if(motor_command[3] == 2){
            motor3->run(BACKWARD);
            motor4->run(BACKWARD);
          }
        }
        else {
          motor3->run(RELEASE);
          motor4->run(RELEASE);
        }
      }

      flag1 = 1;
    }
    delay(50);
    
    // Send distance data to Matlab
    digitalWrite(trigPin, LOW);
    delayMicroseconds(5);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    duration = pulseIn(echoPin, HIGH);
    distance = (duration/2) / 29.1;
    Serial.println(distance);
    Serial.flush();  

    // Drive LED pin (needed to make Red robot draw enough power to keep battery on
    digitalWrite(ledPin, HIGH);
  }
  delay(200); // This is to allow the motor command to run

}

