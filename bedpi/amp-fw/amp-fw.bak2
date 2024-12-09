 /////////////////////////////////////////////////////////////////////////
// Bedroom Amp Controller with Z-Terminal v1.0
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

// RS-232 Baud Rate
const int CONFIG_SERIAL = 9600;
#define toggleTV 10
#define enablePin 11
#define inputSelect 12

// Shared resources
const uint8_t maxMessage = 32;
char cmdData[maxMessage];
char serialMessage[maxMessage];
uint8_t serialMessageEnd = 0;
uint8_t cmdDataEnd = 0;
bool newData = 0;

//////////////////////////////////////////////////////////////////////////
// initialization
void setup() {
  // start serial ports
  Serial.begin(CONFIG_SERIAL);
  pinMode(LED_BUILTIN, OUTPUT);     
  digitalWrite(LED_BUILTIN, LOW);  
  pinMode(enablePin, OUTPUT);
  digitalWrite(enablePin, LOW); 
  pinMode(inputSelect, OUTPUT);  
  digitalWrite(inputSelect, LOW);  
  pinMode(toggleTV, OUTPUT);
  digitalWrite(toggleTV, LOW);   
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
        // store index position
        _cmd2pos = _idx;
        break;
      }  
      _count++;
    }
  } 
  // execute command
  if (cmdFirstColumn == 0){
    // position of the end of message
    cmdDataEnd = (_end - (_cmd2pos + 1));
    // write to characters to message array
    uint8_t _lcdidx = 0;
    for(uint8_t _idx = _cmd2pos + 1; _idx < _end; _idx++) { 
      cmdData[_lcdidx] = serialMessage[_idx]; 
      if (cmdData[0] == 'A') {
        // enable inputs 
        digitalWrite(enablePin, LOW); 
      }
      if (cmdData[0] == 'B') {
        // disable inputs 
        digitalWrite(enablePin, HIGH); 
      }
      if (cmdData[0] == 'C') {
        // optical input
        digitalWrite(inputSelect, LOW); 
      }
      if (cmdData[0] == 'D') { 
        // coax input
        digitalWrite(inputSelect, HIGH);
      }
      if (cmdData[0] == 'E') { 
        // power TV
        digitalWrite(toggleTV, HIGH);
        delay(250);
        digitalWrite(toggleTV, LOW);
      } 
      _lcdidx++; // increment index
    }
  }
  // send ack to computer
  Serial.println("*DATAOUT");
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

void loop() {
  // read serial port data
  readSerial();
}
