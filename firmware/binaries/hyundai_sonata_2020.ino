// Auto-generated from Jinja2 template
// Vehicle: Hyundai Sonata
// Year: 2020
#include<Arduino.h>

const int inputPin = 3;
const int outputPin = 4;

void setup() {
  pinMode(inputPin, INPUT);
  pinMode(outputPin, OUTPUT);
}

void loop() {
  if (digitalRead(inputPin) == HIGH) {
    
    for (int i = 0; i < 3; i++) {
      digitalWrite(outputPin, HIGH);
      delay(100);
      digitalWrite(outputPin, LOW);
      delay(100);
    }
    
    for (int i = 0; i < 2; i++) {
      digitalWrite(outputPin, HIGH);
      delay(200);
      digitalWrite(outputPin, LOW);
      delay(100);
    }
    
    for (int i = 0; i < 1; i++) {
      digitalWrite(outputPin, HIGH);
      delay(500);
      digitalWrite(outputPin, LOW);
      delay(0);
    }
    
  }
}