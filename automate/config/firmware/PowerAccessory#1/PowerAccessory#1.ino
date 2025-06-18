/*
 * Ben Provenzano III
 * -----------------
 * v1 06/17/2025
 * Serial Automation Accessory Controller
 *
 */

#include <SoftwareSerial.h>

// serial resources
#define serialBaudRate 9600
#define RX_PIN 6 // RS-232 RX [Pin #12] TRS=Ring
#define TX_PIN 5 // RS-232 TX [Pin #11] TRS=Tip
SoftwareSerial ExtSerial(RX_PIN, TX_PIN);
const uint8_t maxMessage = 32;
const char respDelimiter = '|';
const char serialMsgStartChr = '<';
const char serialMsgEndChr = '>';
char serialMessageOut[maxMessage];
char serialMessageIn[maxMessage];
uint8_t serialMsgLength = 0;
bool serialFwrdMode = 0;
bool serialMsgEnd = 0;

void setup() {
  // serial initialization
  Serial.begin(serialBaudRate);
  ExtSerial.begin(serialBaudRate);
  resetSerial();
  // GPIO initialization
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
}

void loop() {
  serialProcess();  
}

void processSerialData(char rc, char startInd ,char endInd) {
  static bool recvInProgress = 0;
  static uint8_t ndx = 0;
  if (recvInProgress == 1) {
    if (rc != endInd) {
      serialMessageIn[ndx] = rc;
      ndx++;
      if (ndx >= maxMessage) {
        ndx = maxMessage - 1;
      }
    } else {
      // terminate the string
      serialMessageIn[ndx] = '\0'; 
      serialMsgLength = ndx;
      recvInProgress = 0;
      serialMsgEnd = 1;
      ndx = 0;
    }
  }
  else if (rc == startInd) {
    recvInProgress = 1;
  }
}

void resetSerial() {
  // RX buffer
  serialMsgEnd = 0;
  serialMsgLength = 0;
  // TX buffer
  serialMessageOut[0] = '\0';
}

void writeSerial() { // write response back to computer
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {  
    char _chrout = serialMessageOut[_idx];  
    if (_chrout == '\0') { // stop reading at end-of-message
      break;
    }
    Serial.print(_chrout); // write character-by-character
  }
}

void serialProcess() {
  // read main serial port
  if (Serial.available() > 0 && serialFwrdMode == 0 && serialMsgEnd == 0) {
    char rxChar = Serial.read();
    processSerialData(rxChar,serialMsgStartChr,serialMsgEndChr);
  }
  // main serial end-of-data actions
  if (serialMsgEnd == 1 && serialFwrdMode == 0) {
    digitalWrite(LED_BUILTIN, HIGH);
    decodeMessage();
    resetSerial();
    digitalWrite(LED_BUILTIN, LOW);
  }
  // listen to external serial port when in forwarding mode
  if (ExtSerial.available() > 0 && serialFwrdMode == 1 && serialMsgEnd == 0) {
    char extRxChar = ExtSerial.read();
    processSerialData(extRxChar,respDelimiter,respDelimiter);
  }
  // external serial end-of-data actions
  if (serialMsgEnd == 1 && serialFwrdMode == 1) {
    digitalWrite(LED_BUILTIN, HIGH);
    // forward response to main serial
    Serial.print(respDelimiter);
    for(uint8_t _idx = 0; _idx < serialMsgLength; _idx++) {
      char _msgChr = serialMessageIn[_idx];
      if (_msgChr != '\0') {
        Serial.print(_msgChr); 
      } else {
        break;
      }
    }
    Serial.print(respDelimiter);
    Serial.print('\n');
    serialFwrdMode = 0;
    resetSerial();
    digitalWrite(LED_BUILTIN, LOW);
  }  
}

// decode serial message
void decodeMessage() {
  uint8_t _end = serialMsgLength;
  // count delimiters
  uint8_t _delims = 0;
  uint8_t _maxchars = 10;
  char _delimiter = ',';
  for(uint8_t _idx = 0; _idx < _end; _idx++) {
    char _vchr = serialMessageIn[_idx];  
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
    char _vchr = serialMessageIn[_idx];  
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
  _linebuffer[_linecount] = '\0';
  // convert to integer, store line value
  uint8_t controlData = atoi(_linebuffer); 
  // find second delimiter position
  uint8_t _count = 0;
  uint8_t _cmd2pos = 0; 
  for(uint8_t _idx = 0; _idx < _end; _idx++) {
    char _vchr = serialMessageIn[_idx];   
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
    Serial.println("ERROR!");
  }
  // send response to PC (not in forwarding mode)
  if (serialFwrdMode == 0){
    Serial.print(respDelimiter); // first acknowledgement 
    writeSerial(); // write message to serial
    Serial.print(respDelimiter); // second acknowledgement
    Serial.print('\n'); // newline
  }
}

// extract command data
void extractSerialData(uint8_t messageStart) {
  uint8_t _numcnt = 0;
  const uint8_t cmdLength = 5; // fixed command length
  const uint8_t cmdRegLen = 2; // register select length (99***)
  const uint8_t cmdDataLen = 3; // data length (**999)
  char _cmdarr[cmdLength + 1];
  // extract control code from message
  for(uint8_t _idx = messageStart; _idx < serialMsgLength; _idx++) {
    char _curchar = serialMessageIn[_idx];
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
  /// route data by register ///
  if (_register == 1) {
    uint16_t _ctldata = atoi(_datarr); 
    AccFunctions(_ctldata);
  } else {
    // forward data to external serial port
    ExtSerial.print(serialMsgStartChr);
    for(uint8_t _idx = 0; _idx < serialMsgLength; _idx++) {  
      char _vchr = serialMessageIn[_idx];
      ExtSerial.print(_vchr);
    }
    ExtSerial.print(serialMsgEndChr);
    ExtSerial.print('\n');
    // forward response to main serial port
    serialFwrdMode = 1;
  }
}

// RS-232 control functions
void AccFunctions(uint16_t _ctldata) {
  serialMessageOut[0] = '9';
  serialMessageOut[1] = '9';
  serialMessageOut[2] = '\0';
}
