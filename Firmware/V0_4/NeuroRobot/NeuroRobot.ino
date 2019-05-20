// Neuro Robot Board V0.4
// Backyard Brains
// 25.Mar.2019
// Written by Stanislav Mircic
//
// Code is made for ATMEGA328 (Arduino UNO)
// Code will periodicaly (100 times per second): 
//  - read data from encoders and ultrasonic sensor and send it through serial in CSV format
//    (left motor encoder delta, right motor encoder delta, ultrasonic sensor time in uSeconds, 
//     accelerometer X, accelerometer Y, accelerometer Z, temperature (degrees C), gyroscope X,
//      gyroscope Y,  gyroscope Z)

//  - read commands from serial and execute on motor and LEDs
//
//  Possible commands:

//  LED control command
//  d:[led-command];
//  Diode command example d:320;
//  This will turn OFF green color at 3rd LED
//  d - diode command name
//  : - separator between name and value
//  3 - index of diode 3rd diode (1-6)
//  2 - index of green color (1=B, 2=G, 3=R)
//  0 - state of diode (1=ON, 0=OFF)
//  ; - end of command 
//
//  Special case d:0; used when user wants to turn off all LEDs
//

//  Motor control commands
//  l:[speed];  - control left motor. ex. l:-40; Run left motor CCW at speed 40. Speed can take value from -255 to 255
//  r:[speed];  - control right motor ex. r:80; Run right motor CW at speed 80. Speed can take value from -255 to 255

//
//Sound generator on pin A1
// s:[frequency]; - generate square wave on output A1 with frequency defined by "frequency" parameter
// Half of period of square wave is expressed in 10kHz timer period. Half period is defined as round(10000/frequency). 
// Consequence of that is that not all frequencies can be generated.
// (For example: 
// for frequency = 1000; period = round(10000/1000) = 10;
// for frequency = 1001; period  = round(10000/1001) = 10; !!! the same period!!  
// So frequency resolution will be much better for lower frequency.
// Send s:0; to turn OFF the sound

//If Fs is sample rate than formula is SAMPLE_RATE_PERIOD = (16*10^6) / (Fs*8) - 1
// For 100Hz sample rate the SAMPLE_RATE_PERIOD should be 19999 
#define SAMPLE_RATE_PERIOD 200 
#define DIVIDE_SAMPLE_RATE_BY 10
int sensorSampleRateCounter = 0;
byte sampleRateCounter = 0;

// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

//https://playground.arduino.cc/Main/SoftwareI2CLibrary/
#define SCL_PIN 2
#define SCL_PORT PORTD
#define SDA_PIN 3
#define SDA_PORT PORTD
#include <SoftI2CMaster.h>

//accelerometer and gyro variables
#define I2C_7BITADDR 0x68
int16_t AcX,AcY,AcZ,Tmp,GyX,GyY,GyZ;

// Righ Driver
int R_enc = 7;
volatile int R_counter = 0;
int R_F_E= 2;
int R_R_E= 3;
int R_PWM = 6;

// Left Driver
int L_enc = 4;
volatile int L_counter = 0;
int L_F_E= 0;
int L_R_E= 1;
int L_PWM = 5;

int enableMotorBit = 4;
int commandValue = 0;


int shiftDataPin = 10;
int shiftClockPin = 9;
int shiftLatchPin = 8;

const int ultrasonicTrigPin = 11;
const int ultrasonicEchoPin = 12;
volatile int ultrasonicDistance = 0;
volatile int tempUltrasonicDistance = 0;
volatile unsigned long ultrasonicPulseStart = 0;

#define SIZE_OF_COMMAND_BUFFER 100 //command buffer size
char commandBuffer[SIZE_OF_COMMAND_BUFFER];//receiving command buffer


int motorSpeedLeft = 0;
int motorSpeedRight = 0;

byte executeOneLoop = 0;

byte shiftReg1 = 0;
//bit 0 - left forward
//bit 1 - left backward
//bit 2 - right forward
//bit 3 - right backward
//bit 4 - motor enable
//bit 5 - LED CR blue
//bit 6 - LED CR green
//bit 7 - LED CR red

byte shiftReg2 = 0;
//bit 0 - -----------
//bit 1 - LED CL blue
//bit 2 - LED CL green
//bit 3 - LED CL red
//bit 4 - LED TR blue
//bit 5 - LED TR green
//bit 6 - LED TR red
//bit 7 - LED TL blue

byte shiftReg3 = 0;
//bit 0 - LED TL green
//bit 1 - LED TL red
//bit 2 - LED BL blue
//bit 3 - LED BL green
//bit 4 - LED BL red
//bit 5 - LED BR blue
//bit 6 - LED BR green
//bit 7 - LED BR red
int colorIndex=0;
int LEDIndex=0;



byte bitMask = B00000001;
volatile int diodeCommand = 0;

#define SOUND_PIN 15
volatile int soundCommand = 0;
volatile int soundPeriod = 0;
volatile int soundCounter = 0;




void setup() {
  Serial.begin(115200);
  // Righ Driver
  pinMode(R_enc, INPUT);
  pinMode(R_PWM, OUTPUT);
  // Left Driver
  pinMode(L_enc, INPUT);
  pinMode(L_PWM, OUTPUT);


  pinMode(R_PWM, OUTPUT);

  pinMode(ultrasonicTrigPin, OUTPUT);
  pinMode(ultrasonicEchoPin, INPUT);

  //shift registers
  pinMode(shiftDataPin, OUTPUT);
  pinMode(shiftClockPin, OUTPUT);
  pinMode(shiftLatchPin, OUTPUT);

  //sound output
  pinMode(SOUND_PIN, OUTPUT);

  turnOffLEDs();
  turnOffMotor();
  enableMotor();
  //initGyro();

  pinMode(13, OUTPUT);//debug pin
  setupInterruptForEncoders();
  //delay(15000);
  //delay(24000);
  cli();//stop interrupts

  //Make ADC sample faster. Change ADC clock
  //Change prescaler division factor to 16
  sbi(ADCSRA,ADPS2);//1
  cbi(ADCSRA,ADPS1);//0
  cbi(ADCSRA,ADPS0);//0

  //set timer1 interrupt at 10kHz
  TCCR1A = 0;// set entire TCCR1A register to 0
  TCCR1B = 0;// same for TCCR1B
  TCNT1  = 0;//initialize counter value to 0;
  OCR1A = 99;// Output Compare Registers 
  // turn on CTC mode
  TCCR1B |= (1 << WGM12);
  // Set CS11 bit for 8 prescaler
  TCCR1B |= (1 << CS11);   
  // enable timer compare interrupt
  TIMSK1 |= (1 << OCIE1A);
  
  sei();//allow interrupts
  //END TIMER SETUP
  TIMSK1 |= (1 << OCIE1A);
}


//
// Main sampling timer
//
ISR(TIMER1_COMPA_vect) 
{
  sensorSampleRateCounter++;
  if(sensorSampleRateCounter == SAMPLE_RATE_PERIOD)
  {
    sensorSampleRateCounter = 0;
    executeOneLoop = 1;
  }

  if(soundPeriod>0)
  {
    soundCounter++;
    if(soundCounter>soundPeriod)
    {
      soundCounter = 0;
      PORTC ^=B00000010;
    }
  }
  else
  {
      PORTC &=B11111101;
  }
}


void loop()
{
  
  if(executeOneLoop==1)
  {
    PORTB |=B00100000;
      executeOneLoop = 0;
      
      readNewSerialData();
      
      executeLeftMotor();
      executeRightMotor();
      refreshShiftRegisters();
      executeUltrasonicSensor();
      //executeGyro();
      sampleRateCounter++;
      if(sampleRateCounter==DIVIDE_SAMPLE_RATE_BY)
      {
        sampleRateCounter = 0;
        sendSerialFrame();
      }
      PORTB &=B11011111;
  }
}

void initGyro()
{
  if (!i2c_init()) {
      Serial.println("I2C init failed\n");
  }
  else
  {
      Serial.println("I2C init OK\n"); 
  }
  delay(200);
  if(!i2c_start_wait((I2C_7BITADDR<<1)|I2C_WRITE))
  {
     Serial.print("I2C busy\n");
  }
  i2c_write((uint8_t)0x6B);// PWR_MGMT_1 register
  i2c_write((uint8_t)0); // set to zero (wakes up the MPU-6050)
  i2c_stop();
}

void executeGyro()
{
   if(!i2c_start_wait((I2C_7BITADDR<<1)|I2C_WRITE))
  {
     Serial.print("I2C busy\n");
  }
  //Wire.beginTransmission(MPU_addr);
  i2c_write(0x3B);// starting with register 0x3B (ACCEL_XOUT_H)
  i2c_stop();

  i2c_rep_start((I2C_7BITADDR<<1)|I2C_READ);
  // request a total of 14 registers

  AcX=i2c_read(false)<<8|i2c_read(false);  // 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)    
  AcY=i2c_read(false)<<8|i2c_read(false);  // 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
  AcZ=i2c_read(false)<<8|i2c_read(false);  // 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
  Tmp=i2c_read(false)<<8|i2c_read(false);  // 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
  GyX=i2c_read(false)<<8|i2c_read(false);  // 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
  GyY=i2c_read(false)<<8|i2c_read(false);  // 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)
  GyZ=i2c_read(false)<<8|i2c_read(true);  // 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
  i2c_stop();
}


void executeUltrasonicSensor()
{
   // Send distance data to Matlab
    digitalWrite(ultrasonicTrigPin, LOW);
    delayMicroseconds(5);
    digitalWrite(ultrasonicTrigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(ultrasonicTrigPin, LOW);
    ultrasonicDistance = pulseIn(ultrasonicEchoPin, HIGH,5000);
    /*if(ultrasonicDistance ==0)
    {
      ultrasonicDistance = 5000;
    }*/

}
void executeLeftMotor()
{
  if(motorSpeedLeft>0)
  {
      shiftReg1 |= bitMask<<L_F_E;
      shiftReg1 &= ~(bitMask<<L_R_E);
      analogWrite(L_PWM, motorSpeedLeft);
  }
  else if(motorSpeedLeft<0)
  {
      shiftReg1 |= bitMask<<L_R_E;
      shiftReg1 &= ~(bitMask<<L_F_E);
      analogWrite(L_PWM, -motorSpeedLeft);
  }
  else
  {
      shiftReg1 &= ~(bitMask<<L_F_E);
      shiftReg1 &= ~(bitMask<<L_R_E);
      analogWrite(L_PWM, 0);
  }
}



void executeRightMotor()
{
  if(motorSpeedRight>0)
  {
      shiftReg1 |= bitMask<<R_F_E;
      shiftReg1 &= ~(bitMask<<R_R_E);
      analogWrite(R_PWM, motorSpeedRight);
  }
  else if(motorSpeedRight<0)
  {
      shiftReg1 |= bitMask<<R_R_E;
      shiftReg1 &= ~(bitMask<<R_F_E);
      analogWrite(R_PWM, -motorSpeedRight);
  }
  else
  {
      shiftReg1 &= ~(bitMask<<R_F_E);
      shiftReg1 &= ~(bitMask<<R_R_E);
      analogWrite(R_PWM, 0);
  } 
}



void sendSerialFrame()
{
  Serial.print(L_counter, DEC );
  R_counter = 0;
  Serial.print(",");
  Serial.print(R_counter, DEC);
  L_counter = 0;
  Serial.print(",");
  Serial.print(ultrasonicDistance, DEC );

  Serial.print(","); Serial.print(AcX);
  Serial.print(","); Serial.print(AcY);
  Serial.print(","); Serial.print(AcZ);
  Serial.print(","); Serial.print(Tmp/340.00+36.53);  //equation for temperature in degrees C from datasheet
  Serial.print(","); Serial.print(GyX);
  Serial.print(","); Serial.print(GyY);
  Serial.print(","); Serial.println(GyZ);
}


void readNewSerialData()
{
  if(Serial.available()>0)
  {

        // read untill \n from the serial port:
        String inString = Serial.readStringUntil('\n');
      
        //convert string to null terminate array of chars
        inString.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
        commandBuffer[inString.length()] = 0;
        
        
        // breaks string str into a series of tokens using delimiter ";"
        // Namely split strings into commands
        char* command = strtok(commandBuffer, ";");
        while (command != 0)
        {
            // Split the command in 2 parts: name and value
            char* separator = strchr(command, ':');
            if (separator != 0)
            {
                // Actually split the string in 2: replace ':' with 0
                *separator = 0;
                --separator;
                if(*separator == 'l')//command for left motor 
                {
                  separator = separator+2;
                  motorSpeedLeft = atoi(separator);//read speed
                  if(motorSpeedLeft>255)
                  {
                    motorSpeedLeft = 255;  
                  }
                  if(motorSpeedLeft<-255)
                  {
                    motorSpeedLeft = -255;  
                  }
                }
                if(*separator == 'r')//command for right motor 
                {
                  separator = separator+2;
                  motorSpeedRight = atoi(separator);//read speed
                  if(motorSpeedRight>255)
                  {
                    motorSpeedRight = 255;  
                  }
                  if(motorSpeedRight<-255)
                  {
                    motorSpeedRight = -255;  
                  }
                }
                if(*separator == 'd')//command for LED diode 
                {
                  separator = separator+2;
                  diodeCommand = atoi(separator);//read diode command number
                  executeDiodeCommand(diodeCommand);
                }
                if(*separator == 's')//command for sound generator
                {
                  separator = separator+2;
                  soundCommand = atoi(separator);//read frequency
                  if(soundCommand>0)
                  {
                    
                    soundPeriod = 10000/soundCommand;
                   
                  }
                  else
                  {
                    soundPeriod = 0;
                  
                  }
                }


                
            }
            // Find the next command in input string
            command = strtok(0, ";");
        }//end of while
                 
    }//if serial available
}


//
//Diode command example d:320;
//  d - diode command name
//  : - separator between name and value
//  3 - index of diode 3rd diode (1-6)
//  2 - index of green color (1=B, 2=G, 3=R)
//  0 - state of diode (1=ON, 0=OFF)


void executeDiodeCommand(int newDiodeCommand)
{

  if(newDiodeCommand == 0)
  {
    turnOffLEDs();
    return;
  }
  
  LEDIndex = newDiodeCommand/100 -1;//0-5
  if(LEDIndex<0)
  {
    return;  
  }
  colorIndex = (newDiodeCommand - (LEDIndex+1)*100)/10-1;//0-2
  int ledState = ((newDiodeCommand - (LEDIndex+1)*100) - (colorIndex+1)*10)>0;
  switch (LEDIndex) {
      case 0:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg1 &= B11011111;
            }
            else
            {
              shiftReg1 |= B00100000;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg1 &= B10111111;
            }
            else
            {
              shiftReg1 |= B01000000;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg1 &= B01111111;
            }
            else
            {
              shiftReg1 |= B10000000;
            }
        }
        break;
      case 1:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg2 &= B11111101;
            }
            else
            {
              shiftReg2 |= B00000010;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg2 &= B11111011;
            }
            else
            {
              shiftReg2 |= B00000100;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg2 &= B11110111;
            }
            else
            {
              shiftReg2 |= B00001000;
            }
        }
        break;
      case 2:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg2 &= B11101111;
            }
            else
            {
              shiftReg2 |= B00010000;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg2 &= B11011111;
            }
            else
            {
              shiftReg2 |= B00100000;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg2 &= B10111111;
            }
            else
            {
              shiftReg2 |= B01000000;
            }
        }
        break;
      case 3:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg2 &= B01111111;
            }
            else
            {
              shiftReg2 |= B10000000;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg3 &= B11111110;
            }
            else
            {
              shiftReg3 |= B00000001;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg3 &= B11111101;
            }
            else
            {
              shiftReg3 |= B00000010;
            }
        }
        break;
      case 4:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg3 &= B11111011;
            }
            else
            {
              shiftReg3 |= B00000100;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg3 &= B11110111;
            }
            else
            {
              shiftReg3 |= B00001000;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg3 &= B11101111;
            }
            else
            {
              shiftReg3 |= B00010000;
            }
        }
        break;
      case 5:
        if(colorIndex ==0)
        {
            if(ledState>0)
            {
              shiftReg3 &= B11011111;
            }
            else
            {
              shiftReg3 |= B00100000;
            }
        }
        else if(colorIndex ==1)
        {
            if(ledState>0)
            {
              shiftReg3 &= B10111111;
            }
            else
            {
              shiftReg3 |= B01000000;
            }
        }
        else
        {
            if(ledState>0)
            {
              shiftReg3 &= B01111111;
            }
            else
            {
              shiftReg3 |= B10000000;
            }
        }
        break;
      default:
      break;
  }
  
}

//https://playground.arduino.cc/Main/PinChangeInterrupt
void setupInterruptForEncoders()
{
    *digitalPinToPCMSK(R_enc) |= bit (digitalPinToPCMSKbit(R_enc));  // enable pin
    PCMSK2 |= B10010000;//this is just for echo pin D4 and D7 
    PCIFR  |= bit (digitalPinToPCICRbit(R_enc)); // clear any outstanding interrupt
    PCICR  |= bit (digitalPinToPCICRbit(R_enc)); // enable interrupt for the group

    *digitalPinToPCMSK(L_enc) |= bit (digitalPinToPCMSKbit(L_enc));  // enable pin
    PCMSK2 |= B10010000;//this is just for echo pin D4 and D7 
    PCIFR  |= bit (digitalPinToPCICRbit(L_enc)); // clear any outstanding interrupt
    PCICR  |= bit (digitalPinToPCICRbit(L_enc)); // enable interrupt for the group
}

volatile int lastLeftEncoder = 0;
volatile int lastRightEncoder = 0;
volatile int currentLeftEncoder = 0;
volatile int currentRightEncoder = 0;
ISR (PCINT2_vect) // handle pin change interrupt for D0 to D7 here
{


   currentLeftEncoder = digitalRead(L_enc);
   currentRightEncoder = digitalRead(R_enc);

   if(currentLeftEncoder== HIGH && lastLeftEncoder==LOW)
   {
        if(motorSpeedLeft>0)
         {
            L_counter ++;
         }
         if(motorSpeedLeft<0)
         {
            L_counter --;
         }
   }

   if(currentRightEncoder == HIGH && lastRightEncoder==LOW)
   {
        if(motorSpeedRight>0)
         {
            R_counter ++;
         }
         if(motorSpeedRight<0)
         {
            R_counter --;
         }
   }
   lastRightEncoder = currentRightEncoder;
   lastLeftEncoder = currentLeftEncoder;
}  



void refreshShiftRegisters()
{
    digitalWrite(shiftLatchPin, 0);

    shiftOut(shiftDataPin, shiftClockPin, shiftReg3); 
    shiftOut(shiftDataPin, shiftClockPin, shiftReg2); 
    shiftOut(shiftDataPin, shiftClockPin, shiftReg1);

    digitalWrite(shiftLatchPin, 1);  
}

void turnOffLEDs()
{
    shiftReg1 |= B11100000;
    shiftReg2 = B11111111;
    shiftReg3 = B11111111;
}

void turnOffMotor()
{
    shiftReg1 &= B11100000;
}

void enableMotor()
{
  shiftReg1 |= bitMask<<enableMotorBit;  
}

void shiftOut(int myDataPin, int myClockPin, byte myDataOut) {
  // This shifts 8 bits out MSB first, 
  //on the rising edge of the clock,
  //clock idles low
  
  //internal function setup
  int i=0;
  int pinState;


 //clear everything out just in case to
 //prepare shift register for bit shifting
  digitalWrite(myDataPin, 0);
  digitalWrite(myClockPin, 0);

  //for each bit in the byte myDataOut�
  //NOTICE THAT WE ARE COUNTING DOWN in our for loop
  //This means that %00000001 or "1" will go through such
  //that it will be pin Q0 that lights. 
  for (i=7; i>=0; i--)  {
    digitalWrite(myClockPin, 0);

    //if the value passed to myDataOut and a bitmask result 
    // true then... so if we are at i=6 and our value is
    // %11010100 it would the code compares it to %01000000 
    // and proceeds to set pinState to 1.
    if ( myDataOut & (1<<i) ) {
      pinState= 1;
    }
    else {  
      pinState= 0;
    }

    //Sets the pin to HIGH or LOW depending on pinState
    digitalWrite(myDataPin, pinState);
    //register shifts bits on upstroke of clock pin  
    digitalWrite(myClockPin, 1);
    //zero the data pin after shift to prevent bleed through
    digitalWrite(myDataPin, 0);
  }

  //stop shifting
  digitalWrite(myClockPin, 0);
}
