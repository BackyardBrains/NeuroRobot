int pos = 38;
int led_pin = 13;

#include <Servo.h> 
Servo servo_1;
int servo_1_pos = 0;

void setup() {
  servo_1.attach(10);  
  Serial.begin(115200);  
  pinMode(led_pin, OUTPUT);  
}

void loop() {
    pos = pos + 10;
    if (pos > 180){
      pos = 0;
      }
    if(pos > 90){
      digitalWrite(led_pin, 1);
      }
      else{
        digitalWrite(led_pin, 0);
      }
      servo_1.write(pos);
      delay(50); 
  delay(100); 
}
//  if(Serial.available() == 1) {
//  pos = (Serial.read() - '0') * 10;
//  }
