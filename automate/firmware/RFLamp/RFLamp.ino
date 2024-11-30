/*
 * Ben Provenzano III
 * -----------------
 * v1 06/03/2020
 * v2 03/20/2021
 * v3 08/11/2022
 433MHz Wireless Receiver Pair RFA
 * Wireless 433Mhz Dresser Automation Controller/Receiver
 *
 */
 
// Libraries
#include <RCSwitch.h>
#include <ezButton.h>
RCSwitch mySwitch = RCSwitch();

// Define Buttons
const int button_pin1 = 6;      // Power Button
ezButton button1(button_pin1);  // ezButton object I

// Define Outputs
#define relay0 4 // MOSFET Output
#define led 13   // Status LED

// Variables
int relaysState0 = LOW;
int stateChanged = LOW;

void setup() {
// Buttons Setup
  pinMode(button_pin1, INPUT_PULLUP);
  button1.setDebounceTime(50);
// Output Setup
  pinMode(relay0, OUTPUT); 
  pinMode(led, OUTPUT);
  digitalWrite(relay0, LOW);
  digitalWrite(led, HIGH);
// RF Receive
  delay(500); 
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => that is [pin #2 on uno] [pin #3 on micro]
  digitalWrite(led, LOW);
}

void loop() {
  checkButtons();
  receiveRF();
  writeOutputs();
}

void receiveRF() {
  if (mySwitch.available()) {
    unsigned long rfvalue = mySwitch.getReceivedValue();
    if (rfvalue == 834511)
    {
      stateChanged = HIGH;
      relaysState0 = HIGH;  
    }
    if (rfvalue == 834512)
    {
      stateChanged = HIGH;
      relaysState0 = LOW;
    } 
    mySwitch.resetAvailable();
  }
}

void checkButtons() {
  button1.loop();
  if(button1.isReleased()){
    // toggle state of relay 1
    relaysState0 = !relaysState0;
    stateChanged = HIGH;
  } 
}

void writeOutputs() {
  if (stateChanged == HIGH) {
    // Turn Relay 1 On/Off
    digitalWrite(relay0, relaysState0);
    digitalWrite(led, relaysState0);  
    delay(100);  
    stateChanged = LOW;  
  }  
}
