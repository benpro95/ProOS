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
const int button_pin1 = 5; // [Pin #11] (Light #1 Button)
const int button_pin2 = 6; // [Pin #12] (Light #2 Button)
ezButton button1(button_pin1);  // ezButton object I
ezButton button2(button_pin2);  // ezButton object II
  
// Define Outputs
#define relay0 9  // (Dresser Lamp +12v) [Pin #15]
#define relay1 11 // (Mac Classic) [Pin #16]
#define relay2 10 // (CRT TV) [Pin #17]

// Constants
int debounce_time = 50; // Inputs debounce time (ms) 
//int confirmTime = 75;   // Min inputs steady state time (ms) (change to long not tested!)
long unsigned confirmTime = 75;   // Min inputs steady state time (ms)

// Variables
int relaysState0 = LOW;
int relaysState1 = LOW;
int relaysState2 = LOW;   
int stateChanged = LOW;
static int lastConfirmedVector = 0;

void setup() {
  Serial.begin(9600);
// Output Setup
  pinMode(relay0, OUTPUT);
  digitalWrite(relay0, LOW);
  pinMode(relay1, OUTPUT);
  digitalWrite(relay1, LOW);
  pinMode(relay2, OUTPUT);  
  digitalWrite(relay2, LOW);
// Buttons Setup  
  delay(500); 
  pinMode(button_pin1, INPUT_PULLUP);
  pinMode(button_pin2, INPUT_PULLUP);
  button1.setDebounceTime(debounce_time);
  button2.setDebounceTime(debounce_time);   
// RF Receive  
  delay(500); 
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => that is [pin #2]
}

void loop() {
  checkButtons();
  receiveRF();
  writeOutputs();
}

void checkButtons() {
// Reset state
  static int confirmedVector = 0;
  static int lastVector = -1;
  static long unsigned int heldVector = 0L;
// ezButton calls
  button1.loop();
  button2.loop();
// Read button states   
  int rawVector =
    button1.getState() << 1 |
    button2.getState() << 0;
// Count time that state is steady    
  if (rawVector != lastVector)
  {
    heldVector = millis();
    lastVector = rawVector;
  }
// Return state after settling
  long unsigned heldTime = (millis() - heldVector);
  if (heldTime >= confirmTime)
  {
    confirmedVector = rawVector;
  }
// Set state if confirmed value is unique
  if(lastConfirmedVector != confirmedVector){
     if(confirmedVector == 1){
       // toggle state of relay 0
       stateChanged = HIGH;
       relaysState0 = !relaysState0;
     }
     if(confirmedVector == 2){
       // toggle state of relay 1
       stateChanged = HIGH;
       relaysState1 = !relaysState1;
     }
     if(confirmedVector == 3){
       // toggle state of relay 2
       stateChanged = HIGH;
       relaysState2 = !relaysState2;
     }   
  }
 lastConfirmedVector = confirmedVector;   
}

void receiveRF() {
  if (mySwitch.available()) {
    unsigned long rfvalue = mySwitch.getReceivedValue();
    if (rfvalue == 734731) // 12v aux on
    {
      stateChanged = HIGH;
      relaysState0 = HIGH;  
    }  
    if (rfvalue == 734732) // 12v aux off
    {
      stateChanged = HIGH;
      relaysState0 = LOW;
    } 
    if (rfvalue == 734733) // Relay 2 on 
    {
      stateChanged = HIGH;
      relaysState1 = HIGH;  
    }
    if (rfvalue == 734734) // Relay 2 off 
    {
      stateChanged = HIGH;
      relaysState1 = LOW;
    } 
    if (rfvalue == 734735) // Relay 3 on
    {
      stateChanged = HIGH;
      relaysState2 = HIGH;
    }
    if (rfvalue == 734736) // Relay 3 off
    {
      stateChanged = HIGH;
      relaysState2 = LOW;
    }
    mySwitch.resetAvailable();
  }
}

void writeOutputs() {
  if (stateChanged == HIGH) {
    // Turn Relay 0 On/Off
    digitalWrite(relay0, relaysState0);
    delay(75); 
    // Turn Relay 1 On/Off
    digitalWrite(relay1, relaysState1);
    delay(75);   
    // Turn Relay 2 On/Off
    digitalWrite(relay2, relaysState2);    
    delay(75);  
    stateChanged = LOW;  
  }  
}
