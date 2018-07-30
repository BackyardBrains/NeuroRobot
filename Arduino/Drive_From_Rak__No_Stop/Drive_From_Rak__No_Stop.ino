//#include <Encoder.h>

// Right Driver
int R_enc = 3;
volatile int R_counter = 0;
int R_F_E = 7;
int R_R_E = 9;
int R_PWM = 6;
int R_speed = 80;
volatile int R_state = LOW;

// Left Driver
int L_enc = 2;
volatile int L_counter = 0;
int L_F_E = 4;
int L_R_E = 8;
int L_PWM = 5;
int L_speed = 80;
volatile int L_state = LOW;
int enable = 10;

// Ultrasonic
const int trigPin = 11;
const int echoPin = 12;
long duration;

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT); // Sets the trigPin as an Output
  pinMode(echoPin, INPUT); // Sets the echoPin as an Input

  // Right Driver
  pinMode(enable, OUTPUT);
  pinMode(R_enc, INPUT);
  pinMode(R_F_E, OUTPUT);
  pinMode(R_R_E, OUTPUT);
  pinMode(R_PWM, OUTPUT);
  // Left Driver
  pinMode(L_enc, INPUT);
  pinMode(L_F_E, OUTPUT);
  pinMode(L_R_E, OUTPUT);
  pinMode(L_PWM, OUTPUT);

  digitalWrite(enable, HIGH);

}

int a_bytes;
char text[9] = "noinputs.";
char* cleanse;
String text_string;
int DRIVE_speed = 90;
int TURN_speed = 90;

void loop() {
  // Clears the trigPin
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  // Sets the trigPin on HIGH state for 10 micro seconds
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Reads the echoPin, returns the sound wave travel time in microseconds
  duration = pulseIn(echoPin, HIGH);
  if (duration > 0) {
    Serial.println(duration);
  }
  // check for incoming message
  delay(10);
  a_bytes = Serial.available();
  if (a_bytes >= 8 && a_bytes <= 32 && a_bytes % 8 == 0) {
    Serial.readBytes(text, 8);
    cleanse = &text[8];
    *cleanse = '\0';
  } else {
    while (Serial.available()) {
      Serial.read();
    }
    if (a_bytes == 0) {
      return;
    }
  }

  text_string = text;

  if (text_string.equals("turnrite")) {
    digitalWrite(L_R_E, HIGH);
    digitalWrite(L_F_E, LOW);
    digitalWrite(R_R_E, LOW);
    digitalWrite(R_F_E, HIGH);
    delay(10);
    analogWrite(R_PWM, TURN_speed);
    analogWrite(L_PWM, TURN_speed);

  } else if (text_string.equals("turnleft")) {
    digitalWrite(R_R_E, HIGH);
    digitalWrite(R_F_E, LOW);
    digitalWrite(L_R_E, LOW);
    digitalWrite(L_F_E, HIGH);
    delay(10);
    analogWrite(R_PWM, TURN_speed);
    analogWrite(L_PWM, TURN_speed);

  } else if (text_string.equals("gostrait")) {
    digitalWrite(R_R_E, LOW);
    digitalWrite(L_R_E, LOW);
    digitalWrite(R_F_E, HIGH);
    digitalWrite(L_F_E, HIGH);
    delay(10);
    analogWrite(R_PWM, DRIVE_speed);
    analogWrite(L_PWM, DRIVE_speed);

  } else if (text_string.equals("gorevers")) {
    digitalWrite(R_R_E, HIGH);
    digitalWrite(L_R_E, HIGH);
    digitalWrite(R_F_E, LOW);
    digitalWrite(L_F_E, LOW);
    delay(10);
    analogWrite(R_PWM, DRIVE_speed);
    analogWrite(L_PWM, DRIVE_speed);
  } else if (text_string.equals("minspeed")) {
    DRIVE_speed = max(DRIVE_speed - 25, 55);
    delay(50);

  } else if (text_string.equals("maxspeed")) {
    DRIVE_speed = min(DRIVE_speed + 25, 275);
    delay(50);
  } else if (text_string.equals("minturns")) {
    TURN_speed = max(TURN_speed - 25, 55);
    delay(50);
  } else if (text_string.equals("maxturns")) {
    TURN_speed = min(TURN_speed + 25, 275);
    delay(50);
  } else if (text_string.equals("stopmove")) {
    digitalWrite(R_R_E, LOW);
    digitalWrite(L_R_E, LOW);
    digitalWrite(R_F_E, HIGH);
    digitalWrite(L_F_E, HIGH);
    delay(10);
    analogWrite(R_PWM, 0);
    analogWrite(L_PWM, 0);
  } else { // no correct command detected, clean pipeline
    while (Serial.available()) {
      Serial.read();
    }
  }


}

