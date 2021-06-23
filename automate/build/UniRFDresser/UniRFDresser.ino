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
const int button_pin1 = 5; // [Pin #11] (Light #1 Button)
ezButton button1(button_pin1);  // ezButton object I
const int button_pin2 = 6; // [Pin #12] (Light #2 Button)
ezButton button2(button_pin2);  // ezButton object II

// Relays state variables
int relaysState0 = LOW;
int relaysState1 = LOW;
int relaysState2 = LOW;   

// Setup relays
#define relay1 9 // (Ceiling Lamp +12v) // [Pin #15]
#define relay2 10 // (Mac Classic) // [Pin #16]
#define relay3 11 // (Dresser Lamp) // [Pin #17]

void setup() {
  Serial.begin(9600);
  mySwitch.enableReceive(0);  // Receiver on inerrupt 0 => that is [pin #2]
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(183);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);  
  pinMode(button_pin1, INPUT_PULLUP);
  pinMode(button_pin2, INPUT_PULLUP);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  button1.setDebounceTime(75);
  button2.setDebounceTime(75);
}

void loop () {

// RF Controller
  if (mySwitch.available()) {
    
    unsigned long value = mySwitch.getReceivedValue();
    
    if (value == 734731) //12v aux on
    {
      digitalWrite(relay1, HIGH);
      relaysState0 = HIGH;  
      delay(100);
    }
    
    if (value == 734732) //12v aux off
    {
      digitalWrite(relay1, LOW);
      relaysState0 = LOW;
      delay(100);  
    } 
    
    if (value == 734733) //relay 2 on 
    {
      digitalWrite(relay2, HIGH);
      relaysState2 = HIGH;  
      delay(100);
    }
    
    if (value == 734734) //relay 2 off 
    {
      digitalWrite(relay2, LOW);
      relaysState2 = LOW;
      delay(100);  
    } 
    
    if (value == 734735) //relay 3 on
    {
      digitalWrite(relay3, HIGH);
      relaysState1 = HIGH;
      delay(100);
    }
    
    if (value == 734736) //relay 3 off
    {
      digitalWrite(relay3, LOW);
      relaysState1 = LOW;
      delay(100);
    } 
    {
       mySwitch.resetAvailable();
  }
}
// Button loops must be last
    button1.loop();
    button2.loop();
    {
     if(button1.isPressed() & button2.isPressed()){
     // toggle state of relays
     relaysState2 = !relaysState2;
     // control relays according to state
     digitalWrite(relay2, relaysState2);
    }
    else
    {
     delay(25); 
     if(button1.isPressed()){
     // toggle state of relays
     relaysState1 = !relaysState1;
     // control relays according to state
     digitalWrite(relay3, relaysState1);
     }
     if(button2.isPressed()){
     // toggle state of relays
     relaysState0 = !relaysState0;
     // control relays according to state
     digitalWrite(relay1, relaysState0);
     }
    } 
  }
}
