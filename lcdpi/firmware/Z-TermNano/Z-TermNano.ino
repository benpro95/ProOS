 /////////////////////////////////////////////////////////////////////////
// Z-Terminal Firmware v2.1 for Arduino Nano Every
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

// Libraries //
#include <Wire.h>
#include <neotimer.h>
#include "LiquidCrystal_I2C.h" // custom for MCP23008-E/P, button support

// LCD Valid Characters
const char lcdChars[]=
	{" 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ&:',.*|-+=_#@%/[]()<>?{};!"};

// RS-232 Baud Rate
const int CONFIG_SERIAL = 9600;

// Power Control
#define clearButtonPin 5 // on MCP chip
bool clearButton = 0;
bool lastclearButton = 0;
unsigned long clearButtonMillis = 0;
uint8_t debounceDelay = 50; // button debounce delay in ms
uint8_t startDelay = 35; // delay on initial start in seconds

// 16x2 LCD Display
#define lcdAddr 0x27 // I2C address
LiquidCrystal_I2C lcd(lcdAddr);
const uint8_t lcdCols = 16; // number of columns in the LCD
const uint8_t lcdRows = 2;  // number of rows in the LCD
// Custom Characters (progress bar)
uint8_t bar1[8] = {0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10};
uint8_t bar2[8] = {0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18};
uint8_t bar3[8] = {0x1C,0x1C,0x1C,0x1C,0x1C,0x1C,0x1C,0x1C};
uint8_t bar4[8] = {0x1E,0x1E,0x1E,0x1E,0x1E,0x1E,0x1E,0x1E};
uint8_t bar5[8] = {0x1F,0x1F,0x1F,0x1F,0x1F,0x1F,0x1F,0x1F};
#define lcdBacklight 9 // display backlight pin
#define brightnessHigh 255 // normal LCD backlight brightness
#define brightnessLow 128  // dimmed LCD backlight brightness
Neotimer lcdDelayTimer = Neotimer();
Neotimer lcdDimmer = Neotimer(80000); // ms before dimming display backlight
const uint8_t lcdClearCharSpeed = 50; // clearing display scroll speed
uint8_t charBuffer0[20]; // trailing character buffer (row 0)
uint8_t charBuffer1[20]; // trailing character buffer (row 1)
uint8_t chrarSize = 0; // character array size
uint8_t rowCount0 = 0; // collumn count (row 0)
uint8_t rowCount1 = 0; // collumn count (row 1)

// Shared resources
bool eventlcdMessage = 0;
char lcdMessage[maxMessage];
char serialMessage[maxMessage];
const uint8_t maxMessage = 32;
uint8_t lcdAutoBacklight = 0;
uint8_t serialMessageEnd = 0;
uint8_t lcdMessageEnd = 0;
uint32_t lcdDelay = 0;
uint8_t lcdReset = 0;  
bool lcdNoDelay = 0;
bool newData = 0;

//////////////////////////////////////////////////////////////////////////
// Enable Serial Messages (0 = off) (1 = on)
#define DEBUG 0
/////////////////
#if DEBUG == 1
#define debugstart(x) Serial.begin(x)
#define debug(x) Serial.print(x)
#define debugln(x) Serial.println(x)
#else
#define debugstart(x)
#define debug(x)
#define debugln(x)
#endif

//////////////////////////////////////////////////////////////////////////
// initialization
void setup() {
  // built-in LED
  pinMode(LED_BUILTIN, OUTPUT);  
  digitalWrite(LED_BUILTIN, HIGH);    
  // display backlight (low)
  pinMode(lcdBacklight, OUTPUT);  
  analogWrite(lcdBacklight, brightnessHigh);
  // start serial ports
  Serial.begin(CONFIG_SERIAL);
  Serial1.begin(CONFIG_SERIAL);
  // calculate number of characters
  chrarSize = (sizeof(lcdChars)) - 1;  
  // 16x2 display (calls Wire.begin)
  lcd.begin(lcdCols,lcdRows);   
  lcd.createChar(1, bar1);
  lcd.createChar(2, bar2);
  lcd.createChar(3, bar3);
  lcd.createChar(4, bar4);
  lcd.createChar(5, bar5);
  // startup sequence
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Z-Terminal");   
  lcd.setCursor(0,1);
  lcd.print("Starting up...");
  delay(2000);
  lcd.clear();
  lcdTimedBar(startDelay);
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Ready:");
  // startup complete
  digitalWrite(LED_BUILTIN, LOW);   
  analogWrite(lcdBacklight, brightnessLow);
}

// convert message into character stream 
void lcdMessageEvent() { // (run only from event timer)
  uint8_t _charidx;
  uint8_t _end = lcdMessageEnd;
  uint32_t _delay = 0;
  uint8_t _reset = 0;
  lcdMessageEnd = 0;
  debugln("character stream: ");
  // loop through each character in the request array (message only)
  for(uint8_t _idx = 0; _idx < _end; _idx++) { 
    // convert each character into array index positions
    _charidx = (charLookup(lcdMessage[_idx]));
    // read reset state
    _reset = lcdReset;
    // read delay data 
    _delay = lcdDelay;
    charDelay(_delay); // character delay
    drawChar(_charidx,_reset); // draw each character
    debug(_charidx);
    debug(',');
    // stop drawing if request canceled 
    if (eventlcdMessage == 0) {
      break;
    }    
  }
  debugln(' ');
}

// character translate
int charLookup(char _char) {
  int _index;
  for (_index=0; _index <= chrarSize; _index++){
    if (lcdChars[_index] == _char){
      break;
    }
  } // return position 
  return _index;
}

// scroll text on display
void drawChar(uint8_t _char, uint8_t _reset) {
  bool _line = 1; // 1 = text flows bottom to top, 0 = top to bottom
  // clear LCD routine
  if( _reset > 0){
    // disable dimming then reset timer
    if (lcdAutoBacklight == 0) {
      lcdDim();
    }
    // loop through all display characters
    for(uint8_t _count = 0; _count < lcdCols; _count++) { 
      // draw spaces
      if (_reset > 2) {
        // clear both lines 
        lcd.setCursor(_count, 0);
        lcd.write(' ');
        lcd.setCursor(_count, 1);
      } else {
        // clear a single line
        lcd.setCursor(_count, _reset - 1);
      }  
      lcd.write(' ');
      delay(lcdClearCharSpeed);
    } // reset cursor
    lcd.setCursor(0, _line);
    if( _reset == 1){ // reset row 0
      rowCount0 = 0;
    }
    if( _reset == 2){ // reset row 1
      rowCount1 = 0;
    }
    if( _reset == 3){ // reset both rows
      rowCount0 = 0;
      rowCount1 = 0;
    }   
    lcdReset = 0; // end reset event
    eventlcdMessage = 0; // end message event
    return; 
  }
  // invalid characters
  if( _char >= chrarSize){ 
    return;  
  }
   ///////////////////////////////////////////////////////////////////// line 0
  uint8_t _lastidx = 0;
  uint8_t _trlcount;
  // count row position   
  rowCount0++; 
  // drawing behavior
  if( rowCount0 > lcdCols ){ 
    // store last trailing character
    _lastidx = charBuffer0[0];
    // rearrange trailing characters 
    for(uint8_t _idx = 0; _idx <= lcdCols; _idx++) { 
      charBuffer0[_idx] = charBuffer0[_idx + 1];
    }
    // write display output data
    char tmpchr0;
    char datout0[lcdCols + 1]={0}; // temporary array
    for(uint8_t _idx = 0; _idx <= lcdCols - 1; _idx++) { 
      if( _idx == (lcdCols - 1)){
      	tmpchr0 = lcdChars[_char]; // new character 15th
        strncat(datout0, &tmpchr0, 1);
      } else {
      	uint8_t _tmpidx = charBuffer0[_idx]; // 0-14 from buffer
      	tmpchr0 = lcdChars[_tmpidx]; // convert index position
        strncat(datout0, &tmpchr0, 1);
      }
    } // write to display
    lcd.setCursor(0, _line);
    lcd.write(datout0); 
    // lock trailing behavior on after 15th character
    rowCount0 = lcdCols;       
  } else { 
    // before overflow behavior
    if(rowCount0 != 0){ // stops character drawing after clearing display
      lcd.setCursor(rowCount0 - 1, _line);
      lcd.write(lcdChars[_char]);
    }
  }
  // store each character
  charBuffer0[rowCount0 - 1] = _char;
  /////////////////////////////////////////////////////////////////////// line 1     
  _char = _lastidx; // trailing character index from line 0
  _line = !_line; // invert line
  // count row position    
  rowCount1++; 
  // drawing behavior
  if( rowCount1 > lcdCols ){ 
    // overflow behavior
    for(uint8_t _idx = 0; _idx <= lcdCols; _idx++) { 
      charBuffer1[_idx] = charBuffer1[_idx + 1]; // rearrange characters
    }
    // write display output data
    char tmpchr1;
    char datout1[lcdCols + 1]={0}; // temporary array
    for(uint8_t _idx = 0; _idx <= lcdCols - 1; _idx++) { 
      if( _idx == (lcdCols - 1)){
      	tmpchr1 = lcdChars[_char]; // new character 15th
        strncat(datout1,&tmpchr1,1);
      } else {
      	uint8_t _tmpidx = charBuffer1[_idx]; // 0-14 from buffer
      	tmpchr1 = lcdChars[_tmpidx]; // convert index position
        strncat(datout1,&tmpchr1,1);
      }
    } // write to display
    lcd.setCursor(0, _line);
    lcd.write(datout1); 
    // lock trailing behavior on after 15th character
    rowCount1 = lcdCols;       
  } else {
    // before overflow behavior
    if(rowCount1 != 0){ // stops character drawing after clearing display
      lcd.setCursor(rowCount1 - 1, _line);
      lcd.write(lcdChars[_char]);
    }
  }
  // store each character
  charBuffer1[rowCount1 - 1] = _char;
}

// character delay 
void charDelay(uint32_t _delay) {  
  // prevent dimming while drawing
  if (lcdAutoBacklight == 0) {
    lcdDimmer.reset();
    lcdDimmer.start();
  }
  // delay not in range
  if (_delay > 4096) {
    _delay = 5;
  } // no delay enabled
  if (lcdNoDelay == 1) {
    _delay = 0;
    debugln("no delay mode.");
    lcdNoDelay = 0;
  } // restart character delay timer
  lcdDelayTimer.set(_delay);
  lcdDelayTimer.start();
  // keep checking for events during delay
  for(;;) {
    mainEvents(); 
    if(lcdDelayTimer.done()){
      lcdDelayTimer.reset();
      break; // exit loop when timer done
	  }
  }    
}

// display progress bar for # of seconds 
void lcdTimedBar(int _sec) { 
  uint32_t _ms = _sec * 6; 
  uint32_t _colcount;
  uint32_t _segcount;
  uint8_t _line = 0;
  uint8_t _rowcount;
  // draw bar on each row
  for(_rowcount = 0; _rowcount < 2; _rowcount++) {
  	// draw bar on each collumn
    for(_colcount = 0; _colcount < lcdCols; _colcount++) {
      // draw bar segments	
      for(_segcount = 0; _segcount < 5; _segcount++) { 	
        lcd.setCursor(_colcount,_line);
        // draw custom segment 
        lcd.write(_segcount + 1);
        delay(_ms);
      }    
    } // increment to next row
    _line++;
  }
}  

// clear display button
void readClearButton() {
  // read pin state from MCP23008 //////////////////
  bool reading = lcd.readPin(clearButtonPin);
  // if switch changed
  if (reading != lastclearButton) {
    // reset the debouncing timer
    clearButtonMillis = millis();
  }
  if ((millis() - clearButtonMillis) > debounceDelay) {
    // if button state has changed
    if (reading != clearButton) {
      clearButton = reading;
      // button change event
      if (clearButton == 1) { 
        // clear both lines
        lcdReset = 3; 
      }
    } 
  }
  lastclearButton = reading; 
}

void readSerial() {
  static bool recvInProgress = 0;
  static uint8_t ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;
  if (Serial1.available() > 0 && newData == 0) {
    rc = Serial1.read();
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

// decode LCD message and trigger display event
void decodeMessage() {
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
    debugln("invalid data.");
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
  uint8_t _cmd1 = atoi(_linebuffer); 
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
  // loop through second command characters
  char _cmd2buffer[_maxchars + 1];
  uint8_t _cmd2count = 0;  
  for(uint8_t _idx = _linepos + 1; _idx < _cmd2pos; _idx++) { 
    if (_cmd2count >= _maxchars) {  
      break;
    } // store in new array 
    _cmd2buffer[_cmd2count] = serialMessage[_idx];
    _cmd2count++;
  } // add null character to end
  _cmd2buffer[_cmd2count] = '\0';
  // convert to integer, store second command value
  uint32_t _cmd2 = atoi(_cmd2buffer);
  // auto or manual brightness
  if (_cmd1 == 5) { 
    if (_cmd2 < 3) { 
      lcdAutoBacklight = _cmd2;
    }
    return;
  }
  // delay between drawing characters in (ms)
  if (_cmd1 == 4) { 
    lcdDelay = _cmd2;
    return;
  }
  // clear display trigger (1-3 range)
  if (_cmd1 > 0 && _cmd1 < 4) {
    // write clear trigger
    lcdReset = _cmd1;
    return;
  }
  // write message when event is not running and line command is 0
  if ((eventlcdMessage == 0) && (_cmd1 == 0)){
    // position of the end of message
    lcdMessageEnd = (_end - (_cmd2pos + 1));
    // write to characters to message array
    uint8_t _lcdidx = 0;
    for(uint8_t _idx = _cmd2pos + 1; _idx < _end; _idx++) { 
      lcdMessage[_lcdidx] = serialMessage[_idx]; 
      _lcdidx++; // increment index
    }
    // enable no delay mode (single character)
    if (_cmd2 == 0) {
      lcdNoDelay = 1;
    }
    // trigger event
    eventlcdMessage = 1;
  }
}

// disable LCD dimming then start dimming timer
void lcdDim(){
  lcdDimmer.reset();
  // enable full brightness
  analogWrite(lcdBacklight, brightnessHigh);
  // start dimming timer
  lcdDimmer.start();
}

void mainEvents() {
  // read GPIO button
  readClearButton();
  // read serial port data
  readSerial();
  // display dim event
  if (lcdAutoBacklight == 0) {
    if(lcdDimmer.done()){
    	debugln("dimming backlight...");
      analogWrite(lcdBacklight, brightnessLow);
      lcdDimmer.reset();
    }
  }
  if (lcdAutoBacklight == 1) {
    analogWrite(lcdBacklight, brightnessLow);
  }
  if (lcdAutoBacklight == 2) {
    analogWrite(lcdBacklight, brightnessHigh);
  } 
}

void loop() {
  // main LCD message event
  if (eventlcdMessage == 1) {
    digitalWrite(LED_BUILTIN, HIGH);
    // LCD backlight dimming
    if (lcdAutoBacklight == 0) {
      lcdDim();
    }
    lcdMessageEvent();
    eventlcdMessage = 0;
    // send ack to computer
	  Serial1.println('*');
    digitalWrite(LED_BUILTIN, LOW);
  }
  // clear display event
  if( lcdReset > 0) {
    digitalWrite(LED_BUILTIN, HIGH);
    drawChar(0,lcdReset);
    digitalWrite(LED_BUILTIN, LOW);
  }
  // ran in main and during delay loop 
  mainEvents();
}







