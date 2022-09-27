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

// Motor Pot
#define MOTOR_INIT    1
#define MOTOR_SETTLED   2 // motor pot is at resting state
#define MOTOR_IN_MOTION   3 // motor pot is moving right now
#define MOTOR_COASTING    4 // motor pot just passed its
#define SENSED_ANALOG_POT_INPUT_PIN 1
#define NATIVE_VOL_RATE    1 
#define POT_CHANGE_THRESH 3
#define POT_REREADS   10 
#define MOTOR_POT_ROTATE_CW             16      // motor pot control
#define MOTOR_POT_ROTATE_CCW            17  // motor pot control
#define ANALOG_POT_MIN_RANGE 0
#define ANALOG_POT_MAX_RANGE 63
#define ANALOG_POT_MAX_RANGE 1023
byte volSpan = 1;
int    potValueLast;  // range from 0..1023
byte   volPotLast;
byte   last_volume; 
byte   potState;

// Power
#define powerPin 5
bool powerState = 0;
bool powerCycled = 0;
byte powerButton = 0;
byte lastPowerButton = 0;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50; 


long l_map(long x, long in_min, long in_max, long out_min, long out_max)
{
  return (x - in_min) * (out_max - out_min + 1) /
         (in_max - in_min + 1) + out_min;
} 

int
read_analog_pot_with_smoothing(byte analog_port_num, byte reread_count)
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


// read the pot, translate its native range to our (min..max) range
// and clip to keep any stray values in that range.
int
read_pot_volume_value_with_clipping(int sensed_pot_value)
{
  int temp_volume;

  temp_volume = l_map(sensed_pot_value,
      0, // ANALOG_POT_MIN_RANGE,
      ANALOG_POT_MAX_RANGE,
      volMin, volMax);
    
  return temp_volume;
}

void
handle_analog_pot_value_changes(void)
{
  byte  old_vol;
  byte  temp_volume;
  int sensed_pot_value;

  sensed_pot_value = read_analog_pot_with_smoothing(
    SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
  );  // to smooth it out

  if (abs(sensed_pot_value - potValueLast) > POT_CHANGE_THRESH) {
    // 1-5 is a good value to ignore noise

    /*
     * get the pot raw value into our correct volume min..max range
     */
    old_vol = volLevel; // the setting *just* before the
          // user touched the pot
    temp_volume = read_pot_volume_value_with_clipping(
      sensed_pot_value
    );
    if (temp_volume == old_vol) {
      // don't update the display (or anything) if
      // there was no *effective* change
      return;
    }

    /*
     * if we are at this point, there was a real change and
     * the vol engine needs to be triggered.  we also should
     * restore backlight just as if the user had pressed a
     * vol-change IR key.
     */
//    lcd.restore_backlight();

    volLevel = temp_volume;
    if (temp_volume > old_vol) {
      // are we in mute-mode right now?  if going from mute
      // to 'arrow-up' we should do a slow ramp-up first
      if (volMute == 1) {
        // tell the system we are officially
        // out of mute mode, now
        volMute = 0;
        volUpdate(volLevel, 1);
      }
      else {
        // not in mute mode, handle the volume
        // increase normally.
        // this also sets the volume but also the
        // graph and db display
        volUpdate(temp_volume, 0);
      }
    }
    else {
      // not a volume increase but a decrease
      // this also sets the volume but also the graph
      // and db display
      volUpdate(temp_volume, 0);
    }

    /*
     * since this registered a real change, we save the
     * timestamp and value in our state variables
     */
    volPotLast = volLevel;
    potValueLast = sensed_pot_value;
  }
}


// logic on this routine is simple: the only time the pot is allowed
// to be read is when we consider the motor to be stopped (or 'settled').
void
analog_sensed_pot_logic(void)
{
  if (powerState == 1) {
      // admin status is 0 for 'no motor in action, now'.
      // only read the pot IF it's not in motion 'by us'
      if (potState == MOTOR_SETTLED ||
          potState == MOTOR_INIT) {
        handle_analog_pot_value_changes();
      }
  } // power was not off
}


void
motor_pid(void)
{
  int target_pot_wiper_value;
  int admin_sensed_pot_value;

  // given the 'IR' set volume level, find out what wiper value
  // we should be comparing with
  target_pot_wiper_value = l_map(volLevel, volMin, volMax,
          ANALOG_POT_MIN_RANGE,
          ANALOG_POT_MAX_RANGE);
  
  // this is the oper value of the pot, from the a/d converter
  admin_sensed_pot_value = read_analog_pot_with_smoothing(
    SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
  );
  
  if (abs(target_pot_wiper_value - admin_sensed_pot_value) <= 8) {
    // stop the motor!
    digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);  // stop turning left
    digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);  // stop turning right
    potState = MOTOR_COASTING;
    delay(5);  // 5ms
    return;
  }
  else {
    /*
     * not at target volume yet
     */

    if (admin_sensed_pot_value < target_pot_wiper_value) {
      // turn clockwise

      // stop turning left
      digitalWrite(MOTOR_POT_ROTATE_CCW, LOW);
      // start turning right
      digitalWrite(MOTOR_POT_ROTATE_CW,  HIGH);
    }
    else if (admin_sensed_pot_value > target_pot_wiper_value) {
      // turn counter-clockwise

      // stop turning right
      digitalWrite(MOTOR_POT_ROTATE_CW,  LOW);
      // start turning left
      digitalWrite(MOTOR_POT_ROTATE_CCW, HIGH);
    }
  }
} 


// a state-driven dispatcher
void
motor_pot_logic(void)
{
  int   admin_sensed_pot_value = 0;
  static int  motor_stabilized;

  /*
   * simple PID control for motor pot
   */

  // If max_vol == min_vol then don't run the motor
  if (volSpan == 0)
    return;

#if 0
  if (volMute == 1)
    return; // don't spin the motor if the user
      // just went down to MUTE
#endif

  switch (potState) {
  case MOTOR_INIT:
    /*
     * initial state, just go to 'settled' from here
     */
    potState = MOTOR_SETTLED;
    volPotLast = volLevel;
    break;

  case MOTOR_SETTLED:
    /*
     * if we are 'settled' and the pot wiper changed,
     * it was via a human.  this doesn't affect our
     * motor-driven logic.
     */
    // if the volume changed via the user's IR, this should
    // trigger us to move to the next state
    if (volLevel != volPotLast) {
      potState = MOTOR_IN_MOTION;
      potValueLast = read_analog_pot_with_smoothing(
        SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
      );
    }

    volPotLast = volLevel;
    break;

  case MOTOR_IN_MOTION:
    /*
     * if the motor is moving, we are looking for our target
     * so we can let go of the motor and let it 'coast' to a stop
     */
  //  lcd.restore_backlight();

    motor_stabilized = 0;
    motor_pid();
    break;

  case MOTOR_COASTING:
    /*
     * we are waiting for the motor to stop
     * (which means the last value == this value)
     */
  //  lcd.restore_backlight();
    delay(20);
    admin_sensed_pot_value = read_analog_pot_with_smoothing(
      SENSED_ANALOG_POT_INPUT_PIN, POT_REREADS
    );
    if (admin_sensed_pot_value == potValueLast) {
      if (++motor_stabilized >= 5) {
        // yay! we reached our target
        potState = MOTOR_SETTLED;
      }
    }
    else {
      // we found a value that didn't match,
      // so reset our 'sameness' counter
      motor_stabilized = 0;
    }

    // this is the operating value of the pot,
    // from the a/d converter
    potValueLast = admin_sensed_pot_value;
    break;

  default:
    break;
  }
}


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
  // power state actions  
  if (powerCycled == 0){  
    init(1);
    if (powerState == 1){
      // runs once on boot
      lcd.setCursor(6,0);
      lcd.print("Power On");
      potState = MOTOR_INIT;
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


void init(bool _type ) 
{ // 0=cold boot 1=warm boot
  if (_type == 0){
    // RS-232
    Serial.begin(9600);
    // IR
    IrReceiver.begin(IRpin);
    // 16x2 display (calls Wire.begin)
    lcd.begin(16,2); 
    // Pot
    pinMode(16, OUTPUT);
    pinMode(17, OUTPUT);
    digitalWrite(16, LOW);
    digitalWrite(17, LOW);
    pinMode(1, INPUT);
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
  irCodeScan = 1;
  irReceive();
  analog_sensed_pot_logic();
  motor_pot_logic();
  setPowerState();
}
