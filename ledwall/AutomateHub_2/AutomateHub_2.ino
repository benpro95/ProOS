/*
 * Ben Provenzano III
 * -----------------
 * v1.0 - 07/20/2025
 * Automate Hub #2 (Living Room)
 * -----------------
 */

#include <IRremote.hpp> // v3+
#include <RCSwitch.h>

const char nullTrm = '\0';

// GPIO resources
#define PC_TRIG_PIN 4
#define RF_TX_PIN   3
#define IR_OUT_PIN  2
#define NO_LED_FEEDBACK_CODE 

// serial resources
#define serialBaudRate 9600
#define RX_PIN 6 // RS-232 RX [Pin #12] TRS=Ring
#define TX_PIN 5 // RS-232 TX [Pin #11] TRS=Tip
const uint8_t maxMessage = 32;
const uint8_t cmdRegLen = 2; // register length (99***)
const uint8_t cmdDatLen = 3; // data length (**999)
const char serialDataStart = '<';
const char serialDataEnd = '>';
const char respDelimiter = '|';
uint16_t serialCurPos = 0;
bool serialReading = 0;
bool serialMsgEnd = 0;
char serialMessageIn[maxMessage];
char serialMessageOut[maxMessage];

// IR addresses
const uint16_t IR_Preamp_A1 = 0x6DD2; 
const uint16_t IR_Preamp_A2 = 0xACD2;
const uint16_t IR_Preamp_A3 = 0x6CD2;
const uint16_t IR_1021DAC_A1 = 0x2B5C;
const uint16_t IR_Subamp_A1 = 0x4;

// RF transmission
RCSwitch mySwitch = RCSwitch();

void setup() {
  Serial.begin(serialBaudRate); 
  // GPIO initialization
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(PC_TRIG_PIN, OUTPUT);
  digitalWrite(PC_TRIG_PIN, LOW);
  // controller software serial
  serialMessageOut[0] = '\0';
  Serial.begin(serialBaudRate);
  // RF initialization
  mySwitch.enableTransmit(RF_TX_PIN);
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(315);
  mySwitch.setRepeatTransmit(5);
  // IR initalization
  IrSender.begin(IR_OUT_PIN);
  IrSender.enableIROut(38); // 38-KHz Infrared
}

void loop() {
  serialProcess();
}

void serialProcess() {
  // read main serial port
  if (serialMsgEnd == 0) {
    if (Serial.available()) {
      processSerialData(Serial.read(), serialDataStart, serialDataEnd);
    }
  } else {
    // process serial data
    decodeMessage();
    writeSerial();
    serialMsgEnd = 0;
  }
}
 
void processSerialData(char rc, char startInd ,char endInd) {
  // while reading
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
    // start-of-reading
    if (rc == startInd) {
      serialReading = 1;
      serialCurPos = 0;
      serialMsgEnd = 0;
    }
  }
}

void writeSerial() { // write response back to computer
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
    processCmdData(_cmd2pos + 1);
  } else {
    Serial.print("*INVALID PREFIX!*");
  }
  digitalWrite(LED_BUILTIN, LOW);
}

// process register and command data
void processCmdData(uint8_t messageStart) {
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
  remoteFunctions(_register,_ctldata);
}

// RS-232 control functions
void remoteFunctions(uint8_t _register, uint16_t _ctldata) {
  // device is register #2
  if (_register =! 2) {
    // blink LED when command invalid
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
    return;
  }
  // process register
  switch (_ctldata) {
  case 1:
  // window light on
    mySwitch.send(834511, 24);
    writeSerialMessage(1);
    break;
  case 2:
    // window light off
    mySwitch.send(834512, 24);
    writeSerialMessage(1);  
    break;
  case 10:
    // toggle PC on/off
    digitalWrite(PC_TRIG_PIN, HIGH);
    delay(300);
    digitalWrite(PC_TRIG_PIN, LOW);
    writeSerialMessage(1);  
    break;
  case 101:
    // preamp power toggle
    IrSender.sendNEC(IR_Preamp_A1, 0x4, 0);
    writeSerialMessage(1); 
    break;
  case 102:
    // preamp power on
    IrSender.sendNEC(IR_Preamp_A3, 0x99, 0);
    writeSerialMessage(1); 
    break;
  case 103:
    // preamp power off
    IrSender.sendNEC(IR_Preamp_A3, 0x8E, 0);
    writeSerialMessage(1); 
    break;
  case 104:
    // volume down slow/fine
    IrSender.sendNEC(IR_Preamp_A3, 0x9B, 0); 
    writeSerialMessage(1); 
    break;
  case 105:
    // volume up slow/fine
    IrSender.sendNEC(IR_Preamp_A3, 0x9A, 0);
    writeSerialMessage(1); 
    break;
  case 106:
    // HPF control
    IrSender.sendNEC(IR_Preamp_A3, 0x8D, 0);
    writeSerialMessage(1); 
    break;    
  case 107:
    // input (1) dac input
    IrSender.sendNEC(IR_Preamp_A2, 0xE, 0);
    writeSerialMessage(1); 
    break;   
  case 108:
    // input (2) aux
    IrSender.sendNEC(IR_Preamp_A2, 0xF, 0);
    writeSerialMessage(1); 
    break;   
  case 109:
    // input (3) phono
    IrSender.sendNEC(IR_Preamp_A2, 0x10, 0);
    writeSerialMessage(1); 
    break;  
  case 110:
    // airplay, input (1)
    IrSender.sendNEC(IR_Preamp_A2, 0x11, 0);
    writeSerialMessage(1); 
    break;   
  case 111:
    // toggle volume limiter
    IrSender.sendNEC(IR_Preamp_A2, 0x12, 0);
    writeSerialMessage(1); 
    break;   
  case 112:
    // optical, input (1)
    IrSender.sendNEC(IR_Preamp_A2, 0x17, 0);
    writeSerialMessage(1); 
    break;   
  case 113:
    // volume down fast/course
    IrSender.sendNEC(IR_Preamp_A1, 0x3, 0);
    writeSerialMessage(1); 
    break; 
  case 114:
    // volume up fast/course
    IrSender.sendNEC(IR_Preamp_A1, 0x2, 0);
    writeSerialMessage(1); 
    break; 
  case 115:
    // mute toggle 
    IrSender.sendNEC(IR_Preamp_A1, 0x5, 0);
    writeSerialMessage(1); 
    break;
  case 120:
    // subwoofer mute toggle
    IrSender.sendNEC(IR_Subamp_A1, 0xA, 0);
    writeSerialMessage(1); 
    break; 
  case 121:
    // subwoofer mute off / amp B+ on 
    IrSender.sendNEC(IR_Subamp_A1, 0x12, 0);
    writeSerialMessage(1); 
    break;   
  case 122:
    // subwoofer mute on / amp B+ off
    IrSender.sendNEC(IR_Subamp_A1, 0x11, 0);
    writeSerialMessage(1); 
    break;       
  case 123:
    // subwoofer volume up
    IrSender.sendNEC(IR_Subamp_A1, 0x2, 0);
    writeSerialMessage(1); 
    break;    
  case 124:
    // subwoofer volume down
    IrSender.sendNEC(IR_Subamp_A1, 0x3, 0);
    writeSerialMessage(1); 
    break;
  case 130:
    // DAC USB input
    IrSender.sendNEC(IR_1021DAC_A1, 0x2, 0);
    writeSerialMessage(1); 
    break;
  case 131:
    // DAC coaxial input
    IrSender.sendNEC(IR_1021DAC_A1, 0x3, 0);
    writeSerialMessage(1); 
    break;   
  case 132:
    // DAC optical input
    IrSender.sendNEC(IR_1021DAC_A1, 0x4, 0);
    writeSerialMessage(1); 
    break;
  case 133:
    // DAC auto input
    IrSender.sendNEC(IR_1021DAC_A1, 0x5, 0);
    writeSerialMessage(1); 
    break;      
  default:
    writeSerialMessage(0);  
  }
}

void writeSerialMessage(int16_t value) {
  serialMessageOut[0] = nullTrm;
  uint16_t length = snprintf(NULL, 0, "%d", value);
  snprintf(serialMessageOut, length + 1, "%d", value);
}
