// Configuration
const char* CONFIG_SSID      = "phome";
const char* CONFIG_PSK       = "Provenzano383";
const char* HOSTNAME         = "ESP32";
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

// Validate Incoming Data
int base = 10;
char* behind;

// Setup instructions
void setup() {

  // Start serial and LED
  Serial.begin(CONFIG_SERIAL);
  Serial.println();
  Serial.println("Starting setup");
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, 0);

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
  digitalWrite(LED_BUILTIN, 0);
  Serial.println();

}

// Loop instructions
void loop() {

  // Wait for new client
  WiFiClient client = server.available();
  if (client) {

    // New client
    digitalWrite(LED_BUILTIN, 1);
    //Serial.println("New client connected");

    // Wait nicely for the client to complete its full request
    unsigned long timeout = millis() + CONFIG_TIMEOUT;
    //Serial.println("Waiting for client request to finish...");
    while (!client.available() && millis() < timeout) {
      delay(1);
    }

    // End client connection when timeout is reached to not hold up availability
    if (millis() < timeout) {
      //Serial.println("Client request finished!");
    } else {
      Serial.println("Client request timeout!");
      client.flush();
      client.stop();
      digitalWrite(LED_BUILTIN, 0);
      Serial.println();
      return;
    }

    // Catch client request
    String req = client.readStringUntil('\r');
    //Serial.print("Raw request: ");
    //Serial.println(req);
    if (req.indexOf(F("/xmit/")) != -1) {

    // Truncate request string
    String currentLine = req;
    currentLine.remove(0, ((currentLine.lastIndexOf("/xmit/")) + 6));
    currentLine.remove((currentLine.indexOf(" ")));
    //Serial.print("Valid request: ");
    //Serial.println(currentLine);

///////////////////////////////////////////////      
      
// IR Transmit (must be in integer format)
if(currentLine.indexOf("irtx.") >=0)
{
  //Serial.print("IR Transmit\n");
  if(currentLine.indexOf("nec.") >=4)
  {
    // NEC IR Transmit 32-bit
    String ircode = currentLine.substring(9,60);
    //Serial.println("NEC");
    //Serial.println(ircode);
    long longVal = strtol(ircode.c_str(), &behind, base);
    //Serial.println("Result ");
    //Serial.println(longVal, base);
    //Serial.println("\n");
    irsend.sendNEC(longVal, 32);
    delay(30);
  }
  if(currentLine.indexOf("sony20.") >=4)
  {
    // SONY IR Transmit 20-bit
    String ircode = currentLine.substring(12,60);
    //Serial.println("Sony 20-bit");
    //Serial.println(ircode);
    long longVal = strtol(ircode.c_str(), &behind, base);
    //Serial.println("Result ");
    //Serial.println(longVal, base);
    //Serial.println("\n");
    irsend.sendSony(longVal, 20);
    delay(30);
  }
  if(currentLine.indexOf("sony12.") >=4)
  {
    // SONY IR Transmit 12-bit
    String ircode = currentLine.substring(12,60);
    //Serial.println("Sony 12-bit");
    //Serial.println(ircode);
    long longVal = strtol(ircode.c_str(), &behind, base);
    //Serial.println("Result ");
    //Serial.println(longVal, base);
    //Serial.println("\n");
    irsend.sendSony(longVal, 12);
    delay(30);
  }
}

// FET Control
if(currentLine.indexOf("fet.") >=0)
{
  //Serial.print("FET Control\n");
  if(currentLine.indexOf("on.") >=3)
  {
    // FET on
    String fet = currentLine.substring(7,9);
    //Serial.println("FET on");
    //Serial.println(fet);
    //Serial.println("\n");
    digitalWrite(fet.toInt(), HIGH);
    delay(30);
  }
  if(currentLine.indexOf("off.") >=3)
  {
    // FET off
    String fet = currentLine.substring(8,10);
    //Serial.println("FET off");
    //Serial.println(fet);
    //Serial.println("\n");
    digitalWrite(fet.toInt(), LOW);
    delay(30);
  }
}    

// 433MHz RF Control
if(currentLine.indexOf("rftx.") >=0)
{
  String rfcode = currentLine.substring(5,20);
  //Serial.println("RF Transmit");
  //Serial.println(rfcode);
  //Serial.println("\n");
  mySwitch.send(rfcode.toInt(), 24);
  delay(30);
}
        
/////////////////////////////////

 // Send HTTP response
      client.println("HTTP/1.1 200 OK");
      client.println("Content-Type: text/plain");
      client.println("Connection: close");
      client.println();
      client.println("OK");

    } else {

      // Invalid request
      Serial.println("Invalid client request");
      Serial.println("Sending HTTP/1.1 404 response");
      client.println("HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\r\n<html><body>Not found</body></html>");

    }

    // Flush output buffer
    //Serial.println("Flushing output buffer");
    client.flush();
    digitalWrite(LED_BUILTIN, 0);
    Serial.println();
    return;

  }

}
