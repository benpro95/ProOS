 /////////////////////////////////////////////////////////////////////////
// Bedroom Amp Controller with Z-Terminal v1.0
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

#include "Adafruit_MCP23008.h"
#include "encoder.h"
#include "bounce.h"

// RS-232 configuration
const int CONFIG_SERIAL = 9600;

Adafruit_MCP23008 mcp;

// serial resources
const uint8_t maxMessage = 32;
char cmdData[maxMessage];
char serialMessage[maxMessage];
uint8_t serialMessageEnd = 0;
uint8_t cmdDataEnd = 0;
bool newData = 0;

// PGA2311 resources
#define volumeClockPin         9         // OUTPUT Clock pin for volume control
#define volumeDataPin          8         // OUTPUT Data pin for volume control
#define volumeSelectPin        10        // OUTPUT Select pin for volume control
#define volumeMutePin          11        // OUTPUT Mute pin for the volume control   
byte lastChannelVolume = 0;
byte channelVolume = 0;
bool isMuted = false;

// I/O resources
#define ampPowerPin            12
#define inputBtnPin            7
#define inputIRPin             6
#define powerBtnPin            5
#define muteBtnPin             4
#define inputEncoderA          3
#define inputEncoderB          2

// maximum (byte value) of the volume to send to the PGA2311
// this is here to avoid regions where the high gains has too high S/N
// (192 is 0 dB -- e.g. no gain)
#define maxVolume            192    
#define minVolume              4
#define volumeStep             2
//////////////////////////////////////////////////////////////////////////
// initialization
void setup() {
  mcp.begin(0x27);
  mcp.pinMode(0, OUTPUT);
  mcp.pinMode(1, OUTPUT);
  mcp.pinMode(2, OUTPUT);
  mcp.pinMode(3, OUTPUT);
  mcp.pinMode(4, OUTPUT);
  mcp.pinMode(5, OUTPUT);
  mcp.pinMode(6, OUTPUT);
  mcp.pinMode(7, OUTPUT);
  mcp.digitalWrite(0, LOW); // Aux In Relay (active-high)
  mcp.digitalWrite(1, HIGH); // Trigger R (active-low)
  mcp.digitalWrite(2, HIGH); // Trigger L (active-low)
  mcp.digitalWrite(3, LOW); // TBD Header
  mcp.digitalWrite(4, LOW); // N/C
  mcp.digitalWrite(5, LOW); // 74HC4052 - S0
  mcp.digitalWrite(6, LOW); // 74HC4052 - S1
  mcp.digitalWrite(7, LOW); // Mute Lock (active-high)
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

static inline void byteWrite(byte byteOut){
   for (byte i=0;i<8;i++) {
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

void setVolume(long volume){
   long int r_vol_test;
   byte l_vol=(byte)volume;
   byte r_vol=0;
   l_vol=volume;
   r_vol_test=volume;
   // This test is unlikely to run unless maximumVolume is 255 or very close
   if(r_vol_test>255){
      r_vol=255;
      l_vol=255;
   }
   else if(r_vol_test<0){
     r_vol=0;
     l_vol=0;
   }
   // Business as usual  
   else{
     r_vol=(byte)r_vol_test;
   }
   digitalWrite(volumeSelectPin, LOW);   
   byteWrite(r_vol);                                // Right        
   byteWrite(l_vol);                                // Left
   digitalWrite(volumeSelectPin, HIGH);    
   digitalWrite(volumeClockPin, HIGH);
   digitalWrite(volumeDataPin, HIGH);
}

/*
 * Function to scale volume from one level to another (softer changes for mute)
 */

void scaleVolume(byte startVolume, byte endVolume, byte volumeSteps){
  byte diff;
  long counter;
  if(endVolume==startVolume){
    return;
  }
  if(endVolume>startVolume){
    diff=(endVolume-startVolume)/volumeSteps;
    // Protect against a non-event
    if(diff==0){
      diff=1;
    }
    counter=startVolume;
    while(counter<endVolume){
      setVolume(counter);
      delay(25);  
      counter+=diff;  
    }
    setVolume(endVolume);               
  }  
  else{
    diff=(startVolume-endVolume)/volumeSteps;
    // Protect against a non-event
    if(diff==0){
      diff=1;
    }
    counter=startVolume;
    while(counter>endVolume){
      setVolume(counter);
      delay(25);  
      counter-=diff; 
    }
    setVolume(endVolume);              
  }  
  return;
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
  // execute command
  if (cmdFirstColumn == 0){
    // position of the end of message
    cmdDataEnd = (_end - (_cmd2pos + 1));
    // write to characters to message array
    uint8_t _lcdidx = 0;
    for(uint8_t _idx = _cmd2pos + 1; _idx < _end; _idx++) { 
      //check message data!!!
      cmdData[_lcdidx] = serialMessage[_idx]; 
      if (cmdData[0] == 'A') {
        // optical in #1
        mcp.digitalWrite(6, LOW); // 4052-S1
        mcp.digitalWrite(5, HIGH); // 4052-S0
      }
      if (cmdData[0] == 'B') {
        // optical in #2
        mcp.digitalWrite(6, HIGH); // 4052-S1
        mcp.digitalWrite(5, HIGH); // 4052-S0
      }
      if (cmdData[0] == 'C') {
        // coax input
        mcp.digitalWrite(6, HIGH); // 4052-S1
        mcp.digitalWrite(5, LOW); // 4052-S0 
      }
      if (cmdData[0] == 'D') {
        // DAC input
        mcp.digitalWrite(0, LOW);
      }ec
      if (cmdData[0] == 'E') {
        // Aux input
        mcp.digitalWrite(0, HIGH);
      }               
      if (cmdData[0] == 'F') { 
        // trigger R (pulse)
        mcp.digitalWrite(1, LOW);
        delay(250);
        mcp.digitalWrite(1, HIGH);
      }
      if (cmdData[0] == 'G') {
        // trigger L (pulse)
        mcp.digitalWrite(2, LOW);
        delay(250);
        mcp.digitalWrite(2, HIGH);
      }
      if (cmdData[0] == 'H') {
        // mute lock (ON)
        mcp.digitalWrite(7, HIGH);
      }  
      if (cmdData[0] == 'I') {
        // mute lock (OFF)
        mcp.digitalWrite(7, LOW);
      }  
      if (cmdData[0] == 'X') { 
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
      if (cmdData[0] == 'Y') { 
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
      if (cmdData[0] == 'Z') { 
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
      _lcdidx++; // increment index
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
