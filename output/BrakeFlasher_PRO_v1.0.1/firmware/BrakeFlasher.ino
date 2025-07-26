// Auto-generated Arduino firmware (.ino)
// DO NOT MODIFY BY HAND – use render_config_to_ino.py
// Author: Jeffrey Plewak
// Date: 2025-07-26T19:10:12.459701
// Version: 3.3.3
// Pinout: Input on D3 (active HIGH), Output on D4

const int inputPin = 3;
const int outputPin = 4;

void setup() {
  pinMode(inputPin, INPUT);
  pinMode(outputPin, OUTPUT);
}

void loop() {
  if (digitalRead(inputPin) == HIGH) {
    // no pattern
  } else {
    digitalWrite(outputPin, LOW);
  }
}
