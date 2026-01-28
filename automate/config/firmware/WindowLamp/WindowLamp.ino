#include <WiFi.h>
#include <neotimer.h>
#include "creds.h" 

#define serialBaudRate 115200
#define powerBtnPin 3
#define lamp1PowerPin 21
#define lamp2PowerPin 4
uint8_t debounceDelay = 75; // button debounce in (ms)
WiFiServer WebServer(4000); // web server port
Neotimer WiFiCheck = Neotimer(30000); // 30 second timer
const char nullTrm = '\0';
// command decoder
const uint8_t maxMessage = 64;
char serialMessageIn[maxMessage];
char serialMessageOut[maxMessage];
const uint8_t cmdMaxLength = 2;
const char serialDataStart = '?';
const char serialDataEnd = '~';
uint16_t serialCurPos = 0;
bool serialReading = 0;
bool serialMsgEnd = 0;
// HTTP buffer
const uint8_t HTTPBufferSize = 128;
char HTTPBuffer[HTTPBufferSize];
uint8_t HTTPReqIdx = 0;    
// power button
uint8_t lastPowerButton = 1;
uint8_t powerButton = 0;
uint32_t powerButtonMillis;
// device states
uint8_t lamp2Status = 0;
bool lamp1Status = 1; // 1=OFF, 0=ON

void setup() {
  serialMessageOut[0] = nullTrm;
  pinMode(powerBtnPin, INPUT_PULLUP);
  pinMode(lamp1PowerPin, OUTPUT);
  digitalWrite(lamp1PowerPin, lamp1Status); 
  pinMode(lamp2PowerPin, OUTPUT);
  analogWrite(lamp2PowerPin, lamp2Status);
  Serial.begin(serialBaudRate);
  connectWiFi();
  WebServer.begin();
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
        // toggle lamp #1 power
        lamp1Status = !lamp1Status;
        digitalWrite(lamp1PowerPin, lamp1Status); 
      }
    }
  }
  lastPowerButton = reading;
}

void remoteFunctions(uint16_t _ctldata, uint16_t _state) {
  switch (_ctldata) {
  case 1: 
    // lamp #1 fixed-controls 
    switch (_state) {
    case 0: // lamp status
      writeSerialMessage(!lamp1Status);
      break;     
    case 1: // toggle lamp
      toggleLamp1();
      writeSerialMessage(!lamp1Status);
      break;
    case 2: // lamp power off
      if (lamp1Status == 0) { toggleLamp1(); }
      writeSerialMessage(!lamp1Status);
      break;
    case 3: // lamp power on
      if (lamp1Status == 1) { toggleLamp1(); }
      writeSerialMessage(!lamp1Status);
      break;     
    default:
      serialMessageOut[0] = nullTrm;
    }
    break;
  case 2: 
    // lamp #2 fixed-controls 
    switch (_state) {
    case 0: // lamp power off
      setLamp2(0);
      writeSerialMessage(lamp2Status);
      break;
    case 1: // lamp 10%
      setLamp2(5);
      writeSerialMessage(lamp2Status);
      break;
    case 2: // lamp 20%
      setLamp2(10);
      writeSerialMessage(lamp2Status);
      break;
    case 3: // lamp 30%
      setLamp2(20);
      writeSerialMessage(lamp2Status);
      break;
    case 4: // lamp 40%
      setLamp2(50);
      writeSerialMessage(lamp2Status);
      break;
    case 5: // lamp 50%
      setLamp2(80);
      writeSerialMessage(lamp2Status);
      break;
    case 6: // lamp 60%
      setLamp2(120);
      writeSerialMessage(lamp2Status);
      break;
    case 7: // lamp 70%
      setLamp2(150);
      writeSerialMessage(lamp2Status);
      break;
    case 8: // lamp 80%
      setLamp2(180);
      writeSerialMessage(lamp2Status);
      break;
    case 9: // lamp 90%
      setLamp2(220);
      writeSerialMessage(lamp2Status);
      break;
    case 10: // lamp 100%
      setLamp2(255);
      writeSerialMessage(lamp2Status);
      break;
    case 20: // lamp #2 status
      writeSerialMessage(lamp2Status);
      break; 
    default:
      serialMessageOut[0] = nullTrm;
    }
    break;
  case 3: 
    // lamp #2 direct control
    if (_state >= 0 && _state <= 255) {
      setLamp2(_state);
      writeSerialMessage(_state);
    } else {
      serialMessageOut[0] = nullTrm;
    }
    break;
  case 4: 
    // write all lamps status
    writeAllLampsStatus();
    break;
  default:
    serialMessageOut[0] = nullTrm;
  }
}

void writeSerialMessage(int16_t value) {
  serialMessageOut[0] = nullTrm;
  uint16_t length = snprintf(NULL, 0, "%d", value);
  snprintf(serialMessageOut, length + 1, "%d", value);
}

void writeAllLampsStatus() {
  serialMessageOut[0] = nullTrm;
  char lamp1[8], lamp2[8];
  sprintf(lamp1, "%d", (int)!lamp1Status);
  sprintf(lamp2, "%d", lamp2Status);
  // concat arrays then write to output buffer
  sprintf(serialMessageOut ,"%s~%s" ,lamp1 ,lamp2);
}

void setLamp2(uint8_t state) {
  lamp2Status = state;
  analogWrite(lamp2PowerPin, state);
}

void toggleLamp1() {
  lamp1Status = !lamp1Status;
  digitalWrite(lamp1PowerPin, lamp1Status);
}

// decode serial message
void decodeMessage() {
  const char _delimiter = ',';
  const uint8_t cmdMaxChars = 5;
  uint8_t _delims = 0;
  uint8_t _charscount = 0;
   // count delimiters
  for (uint8_t _idx = 0; _idx <= maxMessage; _idx++) {
    char _vchr = serialMessageIn[_idx];  
    if (_vchr == nullTrm) {
      break;
    }
    if (_vchr == _delimiter) {
      _delims++;
    }
    _charscount++;
  }
  // exit when delimiters incorrect
  if (_delims < 2){
    Serial.println("*INVALID DELIMITERS!*");
    return;
  }
  // find first delimiter position
  uint8_t _linepos = 0;
  for (uint8_t _idx = 0; _idx <= maxMessage; _idx++) {  
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
  // loop through first argument characters 
  char _linebuffer[cmdMaxChars + 1];
  uint8_t _linecount = 0;   
  for (uint8_t _idx = 0; _idx < _linepos; _idx++) {
    if (_linecount >= cmdMaxChars) {
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
  for (uint8_t _idx = 0; _idx < maxMessage; _idx++) {
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
  // loop through second argument characters 
  char _line2buffer[cmdMaxChars + 1];
  uint8_t _line2count = 0; 
  uint8_t _cmd2idx = _cmd2pos + 1;  
  for (uint8_t _idx = 0; _idx < cmdMaxChars; _idx++) {
    // stop reading at end of line character
    char _line2char = serialMessageIn[_cmd2idx];
    if (_line2char == nullTrm) {
      break;
    }
    if (_line2char == _delimiter) {
      break;
    }
    // store in new array
    _line2buffer[_line2count] = _line2char;
    _line2count++;
    _cmd2idx++;
  } // terminate string
  _line2buffer[_line2count] = nullTrm;
  // convert to integer, store line value
  uint8_t stateData = atoi(_line2buffer); 
  // run function
  remoteFunctions(controlData, stateData);
}

void processSerialData(char rc, char startInd ,char endInd) {
  if (serialReading == 1) {
    // end-of-reading
    if (rc == endInd) {
      // terminate the string
      serialMessageIn[serialCurPos] = nullTrm;
      serialReading = 0;
      serialCurPos = 0;
      serialMsgEnd = 1;
      decodeMessage();
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

void webServer() {
  WiFiClient client = WebServer.accept(); 
  if (client) {
    // An incoming client connection
    HTTPReqIdx = 0; // Reset buffer index for new request
    bool lineblank = 1;
    while (client.connected()) {
      if (client.available()) {
        char http_byte = client.read(); // read byte (character)
        // store character in the buffer if space is available
        if (HTTPReqIdx < (HTTPBufferSize - 1)) {
          HTTPBuffer[HTTPReqIdx] = http_byte;
          HTTPReqIdx++;
        }
        // the end of the client request is typically a blank line
        // (CR/LF, which is \r\n, followed by another \r\n)
        if (http_byte == '\n' && lineblank) {
          // end of HTTP request, process the data
          HTTPBuffer[HTTPReqIdx] = nullTrm; // terminate the string
          // process the request array
          Serial.println("received request");
          // process message
          for (size_t _idx = 0; _idx < (HTTPBufferSize - 1); _idx++) {
            char _chr = HTTPBuffer[_idx];
            if (_chr == nullTrm) { break; }
            processSerialData(_chr, serialDataStart, serialDataEnd);
          }
          // send a response to the client
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/plain");
          client.println("Connection: close");
          client.println();
          for(size_t _idx = 0; _idx < maxMessage; _idx++) {
            char _msgChr = serialMessageOut[_idx];
            if (_msgChr == nullTrm) {
              break;
            } else {
              client.print(_msgChr); 
            }
          }
          client.print('\n');
          break;
        }
        // track blank lines for end-of-request detection
        if (http_byte == '\n') {
          lineblank = 1;
        } else if (http_byte != '\r') {
          lineblank = 0;
        }
      }
    }
    // give the client time to receive the data and then stop the connection
    delay(1);
    client.stop();
    Serial.println("client disconnected");
  }
}

void connectWiFi() {
  Serial.println("connecting to Wi-Fi...");
  WiFi.mode(WIFI_STA);
  WiFi.setHostname(hostname);
  WiFi.begin(ssid, ssid_pwd);
}

void checkWiFi() {
  if (WiFiCheck.repeat()) {
    if (WiFi.status() != WL_CONNECTED) {
      WiFi.disconnect(true);
      delay(1000);
      connectWiFi();
    } else {
      Serial.println("connected to Wi-Fi, IP:");
      Serial.println(WiFi.localIP());
    }
  }
}

void loop() {
  checkWiFi();
  readPowerButton();
  webServer();
}
