/*
 * Ben Provenzano III
 * -----------------
 * v2.8 07/06/2025
 * Serial Automation Accessory Controller
 *
 */

// shared libraries
#include <SoftwareSerial.h>

// local libraries
#include "neotimer.h"

// general constants
const uint8_t debounceDelay = 75;
const char nullTrm = '\0';

// power control I/O
#define PWR_TRIG_1 9 // trigger #1 TIP
#define PWR_SENS_1 2 // sense #1 RING
#define PWR_TRIG_2 8 // trigger #2 TIP
#define PWR_SENS_2 3 // sense #2 RING
#define PWR_TRIG_3 7 // trigger #3 TIP
#define PWR_SENS_3 4 // sense #3 RING

// analog inputs
#define ADC_IN_1 A0 // TIP
#define ADC_IN_2 A1 // RING

// toggle switch inputs
#define PWR_SWITCH_2 6 // TIP
#define PWR_SWITCH_1 5 // RING
bool powerButton_1Last = 0;
bool powerButton_1State = 0;
uint32_t powerButton_1Millis;
bool powerButton_2Last = 0;
bool powerButton_2State = 0;
uint32_t powerButton_2Millis;

// serial resources
#define serialBaudRate 9600
#define TX_PIN 11 // 232-TX TIP
#define RX_PIN 10 // 232-RX RING
SoftwareSerial ExtSerial(RX_PIN, TX_PIN); 
const uint8_t maxMessage = 32;
const uint8_t cmdRegLen = 2; // register length (99***)
const uint8_t cmdDatLen = 3; // data length (**999)
const char serialDataStart = '<';
const char serialDataEnd = '>';
const char respDelimiter = '|';
char serialMessageOut[maxMessage + 1];
char serialMessageIn[maxMessage + 1];
bool serialFwrdMode = 0;
bool serialReading = 0;
uint16_t serialCurPos = 0;
bool serialMsgEnd = 0;
const uint8_t maxFwrdWait = 650; // max wait in (ms) for external serial response
Neotimer maxFwrdRead = Neotimer();

void setup() {
  initGPIO();
  initSerial();
}

void initSerial() {
  Serial.begin(serialBaudRate);
  ExtSerial.begin(serialBaudRate);
  serialMessageIn[0] = nullTrm;
  serialMessageOut[0] = nullTrm;
}

void initGPIO() {
  // activity LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  // I/O port #1
  pinMode(PWR_TRIG_1, OUTPUT);
  digitalWrite(PWR_TRIG_1, LOW);
  pinMode(PWR_SENS_1, INPUT_PULLUP);
  // I/O port #2
  pinMode(PWR_TRIG_2, OUTPUT);
  digitalWrite(PWR_TRIG_2, LOW);
  pinMode(PWR_SENS_2, INPUT_PULLUP);
  // I/O port #3
  pinMode(PWR_TRIG_3, OUTPUT);
  digitalWrite(PWR_TRIG_3, LOW);
  pinMode(PWR_SENS_3, INPUT_PULLUP);
  // analog in port
  pinMode(ADC_IN_1, INPUT_PULLUP);
  pinMode(ADC_IN_2, INPUT_PULLUP);
  // switch(s) in port
  pinMode(PWR_SWITCH_1, INPUT_PULLUP);
  pinMode(PWR_SWITCH_2, INPUT_PULLUP);
  // startup delay
  delay(350);
  digitalWrite(LED_BUILTIN, LOW);
}

void loop() {
  serialProcess();
  readDigitalInputs();
}

void readDigitalInputs() {
  readPowerButton_1();
  readPowerButton_2();
}

void readPowerButton_1() {
  // read pin state
  bool reading = digitalRead(PWR_SWITCH_1);
  // switch changed
  if (reading != powerButton_1Last) {
    // reset the debouncing timer
    powerButton_1Millis = millis();
  }
  if ((millis() - powerButton_1Millis) > debounceDelay) {
    if (reading != powerButton_1State) {
      powerButton_1State = reading;
      // input button was pressed
      if (powerButton_1State == 1) { 
        routeMessage(1,10,8); // toggle lamp
      }
    }
  }
  powerButton_1Last = reading;
}

void readPowerButton_2() {
  // read pin state
  bool reading = digitalRead(PWR_SWITCH_2);
  // switch changed
  if (reading != powerButton_2Last) {
    // reset the debouncing timer
    powerButton_2Millis = millis();
  }
  if ((millis() - powerButton_2Millis) > debounceDelay) {
    if (reading != powerButton_2State) {
      powerButton_2State = reading;
      // input button was pressed
      if (powerButton_2State == 1) { 
        routeMessage(1,10,9); // toggle macs
      }
    }
  }
  powerButton_2Last = reading;
}

void serialProcess() {
  // read main serial port
  if (serialFwrdMode == 0) {
    if (serialMsgEnd == 0) {
      if (Serial.available()) {
        readSerialData(Serial.read(), serialDataStart, serialDataEnd);
      }
    } else {
      // process serial data
      decodeMessage();
      // send response to main serial
      if (serialFwrdMode == 0) {
        writeSerialData(0); // write serial out buffer
      }
      serialMsgEnd = 0;
    }
  } 
  if (serialFwrdMode == 1) {
    // listen to external serial port when in forwarding mode
    if (serialMsgEnd == 0) {
      if (ExtSerial.available()) {
        readSerialData(ExtSerial.read(), respDelimiter, respDelimiter);
      }
    } else {
      // forward external serial reponse to main serial
      writeSerialData(1); // write serial in buffer
      disableFwrdMode();
    }
  }  
  // external serial reponse timeout
  if (maxFwrdRead.done()) {
    Serial.print("*EXT-232 MAX WAIT EXCEEDED!*\n");     
    disableFwrdMode();
  }  
}

void readSerialData(char rc, char startInd ,char endInd) {
  if (serialReading == 1) {
    // end-of-reading
    if (rc == endInd) {
      // terminate the string
      serialMessageIn[serialCurPos] = nullTrm;
      serialReading = 0;
      serialCurPos = 0;
      serialMsgEnd = 1;
    } else {
      // store characters in buffer
      if (rc != startInd) {
        serialMessageIn[serialCurPos] = rc;
        serialCurPos++;
        // prevent overflow
        if (serialCurPos >= maxMessage) {
          serialCurPos = maxMessage - 1;
        }
      }
    }
  } else {
    // start reading
    if (rc == startInd) {
      serialReading = 1;
      serialCurPos = 0;
      serialMsgEnd = 0;
    }
  }
}

void writeSerialData(bool InOut) {
  digitalWrite(LED_BUILTIN, HIGH);
  Serial.print(respDelimiter);
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {
    char _fwrdChr;
    if (InOut == 1){
      _fwrdChr = serialMessageIn[_idx];
    } else {
      _fwrdChr = serialMessageOut[_idx];
    }
    if (_fwrdChr != nullTrm) {
      Serial.print(_fwrdChr); 
    } else {
      break;
    }
  }
  Serial.print(respDelimiter);
  Serial.print('\n');
  digitalWrite(LED_BUILTIN, LOW);
}

void disableFwrdMode() {
  maxFwrdRead.reset();
  maxFwrdRead.stop();
  serialFwrdMode = 0;
  serialMsgEnd = 0;
}

// decode serial message
void decodeMessage() {
  // count delimiters
  uint8_t _delims = 0;
  uint8_t _maxchars = 10;
  char _delimiter = ',';
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {
    char _vchr = serialMessageIn[_idx];  
    if (_vchr == nullTrm) {
      break;
    }
    if (_vchr == _delimiter) {
      _delims++;
    }
  } 
  // exit when delimiters incorrect
  if (_delims < 2){
    Serial.print("*INVALID DELIMITERS!*");
    return;
  }
  // find first delimiter position
  uint8_t _linepos = 0;
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {  
    char _vchr = serialMessageIn[_idx];  
    if (_vchr == nullTrm) {
      break;
    }
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
    _linebuffer[_linecount] = serialMessageIn[_idx];
    _linecount++;
  } // terminate string
  _linebuffer[_linecount] = nullTrm;
  // convert to integer, store line value
  uint8_t controlData = atoi(_linebuffer); 
  // find second delimiter position
  uint8_t _count = 0;
  uint8_t _cmd2pos = 0; 
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {
    char _vchr = serialMessageIn[_idx];
    if (_vchr == nullTrm) {
      break;
    }
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
  if (controlData == 9){
    processCmdData(_cmd2pos + 1);
  } else {
    Serial.print("*INVALID PREFIX!*");
  }
}

// process register and command data
void processCmdData(uint8_t messageStart) {
  uint8_t _numcnt = 0;
  uint8_t _cmdlen = cmdRegLen + cmdDatLen;
  char _cmdarr[_cmdlen + 1];
  // extract control code from message
  for(uint8_t _idx = messageStart; _idx <= maxMessage; _idx++) {
    char _curchar = serialMessageIn[_idx];
    if (_curchar == nullTrm) {
      break;
    }
    if (isDigit(_curchar) && _numcnt <= maxMessage) {
      _cmdarr[_numcnt] = _curchar;
      _numcnt++;
    }
  }
  _cmdarr[_numcnt] = nullTrm;
  // validate control code length
  if (_numcnt != _cmdlen) {
    Serial.print("*INVALID LENGTH!*");
    return;
  }
  // extract register select
  char _regarr[cmdRegLen + 1];
  uint8_t _regidx = 0;
  for(uint8_t _idx = 0; _idx < cmdRegLen; _idx++) {
    _regarr[_regidx] = _cmdarr[_idx];
    _regidx++;
  }
  _regarr[_regidx] = nullTrm;
  uint8_t _register = atoi(_regarr); 
  // extract control data
  char _datarr[cmdDatLen + 1];
  uint8_t _dataidx = 0;
  for(uint8_t _idx = (cmdDatLen - 1); _idx < _cmdlen; _idx++) {
    _datarr[_dataidx] = _cmdarr[_idx];
    _dataidx++;
  }
  _datarr[_dataidx] = nullTrm;
  uint16_t _ctldata = atoi(_datarr);
  // route message (from main serial)
  routeMessage(0,_register,_ctldata);
}

void routeMessage(bool origin, uint8_t reg, uint16_t ctldata) {
  // 0 = message from main serial
  // 1 = message from local device
  if (origin == 1) {
    // block routing if processing serial message
    if (serialMsgEnd == 1) {
      return;
    }
    if (serialReading == 1) {
      return;
    }
    if (serialFwrdMode == 1) {
      return;
    }
  }
  /// route data by register ///
  if (reg == 1) {
    internalFunctions(ctldata);
  } else {
    if (origin == 1) {
      // combine fixed-length register and command data
      serialMessageIn[0] = nullTrm;
      uint8_t totalMsgLength = cmdRegLen + cmdDatLen + 1;
      snprintf(serialMessageIn, totalMsgLength, "%02d%03d", reg, ctldata);
    }
    /// send message to external serial port ///
    ExtSerial.print(serialDataStart);
    if (origin == 1) {
      ExtSerial.print("9,9,"); // static characters
    }
    for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {  
      char _vchr;
      _vchr = serialMessageIn[_idx];
      if (_vchr == nullTrm) {
        break;
      }
      ExtSerial.print(_vchr);
    }
    ExtSerial.print(serialDataEnd);
    ExtSerial.print('\n');
    // listen for external serial reponse
    serialFwrdMode = 1;
    maxFwrdRead.set(maxFwrdWait);
    maxFwrdRead.start();
  }
}

// return average digital input reading
int powerSense(int powerSensePin) {
  const int inputReadings = 16;
  int readings[inputReadings];
  int total = 0;
  for (int idx = 0; idx < inputReadings; idx++) {
    // read then add the reading to the total
    total = total + digitalRead(powerSensePin);
  }
  switch (total) {
    case inputReadings:
    // high reading
      return 1;
    case 0:
    // low reading
      return 0;
    default:
    // invalid reading
      return -1;
  }
}

void powerPulse(int _powerPin) {
  digitalWrite(_powerPin, HIGH);
  delay(250);
  digitalWrite(_powerPin, LOW);
}

// main control functions
void internalFunctions(uint16_t command) {
  // power trigger #1 
  if (command >= 1 && command <= 4) {
    int state = powerSense(PWR_SENS_1);
    if (command == 3) { // status
      // write status back to serial
      switch (state) {
        case 1: // power off (inverted)
          serialMessageOut[0] = '0';
          break;
        case 0: // power on (inverted)
          serialMessageOut[0] = '1';
          break;
        default: // invalid response
          serialMessageOut[0] = 'X';
          break;
      }
      serialMessageOut[1] = nullTrm;
    } else {
      if (state == 0) { // device on
        if (command == 2) { // power off
          powerPulse(PWR_TRIG_1);
        }
      } else { // device off
        if (command == 1) { // power on
          powerPulse(PWR_TRIG_1);
        }
      }
      if (command == 4) { // toggle power
        powerPulse(PWR_TRIG_1);
      }
    }
  }
}
