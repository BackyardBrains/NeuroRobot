#include "esp_camera.h"
#include <WiFi.h>


#define CAMERA_MODEL_AI_THINKER  // Has PSRAM
#include "camera_pins.h"

#define MAKE_AP 1
#if defined(MAKE_AP)
#define ROBOT_NAME_AP "NeuroRobot"
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


void startCameraServer();
void sendDataViaSocket(char* dataToSend, int lengthOfData);

void newDataArrivedFromSocket(char* data, int lengthOfData) {
  Serial.println(data);
}


uint32_t getUniqueNumber() {
  uint32_t id = 0;
  for (int i = 0; i < 17; i = i + 8) {
    id |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }
  return id;
}


void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();





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

  sensor_t* s = esp_camera_sensor_get();
  // drop down frame size for higher initial frame rate
  s->set_framesize(s, FRAMESIZE_QVGA);

  s->set_brightness(s, 1);     // -2 to 2
  s->set_contrast(s, 2);       // -2 to 2
  // s->set_saturation(s, 0);     // -2 to 2
  // s->set_special_effect(s, 0); // 0 to 6 (0 - No Effect, 1 - Negative, 2 - Grayscale, 3 - Red Tint, 4 - Green Tint, 5 - Blue Tint, 6 - Sepia)
  s->set_whitebal(s, 0);  // 0 = disable , 1 = enable
  s->set_awb_gain(s, 0);  // 0 = disable , 1 = enable
  // s->set_wb_mode(s, 0);        // 0 to 4 - if awb_gain enabled (0 - Auto, 1 - Sunny, 2 - Cloudy, 3 - Office, 4 - Home)
  // s->set_exposure_ctrl(s, 1);  // 0 = disable , 1 = enable
  // s->set_aec2(s, 0);           // 0 = disable , 1 = enable
  // s->set_ae_level(s, 0);       // -2 to 2
  // s->set_aec_value(s, 300);    // 0 to 1200
  // s->set_gain_ctrl(s, 1);      // 0 = disable , 1 = enable
  // s->set_agc_gain(s, 0);       // 0 to 30
  // s->set_gainceiling(s, (gainceiling_t)0);  // 0 to 6
  // s->set_bpc(s, 0);            // 0 = disable , 1 = enable
  // s->set_wpc(s, 1);            // 0 = disable , 1 = enable
  // s->set_raw_gma(s, 1);        // 0 = disable , 1 = enable
  // s->set_lenc(s, 1);           // 0 = disable , 1 = enable
  // s->set_hmirror(s, 0);        // 0 = disable , 1 = enable
  // s->set_vflip(s, 0);          // 0 = disable , 1 = enable
  // s->set_dcw(s, 1);            // 0 = disable , 1 = enable
  // s->set_colorbar(s, 0);       // 0 = disable , 1 = enable





#if defined(MAKE_AP)

  tempNameOfAP = String(ROBOT_NAME_AP);
  nameOfAP = tempNameOfAP + "_" + getUniqueNumber();

  int channel = DEFAULT_WIFI_CHANNEL;
#if defined(RANDOMIZE_WIFI_CHANNEL)
  channel = random(13) + 1;
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
}


void loop() {
  // put your main code here, to run repeatedly:


  if (Serial.available() > 0) {
    // read untill \n from the serial port:
    String inString = Serial.readStringUntil('\n');
    //convert string to null terminate array of chars
    inString.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
    int lengthOfIncommingMessage = inString.length();
    commandBuffer[lengthOfIncommingMessage] = 0;
    sendDataViaSocket(commandBuffer, lengthOfIncommingMessage);
  }
}
