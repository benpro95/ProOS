 /////////////////////////////////////////////////////////////////////////
// Bedroom Amp Controller with Z-Terminal v1.0
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

#include "encoder.h"
#include "bounce.h"

// RS-232 configuration
const int CONFIG_SERIAL = 9600;

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
long tempChannelVolume = 0;
byte channelVolume = 0;

// control logic resources
#define toggleTV               7
#define enablePin              6
#define inputSelect            5

// maximum (byte value) of the volume to send to the PGA2311
// this is here to avoid regions where the high gains has too high S/N
// (192 is 0 dB -- e.g. no gain)
#define maximumVolume          192    

//////////////////////////////////////////////////////////////////////////
// initialization
void setup() {
  // start serial ports
  Serial.begin(CONFIG_SERIAL);
  pinMode(LED_BUILTIN, OUTPUT);  
  // control logic   
  digitalWrite(LED_BUILTIN, LOW);  
  pinMode(enablePin, OUTPUT);
  pinMode(inputSelect, OUTPUT);  
  pinMode(toggleTV, OUTPUT);
  digitalWrite(enablePin, LOW); 
  digitalWrite(inputSelect, LOW);  
  digitalWrite(toggleTV, LOW);   
  // PGA volume logic
  pinMode(volumeMutePin, OUTPUT);
  digitalWrite(volumeMutePin, LOW);           
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
  digitalWrite(volumeMutePin,HIGH); 
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
    Serial.print("Increasing volume to (byte value) ");
    Serial.println(endVolume);
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
    Serial.print("Diminishing volume to (byte value) ");
    Serial.println(endVolume);
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
