#include <Arduino.h>
#include <Servo.h>


#define servoPin 7
#define relayPin 5
#define photoGate1Pin 8
#define photoGate2Pin 10
#define buttonPin A0

int cameraTriggerDelay = 35; // Delay in milliseconds
int videoDuration = 500; // Total time from camera start to camera stop in ms (if lower than 500, the Chronos camera can't handle the small gap between camera start/stop signals from relay)
int relayDelay = 10; // Time between effective press and effective release of camera trigger (must be < videoDuration)

int servoRestPosition = 0; // Servo position when not triggered
int servoReleasePosition = 15; // Servo position to release the particle

int state; // To ensure button can't be held to prolong camera relay trigger
int prevState = HIGH;

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

void triggerCamera() {
    digitalWrite(relayPin, LOW);
    delay(relayDelay);
    digitalWrite(relayPin, HIGH);
}

void loop() {
  state = digitalRead(buttonPin);
  if (state == LOW && prevState == HIGH) {
    prevState = LOW;
    Serial.println("Trigger detected!");

    releaseServo.write(servoReleasePosition);
    delay(cameraTriggerDelay);
    triggerCamera();

    delay(videoDuration);
    triggerCamera();
    releaseServo.write(servoRestPosition);
  }

   if (state == HIGH && prevState == LOW) { 
    prevState = HIGH; 
  }
}
