// Xmit Transmitter v2.0 by Ben Provenzano III
// Communicates over serial interface 9600 baud

#include <string.h>  

// IR Library
// Output pin #2 on Uno, pin #13 on Micro
#include <IRremote.h>
IRsend irsend;

// RF Library
#include <RCSwitch.h>
RCSwitch mySwitch = RCSwitch();

String readString;

void setup() {
  // Serial Port
  Serial.begin(9600);
  
  // Built-in LED
  pinMode(13, OUTPUT); 
  digitalWrite(13, LOW);
  
  // FET-2 (Internal Fan)
  pinMode(5, OUTPUT);
  digitalWrite(5,LOW);
  
  // FET-0 (Main Light)
  pinMode(6, OUTPUT);
  digitalWrite(6,LOW);
  
  // FET-1 (Network Switch)
  pinMode(7, OUTPUT);
  digitalWrite(7,HIGH);
  
  // RF transmit output on pin #10
  mySwitch.enableTransmit(10);
  mySwitch.setPulseLength(183);
  mySwitch.setProtocol(1);
  //mySwitch.setRepeatTransmit(3);
}

void loop() {

  while (Serial.available()) {
    delay(3); 
    char c = Serial.read();
    readString += c;
  }

  if (readString.length() >0) {

//////////////////

// IR Transmit (must be in integer format)
if(readString.indexOf("irtx.") >=0)
{
  //Serial.print("IR Transmit\n");
  if(readString.indexOf("nec.") >=4)
  {
    // NEC IR Transmit 32-bit
    String ircode = readString.substring(9,27);
    //Serial.println("NEC");
    //Serial.println(ircode);
    //Serial.println("\n");
    irsend.sendNEC(ircode.toInt(), 32);
    delay(30);
  }
  if(readString.indexOf("sony20.") >=4)
  {
    // SONY IR Transmit 20-bit
    String ircode = readString.substring(12,30);
    //Serial.println("Sony 20-bit");
    //Serial.println(ircode);
    //Serial.println("\n");
    irsend.sendSony(ircode.toInt(), 20);
    delay(30);
  }
  if(readString.indexOf("sony12.") >=4)
  {
    // SONY IR Transmit 12-bit
    String ircode = readString.substring(12,30);
    //Serial.println("Sony 12-bit");
    //Serial.println(ircode);
    //Serial.println("\n");
    irsend.sendSony(ircode.toInt(), 12);
    delay(30);
  }
}

// FET Control
if(readString.indexOf("fet.") >=0)
{
  //Serial.print("FET Control\n");
  if(readString.indexOf("on.") >=3)
  {
    // FET on
    String fet = readString.substring(7,9);
    //Serial.println("FET on");
    //Serial.println(fet);
    //Serial.println("\n");
    digitalWrite(fet.toInt(), HIGH);
    delay(30);
  }
  if(readString.indexOf("off.") >=3)
  {
    // FET off
    String fet = readString.substring(8,10);
    //Serial.println("FET off");
    //Serial.println(fet);
    //Serial.println("\n");
    digitalWrite(fet.toInt(), LOW);
    delay(30);
  }
}    

// 433MHz RF Control
if(readString.indexOf("rftx.") >=0)
{
  String rfcode = readString.substring(5,20);
  //Serial.println("RF Transmit");
  //Serial.println(rfcode);
  //Serial.println("\n");
  mySwitch.send(rfcode.toInt(), 24);
  delay(30);
}
        
//////////////////

    readString="";
  }
}

