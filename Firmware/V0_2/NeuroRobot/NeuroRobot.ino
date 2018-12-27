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
int commandValue = 0;

#define SIZE_OF_COMMAND_BUFFER 30 //command buffer size
char commandBuffer[SIZE_OF_COMMAND_BUFFER];//receiving command buffer


int motorSpeedLeft = 0;
int motorSpeedRight = 0;

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
  
  pinMode(13, OUTPUT);//LED diode
  digitalWrite(13,HIGH);
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

void loop()
{


  executeLeftMotor();
  executeRightMotor();

  Serial.print(R_counter, DEC );
  Serial.print("\t");
  Serial.println(L_counter, DEC);



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
        }
                 
    }


}

void Rvoid(){
R_counter ++;
delayMicroseconds(100);
}

void Lvoid(){
L_counter ++;
delayMicroseconds(100);
  }
