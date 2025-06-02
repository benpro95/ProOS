/*
 * Ben Provenzano III
 * -----------------
 * v1 05/31/2025
 * Serial Automation Controller 2x120VAC + 12VDC Switched
 *
 */

#include <SoftwareSerial.h>
  
// GPIO
#define relay0 9  // (Dresser Lamp +12v) [Pin #15]
#define relay1 11 // (Mac Classic) [Pin #16]
#define relay2 10 // (CRT TV) [Pin #17]
int relaysState0 = LOW;
int relaysState1 = LOW;
int relaysState2 = LOW;   
int stateChanged = LOW;

// serial resources
#define RX_PIN 6 // RS-232 RX [Pin #12] TRS=Ring
#define TX_PIN 5 // RS-232 TX [Pin #11] TRS=Tip
SoftwareSerial Ctrl232(RX_PIN, TX_PIN);
#define serialBaudRate 9600
const uint8_t maxMessage = 32;
uint8_t serialMessageInEnd = 0;
char serialMessageIn[maxMessage];
char serialMessageOut[maxMessage];
bool newData = 0;

void setup() {
  Serial.begin(serialBaudRate);
  // GPIO initialization
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(relay0, OUTPUT);
  digitalWrite(relay0, LOW);
  pinMode(relay1, OUTPUT);
  digitalWrite(relay1, LOW);
  pinMode(relay2, OUTPUT);  
  digitalWrite(relay2, LOW);
  // controller software serial
  serialMessageOut[0] = '\0';
  Ctrl232.begin(serialBaudRate);
}

void loop() {
  readSerial();  
  writeOutputs();
}

void writeSerialMessage(int16_t value) {
  uint16_t length = snprintf(NULL, 0, "%d", value);
  snprintf(serialMessageOut, length + 1, "%d", value);
}

void writeOutStates(){
  char outTbl[4];
  outTbl[0] = '1';
  if (relaysState0 == true) {
    outTbl[0] = '9';
  }
  outTbl[1] = '1';
  if (relaysState1 == true) {
    outTbl[1] = '9';
  }
  outTbl[2] = '1';
  if (relaysState2 == true) {
    outTbl[2] = '9';
  }
  outTbl[3] = '\0';
  int16_t intOut = atoi(outTbl);
  writeSerialMessage(intOut);
}

// RS-232 control functions
void remoteFunctions(uint8_t _register, uint16_t _ctldata) {
  // process register
  switch (_register) {
  // power select register
  case 10:
    // all outputs off
    if (_ctldata == 0) {
      stateChanged = HIGH;
      relaysState0 = LOW;
      relaysState1 = LOW;
      relaysState2 = LOW;
      writeOutStates(); 
    }  
    // output #1 off (10001)
    if (_ctldata == 1) {
      stateChanged = HIGH;
      relaysState0 = LOW;
      writeOutStates(); 
    }
    // output #1 on (10002)
    if (_ctldata == 2) { 
      stateChanged = HIGH;
      relaysState0 = HIGH;
      writeOutStates(); 
    }
    // output #2 off (10003)
    if (_ctldata == 3) {
      stateChanged = HIGH;
      relaysState1 = LOW;
      writeOutStates(); 
    }
    // output #2 on (10004)
    if (_ctldata == 4) { 
      stateChanged = HIGH;
      relaysState1 = HIGH;
      writeOutStates(); 
    }
    // output #3 off (10005)
    if (_ctldata == 5) {
      stateChanged = HIGH;
      relaysState2 = LOW;
      writeOutStates();   
    }
    // output #3 on (10006)
    if (_ctldata == 6) { 
      stateChanged = HIGH;
      relaysState2 = HIGH;    
      writeOutStates();
    }
    // show output states (10007)
    if (_ctldata == 7) { 
      writeOutStates();
    }
    break;
  default:
    // blink LED when command invalid
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
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
  for(uint8_t _idx = messageStart; _idx < serialMessageInEnd; _idx++) {
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
  uint16_t _ctldata = atoi(_datarr); 
  // process control code
  remoteFunctions(_register, _ctldata);
}

// decode serial message
void decodeMessage() {
  digitalWrite(LED_BUILTIN, HIGH);
  uint8_t _end = serialMessageInEnd;
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
    processMessage(_cmd2pos + 1);
  } else {
    Ctrl232.print('!');
  }
  Ctrl232.print('|'); // first acknowledgement 
  writeSerial(); // write message to serial
  Ctrl232.print('|'); // second acknowledgement
  Ctrl232.print('\n'); // newline
  digitalWrite(LED_BUILTIN, LOW);
}


void writeSerial() { // write response back to computer
  for(uint8_t _idx = 0; _idx <= maxMessage; _idx++) {  
    char _chrout = serialMessageOut[_idx];  
    if (_chrout == '\0') { // stop reading at end-of-message
      break;
    }
    Ctrl232.print(_chrout); // write character
  }
}

void readSerial() {
  static bool recvInProgress = 0;
  static uint8_t ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;
  if (Ctrl232.available() > 0 && newData == 0) {
    rc = Ctrl232.read();
    if (recvInProgress == 1) {
      if (rc != endMarker) {
        serialMessageIn[ndx] = rc;
        ndx++;
        if (ndx >= maxMessage) {
          ndx = maxMessage - 1;
        }
      } else {
        // terminate the string
        serialMessageIn[ndx] = '\0'; 
        serialMessageInEnd = ndx;
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
    // Reset registers
    newData = 0;
    serialMessageInEnd = 0;
    serialMessageOut[0] = '\0';
  }
}

void writeOutputs() {
  if (stateChanged == HIGH) {
    // Turn Relay 0 On/Off
    digitalWrite(relay0, relaysState0);
    // Turn Relay 1 On/Off
    digitalWrite(relay1, relaysState1); 
    // Turn Relay 2 On/Off
    digitalWrite(relay2, relaysState2);    
    stateChanged = LOW;  
  }  
}
