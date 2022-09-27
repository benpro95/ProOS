// Preamp Controller v1.0 
// by Ben Provenzano III
// 09/28/2022

// Libraries //
#include "LiquidCrystal_I2C.h" // custom for MCP23008-E/P, power button support
#include <IRremote.hpp>
#include <Arduino.h>
#include <Wire.h> 


// I2C (0x3E) Volume Reset
// I2C (0x3F) Volume Set
// I2C (0x27) Display / Power Button
#define volResetAddr 0x3E
#define volSetAddr 0x3F
#define lcdAddr 0x27

// 16x2 Display
LiquidCrystal_I2C lcd(lcdAddr);

// IR (pin 8)
int IRpin = 8;
bool irCodeScan = 0;

// Input selector
int selectedInput = 0;
long muteDelay = 1000;

// Relay attenuator
byte volMax = 63;
byte volRelayCount = 6;
byte volCoarseSteps = 4;
#define volControlDown 1
#define volControlUp 2
#define volControlSlow 1 
#define volControlFast 2
byte volLastLevel = 0;
byte volLevel = 0;
byte volMin = 0;
bool volMute;

// Power
#define powerPin 5
bool powerState = 0;
bool powerCycled = 0;
byte powerButton = 0;
byte lastPowerButton = 0;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50; 




// Increment volume
void volIncrement (byte dir_flag, byte speed_flag)
{
  if (dir_flag == volControlUp) {
    if (volLevel >= volMax)
      return;
  } 
  else if (dir_flag == volControlDown) {
    if (volLevel <= volMin)
      return;
  }
  if (volMute == 1 && dir_flag == volControlUp) {
    volMute = 0;
   // !! add restore display volume (unmute)
  }
  if (dir_flag == volControlUp) {
    if (speed_flag == volControlSlow) {    
      // volume up-slow
      if (volLevel < volMax &&
         (volLevel + 1) < volMax) {
        volLevel += 1;
      } 
      else {
        volLevel = volMax;
      }
      volUpdate(volLevel, 0);  
    } 
    else if (speed_flag == volControlFast) {
      // volume up-fast
      if (volLevel < (volMax - volCoarseSteps)) {
        volLevel += volCoarseSteps;
      } 
      else {
        volLevel = volMax;
      }
      volUpdate(volLevel, 0); 
    }
  }
  else if (dir_flag == volControlDown) {
    if (speed_flag == volControlSlow) {
      // volume down-slow
      if (volLevel > volMin &&
         (volLevel - 1) > volMin) {
        volLevel -= 1;
      } 
      else {
        volLevel = volMin;
      }
      volUpdate(volLevel, 0); 
    } 
    else if (speed_flag == volControlFast) {
      // volume down-fast
      if (volLevel > (volMin + volCoarseSteps)) {
        volLevel -= volCoarseSteps;
      } 
      else {
        volLevel = volMin;
      }
      volUpdate(volLevel, 0); 
    }
  }
}


// Set a specific volume level
void volUpdate (byte _vol, byte _force) 
{
   setRelays(volSetAddr, volResetAddr, _vol, volRelayCount, _force);  
   volLastLevel = volLevel;
}


// Set a relay controller board (volume or inputs)
void setRelays(byte pcf_a, byte pcf_b,  // first pair of i2c addr's
      byte vol_byte,                    // the 0..255 value to write
      byte installed_relay_count,    // how many bits are installed
      byte forced_update_flag)  // forced or relative mode (1=forced)
{
  int bitnum;
  byte  mask_left;
  byte  mask_right;
  byte  just_the_current_bit;
  byte  just_the_previous_bit;
  byte  shifted_one_bit;
  
// this must to be able to underflow to *negative* numbers
// walk the bits and just count the bit-changes and save into left and right masks
  mask_left = mask_right = 0;
  
  // this loop walks ALL bits, even the 'mute bit'
  for (bitnum = (installed_relay_count-1); bitnum >= 0 ; bitnum--) {
    
    // optimize: calc this ONLY once per loop
    shifted_one_bit = (1 << bitnum);
    
    // this is the new volume value; and just the bit we are walking
    just_the_current_bit = (vol_byte & shifted_one_bit);
    
    // logical AND to extra just the bit we are interested in
    just_the_previous_bit = (volLastLevel & shifted_one_bit);
    
    // examine our current bit and see if it changed from the last run
    if (just_the_previous_bit != just_the_current_bit ||
        forced_update_flag == 1) {
     // latch the '1' on the left or right side of the relays
     
      if (just_the_current_bit != 0) {
      // a '1' in this bit pos
      // (1 << bitnum);
        mask_left |= ((byte)shifted_one_bit);
      } 
      else { // (1 << bitnum);
        mask_right |= ((byte)shifted_one_bit);
      }
      
    } // the 2 bits were different
  } // for each of the 8 bits
  
// set upper relays
  PCFexpanderWrite(pcf_b, mask_right);
  PCFexpanderWrite(pcf_a, 0x00);
  resetPCF(pcf_a, pcf_b);
// set lower relays
  PCFexpanderWrite(pcf_a, mask_left);
  PCFexpanderWrite(pcf_b, 0x00);
  resetPCF(pcf_a, pcf_b);
}


void resetPCF(byte pcf_a, byte pcf_b)
{
  // let them settle before we unlatch them
  delayMicroseconds(3700);
  // do the unlatch (relax) stuff
  // left side of relay coil
  PCFexpanderWrite(pcf_a, B00000000);
  // right side of relay coil
  PCFexpanderWrite(pcf_b, B00000000);
  // let the relay hold for a while
  delayMicroseconds(3700);
}


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
        // Power toggle
        powerState = !powerState;  
        powerCycled = 0;
      }  
      if (powerState == 1) {
        if (IrReceiver.decodedIRData.command == 0xC) {
          // Volume down
          volIncrement(1,2);
          lcd.clear();
          lcd.setCursor(7,0);
          lcd.print(volLevel); 
        }      
        if (IrReceiver.decodedIRData.command == 0xA) {
          // Volume up
          volIncrement(2,2);
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
  if (reading != lastPowerButton) {
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
  lastPowerButton = reading; 
}


void init(bool _type ) 
{ // 0=cold boot 1=warm boot
  if (_type == 0){
    // RS-232
    Serial.begin(9600);
    // IR
    IrReceiver.begin(IRpin);
    // 16x2 display (calls Wire.begin)
    lcd.begin(16,2); 
  }
  // Clear display
  lcd.clear();
  // Set I/O expander to all lows
  resetPCF(volSetAddr,volResetAddr);
}



void setup()
{
init(0);
delay(100);
}


void loop()
{
  setPowerState();
  irCodeScan = 1;
  irReceive(); 
  if (powerCycled == 0){  
    init(1);
    if (powerState == 1){
      // runs once on boot
      lcd.setCursor(6,0);
      lcd.print("Power On"); 
      volUpdate(volLevel, 1);
    } else {  
      // runs once on shutdown
      volUpdate(0, 0);  
      lcd.clear;
      lcd.setCursor(6,0);
      lcd.print("Power Off"); 
      delay(2500);
      lcd.clear();
      lcd.setCursor(4,0);
      lcd.print("Preamp v1.0"); 
      lcd.setCursor(0,1);
      lcd.print("Ben Provenzano III"); 
    }  
    powerCycled = 1;  
  }  
}
