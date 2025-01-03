 /////////////////////////////////////////////////////////////////////////
// Bedroom Amp Controller v1.2
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

#include "encoder.h"
#include "bounce.h"
#include <Wire.h>

// RS-232 configuration
const int CONFIG_SERIAL = 9600;

// serial resources
const uint8_t maxMessage = 32;
char serialMessage[maxMessage];
uint8_t serialMessageEnd = 0;
bool newData = 0;

// I/O resources
#define ampPowerPin            12
#define inputBtnPin            7
#define inputIRPin             6
#define powerBtnPin            5
#define muteBtnPin             4
#define inputEncoderA          3
#define inputEncoderB          2
uint8_t selectedInput = 0;
uint8_t lastInput = 0;

// PGA2311 resources
#define volumeClockPin         9     // clock pin for volume control
#define volumeDataPin          8     // data pin for volume control
#define volumeSelectPin        10    // select pin for volume control
#define volumeMutePin          11    // mute pin for the volume control  
#define maxVolume              192   // maximum PGA volume (192 is 0 dB -- no gain)
#define minVolume              4
#define volumeStep             2
uint8_t lastChannelVolume = 0;
uint8_t channelVolume = 0;
bool isMuted = false;

// MCP23008 resources
#define MCP23_ADDR           0x27    //  MCP's I2C address
#define MCP23_DDR_A          0x00    //  data direction register A
#define MCP23_POL_A          0x01    //  input polarity A
#define MCP23_IOCR           0x05    //  IO control register
#define MCP23_PUR_A          0x06    //  pull-up resistors A
#define MCP23_GPIO_A         0x09    //  general purpose IO A
#define MCP23_IOCR_OUT       0x00    //  sets all pins as outputs
#define MCP23_IOCR_SEQOP     0x20    //  sequential operation mode bit.
#define MCP23_IOCR_DISSLW    0x10    //  slew rate control bit for SDA output.
#define MCP23_IOCR_ODR       0x04    //  sets the INT pin as an open-drain output.
#define MCP23_IOCR_INTPOL    0x02    //  polarity of the INT output pin.
uint8_t mcpState = 0x00;  

//////////////////////////////////////////////////////////////////////////
// initialization
void setup() {
  // MCP23008 setup
  Wire.begin();
  Wire.beginTransmission(MCP23_ADDR);
  Wire.write(MCP23_DDR_A);
  Wire.write(MCP23_IOCR_OUT);
  Wire.endTransmission();
  // set trigger pin states
  writeMCP(1, HIGH);
  writeMCP(2, HIGH);
  // default audio input
  audioInput(2); // optical #2
  // start serial ports
  Serial.begin(CONFIG_SERIAL);
  pinMode(LED_BUILTIN, OUTPUT);  
  // control logic   
  digitalWrite(LED_BUILTIN, LOW);
  // PGA volume logic
  pinMode(volumeMutePin, OUTPUT);
  digitalWrite(volumeMutePin, HIGH);           
  pinMode(volumeSelectPin, OUTPUT);
  pinMode(volumeClockPin, OUTPUT);
  pinMode(volumeDataPin, OUTPUT);
  digitalWrite(volumeSelectPin, HIGH);
  digitalWrite(volumeClockPin, HIGH);
  digitalWrite(volumeDataPin, HIGH);
  // PGA initialization
  delay(100);
  setVolume(0);
  delay(800);
  // un-mute PGA
  digitalWrite(volumeMutePin,LOW); 
  delay(200);
  // set default volume
  channelVolume = 150;
  Serial.print("Setting initial volume to (byte value) ");
  Serial.println(channelVolume);
  // scale into default volume
  scaleVolume(0,channelVolume,50);
}

static inline void writeMCP(uint8_t outputPin, bool pinState) {
  //// MCP23008 configuration ////
  // Aux-In Relay (active-high) //
  // Trigger R (active-low)     //
  // Trigger L (active-low)     //
  // TBD Header                 //
  // N/C                        //
  // 74HC4052 - S0              //
  // 74HC4052 - S1              //
  // Mute Lock (active-high)    //
  ////////////////////////////////
  if (outputPin > 7) {
    return;
  }
  bitWrite(mcpState, outputPin, pinState);
  Wire.beginTransmission(MCP23_ADDR);
  Wire.write(MCP23_GPIO_A);
  Wire.write(mcpState);
  Wire.endTransmission();
}

static inline void volWriteByte(uint8_t byteOut) {
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
 
/*
 * Function to set the (stereo) volume on the PGA2311
 */
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

/*
 * Function to scale volume from one level to another (softer changes for mute)
 */
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

void audioInput(uint8_t _input) {
  lastInput = selectedInput;
  // optical #1 input
  if (_input == 1) {
    writeMCP(6, LOW);  // 4052-S1
    writeMCP(5, HIGH); // 4052-S0
    // DAC analog input
    writeMCP(0, LOW);
  }
  // optical #2 input
  if (_input == 2) {
    writeMCP(6, HIGH); // 4052-S1
    writeMCP(5, HIGH); // 4052-S0
    // DAC analog input
    writeMCP(0, LOW);
  }
  // coaxial digital input
  if (_input == 3) {
    writeMCP(6, HIGH); // 4052-S1
    writeMCP(5, LOW);  // 4052-S0 
    // DAC analog input
    writeMCP(0, LOW);
  }
  // aux analog input
  if (_input == 4) {
    writeMCP(0, HIGH);
  }
  selectedInput = _input;
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
  // read command data
  if (cmdFirstColumn == 0){
    for(uint8_t _idx = _cmd2pos + 1; _idx < _end; _idx++) {

      if (serialMessage[_idx] == 'A') {
        // optical in #1
        audioInput(1);
      }
      if (serialMessage[_idx] == 'B') {
        // optical in #2
        audioInput(2);
      }
      if (serialMessage[_idx] == 'C') {
        // coax input
        audioInput(3);
      }
      if (serialMessage[_idx] == 'E') {
        // aux input
        audioInput(4);
      }               
      if (serialMessage[_idx] == 'F') { 
        // trigger R (pulse)
        writeMCP(1, LOW);
        delay(250);
        writeMCP(1, HIGH);
      }
      if (serialMessage[_idx] == 'G') {
        // trigger L (pulse)
        writeMCP(2, LOW);
        delay(250);
        writeMCP(2, HIGH);
      }
      if (serialMessage[_idx] == 'H') {
        // mute lock (ON)
        writeMCP(7, HIGH);
      }  
      if (serialMessage[_idx] == 'I') {
        // mute lock (OFF)
        writeMCP(7, LOW);
      }  
      if (serialMessage[_idx] == 'X') { 
        // volume up
        if (isMuted == false ) {
          lastChannelVolume = channelVolume;
          channelVolume = channelVolume + volumeStep;
          if (channelVolume >= maxVolume) {
            channelVolume = maxVolume;
          }
          scaleVolume(lastChannelVolume,channelVolume,volumeStep);    
        }
      }
      if (serialMessage[_idx] == 'Y') { 
        // volume down 
        if (isMuted == false ) {
          lastChannelVolume = channelVolume;
          channelVolume = channelVolume - volumeStep;
          if (channelVolume <= minVolume) {
            channelVolume = minVolume;
          }
          scaleVolume(lastChannelVolume,channelVolume,volumeStep);    
        }
      }
      if (serialMessage[_idx] == 'Z') { 
        // mute
        if (isMuted == false) {
          isMuted = true;
          Serial.println("Muting...");
          scaleVolume(channelVolume,0,35);
        } else {
          isMuted = false;
          Serial.println("Unmuting...");
          scaleVolume(0,channelVolume,40);
        }
      }

      ////
    }
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

void loop() {
  // read serial port data
  readSerial();
}
