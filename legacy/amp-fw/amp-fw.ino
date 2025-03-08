 /////////////////////////////////////////////////////////////////////////
// Integrated Amp Controller v1.3
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

// shared libraries
#include <Wire.h>
#include <Encoder.h>

// local libraries
#include "neotimer.h"

// serial resources
#define serialBaudRate 9600
const uint8_t maxMessage = 32;
char serialMessage[maxMessage];
uint8_t serialMessageEnd = 0;
bool newData = 0;

// GPIO pins
#define ampPowerPin            12
#define inputBtnPin            7
#define inputIRPin             6
#define powerBtnPin            5
#define muteBtnPin             4
#define inputEncPinA           3
#define inputEncPinB           2

// common resources
bool powerState = 0;
bool powerCycle = 0;
uint8_t debounceDelay = 75;

// power control resources
bool runPowerAction = 0;
uint8_t lastPowerButton = 1;
uint8_t powerButton = 0;
uint32_t powerButtonMillis;

// input control resources
uint8_t selectedInput = 0;
uint8_t lastInput = 0;
uint8_t lastInputButton = 1;
uint8_t inputButton = 0;
uint32_t inputButtonMillis;

// front panel LED resources
Neotimer frntLEDTimer = Neotimer();
uint32_t frntLEDSpeed = 0;
uint16_t frontLEDCycles = 0;
bool frntLEDKeepBlink = 0;
bool frntLEDState = 0;
bool blinkLEDdone = 0;

// MCP23008 resources
#define analogRelayPin         0     // Aux-In Relay (active-high) 
#define trigger1Pin            1     // Trigger R (active-low) 
#define trigger2Pin            2     // Trigger L (active-low)
#define powerLEDPin            3     // Power LED (active-high) 
#define digitalS0Pin           5     // 74HC4052 (S0)
#define digitalS1Pin           6     // 74HC4052 (S1) 
#define muteLockPin            7     // Mute Lock (active-high)
uint8_t mcpState = 0x0;
#define MCP23_ADDR             0x27  //  MCP's I2C address
#define MCP23_DDR_A            0x00  //  data direction register A
#define MCP23_POL_A            0x01  //  input polarity A
#define MCP23_IOCR             0x05  //  IO control register
#define MCP23_PUR_A            0x06  //  pull-up resistors A
#define MCP23_GPIO_A           0x09  //  general purpose IO A
#define MCP23_IOCR_OUT         0x00  //  sets all pins as outputs
#define MCP23_IOCR_SEQOP       0x20  //  sequential operation mode bit.
#define MCP23_IOCR_DISSLW      0x10  //  slew rate control bit for SDA output.
#define MCP23_IOCR_ODR         0x04  //  sets the INT pin as an open-drain output.
#define MCP23_IOCR_INTPOL      0x02  //  polarity of the INT output pin.

// PGA2311 resources
#define volumeClockPin         9     // clock pin for volume control
#define volumeDataPin          8     // data pin for volume control
#define volumeSelectPin        10    // select pin for volume control
#define volumeMutePin          11    // mute pin for the volume control  
#define maxVolume              192   // maximum PGA volume (192 is 0 dB -- no gain)
#define minVolume              4

// volume control resources
uint8_t lastChannelVolume = 0;
uint8_t channelVolume = 0;
bool isMuted = 0;
uint8_t lastMuteButton = 1;
uint8_t muteButton = 0;
uint32_t muteButtonMillis;
// volume encoder resources
Encoder volumeEncoder(inputEncPinB, inputEncPinA);
uint16_t oldVolEncPos = 1;

/// initialization ///
void setup() {
  // GPO initialization
  pinMode(LED_BUILTIN, OUTPUT);  
  digitalWrite(LED_BUILTIN, HIGH);
  pinMode(ampPowerPin, OUTPUT);
  digitalWrite(ampPowerPin, LOW); 
  // GPI initialization
  pinMode(powerBtnPin, INPUT);
  pinMode(muteBtnPin, INPUT);
  pinMode(inputBtnPin, INPUT);
  // PGA volume logic
  pinMode(volumeMutePin, OUTPUT);
  digitalWrite(volumeMutePin, HIGH);           
  pinMode(volumeSelectPin, OUTPUT);
  pinMode(volumeClockPin, OUTPUT);
  pinMode(volumeDataPin, OUTPUT);
  digitalWrite(volumeSelectPin, HIGH);
  digitalWrite(volumeClockPin, HIGH);
  digitalWrite(volumeDataPin, HIGH);  
  // MCP23008 initialization
  Wire.begin();
  Wire.beginTransmission(MCP23_ADDR);
  Wire.write(MCP23_DDR_A);
  Wire.write(MCP23_IOCR_OUT);
  Wire.endTransmission();
  // set trigger pin states
  writeMCP(trigger1Pin, HIGH);
  writeMCP(trigger2Pin, HIGH);
  // PGA initialization
  delay(250);
  setVolume(0);
  delay(800);
  // set default volume
  channelVolume = 120;
  lastChannelVolume = channelVolume;
  // set default audio input
  selectedInput = 2; // optical #2
  lastInput = selectedInput;
  // start serial ports
  Serial.begin(serialBaudRate);
  delay(800);
  digitalWrite(LED_BUILTIN, LOW);
}

void writeMCP(uint8_t outputPin, bool pinState) {
  if (outputPin > 7) {
    return;
  }
  bitWrite(mcpState, outputPin, pinState);
  Wire.beginTransmission(MCP23_ADDR);
  Wire.write(MCP23_GPIO_A);
  Wire.write(mcpState);
  Wire.endTransmission();
}

void volWriteByte(uint8_t byteOut) {
  for (uint8_t i=0; i<8; i++) {
    digitalWrite(volumeClockPin, LOW);
    if (0x80 & byteOut) {
      digitalWrite(volumeDataPin, HIGH);
    } else {
      digitalWrite(volumeDataPin, LOW);
    } 
    digitalWrite(volumeClockPin, HIGH);
    digitalWrite(volumeClockPin, LOW);
    byteOut<<=1;
  }
}
 
/* set PGA2311's volume */
void setVolume(long _intvol){
   uint8_t _vol = 0;
   if (_intvol > 255) {
     _vol = 255;
   }
   else if (_intvol < 0) {
     _vol = 0;
   } else {
     _vol = (uint8_t)_intvol;
   }
   digitalWrite(volumeSelectPin, LOW);   
   volWriteByte(_vol); // Right        
   volWriteByte(_vol); // Left
   digitalWrite(volumeSelectPin, HIGH);    
   digitalWrite(volumeClockPin, HIGH);
   digitalWrite(volumeDataPin, HIGH);
}

void scaleVolume(uint8_t startVolume, uint8_t endVolume, uint8_t volumeSteps){
  uint8_t diff;
  long counter;
  if (endVolume == startVolume) {
    return;
  }
  if (endVolume > startVolume) {
    diff = (endVolume - startVolume) / volumeSteps;
    // Protect against a non-event
    if (diff == 0){
      diff = 1;
    }
    counter = startVolume;
    while (counter < endVolume) {
      setVolume(counter);
      delay(25);  
      counter += diff;  
    }
    setVolume(endVolume);               
  } else {
    diff = (startVolume - endVolume) / volumeSteps;
    // Protect against a non-event
    if (diff == 0) {
      diff = 1;
    }
    counter = startVolume;
    while (counter > endVolume){
      setVolume(counter);
      delay(25);  
      counter -= diff; 
    }
    setVolume(endVolume);              
  }  
  return;
}

void volumeUp(uint8_t _volumeStep) {
  // volume up
  if (isMuted == 0) {
    lastChannelVolume = channelVolume;
    channelVolume = channelVolume + _volumeStep;
    if (channelVolume >= maxVolume) {
      channelVolume = maxVolume;
    }
    scaleVolume(lastChannelVolume,channelVolume,_volumeStep);    
  }
}

void volumeDown(uint8_t _volumeStep) {
  // volume down 
  if (isMuted == 0) {
    lastChannelVolume = channelVolume;
    channelVolume = channelVolume - _volumeStep;
    if (channelVolume <= minVolume) {
      channelVolume = minVolume;
    }
    scaleVolume(lastChannelVolume,channelVolume,_volumeStep);    
  }
}

void volumeMute() {
  // mute toggle
  if (isMuted == 0) {
    // blink LED continously
    setBlinkFrontLED(600,0,1);    
    // mute
    isMuted = 1;
    scaleVolume(channelVolume,0,35);
  } else {
    // disable blinking LED
    disableFntLEDBlink(); 
    // un-mute
    isMuted = 0;
    scaleVolume(0,channelVolume,40);
  }
}

void audioInput(uint8_t _input) {
  lastInput = selectedInput;
  if (_input == 0) {
    // disconnect all inputs
    writeMCP(digitalS1Pin, HIGH);
    writeMCP(digitalS0Pin, HIGH);
    writeMCP(analogRelayPin, LOW);
    writeMCP(muteLockPin, LOW);
  }
  if (_input == 1) {
    // optical #1 input
    writeMCP(digitalS1Pin, LOW);
    writeMCP(digitalS0Pin, HIGH);
    // DAC analog input
    writeMCP(analogRelayPin, LOW);
    // enable DAC mute logic
    writeMCP(muteLockPin, LOW);
  }
  if (_input == 2) {
    // optical #2 input
    writeMCP(digitalS1Pin, HIGH); 
    writeMCP(digitalS0Pin, HIGH);
    // DAC analog input
    writeMCP(analogRelayPin, LOW);
    // enable DAC mute logic
    writeMCP(muteLockPin, LOW);
  }
  if (_input == 3) {
    // coaxial digital input
    writeMCP(digitalS1Pin, HIGH); 
    writeMCP(digitalS0Pin, LOW);  
    // DAC analog input
    writeMCP(analogRelayPin, LOW);
    // enable DAC mute logic
    writeMCP(muteLockPin, LOW);
  }
  if (_input == 4) {
    // aux analog input
    writeMCP(analogRelayPin, HIGH);
    // disable DAC mute logic
    writeMCP(muteLockPin, HIGH);
  }
  selectedInput = _input;
}

  // cycle thru audio inputs
void cycleThruInputs() {
  if (selectedInput != 0) {
    uint8_t _input = selectedInput + 1;
    uint8_t _maxInputRange = 4;
    uint8_t _minInputRange = 1;
    if ((_input > _maxInputRange) || (_input < _minInputRange)) {
      _input = _minInputRange;
    }
    setBlinkFrontLED(300,1,0);
    audioInput(_input);
  }
}

void remoteFunctions(uint8_t _register, uint16_t _ctldata) {
  // process register
  switch (_register) {
  // power select
  case 1:
    // power amplifier on (01001)
    if (_ctldata == 1) {
      powerOn();
    }
    // power amplifier off (01002)
    if (_ctldata == 2) { 
      powerOff();
    }
    // trigger R (01003)
    if (_ctldata == 3) { 
      writeMCP(trigger1Pin, LOW);
      delay(250);
      writeMCP(trigger1Pin, HIGH);
    }
    // trigger L (01004)    
    if (_ctldata == 4) {
      writeMCP(trigger2Pin, LOW);
      delay(250);
      writeMCP(trigger2Pin, HIGH);
    }
    break;
  // input select
  case 2:
    if (powerState == 1) {
      if (isMuted == 0) {
        // optical in #1 (02001) 
        if (_ctldata == 1) {
          setBlinkFrontLED(300,1,0);
          audioInput(1);
        }
        // optical in #2 (02002) 
        if (_ctldata == 2) {
          setBlinkFrontLED(300,1,0);
          audioInput(2);
        }
        // coax input (02003)  
        if (_ctldata == 3) {
          setBlinkFrontLED(300,1,0);
          audioInput(3);
        }
        // aux input (02004) 
        if (_ctldata == 4) {
          setBlinkFrontLED(300,1,0);
          audioInput(4);
        }
      }
    }
    break;
  // volume select
  case 3:
    if (powerState == 1) {
      // mute toggle (03001) 
      if (_ctldata == 1) { 
        volumeMute();
      }
      if (isMuted == 0) {
        // volume up (03002) 
        if (_ctldata == 2) { 
          volumeUp(2);
        }
        // volume down (03003) 
        if (_ctldata == 3) { 
          volumeDown(2);
        }
      }
    }
    break;
  default:
    // blink LED when command invalid
    if (powerState == 1){ 
      setBlinkFrontLED(300,1,0);
    }
    break; 
  }
}

// process serial message
void processMessage(uint8_t messageStart) {
  uint8_t _numcnt = 0;
  const uint8_t cmdLength = 5; // fixed command length
  const uint8_t cmdRegLen = 2; // register select length (99***)
  const uint8_t cmdDataLen = 3; // data length (**999)
  char _cmdarr[cmdLength + 1];
  // extract control code from message
  for(uint8_t _idx = messageStart; _idx < serialMessageEnd; _idx++) {
    char _curchar = serialMessage[_idx];
    if (isDigit(_curchar) && _numcnt < cmdLength) {
      _cmdarr[_numcnt] = _curchar;
      _numcnt++;
    }
  }
  _cmdarr[_numcnt] = '\0';
  // valiate control code length
  if (_numcnt =! (cmdLength - 1)) {
    return;
  }
  // extract register select
  char _regarr[cmdRegLen + 1];
  uint8_t _regidx = 0;
  for(uint8_t _idx = 0; _idx < cmdRegLen; _idx++) {
    _regarr[_regidx] = _cmdarr[_idx];
    _regidx++;
  }
  _regarr[_regidx] = '\0';
  uint8_t _register = atoi(_regarr); 
  // extract control data
  char _datarr[cmdDataLen + 1];
  uint8_t _dataidx = 0;
  for(uint8_t _idx = (cmdDataLen - 1); _idx < cmdLength; _idx++) {
    _datarr[_dataidx] = _cmdarr[_idx];
    _dataidx++;
  }
  _datarr[_dataidx] = '\0';
  uint16_t _ctldata = atoi(_datarr); 
  // process control code
  remoteFunctions(_register, _ctldata);
}

// decode serial message
void decodeMessage() {
  digitalWrite(LED_BUILTIN, HIGH);
  uint8_t _end = serialMessageEnd;
  // count delimiters
  uint8_t _delims = 0;
  uint8_t _maxchars = 10;
  char _delimiter = ',';
  for(uint8_t _idx = 0; _idx < _end; _idx++) {
    char _vchr = serialMessage[_idx];  
    if (_vchr == _delimiter) {
      _delims++;
    }
  } 
  // exit when delimiters incorrect
  if (_delims < 2){ 
    return;
  }
  // find first delimiter position
  uint8_t _linepos = 0;
  for(uint8_t _idx = 0; _idx < _end; _idx++) {  
    char _vchr = serialMessage[_idx];  
    if (_vchr == _delimiter) {
      // store index position
      _linepos = _idx;
      break;
    }
  }
  // loop through line characters 
  char _linebuffer[_maxchars + 1];
  uint8_t _linecount = 0;   
  for(uint8_t _idx = 0; _idx < _linepos; _idx++) {
  	if (_linecount >= _maxchars) {
      break;
    } 
    // store in new array
    _linebuffer[_linecount] = serialMessage[_idx];
    _linecount++;
  } // terminate string
  _linebuffer[_linecount] = '\0';
  // convert to integer, store line value
  uint8_t cmdFirstColumn = atoi(_linebuffer); 
  // find second delimiter position
  uint8_t _count = 0;
  uint8_t _cmd2pos = 0; 
  for(uint8_t _idx = 0; _idx < _end; _idx++) {
    char _vchr = serialMessage[_idx];   
    if (_vchr == _delimiter) {
      if (_count == 1) {
        // store pointer position
        _cmd2pos = _idx;
        break;
      }  
      _count++;
    }
  }
  // process command data
  if (cmdFirstColumn == 0){
    processMessage(_cmd2pos + 1);
  }
  // send ack to computer
  Serial.println("*");
  digitalWrite(LED_BUILTIN, LOW);
}

void readSerial() {
  static bool recvInProgress = 0;
  static uint8_t ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;
  if (Serial.available() > 0 && newData == 0) {
    rc = Serial.read();
    if (recvInProgress == 1) {
      if (rc != endMarker) {
        serialMessage[ndx] = rc;
        ndx++;
        if (ndx >= maxMessage) {
          ndx = maxMessage - 1;
        }
      } else {
        // terminate the string
        serialMessage[ndx] = '\0'; 
        serialMessageEnd = ndx;
        recvInProgress = 0;
        newData = 1;
        ndx = 0;
      }
    }
    else if (rc == startMarker) {
      recvInProgress = 1;
    }
  }
  if (newData == 1) {
    // End-of-data action
    decodeMessage();
    serialMessageEnd = 0;
    newData = 0;
  }
}

// read power button state
void readInputButton() {
  // read pin state
  uint8_t reading = digitalRead(inputBtnPin);
  // switch changed
  if (reading != lastInputButton) {
    // reset the debouncing timer
    inputButtonMillis = millis();
  }
  if ((millis() - inputButtonMillis) > debounceDelay) {
    if (reading != inputButton) {
      inputButton = reading;
      // input button was pressed
      if (inputButton == 0) { 
        cycleThruInputs();
      }
    }
  }
  lastInputButton = reading;
}

// read power button state
void readPowerButton() {
  // read pin state
  uint8_t reading = digitalRead(powerBtnPin);
  // switch changed
  if (reading != lastPowerButton) {
    // reset the debouncing timer
    powerButtonMillis = millis();
  }
  if ((millis() - powerButtonMillis) > debounceDelay) {
    if (reading != powerButton) {
      powerButton = reading;
      // power button was pressed
      if (powerButton == 0) {
        powerState = !powerState; // toggle power state 
        powerCycle = 1; // set power cycle flag
      }
    }
  }
  lastPowerButton = reading;
}

void readMuteButton() {
  // read pin state
  uint8_t reading = digitalRead(muteBtnPin);
  // switch changed
  if (reading != lastMuteButton) {
    // reset the debouncing timer
    muteButtonMillis = millis();
  }
  if ((millis() - muteButtonMillis) > debounceDelay) {
    if (reading != muteButton) {
      muteButton = reading;
      // mute button was pressed
      if (muteButton == 0) { 
        volumeMute();
      }
    }
  }
  lastMuteButton = reading;
}

void readVolumeEncoder() {
  uint8_t volEncPosition = volumeEncoder.read();
  if(volEncPosition != oldVolEncPos){
    if (volEncPosition > oldVolEncPos) {
      volumeUp(1); // volume step
    }
    if (volEncPosition < oldVolEncPos) {
      volumeDown(1); // volume step
    }
    oldVolEncPos = volEncPosition;
  }
}

// read front-panel buttons
void readButtonStates() {
  if (powerState == 1) { // power-on state
    if (isMuted == 0) { // not muted
      readVolumeEncoder();
      readInputButton();
    }
    readMuteButton();
  }
}

// set power states
void powerOff() {
  if (powerState == 1) {
    // turn-off system
    powerCycle = 1;
    powerState = 0;
  }
}
void powerOn() {
  if (powerState == 0) {
    // turn-on system
    powerCycle = 1;
    powerState = 1; 
  }
}

void powerOnLogic() {
  // last set audio input
  audioInput(lastInput);
  // un-mute PGA
  digitalWrite(volumeMutePin,LOW);
  isMuted = 0;
  delay(250);
  // turn power amps on 
  digitalWrite(ampPowerPin, HIGH);   
  delay(150);
  // scale into last set volume
  scaleVolume(0,lastChannelVolume,50);
  // set power LED on
  frntLEDState = 1;
  writeMCP(powerLEDPin, frntLEDState);       
}

void powerOffLogic() {
  // stop any running LED timers
  disableFntLEDBlink();
  // mute system
  if (isMuted == 0) {
    scaleVolume(channelVolume,0,25);
    isMuted = 1;
  } // mute PGA
  digitalWrite(volumeMutePin,HIGH);  
  // disconnect inputs
  audioInput(0);
  delay(250);
  // turn power amps off 
  digitalWrite(ampPowerPin, LOW); 
  delay(150);
  // set power LED off
  frntLEDState = 0;
  writeMCP(powerLEDPin, frntLEDState);  
}

void afterBlinkActions() {
  // action after blinking done
  if (blinkLEDdone == 1) {
    blinkLEDdone = 0;
    // power state change actions
    if (runPowerAction == 1) {
      runPowerAction = 0;
      /// startup logic ///
      if (powerState == 1) {         
        powerOnLogic(); 
      }  
      /// shutdown logic ///      
      if (powerState == 0) {
        powerOffLogic();
      }
    }
  }
}

void restartFrontLED() {
  // re-start timer
  frntLEDTimer.set(frntLEDSpeed);
  frntLEDTimer.start();
}

void blinkFrontLED() {
  if (frntLEDTimer.done()) {
    // blink front-panel LED
    frntLEDState = !frntLEDState;    
    writeMCP(powerLEDPin, frntLEDState);
    if (frntLEDKeepBlink == 1) {
      // continous blinkmode
      restartFrontLED();
    } else {
      // x # of cycles mode
      if (frontLEDCycles == 0) {
        // reset & stop timer
        frntLEDTimer.stop();
        frntLEDTimer.reset();
        frntLEDSpeed = 0;
        // trigger after blink actions     
        blinkLEDdone = 1;
      } else {
        // countdown cycles
        restartFrontLED();
        frontLEDCycles--; 
      }
    }
  }
}

void disableFntLEDBlink() {
  // reset & stop timer
  frntLEDTimer.stop();
  frntLEDTimer.reset();
  // disable continous blinking
  frntLEDKeepBlink = 0;
  // re-enable power LED
  frntLEDState = 1;
  writeMCP(powerLEDPin, frntLEDState);
}

void setBlinkFrontLED(uint32_t _speed, uint32_t _cycles, bool _continous) {
  // _speed = delay (ms)
  // _cycles = # of blinks
  // * (even # LED stays on, odd # LED stays off)
  disableFntLEDBlink(); // reset LED timer
  if (_continous == 1) {
    frontLEDCycles = 1;
    frntLEDKeepBlink = 1;
  } else {
    frontLEDCycles = _cycles;
    frntLEDKeepBlink = 0;
  }
  frntLEDSpeed = _speed;
  frntLEDTimer.set(_speed);
  frntLEDTimer.start();
}

void setPowerState() {
  // power state changed actions  
  if (powerCycle == 1){
    powerCycle = 0;
    if (powerState == 1) {   
      // startup LED blinks
      setBlinkFrontLED(250,7,0);
    } else {       
      // shutdown LED blinks
      setBlinkFrontLED(250,5,0);
    }
    // run after blink actions
    runPowerAction = 1;
  }
}

void loop() {
  // read serial port data
  readSerial();  
  // read front-panel buttons
  readButtonStates();
  // read power button
  readPowerButton();
  // manage power state
  setPowerState();  
  // blink front-panel LED
  blinkFrontLED();
  // action after LED blinking
  afterBlinkActions();
}
