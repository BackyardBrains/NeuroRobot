//Board V0.2



// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif


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

  pinMode(ultrasonicTrigPin, OUTPUT);
  pinMode(ultrasonicEchoPin, INPUT);
  
  pinMode(enablePin, OUTPUT);
  digitalWrite(enablePin, HIGH);
  attachInterrupt(digitalPinToInterrupt(R_enc), Rvoid, RISING);
  attachInterrupt(digitalPinToInterrupt(L_enc), Lvoid, FALLING);
  
  pinMode(13, OUTPUT);//LED diode


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
      digitalWrite(L_F_E, HIGH);
      digitalWrite(L_R_E, LOW);
      analogWrite(L_PWM, motorSpeedLeft);
  }
  else if(motorSpeedLeft<0)
  {
      digitalWrite(L_F_E, LOW);
      digitalWrite(L_R_E, HIGH);
      analogWrite(L_PWM, -motorSpeedLeft);
  }
  else
  {
      digitalWrite(L_F_E, LOW);
      digitalWrite(L_R_E, LOW);
      analogWrite(L_PWM, 0);
  }
}



void executeRightMotor()
{
  if(motorSpeedRight>0)
  {
      digitalWrite(R_F_E, HIGH);
      digitalWrite(R_R_E, LOW);
      analogWrite(R_PWM, motorSpeedRight);
  }
  else if(motorSpeedRight<0)
  {
      digitalWrite(R_F_E, LOW);
      digitalWrite(R_R_E, HIGH);
      analogWrite(R_PWM, -motorSpeedRight);
  }
  else
  {
      digitalWrite(R_F_E, LOW);
      digitalWrite(R_R_E, LOW);
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
