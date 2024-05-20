// NeuroRobot firmware 27. Feb. 2024
// Made for BYB ESP32 S3 
// Programmed by selecting "ESP32S3 Dev Module" in Arduino
// and set board parameters in Arduino IDE:
// PSRAM: OPI PSRAM
// Flash mode: OPI 80Mhz
// Written by Stanislav Mircic
// Backyard Brains


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
#define USE_BATTERY_MEASUREMENT 1
#define SEND_MM_FOR_DISTANCE 1
//free pin that can be used for debug IO1
#define DEBUG_PIN 1

#if defined(USE_BATTERY_MEASUREMENT)
  #define BATTERY_PIN 4
  int batteryCounter = 0;
  //make measurement every 2 seconds (1second = 200 loops approx.)
  #define BATTERY_MEASUREMENTS_PERIOD (400)
#endif

#if defined(USE_SPEAKER)

    //change this acording to the absolute path to your esp32 library
    #include "C:\Users\chris\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.16\tools\sdk\esp32s3\include\hal\include\hal\timer_types.h"// find this two header files in the tools/sdk/esp32s2/** directories, should be in similar places
    #include "C:\Users\chris\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.16\tools\sdk\esp32s3\include\driver\include\driver\timer.h"// possibly usable just by including last two path names?
    #include <stdio.h>
    #include "esp_types.h"
    #include "driver/timer.h"
    #define TIMER_DIVIDER         80  //  Hardware timer clock divider
    #define TIMER_SCALE           (TIMER_BASE_CLK / TIMER_DIVIDER)  // convert counter value to seconds
    #define TIMER_INTERVAL0_SEC   (0.00001) // sample test interval for the audio timer
    #define SELECTED_TIMER_GROUP TIMER_GROUP_1
    #define SELECTED_TIMER_INDEX TIMER_1
    #define SPEAKER_PIN 14
#endif


#if defined(USE_DISTANCE_SENSOR)
  #define I2C_SDA 45
  #define I2C_SCL 21
  TwoWire I2CSensors = TwoWire(0);
  Adafruit_VCNL4010 vcnl;
#endif

#define CAMERA_MODEL_BYBV1 // Has PSRAM
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
  #define LED_PIN   13
  #define LED_COUNT 4
  volatile int diodeCommand = 0;
  Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
  uint32_t colorBlue = (0,0,255);
  uint32_t colorGreen = (0,255,0);
  bool shouldSetGreen = false;
#endif

#if defined(USE_MOTORS)
  Servo servo1;
  Servo servo2;
  int pos = 90;
  int motorSpeedLeft;
  int motorSpeedRight;
  int rServoPin = 5; //
  int lServoPin = 2; //
#endif

int this_speed = 0;
int io_command[] = {0, 0, 0, 0, 0};
long duration;
long distance;
long battery = 0;
int this_tone = 0;
int micPin = 0;

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

#if defined(USE_SPEAKER)
    bool speakerActive = false;
    int halfPeriodTone = 0;
    int fullPeriodTone = 0;
    int counterForTone = 0;




//Sound command example s:440;
//  s - sound command name
//  : - separator between name and value
//  440 - frequency of sound in Hz
//  ; - end of the command (separator)

    void setToneOnSpeaker(int toneFrequency)
    {
      if(toneFrequency<1)
      {
        speakerActive = false;
        halfPeriodTone = 0;
        fullPeriodTone = 0;
        counterForTone = 0;
        digitalWrite(SPEAKER_PIN, LOW);
      }
      else
      {
        float calc;
        calc = 0.5*((1.0/(float)toneFrequency)/TIMER_INTERVAL0_SEC);
        halfPeriodTone = calc;
        fullPeriodTone = halfPeriodTone + halfPeriodTone; 
        counterForTone = 0;
        speakerActive = true;
      }
    }


    timer_config_t tconfig = {
        .alarm_en=TIMER_ALARM_EN,//enable timer alarm
        .counter_en=TIMER_START,//starts counting counter once timer_init called
        .intr_type=TIMER_INTR_MAX,
        .counter_dir=TIMER_COUNT_UP,//counts from 0 to counter value
        .auto_reload=TIMER_AUTORELOAD_EN,// reloads counter automatically
        .divider=TIMER_DIVIDER   
    };
        
    timer_idx_t timer_idx = SELECTED_TIMER_INDEX;

    void IRAM_ATTR timer_group_isr(void *para) { 
        uint32_t timer_intr = timer_group_get_intr_status_in_isr(SELECTED_TIMER_GROUP);// gets interrupt flag
        if (timer_intr & TIMER_INTR_T0) {// if interrupt status is bit 0, timer 0 interrupt triggered, TIMER_INTR_T0 defined in API at bottom
            
              timer_group_clr_intr_status_in_isr(SELECTED_TIMER_GROUP, TIMER_0);//clear interrupt flag for timer_group0, timer_0
              if(speakerActive)
              {
                  if(counterForTone<halfPeriodTone)
                  {
                    digitalWrite(SPEAKER_PIN, HIGH);
                  }
                  else
                  {
                    digitalWrite(SPEAKER_PIN, LOW);
                  }
                  if(counterForTone>fullPeriodTone)
                  {
                    counterForTone = 0;
                  }
                  counterForTone = counterForTone+1;
              }
              //timer_counter_value += (uint64_t) (TIMER_INTERVAL0_SEC * TIMER_SCALE);
              //timer_group_set_alarm_value_in_isr(TIMER_GROUP_0, timer_idx, timer_counter_value);// probably dont need to set this if auto reload is enabled.
          } else if (timer_intr & TIMER_INTR_T1) {// if interrupt status is bit 1, timer 1 interrupr triggered
              timer_group_clr_intr_status_in_isr(SELECTED_TIMER_GROUP, TIMER_1);
              if(speakerActive)
              {
                  if(counterForTone<halfPeriodTone)
                  {
                    digitalWrite(SPEAKER_PIN, HIGH);
                  }
                  else
                  {
                    digitalWrite(SPEAKER_PIN, LOW);
                  }
                  if(counterForTone>fullPeriodTone)
                  {
                    counterForTone = 0;
                  }
                  counterForTone = counterForTone+1;
              }
          } 
          timer_group_enable_alarm_in_isr(SELECTED_TIMER_GROUP, timer_idx);// might have to reset alarm enable everytime interrupt triggers?( to be confirmed)
    }
#endif

//
//Diode command d:[index],[red],[green],[blue];
//example d:2,200,128,240;
//  d - diode command name
//  : - separator between name and value
//  2 - index of diode 3rd diode (1-4)
//  200 - value of intensity of red color (0-255)
//  128 - value of intensity of green color (0-255)
//  240 - value of intensity blue color (0-255)
//  ; - separator between commands

#if defined(USE_LEDS)

  void executeRGBDiodeCommand(int* diodeParameters)
  {
    int LEDIndex = diodeParameters[0]; //0-3
    if (LEDIndex < 0)
    {
      return;
    }
    if (LEDIndex >=LED_COUNT)
    {
      return;
    }

    strip.setPixelColor(LEDIndex, strip.Color(  diodeParameters[1],   diodeParameters[2],   diodeParameters[3])); 
   
    strip.show();
  }

#endif



void newDataArrivedFromSocket(char * data, int lengthOfData)
{
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
        //d:2,200,128,200;
        if (*separator == 'd') //command for LED diode
        {
          separator = separator + 2;
          #if defined(USE_LEDS)
            char tempBuffer[4];
            int diodeParameters[4];
            int parameterIndex = 0;
            int characterIndex = 0;
            int foundEndOfTheCommand = 0;
            while(characterIndex<15)
            {
                int tempBufferIndex = 0;
                while(tempBufferIndex<4)
                {
                    if(separator[characterIndex]==',' || separator[characterIndex]==';' || separator[characterIndex]==0)
                    {
                        tempBuffer[tempBufferIndex] = 0;
                        diodeParameters[parameterIndex] = atoi(tempBuffer);
                        parameterIndex++;
                        if(separator[characterIndex]==';' || separator[characterIndex]==0)
                        {
                          foundEndOfTheCommand =1;
                        }
                        characterIndex++;
                        break;
                    }
                    else
                    {
                        tempBuffer[tempBufferIndex] = separator[characterIndex];
                        characterIndex++;
                        tempBufferIndex++;
                    }
                }
                if(foundEndOfTheCommand)
                {
                  foundEndOfTheCommand = 0;
                  break;
                }
            }
            if(parameterIndex>=4)
            {
              executeRGBDiodeCommand(diodeParameters);
            }
          #endif
        }
        if (*separator == 's') //command for sound generator
        {
          separator = separator + 2;
          this_tone = atoi(separator);//read frequency
          #if defined(USE_SPEAKER)
            setToneOnSpeaker(this_tone);
          #endif
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
    //set Power down pin on camera to HIHG. BYB board has inverse logic in comparison with ESP32-CAM
    pinMode (39, OUTPUT);
    digitalWrite(39,LOW);


  #if defined(USE_BATTERY_MEASUREMENT)
    //set ADC for battery monitoring 
    pinMode(BATTERY_PIN,INPUT);
    analogReadResolution(10);
    battery = analogRead(BATTERY_PIN);
  #endif

    Serial.begin(115200);
    Serial.setDebugOutput(true);
    Serial.println();

    #if defined(USE_LEDS)
      strip.begin();
      strip.show();
      strip.setBrightness(25);
      strip.setPixelColor(0, colorBlue);
      strip.setPixelColor(1, colorBlue);
      strip.setPixelColor(2, colorBlue);
      strip.setPixelColor(3, colorBlue);
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

      //camera init
      esp_err_t err = esp_camera_init(&config);
      Serial.printf("Camera");
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

    #if defined(USE_SPEAKER)
      pinMode(14, OUTPUT);
      timer_init(SELECTED_TIMER_GROUP,SELECTED_TIMER_INDEX,&tconfig);// call init before setting counters
      timer_set_counter_value(SELECTED_TIMER_GROUP, timer_idx ,0x00000000ULL);// sets counter value to 0, counters up to alarm value because .counter_dir counts up
      timer_set_alarm_value(SELECTED_TIMER_GROUP, timer_idx, TIMER_INTERVAL0_SEC * TIMER_SCALE);// sets alarm value to 100 useconds, uses macro above.    
      timer_enable_intr(SELECTED_TIMER_GROUP, timer_idx);// enable interrupts for selected group and timer
      timer_isr_register(SELECTED_TIMER_GROUP, timer_idx, timer_group_isr, (void *) timer_idx, ESP_INTR_FLAG_IRAM, NULL);// registers the isr handle.
    #endif

    //setToneOnSpeaker(100);
}//end of setup


void loop() 
{
  #if defined(USE_BATTERY_MEASUREMENT)
    batteryCounter++;
    if(batteryCounter>BATTERY_MEASUREMENTS_PERIOD)
    {
      battery = analogRead(BATTERY_PIN);
      batteryCounter = 0;
    }

  #endif

  #if defined(USE_DISTANCE_SENSOR)
    distance =  vcnl.readProximity();
    if(distance<1)
    {
      distance = 1;
    }
    #if defined(SEND_MM_FOR_DISTANCE)
      distance = exp(7000.0*(1.0/((float)distance)))*10;
    #endif
  #endif

  //send distance to host computer via Socket
  String distanceStr =  String(distance); 
  String batteryStr =  String(battery); 
  String distanceStrWithComma =  String("0,0,"+distanceStr + ","+batteryStr+", ");
  distanceStrWithComma.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
  int lengthOfIncommingMessage = distanceStrWithComma.length();
  commandBuffer[lengthOfIncommingMessage] = 0;
  sendDataViaSocket(commandBuffer, lengthOfIncommingMessage);
  

  #if defined(USE_LEDS)
  #if defined(MAKE_AP)
    if(WiFi.softAPgetStationNum()==0)
    {


        strip.setBrightness(25);
        strip.setPixelColor(0, colorBlue);
        strip.setPixelColor(1, colorBlue);
        strip.setPixelColor(2, colorBlue);
        strip.setPixelColor(3, colorBlue);
        strip.show();
        shouldSetGreen = true;
    }
    else
    {
      if(shouldSetGreen)
      {
        shouldSetGreen = false;
        strip.setBrightness(25);
        strip.setPixelColor(0, 0,255,0);
        strip.setPixelColor(1, 0,255,0);
        strip.setPixelColor(2, 0,255,0);
        strip.setPixelColor(3, 0,255,0);
        strip.show();
      }
    }
  #endif
  #endif

}
