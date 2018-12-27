//#include <Encoder.h>

// Righ Driver
int R_enc = 2;
volatile int R_counter = 0;
int R_F_E= 9;
int R_R_E= 7;
int R_PWM = 6;
int R_speed = 80;
volatile int R_state = LOW; 


// Left Driver
int L_enc = 3;
volatile int L_counter = 0;
int L_F_E= 4;
int L_R_E= 8;
int L_PWM = 5;
int L_speed =80;
volatile int L_state = LOW; 

int enablePin = 10;

void setup() {
  Serial.begin(115200);
  // Righ Driver
  pinMode(R_enc, INPUT);
  pinMode(R_F_E, OUTPUT);
  pinMode(R_R_E, OUTPUT);
  pinMode(R_PWM, OUTPUT);
  // Left Driver
  pinMode(L_enc, INPUT);
  pinMode(L_F_E, OUTPUT);
  pinMode(L_R_E, OUTPUT);
  pinMode(L_PWM, OUTPUT);
  
  pinMode(enablePin, OUTPUT);
  digitalWrite(enablePin, HIGH);
  attachInterrupt(digitalPinToInterrupt(R_enc), Rvoid, RISING);
  attachInterrupt(digitalPinToInterrupt(L_enc), Lvoid, FALLING);
  
  pinMode(13, OUTPUT);
  digitalWrite(13,HIGH);
}
void loop()
{


  
  digitalWrite(R_F_E, HIGH);
  digitalWrite(R_R_E, LOW);
  digitalWrite(L_F_E, HIGH);
  digitalWrite(L_R_E, LOW);
  analogWrite(R_PWM, 40);
  analogWrite(L_PWM, 40);
  delay(1000);

  Serial.print(R_counter, DEC );
  Serial.print("\t");
  Serial.println(L_counter, DEC);
    
  digitalWrite(R_F_E, LOW);
  digitalWrite(R_R_E, HIGH);
  digitalWrite(L_F_E, LOW);
  digitalWrite(L_R_E, HIGH);
  analogWrite(R_PWM, 40);
  analogWrite(L_PWM, 40);
  delay(1000);

/*analogWrite(R_PWM, 70);
analogWrite(L_PWM, 70);
delay(300);
analogWrite(R_PWM, 90);
analogWrite(L_PWM, 90);
delay(300);
analogWrite(R_PWM, 120);
analogWrite(L_PWM, 120);
delay(300);
analogWrite(R_PWM, 160);
analogWrite(L_PWM, 160);
delay(300);
digitalWrite(13,LOW);
for( int a=0; a<400; a++){

 if(R_counter == L_counter){
 analogWrite(L_PWM, 254);
 analogWrite(R_PWM, 254);
 }
 if(R_counter > L_counter){
 analogWrite(L_PWM, 254);
 analogWrite(R_PWM, 0);
 }
 if(R_counter < L_counter){
 analogWrite(L_PWM, 0);
 analogWrite(R_PWM, 254);
  }
  */
  Serial.print(R_counter, DEC );
  Serial.print("\t");
  Serial.println(L_counter, DEC);
  /*
}
digitalWrite(R_F_E, LOW);
digitalWrite(L_F_E, LOW);
digitalWrite(L_R_E, LOW);
delay(1000);
digitalWrite(R_F_E, HIGH);
digitalWrite(L_F_E, LOW);
digitalWrite(L_R_E, HIGH);
analogWrite(L_PWM, 100);
analogWrite(R_PWM, 100);
delay(1050);
digitalWrite(R_F_E, LOW);
digitalWrite(L_F_E, LOW);
digitalWrite(L_R_E, LOW);
R_speed = 254;
L_speed = 254;
digitalWrite(13,HIGH);
delay(1000);
digitalWrite(13,LOW);*/

}

void Rvoid(){
R_counter ++;
delayMicroseconds(100);
}

void Lvoid(){
L_counter ++;
delayMicroseconds(100);
  }
