/*
 * Ben Provenzano III
 * -----------------
 * Nov. 22th 2015
 433MHz Wireless Receiver Paired with Arduino UNO running on channel characters (j,k,l,m,n,o,p,q) RS232 1200baud
 ** Patent Pending **
 * Wireless 433Mhz Desktop Automation Controller/Receiver
 * v2
 *
 */
 

#include <RCSwitch.h>

RCSwitch mySwitch = RCSwitch();

long toggleTimer0 = millis();  // // debounce timer
long toggleTimer1 = millis();  // // debounce timer
boolean toggleState0; // hold current state of switch
boolean lastToggleState0;  // hold last state to sense when switch is changed
boolean toggleState1; // hold current state of switch
boolean lastToggleState1;  // hold last state to sense when switch is changed

#define switch1 5 // [Pin #11] (Overhead Light)
#define switch2 6 // [Pin #12] (Desktop E-Stop)

#define relay1 9 //(Light 2 / Overhead Light) // [Pin #15]
#define relay2 10 //(Desk Power) // [Pin #16]
#define relay3 11 // (Desk Power HC) // [Pin #17]


void setup() {
  //Serial.begin(1200);
  mySwitch.enableReceive(0);  // Receiver on inerrupt 0 => that is [pin #2]
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(183);
  pinMode(relay1, OUTPUT);    
  pinMode(relay2, OUTPUT);  
  pinMode(relay3, OUTPUT);  
  pinMode(switch1, INPUT_PULLUP);
  pinMode(switch2, INPUT_PULLUP);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
}

void loop () {

  toggleState0 = digitalRead(switch1); 

if (millis() - toggleTimer0 > 100){  // debounce switch 100ms timer
  if (toggleState0 && !lastToggleState0) {  // if switch is on but was previously off
    lastToggleState0 = true;  // switch is now on
    toggleTimer0 = millis();  // reset timer
    digitalWrite(relay1, HIGH);
  }

  if (!toggleState0 && lastToggleState0){  // if switch is off but was previously on
    lastToggleState0 = false; // switch is now off
    toggleTimer0 = millis(); // reset timer
    digitalWrite(relay1, LOW);
    }
  }
  

toggleState1 = digitalRead(switch2); 

if (millis() - toggleTimer1 > 100){  // debounce switch 100ms timer
  if (toggleState1 && !lastToggleState1) {  // if switch is on but was previously off
    lastToggleState1 = true;  // switch is now on
    toggleTimer1 = millis();  // reset timer
    digitalWrite(relay3, HIGH);
  }

  if (!toggleState1 && lastToggleState1){  // if switch is off but was previously on
    lastToggleState1 = false; // switch is now off
    toggleTimer1 = millis(); // reset timer
    digitalWrite(relay3, LOW);
    }
}

  if (mySwitch.available()) {
    
    unsigned long value = mySwitch.getReceivedValue();
    
    
    if (value == 864341) //relay 1 on (Overhead Light On)
    {
      digitalWrite(relay1, HIGH);
      delay(100); 
    }
    
    if (value == 864342) //relay 1 off (Overhead Light Off)
    {
      digitalWrite(relay1, LOW);
      delay(100);
    } 
    
    if (value == 864343) //relay 2 (12v Aux Pulse)
    {
      digitalWrite(relay2, HIGH);
      delay(275);
      digitalWrite(relay2, LOW);
      delay(100);
    }
    
    if (value == 864345) //relay 3 on (Desk Power On)
    {
      digitalWrite(relay3, HIGH);
      delay(100);
    }
    
    if (value == 864346) //relay 3 off (Desk Power Off)
    {
      digitalWrite(relay3, LOW);
      delay(100);  
    } 
    
    
    {

       mySwitch.resetAvailable();
  }
}
 
}
