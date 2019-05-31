// Vertebot Arduino Code
// Written by Christopher Harris at Backyard Brains, Inc.
// This code is licensed under a GNU 2.1 license

// Libraries
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_MS_PWMServoDriver.h"
#include "pitches.h"

// Variables
int this_speed = 0;
int motor_command[] = {0, 0, 0, 0, 0};
long duration;
long distance;
int this_tone = 0;

// Constants
#define echoPin 3
#define trigPin 5

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
}


// Main loop
void loop(){

  // Check for new command from robot
  if(Serial.available() >= 5) {
    while(Serial.available() > 5) {
      char t = Serial.read();
    }
    motor_command[0] = Serial.read();
    motor_command[1] = Serial.read();
    motor_command[2] = Serial.read();
    motor_command[3] = Serial.read();
    motor_command[4] = Serial.read();

    // Update motor 1
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

    // Update motor 2
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

    // Get sound output
    if(motor_command[4] > 0){
      this_tone = motor_command[4] * 256;
      // this_tone = this_tone / 10;
    }
    else {
      this_tone = 0;
    }    
    
  }

  // Estimate and send distance
  digitalWrite(trigPin, LOW);
  delayMicroseconds(5);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  distance = (duration/2) / 29.1;
  Serial.println(distance);
  Serial.flush();

  // Update speaker
  //delay(50);
  delay(10);
  if(this_tone > 0){
    tone(8, this_tone, 80);
  }
  else {
    delay(80);
  }
  delay(10);

}
