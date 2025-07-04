/*
 * Ben Provenzano III
 * -----------------
 * v1 06/19/2025
 * Serial Automation Accessory Controller
 *
 */

// shared libraries
#include <SoftwareSerial.h>

// local libraries
#include "neotimer.h"

const char nullTrm = '\0';

// GPIO
#define PWR_TRIG_1 9 // power trigger #1
#define PWR_SENS_1 2 // power sense #1

// serial resources
#define serialBaudRate 9600
#define RX_PIN 10 // RS-232 RX [Pin #12] TRS=Ring
#define TX_PIN 11 // RS-232 TX [Pin #11] TRS=Tip
SoftwareSerial ExtSerial(RX_PIN, TX_PIN); 
const uint8_t maxMessage = 32;
const uint8_t cmdRegLen = 2; // register select length (99***)
const uint8_t cmdDatLen = 3; // data length (**999)
const char serialDataStart = '<';
const char serialDataEnd = '>';
const char respDelimiter = '|';
char serialMessageOut[maxMessage];
char serialMessageIn[maxMessage];
uint8_t serialCurPos = 0;
bool serialFwrdMode = 0;
bool serialReading = 0;
bool serialMsgEnd = 0;
const uint8_t maxFwrdWait = 450; // max wait in (ms) for external response
Neotimer maxFwrdRead = Neotimer();

void setup() {
  // GPIO initialization
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  pinMode(PWR_TRIG_1, OUTPUT);
  digitalWrite(PWR_TRIG_1, LOW);
  pinMode(PWR_SENS_1, INPUT_PULLUP);
  delay(350);
  digitalWrite(LED_BUILTIN, LOW);
  // serial initialization
  Serial.begin(serialBaudRate);
  ExtSerial.begin(serialBaudRate);
  serialMessageIn[0] = nullTrm;
  serialMessageOut[0] = nullTrm;
}

void loop() {
  serialProcess();  
}

void processSerialData(char rc, char startInd ,char endInd) {
  if (serialReading == 1) {
    if (rc != endInd) {
      serialMessageIn[serialCurPos] = rc;
      serialCurPos++;
      if (serialCurPos >= maxMessage) {
        serialCurPos = maxMessage - 1;
      }
    } else {
      // terminate the string
      serialMessageIn[serialCurPos] = nullTrm; 
      serialReading = 0;
      serialCurPos = 0;
      serialMsgEnd = 1;
    }
  }
  else if (rc == startInd) {
    serialReading = 1;
  }
}

void serialProcess() {
  // read main serial port
  if (Serial.available() > 0 && serialFwrdMode == 0 && serialMsgEnd == 0) {
    char rxChar = Serial.read();
    processSerialData(rxChar,serialDataStart,serialDataEnd);
  }
  // listen to external serial port when in forwarding mode
  if (ExtSerial.available() > 0 && serialFwrdMode == 1 && serialMsgEnd == 0) {
    char extRxChar = ExtSerial.read();
    processSerialData(extRxChar,respDelimiter,respDelimiter);
  }
  // end-of-data actions
  if (serialMsgEnd == 1 && serialFwrdMode == 0) {
    // process serial data
    decodeMessage();
    // send response to main serial
    if (serialFwrdMode == 0) {
      writeSerial();
    }
    resetSerial();
  }
  // forward external serial reponse to main port
  if (serialFwrdMode == 1 && maxFwrdRead.done()) {
    Serial.print("*EXT-232 MAX WAIT EXCEEDED!*");
    stopFwrdMode();
  } 
  if (serialMsgEnd == 1 && serialFwrdMode == 1) {
    for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {
      char _fwrdChr = serialMessageIn[_idx];
      if (_fwrdChr != nullTrm) {
        serialMessageOut[_idx] = _fwrdChr;
      } else {
        break;
      }
    }
    stopFwrdMode();
  }
}

void writeSerial() {
  digitalWrite(LED_BUILTIN, HIGH);
  Serial.print(respDelimiter);
  for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {
    char _msgChr = serialMessageOut[_idx];
    if (_msgChr != nullTrm) {
      Serial.print(_msgChr); 
    } else {
      break;
    }
  }
  Serial.print(respDelimiter);
  Serial.print('\n');
  digitalWrite(LED_BUILTIN, LOW);
}

void stopFwrdMode() {
  writeSerial();
  resetSerial();
  maxFwrdRead.stop();
  maxFwrdRead.reset();
  serialFwrdMode = 0;
}

void resetSerial() {
  serialReading = 0;
  serialMsgEnd = 0;
  serialCurPos = 0;
  serialMessageIn[0] = nullTrm;
  serialMessageOut[0] = nullTrm;
}

// decode serial message
void decodeMessage() {
  // count delimiters
  uint8_t _delims = 0;
  uint8_t _maxchars = 10;
  char _delimiter = ',';
  for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {
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
    return;
  }
  // find first delimiter position
  uint8_t _linepos = 0;
  for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {  
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
  for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {
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
    extractSerialData(_cmd2pos + 1);
  } else {
    Serial.print("*INVALID PREFIX!*");
  }
}

// extract command data
void extractSerialData(uint8_t messageStart) {
  uint8_t _numcnt = 0;
  uint8_t _cmdlen = cmdRegLen + cmdDatLen;
  char _cmdarr[_cmdlen + 1];
  // extract control code from message
  for(uint8_t _idx = messageStart; _idx < maxMessage; _idx++) {
    char _curchar = serialMessageIn[_idx];
    if (_curchar == nullTrm) {
      break;
    }
    if (isDigit(_curchar) && _numcnt < maxMessage) {
      _cmdarr[_numcnt] = _curchar;
      _numcnt++;
    }
  }
  _cmdarr[_numcnt] = nullTrm;
  // valiate control code length
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
  /// route data by register ///
  if (_register == 1) {
    uint16_t _ctldata = atoi(_datarr); 
    mainFunctions(_ctldata);
  } else {
    // forward data to external serial port
    ExtSerial.print(serialDataStart);
    for(uint8_t _idx = 0; _idx < maxMessage; _idx++) {  
      char _vchr = serialMessageIn[_idx];
      if (_vchr == nullTrm) {
        break;
      }
      ExtSerial.print(_vchr);
    }
    ExtSerial.print(serialDataEnd);
    ExtSerial.print('\n');
    // forward response to main serial port
    serialFwrdMode = 1;
    // start max-wait timer
    maxFwrdRead.set(maxFwrdWait);
    maxFwrdRead.start();
  }
}

bool powerSense(int _powerSensePin, bool _writeSerial, bool _invertOut) {
  bool _pwrState = digitalRead(_powerSensePin);
  if (_invertOut == 1) {
    _pwrState = !_pwrState;
  }
  if (_writeSerial == 1) {
    serialMessageOut[0] = '0';
    if (_pwrState == 1) {
      serialMessageOut[0] = '1';
    }
    serialMessageOut[1] = nullTrm;
  }
  return _pwrState;
}

void powerPulse(int _powerPin) {
  digitalWrite(_powerPin, HIGH);
  delay(200);
  digitalWrite(_powerPin, LOW);
}

// main control functions
void mainFunctions(uint16_t _ctldata) {
  // power trigger #1 
  if (_ctldata == 1 || _ctldata == 2) {
    bool _pwrState = powerSense(PWR_SENS_1,0,1);
    // device on
    if (_pwrState == 1) {
      // power off mode
      if (_ctldata == 2) {
        powerPulse(PWR_TRIG_1);
      }
    } else { // device off
      // power on mode
      if (_ctldata == 1) {
        powerPulse(PWR_TRIG_1);
      }
    }
  }
  // power sense #1 status
  if (_ctldata == 3) {
    (void)powerSense(PWR_SENS_1,1,1);
  }
}
