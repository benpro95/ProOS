//////////////////////////////////////////////////////////////////////////
// by Ben Provenzano III
//////////////////////////////////////////////////////////////////////////

// Include libraries
#include <WiFi.h>
#include <RCSwitch.h>
#include "IRremote.h" //v2.9 local

//////////////////////////////////////////////////////////////////////////
// Wi-Fi Configuration
const char* CONFIG_SSID   = "mach_kernel";
const char* CONFIG_PSK    = "phonics.87.reply.218";
const char* HOSTNAME      = "xmit";
const int   CONFIG_SERIAL = 115200;
const int   CONFIG_PORT   = 80;
//////////////////////////////////////////////////////////////////////////

// RTOS Multi-Core Support
TaskHandle_t Task2;

// Shared resources
#define httpBufferSize 256 // HTTP request buffer (bytes)
char httpReq[httpBufferSize] = {'\0'};
uint32_t xmitMessageEnd = 0;
uint32_t xmitMode = 0;
long xmitCommand = 0;
long xmitData = 0;
bool eventXmit = 0;

// Web Server
WiFiServer server(CONFIG_PORT);
char httpHeader[] = {"####?|"}; // API header signature
unsigned long HTTPlastTime = 0; 
unsigned long HTTPcurTime = millis(); 
unsigned long httpLineCount = 0;
unsigned long httpReqCount = 0;
const long timeoutTime = 1500; // HTTP timeout (ms)

// Wi-Fi
unsigned long WiFiDownInterval = 300000; // WiFi reconnect timeout (5-min)
unsigned long WiFiLastMillis = 0;

// GPIO
#define triggerPin 32 // PC power trigger
#define onBoardLED 5 // built-in LED

// Transmits IR on pin #4
IRsend irsend;

// Create RF send object
RCSwitch mySwitch = RCSwitch();

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
  // trigger Out 3.5mm Jack 
  pinMode(triggerPin, OUTPUT);
  digitalWrite(triggerPin, LOW);
  // built-in LED
  pinMode(onBoardLED, OUTPUT);  
  digitalWrite(onBoardLED, LOW);      
  delay(1500); // LED off
  debug("Xmit running on core ");
  debugln(xPortGetCoreID());
  // RF transmit output on pin #19
  mySwitch.enableTransmit(19);
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(315);
  mySwitch.setRepeatTransmit(12);
  digitalWrite(onBoardLED, HIGH);    
  // web server parallel task
  xTaskCreatePinnedToCore(
   WebServer,   /* task function. */
   "Task2",     /* name of task. */
   16384,       /* Stack size of task */
   NULL,        /* parameter of the task */
   2,           /* priority of the task */
   &Task2,      /* Task handle to keep track of created task */
   1);          /* pin task to core 1 */  
  delay(500);
}

//////////////////////////////////////////////////////////////////////////
// parallel task 0
void WebServer( void * pvParameters ){
  //disableCore0WDT(); // disable watchdog on core 0 
  // start serial
  debugstart(CONFIG_SERIAL);
  debug("Web running on core ");
  debugln(xPortGetCoreID());
  // start WiFi connection
  debug("Connecting to: ");
  debugln(CONFIG_SSID);
  int _tryCount = 0;
  while (WiFi.status() != WL_CONNECTED) {
    _tryCount++;
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE);
    WiFi.setHostname(HOSTNAME);
    WiFi.begin(CONFIG_SSID, CONFIG_PSK);
    vTaskDelay( 4000 );
    if ( _tryCount == 10 )
    {
      ESP.restart();
    }
  }
  debugln();
  debugln("WiFi connected!");
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  // Print WiFi connection information
  debug("  SSID: ");
  debugln(WiFi.SSID());
  debug("  RSSI: ");
  debug(WiFi.RSSI());
  debugln(" dBm");
  debug("  Local IP: ");
  debugln(WiFi.localIP());
  debug("  Port: ");
  debugln(CONFIG_PORT);  
  // Start webserver
  debugln("Starting webserver...");
  server.begin();
  delay(1000);
  debugln("Webserver started.");
  // setup done
  for(;;){ //
  ///////////////////
    // if WiFi is down, try reconnecting
    unsigned long WiFiCurMillis = millis();
    if ((WiFi.status() != WL_CONNECTED) && \
     (WiFiCurMillis - WiFiLastMillis >= WiFiDownInterval)) {
      debug(millis());
      debugln("Reconnecting to WiFi...");
      WiFi.disconnect();
      WiFi.reconnect();
      WiFiLastMillis = WiFiCurMillis;
    }  
    // light web server
    webServer();
  }
}

// HTTP request server
void webServer() 
{ // wait for new client
  WiFiClient client = server.available();
  if (client) {
    HTTPcurTime = millis();
    HTTPlastTime = HTTPcurTime;
    debugln("New Client.");                 // print a message out in the serial port              
    char curLine[httpBufferSize] = {'\0'};  // make an array to hold incoming data from the client
    while (client.connected() && HTTPcurTime - HTTPlastTime <= timeoutTime) {
      HTTPcurTime = millis();
      // loop while the client's connected
      if (client.available()) {             // if there's bytes to read from the client,
        char c = client.read();             // read a byte, then
        // add each character to array 
        if (httpReqCount < httpBufferSize && httpReqCount >= 0){
          httpReq[httpReqCount] = c;
          httpReqCount++;
        } else {
          httpReqCount = 0;   
        } // if the byte is a newline character
        if (c == '\n') { 
          // if the current line is blank, you got two newline characters in a row.
          // that's the end of the client HTTP request, send a response:
          if (httpLineCount == 0) {
            // HTTP headers always start with a response code (e.g. HTTP/1.1 200 OK)
            // and a content-type so the client knows what's coming, then a blank line:
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type:text/html");
            client.println("Connection: close");
            client.println();
            // transmit example: (curl http://hostname.home -H "Accept: ####?|mode|command|data")
            debugln("HTTP request");
            for(uint32_t _idx = 0; _idx < httpReqCount; _idx++) {
              char _vchr = httpReq[_idx];    
              debug(_vchr); 
            }
            debugln("");
            // loop through characters (detect header signature)
            uint32_t _matches = 0;
            uint32_t _charstart = 0;            
            uint8_t _hdrcount = sizeof(httpHeader) - 2;
            for(uint32_t _idx = 0; _idx < httpReqCount; _idx++) {
              // find matching characters
              if (httpReq[_idx] == httpHeader[_matches]) {
                if (_matches >= _hdrcount){
                  // pass array start-end positions to message function
                  decodeMessage(_idx + 1, httpReqCount);
                  client.println("command received.");
                  break;
                } // count matches 
                _matches++;
              }  
            }      
            // the HTTP response ends with another blank line
            client.println();
            break; // break out of the while loop
          } else { // if you got a newline, then clear currentLine
            httpLineCount = 0;  
          }
        } else if (c != '\r') {  // if you have anything else but a carriage return character
          // add it to the end of the current line
          if (httpLineCount < httpBufferSize && httpLineCount >= 0){
            curLine[httpLineCount] = c;
            httpLineCount++;
          } else {
            httpLineCount = 0;   
          }
        }
      }
    }
    // reset the HTTP request array index counter
    httpReqCount = 0;
    // close the connection
    client.stop();
    debugln("client disconnected.");
    debugln("");
  } else { // watchdog timer fix!
    delay(10);
  }
}

// decode LCD message and trigger display event
void decodeMessage(uint32_t _startpos, uint32_t _httpcount) {
  if (eventXmit == 1) { 
    for(;;){ // event already running
      delay(2); // wait unit done then process
      if (eventXmit == 0) {
        break;
      }
    }
  }  
  // count delimiters
  char _delimiter = '|'; 
  uint32_t _delims = 0;
  for(uint32_t _idx = _startpos; _idx < _httpcount; _idx++) {
    char _vchr = httpReq[_idx];  
    if (_vchr == _delimiter) {
      _delims++;
    }
  } 
  // exit if all delimiters not found
  debugln(" ");
  if (_delims >= 2){ 
    debugln("processing data...");
  } else {
    debugln("invalid data.");
    return;
  }  
  //////////// start and end positions of control characters & message
  uint8_t _maxchars = 24; // max characters for commands
  uint32_t _linepos = 0;
  // find second delimiter position
  for(uint32_t _idx = _startpos; _idx < _httpcount; _idx++) {  
    char _vchr = httpReq[_idx];  
    if (_vchr == _delimiter) {
      // store index position
      _linepos = _idx;
      break;
    }
  }
  // loop through line characters  
  uint8_t _linecount = 0;
  char _linebuffer[_maxchars];
  for(uint32_t _idx = _startpos; _idx < _linepos; _idx++) {
    if (_linecount >= _maxchars) {
      break;
    } // store in new array
    _linebuffer[_linecount] = httpReq[_idx];
    _linecount++;
  }
  // find third delimiter position
  uint8_t _count = 0;
  uint32_t _cmd2pos = 0; 
  for(uint32_t _idx = _startpos; _idx < _httpcount; _idx++) {
    char _vchr = httpReq[_idx];   
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
  uint32_t _cmd2count = 0;  
  char _cmd2buffer[_maxchars];
  for(uint32_t _idx = _linepos + 1; _idx < _cmd2pos; _idx++) { 
    if (_cmd2count >= _maxchars) {  
      break;
    } // store in new array 
    _cmd2buffer[_cmd2count] = httpReq[_idx];
    _cmd2count++;
  }    
  // convert to integer, store mode
  uint32_t _mode = atoi(_linebuffer); 
  // exit if out of range
  if (_mode > 4) {
    debugln("invalid mode.");
    return;
  } 
  // loop through and write data portion 
  uint32_t _lcdidx = 0;
  char _databuffer[_maxchars];
  for(uint32_t _idx = _cmd2pos + 1; _idx < _httpcount; _idx++) { 
    _databuffer[_lcdidx] = httpReq[_idx]; // write to message array
    _lcdidx++; // increment index
  }
  // convert to integers and write to shared buffer
  xmitMode = _mode;
  xmitData = atol(_databuffer);
  xmitCommand = atol(_cmd2buffer);
  // position of the end of message  
  xmitMessageEnd = (_httpcount - (_cmd2pos + 1)); 
  // trigger event
  eventXmit = 1;
}

void xmitEvent() {
  // IR Transmit
  if (xmitMode == 0) {
    if (xmitCommand == 0) {
      // NEC IR Transmit 32-bit
      debugln("transmitting IR NEC...");
      irsend.sendNEC(xmitData, 32);                  
    }
    if (xmitCommand == 1) {
      // SONY IR Transmit 20-bit
      debugln("transmitting IR Sony 20-bit...");
      irsend.sendSony(xmitData, 20);                    
    }
    if (xmitCommand == 2) {
      // SONY IR Transmit 12-bit
      debugln("transmitting IR Sony 12-bit...");
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(xmitData, 12);
      } 
    }  
  }
  // RF Transmit
  if ((xmitMode == 1) && (xmitCommand == 0)) {
    debugln("transmitting RF...");
    mySwitch.send(xmitData, 24); 
  }
  // GPIO control
  if (xmitMode == 2) {
    // GPIO on
    if (xmitCommand == 0) {
      if ((xmitData == onBoardLED) || (xmitData == triggerPin)) {
        debugln("enabling GPIO pin...");
        digitalWrite(xmitData, HIGH);
      }
    }
    // GPIO off
    if (xmitCommand == 1) {
      if ((xmitData == onBoardLED) || (xmitData == triggerPin)) {
        debugln("disabling GPIO pin...");
        digitalWrite(xmitData, LOW);
      }                
    }
    // GPIO toggle
    if (xmitCommand == 2) {
      if ((xmitData == onBoardLED) || (xmitData == triggerPin)) {
        debugln("toggling GPIO pin...");
        digitalWrite(xmitData, HIGH);
        delay(300);
        digitalWrite(xmitData, LOW);
      }                  
    }
  } 
  debug("Xmit mode: ");
  debugln(xmitMode);
  debug("Xmit command: ");
  debugln(xmitCommand);
  debug("Xmit data: ");
  debugln(xmitData);
}

void loop() {
  if (eventXmit == 1) { 
    delay(10); 
    xmitEvent();
    eventXmit = 0; 
  } else {
    delay(10);  
  }
}