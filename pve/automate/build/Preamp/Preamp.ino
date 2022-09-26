/// Libraries ///
#include <Arduino.h>
#include "LiquidCrystal_I2C.h" // custom for MCP23008-E/P, power button support
#include <IRremote.hpp>
#include "I2CIO.h"

#include <Wire.h> 

// I2C (0x3E) Volume Reset
// I2C (0x3F) Volume Set
#define volResetAddr 0x3E
#define volSetAddr 0x3F
#define lcdAddr 0x27
// I2C Display
LiquidCrystal_I2C lcd(lcdAddr);
// IR (pin 8)
int receive_pin = 8;
bool irCodeScan = 0;

// Input selector stuff
int selectedInput = 0;
long muteDelay = 1000;

// Relay attenuator stuff
bool muteEnabled = false;
byte lastAttenuatorLevel;
byte volLevel = 0;

// System stuff
#define powerPin 5
unsigned long timeOfLastOperation;

byte powerButton = 0;
bool powerState = 0; // initial power state
bool powerCycled = 0; 
byte lastPowerState = 0;    // the previous reading from the power button
unsigned long lastDebounceTime = 0;  // the last time the output pin was toggled
unsigned long debounceDelay = 50;    // the debounce time; increase if the output flickers


byte PCFexpanderRead(int address) 
{
 byte _data;
 Wire.requestFrom(address, 1);
 if(Wire.available()) {
   _data = Wire.read();
 }
 return _data;
}

void PCFexpanderWrite(byte address, byte _data ) 
{
 Wire.beginTransmission(address);
 Wire.write(_data);
 Wire.endTransmission(); 
}

// Function to set a specific attenuator level
int setAttenuatorLevel (byte level) {
  muteEnabled = false;
  PCFexpanderWrite(volResetAddr, ~level);
  PCFexpanderWrite(volSetAddr, level);
  delay(5);
  PCFexpanderWrite(volSetAddr, B00000000);
  PCFexpanderWrite(volResetAddr, B00000000);
}

void irReceive() 
{
  if (IrReceiver.decode()) {
    // Display IR codes on terminal
    if (irCodeScan == 1) {   
      if (IrReceiver.decodedIRData.protocol == UNKNOWN) {
        IrReceiver.printIRResultRawFormatted(&Serial, true);
      }
        IrReceiver.printIRResultMinimal(&Serial);
    }
    // IR functions 
    if (IrReceiver.decodedIRData.address == 0xCE) {  
      if (IrReceiver.decodedIRData.command == 0x3) {
        // Power button
        powerState = !powerState;  
        powerCycled = 0;
      }  
      if (powerState == 1) {
        if (IrReceiver.decodedIRData.command == 0xC) {
          // Volume down
          volLevel = volLevel - 1;
          setAttenuatorLevel(volLevel);
          lcd.clear();
          lcd.setCursor(7,0);
          lcd.print(volLevel); 
              
        } else if (IrReceiver.decodedIRData.command == 0xA) {
          // Volume up
          volLevel = volLevel + 1;
          setAttenuatorLevel(volLevel);
          lcd.clear();
          lcd.setCursor(7,0);
          lcd.print(volLevel); 
        }
      }  
    delay(50); 
    IrReceiver.resume();  
    }
  }
}


void setPowerState() {
  // read pin state from MCP23008
  int reading = lcd.readPin(powerPin);
  // If switch changed
  if (reading != lastPowerState) {
    // reset the debouncing timer
    lastDebounceTime = millis();
  }
  if ((millis() - lastDebounceTime) > debounceDelay) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:
    // if the button state has changed:
    if (reading != powerButton) {
      powerButton = reading;
      // power state has changed!
      if (powerButton == 1) { 
        powerState = !powerState;  
        powerCycled = 0;
      }
    }
  }
  lastPowerState = reading; 
}

void setup()
{
Serial.begin(9600);

// IR
IrReceiver.begin(receive_pin);

// 16x2 Display (calls Wire.begin)
lcd.begin(16,2);

// Volume Control Expander
PCFexpanderWrite(volResetAddr, 0x00);
PCFexpanderWrite(volSetAddr, 0x00);

delay(100);
}

void loop()
{
  setPowerState();
  irCodeScan = 1;
  irReceive(); 
  
  if (powerCycled == 0){
    if (powerState == 1){
      lcd.clear();
      lcd.setCursor(6,0);
      lcd.print("Power On"); 
    } else {  
      setAttenuatorLevel(0);
      lcd.clear();
      lcd.setCursor(6,0);
      lcd.print("Power Off"); 
    }  
    powerCycled = 1;  
  }  

}
