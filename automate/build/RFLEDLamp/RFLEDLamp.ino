/*
 * Ben Provenzano III
 * -----------------
 * v1 6/3/2020
 * v2 3/20/2021
 433MHz Wireless Receiver Pair RFA
 ** Patent Pending **
 * Wireless 433Mhz Dresser Automation Controller/Receiver
 * v2
 *
 */
 

#include <RCSwitch.h>
#include <ezButton.h>
RCSwitch mySwitch = RCSwitch();

// Setup buttons
const int button_pin1 = 6; // Power Button
ezButton button1(button_pin1);  // ezButton object I

// Relays state variables
int relaysState0 = LOW;

// Setup outputs
#define relay1 4 // MOSFET Output
#define led 13

void setup() {
  pinMode(relay1, OUTPUT); 
  pinMode(led, OUTPUT);
  pinMode(button_pin1, INPUT_PULLUP);
  button1.setDebounceTime(75);
  digitalWrite(relay1, LOW);
  digitalWrite(led, HIGH);
  delay(500); 
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => that is [pin #2 on uno] [pin #3 on micro]
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(183);
  digitalWrite(led, LOW);
}

void loop () {

// RF Controller
  if (mySwitch.available()) {
    
    unsigned long value = mySwitch.getReceivedValue();
    
    if (value == 834511)
    {
      digitalWrite(relay1, HIGH);
      digitalWrite(led, HIGH);
      relaysState0 = HIGH;  
      delay(100);
    }
    
    if (value == 834512)
    {
      digitalWrite(relay1, LOW);
      digitalWrite(led, LOW);
      relaysState0 = LOW;
      delay(100);  
    } 
  
    {
       mySwitch.resetAvailable();
  }
}
// Button loops must be last
    button1.loop();
    {
     if(button1.isPressed()){
     // toggle state of relays
     relaysState0 = !relaysState0;
     // control relays according to state
     digitalWrite(relay1, relaysState0);
     digitalWrite(led, relaysState0);
    } 
  }
}
