/*
* Made for Neuro Robot that has only ESP32-Cam
* 10. Oct. 2023
* Modified by Stanislav Mircic
*/

#include "esp_camera.h"
#include <WiFi.h>
#include <ESP32Servo.h>
#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include "Adafruit_VCNL4010.h"


#define USE_LEDS 1
#define USE_DISTANCE_SENSOR 1
#define USE_MOTORS 1
#define USE_SPEAKER 1
#define MAKE_AP 1

#if defined(USE_DISTANCE_SENSOR)
  #define I2C_SDA 13
  #define I2C_SCL 2
  TwoWire I2CSensors = TwoWire(0);
  Adafruit_VCNL4010 vcnl;
#endif

#define CAMERA_MODEL_AI_THINKER // Has PSRAM
#include "camera_pins.h"

#if defined(MAKE_AP)
  #define ROBOT_NAME_AP "Neurobot"
  String tempNameOfAP, nameOfAP;
  #define DEFAULT_WIFI_CHANNEL 6
  #define RANDOMIZE_WIFI_CHANNEL 1
#else
  const char* ssid = "bfd52a";
  const char* password = "282875063";
#endif

// Select camera model

#define SIZE_OF_COMMAND_BUFFER 256
char commandBuffer[256];

#if defined(USE_LEDS)
  #define LED_PIN   12
  #define LED_COUNT 4
  volatile int diodeCommand = 0;
  Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
  uint32_t color = (0,255,0);
#endif

#if defined(USE_MOTORS)
  Servo servo1;
  Servo servo2;
  int pos = 90;
  int motorSpeedLeft;
  int motorSpeedRight;
  int rServoPin = 14;
  int lServoPin = 15;
#endif
int this_speed = 0;
int io_command[] = {0, 0, 0, 0, 0};
long duration;
long distance;
int this_tone = 0;
int micPin = 0;
int spkPin = 4;
int micVal = 0;
int toneVal = 0;

void startCameraServer();
void sendDataViaSocket(char * dataToSend, int lengthOfData);

#if defined(USE_LEDS)
  void turnOffLEDs()
  {
  strip.setPixelColor(0, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(1, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(2, strip.Color(  0,   0,   0)); 
  strip.setPixelColor(3, strip.Color(  0,   0,   0)); 
  strip.show();
  }
#endif

//
//Diode command example d:320;
//  d - diode command name
//  : - separator between name and value
//  3 - index of diode 3rd diode (1-6)
//  2 - index of green color (1=B, 2=G, 3=R)
//  0 - state of diode (1=ON, 0=OFF)

#if defined(USE_LEDS)
  void executeDiodeCommand(int newDiodeCommand)
  {

    if (newDiodeCommand == 0)
    {
      turnOffLEDs();
      return;
    }

    int LEDIndex = newDiodeCommand / 100 - 1; //0-3
    if (LEDIndex < 0)
    {
      return;
    }
    if (LEDIndex >=LED_COUNT)
    {
      return;
    }
    int colorIndex = (newDiodeCommand - (LEDIndex + 1) * 100) / 10 - 1; //0-2
    int ledState = ((newDiodeCommand - (LEDIndex + 1) * 100) - (colorIndex + 1) * 10) > 0;

    int intensity = 255;
    if(ledState==0)
    {
      intensity = 0;
    }

    if (colorIndex == 0)
    {
  
      strip.setPixelColor(LEDIndex, strip.Color(  intensity,   0,   0)); 
    }
    else if (colorIndex == 1)
    {
  
      strip.setPixelColor(LEDIndex, strip.Color(  0,   intensity,   0)); 
    }
    else
    {

      strip.setPixelColor(LEDIndex, strip.Color(  0,   0,   intensity)); 
    }
    
    strip.show();

  }

#endif

void newDataArrivedFromSocket(char * data, int lengthOfData)
{
    //Serial.println(data);

    // breaks string str into a series of tokens using delimiter ";"
    // Namely split strings into commands
    char* command = strtok(data, ";");
    while (command != 0)
    {
      // Split the command in 2 parts: name and value
      char* separator = strchr(command, ':');
      if (separator != 0)
      {
        // Actually split the string in 2: replace ':' with 0
        *separator = 0;
        --separator;
        if (*separator == 'l') //command for left motor
        {
          separator = separator + 2;
          #if defined(USE_MOTORS)
              motorSpeedLeft = atoi(separator);//read speed
              if (motorSpeedLeft > 255)
              {
                motorSpeedLeft = 255;
              }
              if (motorSpeedLeft < -255)
              {
                motorSpeedLeft = -255;
              }
              motorSpeedLeft = motorSpeedLeft*2+1500;
              
              servo1.write(motorSpeedLeft); 
                  //Serial.println(motorSpeedLeft);
          #endif
        }
        if (*separator == 'r') //command for right motor
        {
          separator = separator + 2;
          #if defined(USE_MOTORS)
              motorSpeedRight = atoi(separator);//read speed
              if (motorSpeedRight > 255)
              {
                motorSpeedRight = 255;
              }
              if (motorSpeedRight < -255)
              {
                motorSpeedRight = -255;
              }
              motorSpeedRight = motorSpeedRight*2+1500;
              
              servo2.write(motorSpeedRight); 
                  //Serial.println(motorSpeedRight);
          #endif
        }
        if (*separator == 'd') //command for LED diode
        {
          separator = separator + 2;
          #if defined(USE_LEDS)
            diodeCommand = atoi(separator);//read diode command number
            executeDiodeCommand(diodeCommand);
          #endif
        }
        if (*separator == 's') //command for sound generator
        {
          separator = separator + 2;
          this_tone = atoi(separator);//read frequency
        }
      }
      // Find the next command in input string
      command = strtok(0, ";");
    }//end of while
}


uint32_t getUniqueNumber()
{
    uint32_t id = 0;
    for(int i=0; i<17; i=i+8) 
    {
      id |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
    }
    return id;
}


void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

#if defined(USE_LEDS)
  strip.begin();
  strip.show();
  strip.setBrightness(25);
  strip.setPixelColor(0, color);
  strip.show();
#endif

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_UXGA;
  config.jpeg_quality = 10;
  config.fb_count = 2;

  // camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  sensor_t * s = esp_camera_sensor_get();
  // drop down frame size for higher initial frame rate
  s->set_framesize(s, FRAMESIZE_QVGA);

#if defined(USE_MOTORS)
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);
  servo1.setPeriodHertz(50);  // standard 50 hz servo
  servo2.setPeriodHertz(50);
  servo1.attach(rServoPin, 1000, 2000);
  servo2.attach(lServoPin, 1000, 2000);
#endif

#if defined(USE_DISTANCE_SENSOR)
  I2CSensors.begin(I2C_SDA, I2C_SCL, 100000);
  if (! vcnl.begin(0x13, &I2CSensors)){
    Serial.println("Sensor not found :(");
    while (1);
  }
  Serial.println("Found VCNL4010");
#endif

#if defined(MAKE_AP)

  tempNameOfAP = String(ROBOT_NAME_AP);
  nameOfAP = tempNameOfAP+"_" +getUniqueNumber();
  
  int channel = DEFAULT_WIFI_CHANNEL;
  #if defined(RANDOMIZE_WIFI_CHANNEL)
    channel = random(13)+1;
  #endif
  
  WiFi.softAP(nameOfAP.c_str(), NULL, channel);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("Use 'http://");
  Serial.print(IP);
  Serial.println("' to connect");
#else
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  
  Serial.print("Use 'http://")
  Serial.print(WiFi.localIP());
  Serial.println("' to connect");
#endif
  startCameraServer();
  Serial.print("Camera Ready!");

#if defined(USE_MOTORS)
  servo1.write(1500);
  servo2.write(1500);
#endif
  
}


void loop() {

  //send distance to host computer via Socket
  String distanceStr =  String(distance); 
  String distanceStrWithComma =  String("0,0,"+distanceStr + ", ");
  distanceStrWithComma.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
  int lengthOfIncommingMessage = distanceStrWithComma.length();
  commandBuffer[lengthOfIncommingMessage] = 0;
  sendDataViaSocket(commandBuffer, lengthOfIncommingMessage);
  
  #if defined(USE_DISTANCE_SENSOR)
    distance = 12000 - vcnl.readProximity();
    distance = distance * 0.2;    
    if(distance<0)
    {
      distance = 0;
    }
    //Serial.println(distance);
  #endif
 

  #if defined(USE_SPEAKER)
    if(this_tone > 0){
      tone(spkPin,this_tone);
    }
    else {
      noTone(spkPin);
    }
  #endif
}
