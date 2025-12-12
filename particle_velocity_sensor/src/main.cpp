#include <Arduino.h>

long gate_one_time = 0;
long gate_two_time = 0;
long previous_event_time = 0;
long min_interval = 1000;

void setup() {
  Serial.begin(9600);
  pinMode(4, INPUT);
  pinMode(5, INPUT);

}

void loop() {
  // put your main code here, to run repeatedly:
  long current_time = millis();
  int gate_one = digitalRead(4);
  int gate_two = digitalRead(5);

  if(current_time - previous_event_time > min_interval) {
    if(gate_one == HIGH || gate_two == HIGH) {
      previous_event_time = current_time;
    }
  }
  if(gate_one == HIGH) {
    
    Serial.print("Gate 1 HIGH");
  }
  if(gate_two == HIGH) {
    Serial.print("Gate 2 HIGH ");
  }
}
