# 1 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
// Preamp Controller v1.0 
// by Ben Provenzano III
// 09/28/2022

// Libraries //
# 7 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino" 2
# 8 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino" 2
# 9 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino" 2
# 10 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino" 2


// I2C (0x3E) Volume Reset
// I2C (0x3F) Volume Set
// I2C (0x27) Display / Power Button




// 16x2 Display
LiquidCrystal_I2C lcd(0x27);

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




byte volLastLevel = 0;
byte volLevel = 0;
byte volMin = 0;
bool volMute;

// Motor Pot
# 57 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
byte volSpan = 1;
int potValueLast; // range from 0..1023
byte volPotLast;
byte last_volume;
byte potState;

// Power

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
      1023,
      volMin, volMax);

  return temp_volume;
}

void
handle_analog_pot_value_changes(void)
{
  byte old_vol;
  byte temp_volume;
  int sensed_pot_value;

  sensed_pot_value = read_analog_pot_with_smoothing(
    1, 10
  ); // to smooth it out

  if (((sensed_pot_value - potValueLast)>0?(sensed_pot_value - potValueLast):-(sensed_pot_value - potValueLast)) > 3) {
    // 1-5 is a good value to ignore noise

    /*

     * get the pot raw value into our correct volume min..max range

     */
# 129 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
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
# 146 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
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
# 177 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
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
      if (potState == 2 /* motor pot is at resting state*/ ||
          potState == 1) {
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
          0,
          1023);

  // this is the oper value of the pot, from the a/d converter
  admin_sensed_pot_value = read_analog_pot_with_smoothing(
    1, 10
  );

  if (((target_pot_wiper_value - admin_sensed_pot_value)>0?(target_pot_wiper_value - admin_sensed_pot_value):-(target_pot_wiper_value - admin_sensed_pot_value)) <= 8) {
    // stop the motor!
    digitalWrite(17 /* motor pot control*/, 0x0); // stop turning left
    digitalWrite(16 /* motor pot control*/, 0x0); // stop turning right
    potState = 4 /* motor pot just passed its*/;
    delay(5); // 5ms
    return;
  }
  else {
    /*

     * not at target volume yet

     */
# 229 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
    if (admin_sensed_pot_value < target_pot_wiper_value) {
      // turn clockwise

      // stop turning left
      digitalWrite(17 /* motor pot control*/, 0x0);
      // start turning right
      digitalWrite(16 /* motor pot control*/, 0x1);
    }
    else if (admin_sensed_pot_value > target_pot_wiper_value) {
      // turn counter-clockwise

      // stop turning right
      digitalWrite(16 /* motor pot control*/, 0x0);
      // start turning left
      digitalWrite(17 /* motor pot control*/, 0x1);
    }
  }
}


// a state-driven dispatcher
void
motor_pot_logic(void)
{
  int admin_sensed_pot_value = 0;
  static int motor_stabilized;

  /*

   * simple PID control for motor pot

   */
# 260 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
  // If max_vol == min_vol then don't run the motor
  if (volSpan == 0)
    return;







  switch (potState) {
  case 1:
    /*

     * initial state, just go to 'settled' from here

     */
# 275 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
    potState = 2 /* motor pot is at resting state*/;
    volPotLast = volLevel;
    break;

  case 2 /* motor pot is at resting state*/:
    /*

     * if we are 'settled' and the pot wiper changed,

     * it was via a human.  this doesn't affect our

     * motor-driven logic.

     */
# 285 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
    // if the volume changed via the user's IR, this should
    // trigger us to move to the next state
    if (volLevel != volPotLast) {
      potState = 3 /* motor pot is moving right now*/;
      potValueLast = read_analog_pot_with_smoothing(
        1, 10
      );
    }

    volPotLast = volLevel;
    break;

  case 3 /* motor pot is moving right now*/:
    /*

     * if the motor is moving, we are looking for our target

     * so we can let go of the motor and let it 'coast' to a stop

     */
# 302 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
  //  lcd.restore_backlight();

    motor_stabilized = 0;
    motor_pid();
    break;

  case 4 /* motor pot just passed its*/:
    /*

     * we are waiting for the motor to stop

     * (which means the last value == this value)

     */
# 313 "Z:\\ProOS\\pve\\automate\\build\\Preamp\\Preamp.ino"
  //  lcd.restore_backlight();
    delay(20);
    admin_sensed_pot_value = read_analog_pot_with_smoothing(
      1, 10
    );
    if (admin_sensed_pot_value == potValueLast) {
      if (++motor_stabilized >= 5) {
        // yay! we reached our target
        potState = 2 /* motor pot is at resting state*/;
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
  if (dir_flag == 2) {
    if (volLevel >= volMax)
      return;
  }
  else if (dir_flag == 1) {
    if (volLevel <= volMin)
      return;
  }
  if (volMute == 1 && dir_flag == 2) {
    volMute = 0;
   // !! add restore display volume (unmute)
  }
  if (dir_flag == 2) {
    if (speed_flag == 1) {
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
    else if (speed_flag == 2) {
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
  else if (dir_flag == 1) {
    if (speed_flag == 1) {
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
    else if (speed_flag == 2) {
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
   setRelays(0x3F, 0x3E, _vol, volRelayCount, _force);
   volLastLevel = volLevel;
}


// Set a relay controller board (volume or inputs)
void setRelays(byte pcf_a, byte pcf_b, // first pair of i2c addr's
      byte vol_byte, // the 0..255 value to write
      byte installed_relay_count, // how many bits are installed
      byte forced_update_flag) // forced or relative mode (1=forced)
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
  PCFexpanderWrite(pcf_a, 0);
  // right side of relay coil
  PCFexpanderWrite(pcf_b, 0);
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
  int reading = lcd.readPin(5);
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
      potState = 1;
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
    pinMode(16, 0x1);
    pinMode(17, 0x1);
    digitalWrite(16, 0x0);
    digitalWrite(17, 0x0);
    pinMode(1, 0x0);
  }
  // Clear display
  lcd.clear();
  // Set I/O expander to all lows
  resetPCF(0x3F,0x3E);
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
