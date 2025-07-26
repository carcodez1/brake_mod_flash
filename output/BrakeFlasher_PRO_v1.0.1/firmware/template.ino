// template.ino
// Static fallback firmware: BrakeFlasher PRO
// Target: Arduino Nano (ATmega328P, 5V, 16MHz)
// Input Pin: D3 (active HIGH)
// Output Pin: D4 (brake light signal)
// Author: Jeffrey Plewak
// Version: 1.0.1
// Date: 2025-07-26
// License: Proprietary – NDA / IP Assigned
// SHA256 Expected: Defined in config/sha256_manifest.txt

const int inputPin = 3;   // Brake trigger (digital, opto-isolated preferred)
const int outputPin = 4;  // Output to third brake light (solid state relay)

void setup() {
  pinMode(inputPin, INPUT);
  pinMode(outputPin, OUTPUT);
  digitalWrite(outputPin, LOW);
}

void loop() {
  if (digitalRead(inputPin) == HIGH) {
    // Begin flash sequence — matches config_template.json
    digitalWrite(outputPin, HIGH); delay(100);
    digitalWrite(outputPin, LOW);  delay(100);

    digitalWrite(outputPin, HIGH); delay(100);
    digitalWrite(outputPin, LOW);  delay(100);

    digitalWrite(outputPin, HIGH); delay(100);
    digitalWrite(outputPin, LOW);  delay(100);

    digitalWrite(outputPin, HIGH); delay(200);
    digitalWrite(outputPin, LOW);  delay(200);

    digitalWrite(outputPin, HIGH); delay(200);
    digitalWrite(outputPin, LOW);  delay(200);

    digitalWrite(outputPin, HIGH); delay(400);
    digitalWrite(outputPin, LOW);  delay(400);

    // Hold ON state (until brake released)
    digitalWrite(outputPin, HIGH);
  } else {
    digitalWrite(outputPin, LOW);
  }
}
