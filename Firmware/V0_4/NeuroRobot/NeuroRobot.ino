//Board V0.4



// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif


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

const int ultrasonicTrigPin = 11;
const int ultrasonicEchoPin = 12;
volatile int ultrasonicDistance = 0;
volatile int tempUltrasonicDistance = 0;
volatile unsigned long ultrasonicPulseStart = 0;

#define SIZE_OF_COMMAND_BUFFER 30 //command buffer size
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

int shiftDataPin = 10;
int shiftClockPin = 9;
int shiftLatchPin = 8;

byte bitMask = B00000001;

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

  turnOffLEDs();
  turnOffMotor();
  enableMotor();

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
  OCR1A = 19999;// Output Compare Registers 
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
  executeOneLoop = 1;
}


void loop()
{
  
  if(executeOneLoop==1)
  {
      executeOneLoop = 0;
      
      readNewSerialData();
      
      executeLeftMotor();
      executeRightMotor();
      refreshShiftRegisters();
      executeUltrasonicSensor();
      

      sendSerialFrame();
      
  }
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
    if(ultrasonicDistance ==0)
    {
      ultrasonicDistance = 5000;
    }

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
  Serial.print(R_counter, DEC );
  R_counter = 0;
  Serial.print("\t");
  Serial.print(L_counter, DEC);
  L_counter = 0;
  Serial.print("\t");
  Serial.println(ultrasonicDistance, DEC );
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
                  motorSpeedLeft = atoi(separator);//read number of channels
                  if(motorSpeedLeft>255)
                  {
                    motorSpeedLeft = 255;  
                  }
                  if(motorSpeedLeft<-255)
                  {
                    motorSpeedLeft = -255;  
                  }
                }
                if(*separator == 'r')//command for left motor 
                {
                  separator = separator+2;
                  motorSpeedRight = atoi(separator);//read number of channels
                  if(motorSpeedRight>255)
                  {
                    motorSpeedRight = 255;  
                  }
                  if(motorSpeedRight<-255)
                  {
                    motorSpeedRight = -255;  
                  }
                }
            }
            // Find the next command in input string
            command = strtok(0, ";");
        }//end of while
                 
    }//if serial available
}



void Rvoid(){
  
    if(motorSpeedRight>0)
     {
        R_counter ++;
     }
     if(motorSpeedRight<0)
     {
        R_counter --;
     }
    delayMicroseconds(100);
}

void Lvoid()
{
     if(motorSpeedLeft>0)
     {
        L_counter ++;
     }
     if(motorSpeedLeft<0)
     {
        L_counter --;
     }
     delayMicroseconds(100);
}



/*
 
volatile byte waitForEcho = 0;
void ultrasonicInterruptSetup()
{
    *digitalPinToPCMSK(ultrasonicEchoPin) |= bit (digitalPinToPCMSKbit(ultrasonicEchoPin));  // enable pin
    PCMSK0 |= B00010000;//this is just for echo pin D12 (it is port B index)
    PCIFR  |= bit (digitalPinToPCICRbit(ultrasonicEchoPin)); // clear any outstanding interrupt
    PCICR  |= bit (digitalPinToPCICRbit(ultrasonicEchoPin)); // enable interrupt for the group
}


ISR (PCINT0_vect) // handle pin change interrupt for D8 to D13 here
{    
      //byte test = PORTB & B00010000;
     //if(digitalRead(ultrasonicEchoPin)==0)
     //if(test==0)
     if(waitForEcho)
     {
        waitForEcho = 0;
     }
     else
     {
        PORTB |= B00100000;
        tempUltrasonicDistance = micros() - ultrasonicPulseStart; 
        PORTB &= B11011111;
     }
}
 
void startMeasuringUltrasonic()
{
    waitForEcho = 1;
    //PORTB |= B00100000;
    digitalWrite(ultrasonicTrigPin, LOW);
    delayMicroseconds(5);
    digitalWrite(ultrasonicTrigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(ultrasonicTrigPin, LOW);
    ultrasonicPulseStart = micros(); // store the current microseconds
}

int getUltrasonicDistance()
{
    if(( micros() - ultrasonicPulseStart)>5000)
    {
      return 5000;
    }
    else
    {
      return tempUltrasonicDistance;
    }
    
}
*/

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
