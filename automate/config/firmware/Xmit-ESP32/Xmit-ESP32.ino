// Configuration
const char* CONFIG_SSID      = "mach_kernel";
const char* CONFIG_PSK       = "phonics.87.reply.218";
const char* HOSTNAME         = "xmit";
const int   CONFIG_SERIAL    = 115200;
const int   CONFIG_PORT      = 80;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Include libraries
#include <Arduino.h>
#include <WiFi.h>
#include "IRremote.h" //v2.9 local
#include <RCSwitch.h>

// Enable Serial Messages (0 disable)
#define DEBUG 0

#if DEBUG == 1
#define debugstart(x) Serial.begin(x)
#define debug(x) Serial.print(x)
#define debugln(x) Serial.println(x)
#else
#define debugstart(x)
#define debug(x)
#define debugln(x)
#endif

// Create webserver object
WiFiServer server(CONFIG_PORT);

// Create IR send object
// Transmits on pin #4
IRsend irsend;

// Create RF send object
RCSwitch mySwitch = RCSwitch();

// WiFi Constants
unsigned long previousMillis = 0;
unsigned long interval = 30000;
// Validate Constants
long intout;
int base = 10;
char* behind;

// Variables to store the HTTP request
String req;
String req_trunc;

// Current time
unsigned long currentTime = millis();
// Previous time
unsigned long previousTime = 0;        
// Define timeout time in milliseconds
const long timeoutTime = 2000;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Setup instructions
void setup() {

  // Start serial and LED
  debugstart(CONFIG_SERIAL);
  debugln();
  debugln("Starting setup");

  // Trigger Out 3.5mm Jack 
  pinMode(32, OUTPUT);
  digitalWrite(32, 0);

  // Built-in LED (turn-on, active low)
  pinMode(5, OUTPUT);
  digitalWrite(5, 0);

  // RF transmit output on pin #19
  mySwitch.enableTransmit(19);
  mySwitch.setPulseLength(183);
  mySwitch.setProtocol(1);
  //mySwitch.setRepeatTransmit(3);
  delay(500);

  // Start WiFi connection
  debug("Connecting to: ");
  debugln(CONFIG_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true);
  WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE);
  WiFi.setHostname(HOSTNAME);
  WiFi.begin(CONFIG_SSID, CONFIG_PSK);

  // Wait for WiFi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    debug(".");
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

  // Start webserver
  debugln("Starting webserver...");
  server.begin();
  delay(1000);
  debugln("Webserver started!");

  // Print webserver information
  debug("  Host: ");
  debugln(WiFi.localIP());
  debug("  Port: ");
  debugln(CONFIG_PORT);

  // Setup complete
  debugln("Setup completed");
  debugln();
  digitalWrite(5, 1);

}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Loop instructions
void loop() {

  // if WiFi is down, try reconnecting every CHECK_WIFI_TIME seconds
  unsigned long currentMillis = millis();
  if ((WiFi.status() != WL_CONNECTED) && (currentMillis - previousMillis >=interval)) {
    debug(millis());
    debugln("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.reconnect();
    previousMillis = currentMillis;
  }  

  // Wait for new client
  WiFiClient client = server.available();
  if (client) {

    currentTime = millis();
    previousTime = currentTime;
    debugln("New Client.");                 // print a message out in the serial port
    String currentLine = "";                // make a String to hold incoming data from the client
    while (client.connected() && currentTime - previousTime <= timeoutTime) {
      currentTime = millis();
      // loop while the client's connected
      if (client.available()) {             // if there's bytes to read from the client,
        char c = client.read();             // read a byte, then
        debug(c);                           // print it out the serial monitor
        req += c;
        if (c == '\n') {                    // if the byte is a newline character
          // if the current line is blank, you got two newline characters in a row.
          // that's the end of the client HTTP request, so send a response:
          if (currentLine.length() == 0) {
            // HTTP headers always start with a response code (e.g. HTTP/1.1 200 OK)
            // and a content-type so the client knows what's coming, then a blank line:
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type:text/html");
            client.println("Connection: close");
            client.println();

             // Only process a xmit request  
             if (req.indexOf(F("/xmit/")) != -1) {

              // Truncate request string
              String req_trunc = req;
              req_trunc.remove(0, ((req_trunc.lastIndexOf("/xmit/")) + 6));
              req_trunc.remove((req_trunc.indexOf(" ")));
              debug("Valid request: ");
              debugln(req_trunc);
              
              ///////////////////////////////////////////////      
                    
              // IR Transmit (must be in integer format)
              if(req_trunc.indexOf("irtx.") >=0)
              {
                if(req_trunc.indexOf("nec.") >=4)
                {
                  // NEC IR Transmit 32-bit
                  debug("IR NEC\n");
                  req_trunc = req_trunc.substring(9,21);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                   irsend.sendNEC(intout, 32);
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;                     
                }
                if(req_trunc.indexOf("sony20.") >=4)
                {
                  // SONY IR Transmit 20-bit
                  debug("IR Sony 20-bit\n");
                  req_trunc = req_trunc.substring(12,24);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                   irsend.sendSony(intout, 20);
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;                     
                }
                if(req_trunc.indexOf("sony12.") >=4)
                {
                  // SONY IR Transmit 12-bit
                  debug("IR Sony 12-bit\n");
                  req_trunc = req_trunc.substring(12,24);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                  for (int i = 0; i < 3; i++) {
                    irsend.sendSony(intout, 12);
                  }
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;   
                }  
              }

              // FET Control
              if(req_trunc.indexOf("fet.") >=0)
              {
                if(req_trunc.indexOf("on.") >=3)
                {
                  // FET on
                  debug("FET on\n");
                  req_trunc = req_trunc.substring(7,9);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                  if (intout == 32 ) {
                    digitalWrite(intout, HIGH);
                  }
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;   
                }
                if(req_trunc.indexOf("off.") >=3)
                {
                  // FET off
                  debug("FET off\n");
                  req_trunc = req_trunc.substring(8,10);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                  if (intout == 32 || intout == 5) {
                    digitalWrite(intout, LOW);
                  }  
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;                     
                }
                if(req_trunc.indexOf("tgl.") >=3)
                {
                  // FET toggle
                  debug("FET toggled\n");
                  req_trunc = req_trunc.substring(8,10);
                  intout = strtol(req_trunc.c_str(), &behind, base);
                  if (intout == 32 || intout == 5) {
                    digitalWrite(intout, HIGH);
                    delay(300);
                    digitalWrite(intout, LOW);
                  }  
                  delay(30);
                  intout = 0;
                  behind = 0;
                  base = 10;                  
                }
              }    

              // 433MHz RF Control
              if(req_trunc.indexOf("rftx.") >=0)
              {
                debug("RF transmit\n");
                req_trunc = req_trunc.substring(5,20);
                intout = strtol(req_trunc.c_str(), &behind, base);
                 mySwitch.send(intout, 24);
                delay(30);
                intout = 0;
                behind = 0;
                base = 10;
              }
                
              req_trunc = "";
              ///////////////////////////////////////////////                    
            }            
            // The HTTP response ends with another blank line
            client.println();
            
            // Break out of the while loop
            break;
          } else { // if you got a newline, then clear currentLine
            currentLine = "";
          }
        } else if (c != '\r') {  // if you got anything else but a carriage return character,
          currentLine += c;      // add it to the end of the currentLine
        }
      }
    }
    // Clear the request variable
    req = "";
    // Close the connection
    client.stop();
    debugln("Client disconnected.");
    debugln("");
  }
}
