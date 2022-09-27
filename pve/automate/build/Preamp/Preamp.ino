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
#define volControlDown 1
#define volControlUp 2
#define volControlSlow 1 
#define volControlFast 2
bool volMute;
byte volLevel = 0;
byte volLastLevel = 0;
byte volCoarseSteps = 4;
byte volRelayCount = 6;
byte volMax = 63;
byte volMin = 0;


// Motor Pot
#define motorInit 1
#define motorSettled 2  // motor pot is at resting state
#define motorInMotion 3 // motor pot is moving right now
#define motorCoasting 4 // motor pot just passed its
#define potThreshold 3
#define potRereads 10 
#define potAnalogPin 1
#define motorPinCW 16 
#define motorPinCCW 17 
#define potMinRange 0
#define potMaxRange 1023
int potValueLast;    // range from 0..1023
byte volPotLast;
byte potState;

// Power
#define powerPin 5
bool powerState = 0;
bool powerCycled = 0;
byte powerButton = 0;
byte lastPowerButton = 0;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50; 



// mapping function
long l_map(long x, long in_min, long in_max, long out_min, long out_max)
{
  return (x - in_min) * (out_max - out_min + 1) /
         (in_max - in_min + 1) + out_min;
} 


// read the pot, smooth out the data
int readPotWithSmoothing(byte analog_port_num, byte reread_count)
{
  int sensed_port_value = 0;
  for (byte i = 0; i < reread_count; i++) {
    sensed_port_value += analogRead(analog_port_num);
    // delayMicroseconds(200);
  }
  if (reread_count > 1) {
    sensed_port_value /= reread_count;
  }
  return sensed_port_value;
}


// read the pot, and clip to keep any stray values in that range
int readPotWithClipping(int sensed_pot_value)
{
  int temp_volume;

  temp_volume = l_map(sensed_pot_value,
      0, // potMinRange,
      potMaxRange,
      volMin, volMax);
    
  return temp_volume;
}


// runs when pot state changes
void potValueChanges(void)
{
  byte old_vol;
  byte temp_volume;
  int sensed_pot_value;
  // read pot smoothed output
  sensed_pot_value = readPotWithSmoothing(
    potAnalogPin, potRereads
  );  // to smooth it out
  // read an average pot value
  if (abs(sensed_pot_value - potValueLast) > potThreshold) {
    // 1-5 is a good value to ignore noise
    // convert the pot raw value into our correct volume min..max range
    old_vol = volLevel; // the setting before user touched the pot
    // read pot clipped output
    temp_volume = readPotWithClipping(
      sensed_pot_value
    );
    if (temp_volume == old_vol) {
      // don't update if there was no effective change
      return;
    }
    //    lcd.restore_backlight();
    // volume state changed    
    volLevel = temp_volume;
    if (temp_volume > old_vol) {
      if (volMute == 1) {
        // tell the system we out of mute mode
        volMute = 0;
        volUpdate(volLevel, 1);
      }
      else {
        // not in mute mode, set volume up
        volUpdate(temp_volume, 0);
      }
    }
    else {
      // not in mute mode, set volume down
      volUpdate(temp_volume, 0);
    }
    // real change, save the changed state
    volPotLast = volLevel;
    potValueLast = sensed_pot_value;
  }
}


// motor pot PID control loop
void motorControlLoop(void)
{
  int target_pot_wiper_value;
  int pot_pid_value;
  // given the 'IR' set volume level, find out what wiper value to compare
  target_pot_wiper_value = l_map(volLevel, volMin, volMax,
          potMinRange,
          potMaxRange);
  // this is the value of the pot, from the a/d converter
  pot_pid_value = readPotWithSmoothing(
    potAnalogPin, potRereads
  );
  // average out the values
  if (abs(target_pot_wiper_value - pot_pid_value) <= 8) {
    // stop the motor!
    digitalWrite(motorPinCCW, LOW);  // stop turning left
    digitalWrite(motorPinCW,  LOW);  // stop turning right
    potState = motorCoasting;
    delay(5);
    return;
  }
  else {
    // not at target volume yet
    if (pot_pid_value < target_pot_wiper_value) {
      // turn clockwise
      digitalWrite(motorPinCCW, LOW);
      digitalWrite(motorPinCW,  HIGH);
    }
    else if (pot_pid_value > target_pot_wiper_value) {
      // turn counter-clockwise
      digitalWrite(motorPinCW,  LOW);
      digitalWrite(motorPinCCW, HIGH);
    }
  }
} 


// motor pot state-driven dispatcher
void motorPot(void)
{
  // PID control loop for motor pot
  int pot_pid_value = 0;
  static int motor_stabilized;
// action states
#if 0
  if (volMute == 1)
    return; // don't spin the motor just muted
#endif
// action states
  switch (potState) {
  case motorInit:
    // initial state, just go to 'settled' from here
    potState = motorSettled;
    volPotLast = volLevel;
    break;
//---------------//
  case motorSettled:
    /*
     * if we are 'settled' and the pot wiper changed,
     * it was via a human.  this doesn't affect our
     * motor-driven logic.
     */
    // if the volume changed via the user's IR, this should
    // trigger us to move to the next state
    if (volLevel != volPotLast) {
      potState = motorInMotion;
      potValueLast = readPotWithSmoothing(
        potAnalogPin, potRereads
      );
    }

    volPotLast = volLevel;
    break;
//---------------//
  case motorInMotion:
    /*
     * if the motor is moving, we are looking for our target
     * so we can let go of the motor and let it 'coast' to a stop
     */
    //  lcd.restore_backlight();
    motor_stabilized = 0;
    motorControlLoop();
    break;
//---------------//
  case motorCoasting:
    /*
     * we are waiting for the motor to stop
     * (which means the last value == this value)
     */
  //  lcd.restore_backlight();
    delay(20);
    pot_pid_value = readPotWithSmoothing(
      potAnalogPin, potRereads
    );
    if (pot_pid_value == potValueLast) {
      if (++motor_stabilized >= 5) {
        // yay! we reached our target
        potState = motorSettled;
      }
    }
    else {
      // we found a value that didn't match,
      // so reset our 'sameness' counter
      motor_stabilized = 0;
    }
//---------------//
    // this is the operating value of the pot,
    // from the a/d converter
    potValueLast = pot_pid_value;
    break;
//
  default:
    break;
  }
}


// increment volume up/down slow/fast
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


// set a specific volume level
void volUpdate (byte _vol, byte _force) 
{
   setRelays(volSetAddr, volResetAddr, _vol, volRelayCount, _force);  
   volLastLevel = volLevel;
}


// set a relay controller board (volume or inputs)
void setRelays(byte pcf_a, byte pcf_b,  // first pair of i2c addr's
      byte vol_byte,                    // the 0..255 value to write
      byte installed_relay_count,    // how many bits are installed
      byte forced_update_flag)  // forced or relative mode (1=forced)
{
  int bitnum;
  byte mask_left;
  byte mask_right;
  byte just_the_current_bit;
  byte just_the_previous_bit;
  byte shifted_one_bit;
  // this must to be able to underflow to *negative* numbers
  // walk the bits and just count the bit-changes and save into left and right masks
  mask_left = mask_right = 0;
  //
  // this loop walks ALL bits, even the 'mute bit'
  for (bitnum = (installed_relay_count-1); bitnum >= 0 ; bitnum--) {
    //
    // optimize: calc this ONLY once per loop
    shifted_one_bit = (1 << bitnum);
    //
    // this is the new volume value; and just the bit we are walking
    just_the_current_bit = (vol_byte & shifted_one_bit);
    //
    // logical AND to extra just the bit we are interested in
    just_the_previous_bit = (volLastLevel & shifted_one_bit);
    //
    // examine our current bit and see if it changed from the last run
    if (just_the_previous_bit != just_the_current_bit ||
        forced_update_flag == 1) {
      //	
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


// reset all pins PCF8574A I/O expander
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


// read a byte from PCF8574A I/O expander
byte PCFexpanderRead(int address) 
{
 byte _data;
 Wire.requestFrom(address, 1);
 if(Wire.available()) {
   _data = Wire.read();
 }
 return _data;
}


// write a byte to PCF8574A I/O expander
void PCFexpanderWrite(byte address, byte _data ) 
{
 Wire.beginTransmission(address);
 Wire.write(_data);
 Wire.endTransmission(); 
}


// receive IR remote commands 
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


// power on/off
void setPowerState() {
  // read pin state from MCP23008
  int reading = lcd.readPin(powerPin);
  // if switch changed
  if (reading != lastPowerButton) {
    // reset the debouncing timer
    lastDebounceTime = millis();
  }
  if ((millis() - lastDebounceTime) > debounceDelay) {
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
  // power state actions  
  if (powerCycled == 0){  
    init(1);
    if (powerState == 1){
      // runs once on boot
      lcd.setCursor(6,0);
      lcd.print("Power On");
      potState = motorInit;
      volUpdate(volLevel, 1);
    } else {  
      // runs once on shutdown
      volUpdate(0,0);  
      lcd.clear();
      lcd.setCursor(6,0);
      lcd.print("Power Off"); 
      delay(500);
      lcd.clear();
      lcd.setCursor(4,0);
      lcd.print("Preamp v1.0"); 
      lcd.setCursor(0,1);
      lcd.print("Ben Provenzano III"); 
    }  
    powerCycled = 1;  
  }  
}


// initialization
void init(bool _type ) 
{ // 0=cold 1=warm boot
  if (_type == 0){
    // IR remote
    IrReceiver.begin(IRpin);
    // 16x2 display (calls Wire.begin)
    lcd.begin(16,2); 
    // Motor pot
    pinMode(potAnalogPin, INPUT);   
    pinMode(motorPinCW, OUTPUT);
    pinMode(motorPinCCW, OUTPUT);
    digitalWrite(motorPinCW, LOW);
    digitalWrite(motorPinCCW, LOW);
    // IR codes over serial
    irCodeScan = 1;
    // Serial support
    if (irCodeScan == 1){
      Serial.begin(9600);
    }
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


// superloop
void loop()
{
  // IR remote
  irReceive();
  // motor potentiometer 
  if (powerState == 1) {
    if (potState == motorSettled ||
        potState == motorInit) {
    potValueChanges();
    }
  } 
  motorPot();
  // power management
  setPowerState();
}
