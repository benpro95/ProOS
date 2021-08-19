// Configuration
const char* CONFIG_SSID      = "mach_kernel";
const char* CONFIG_PSK       = "phonics.87.reply.218";
const char* HOSTNAME         = "xmit";
const int   CONFIG_SERIAL    = 115200;
const int   CONFIG_PORT      = 80;
const int   CONFIG_TIMEOUT   = 5000;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Include libraries
#include <Arduino.h>
#include <WiFi.h>
#include <IRremote.h>
#include <RCSwitch.h>

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
long valout;
int base = 10;
char* behind;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Setup instructions
void setup() {

  // Start serial and LED
  Serial.begin(CONFIG_SERIAL);
  Serial.println();
  Serial.println("Starting setup");

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
  Serial.print("Connecting to: ");
  Serial.println(CONFIG_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true);
  WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE);
  WiFi.setHostname(HOSTNAME);
  WiFi.begin(CONFIG_SSID, CONFIG_PSK);

  // Wait for WiFi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("WiFi connected!");
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

  // Print WiFi connection information
  Serial.print("  SSID: ");
  Serial.println(WiFi.SSID());
  Serial.print("  RSSI: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
  Serial.print("  Local IP: ");
  Serial.println(WiFi.localIP());

  // Start webserver
  Serial.println("Starting webserver...");
  server.begin();
  delay(1000);
  Serial.println("Webserver started!");

  // Print webserver information
  Serial.print("  Host: ");
  Serial.println(WiFi.localIP());
  Serial.print("  Port: ");
  Serial.println(CONFIG_PORT);

  // Setup complete
  Serial.println("Setup completed");
  Serial.println();
  digitalWrite(5, 1);

}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

// Loop instructions
void loop() {

  // if WiFi is down, try reconnecting every CHECK_WIFI_TIME seconds
  unsigned long currentMillis = millis();
  if ((WiFi.status() != WL_CONNECTED) && (currentMillis - previousMillis >=interval)) {
    Serial.print(millis());
    Serial.println("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.reconnect();
    previousMillis = currentMillis;
  }  

  // Wait for new client
  WiFiClient client = server.available();
  if (client) {

    // New client
    Serial.println("New client connected");

    // Wait nicely for the client to complete its full request
    unsigned long timeout = millis() + CONFIG_TIMEOUT;
    Serial.println("Waiting for client request to finish...");
    while (!client.available() && millis() < timeout) {
      delay(1);
    }

    // End client connection when timeout is reached to not hold up availability
    if (millis() < timeout) {
      Serial.println("Client request finished!");
    } else {
      Serial.println("Client request timeout!");
      client.flush();
      client.stop();
      Serial.println();
      return;
    }

    // Catch client request
    String req = client.readStringUntil('\r');
    Serial.print("Raw request: ");
    Serial.println(req);
    if (req.indexOf(F("/xmit/")) != -1) {

    // Truncate request string
    String currentLine = req;
    currentLine.remove(0, ((currentLine.lastIndexOf("/xmit/")) + 6));
    currentLine.remove((currentLine.indexOf(" ")));
    Serial.print("Valid request: ");
    Serial.println(currentLine);
    // Turn-on LED when valid request received
    digitalWrite(5, 0);
    
///////////////////////////////////////////////      
      
// IR Transmit (must be in integer format)
if(currentLine.indexOf("irtx.") >=0)
{
  if(currentLine.indexOf("nec.") >=4)
  {
    // NEC IR Transmit 32-bit
    Serial.print("IR NEC\n");
    String code = currentLine.substring(9,21);
    valdata(code);
    irsend.sendNEC(valout, 32);
    delay(30);
  }
  if(currentLine.indexOf("sony20.") >=4)
  {
    // SONY IR Transmit 20-bit
    Serial.print("IR Sony 20-bit\n");
    String code = currentLine.substring(12,24);
    valdata(code);
    irsend.sendSony(valout, 20);
    delay(30);
  }
  if(currentLine.indexOf("sony12.") >=4)
  {
    // SONY IR Transmit 12-bit
    Serial.print("IR Sony 12-bit\n");
    String code = currentLine.substring(12,24);
    valdata(code);
    for (int i = 0; i < 3; i++) {
      irsend.sendSony(valout, 12);
      delay(30);
    }  
  }
}

// FET Control
if(currentLine.indexOf("fet.") >=0)
{
  if(currentLine.indexOf("on.") >=3)
  {
    // FET on
    Serial.print("FET on\n");
    String code = currentLine.substring(7,9);
    valdata(code);
    if (valout == 32 ) {
      digitalWrite(valout, HIGH);
    }
    delay(30);
  }
  if(currentLine.indexOf("off.") >=3)
  {
    // FET off
    Serial.print("FET off\n");
    String code = currentLine.substring(8,10);
    valdata(code);
    if (valout == 32 || valout == 5) {
      digitalWrite(valout, LOW);
    }  
    delay(30);
  }
  if(currentLine.indexOf("tgl.") >=3)
  {
    // FET toggle
    Serial.print("FET toggled\n");
    String code = currentLine.substring(8,10);
    valdata(code);
    if (valout == 32 || valout == 5) {
      digitalWrite(valout, HIGH);
      delay(300);
      digitalWrite(valout, LOW);
    }  
    delay(30);
  }
}    

// 433MHz RF Control
if(currentLine.indexOf("rftx.") >=0)
{
  Serial.print("RF transmit\n");
  String code = currentLine.substring(5,20);
  valdata(code);
  mySwitch.send(valout, 24);
  delay(30);
}
        
/////////////////////////////////

 // Send HTTP response
      client.println("HTTP/1.1 200 OK");
      client.println("Content-Type: text/plain");
      client.println("Connection: close");
      client.println();
      // Turn-off LED when request is finished
      digitalWrite(5, 1);

    } else {

      // Invalid request
      Serial.println("Invalid client request");
      Serial.println("Sending HTTP/1.1 404 response");
      client.println("HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\r\n<html><body>Not found</body></html>");

    }

    // Flush output buffer
    Serial.println("Flushing output buffer");
    client.flush();
    Serial.println();
    return;

  }

}

// Data validation function, converts string to integers
int valdata(String code)
{
  valout = strtol(code.c_str(), &behind, base);
  Serial.print("Validated request: ");
  Serial.println(valout, base);
}

