int pos = 38;

void setup() {
  Serial.begin(115200);  
  pinMode(13, OUTPUT);  
}

void loop() {
  if(Serial.available() >= 1) {
    pos = Serial.read();
    if(pos > 5){
      digitalWrite(13, 1);
      delay(1000);
      digitalWrite(13, 0);
    }
  }
  delay(100); 
}
