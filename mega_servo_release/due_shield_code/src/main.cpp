#include <Arduino.h>
#include <Servo.h>


#define servoPin 7
#define relayPin 5
#define photoGate1Pin 8
#define photoGate2Pin 10
#define buttonPin A0

int cameraTriggerDelay = 10; // Delay in milliseconds

int servoRestPosition = 0; // Servo position when not triggered
int servoReleasePosition = 15; // Servo position to release the particle

Servo releaseServo;

void setup() {
  Serial.begin(9600);
  Serial.println("Particle Launcher Ready!");

  releaseServo.attach(servoPin);
  releaseServo.write(servoRestPosition);

  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH); // HIGH = relay off (active-low module)

  pinMode(photoGate1Pin, INPUT);
  pinMode(photoGate2Pin, INPUT);
  pinMode(buttonPin, INPUT);
}

void loop() {
  if (digitalRead(buttonPin) == LOW) {
    Serial.println("Trigger detected!");

    digitalWrite(relayPin, LOW);  // LOW = relay on (active-low module)
    delay(cameraTriggerDelay);

    releaseServo.write(servoReleasePosition);
    delay(1000);
    releaseServo.write(servoRestPosition);
    digitalWrite(relayPin, HIGH); // HIGH = relay off
  }
}
