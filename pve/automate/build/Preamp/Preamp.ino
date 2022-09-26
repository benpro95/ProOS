/// Libraries ///
#include <Arduino.h>
#include "LiquidCrystal_I2C.h" // modified to support MCP23008 expander chip
#include <IRremote.hpp>

#include <Wire.h> 

// I2C (0x3E) Volume Reset
// I2C (0x3F) Volume Set
#define volResetAddr 0x3E
#define volSetAddr 0x3F
// I2C (0x27) Display
LiquidCrystal_I2C lcd(0x27);
// IR (pin 8)
int receive_pin = 8;
bool irCodeScan = 0;

// Input selector stuff
int selectedInput = 0;
long muteDelay = 1000;

// Relay attenuator stuff
bool muteEnabled = false;
byte lastAttenuatorLevel;
byte volLevel = 0;

// System stuff
unsigned long timeOfLastOperation;


void volDemo()
{
  Serial.print("Please enter volume: ");
  while (Serial.available() == 0) {
  }
  int inputchar = Serial.parseInt();
  if ( inputchar != 0 )
  {
    volLevel = inputchar;
    Serial.println(volLevel);
    volSet(); 
    lcdSetup();
    lcd.setCursor(0,0);
    lcd.print(inputchar);
    delay(500); 
    lcdSetup();
    lcd.setCursor(0,0);
    lcd.print("Ben Provenzano");
  }
}

void lcdSetup()
{
  // 16x2 display module
  lcd.begin(16,2);
  lcd.backlight();
  lcd.clear();
}

void IOexpanderWrite(byte address, byte _data ) 
{
 Wire.beginTransmission(address);
 Wire.write(_data);
 Wire.endTransmission(); 
}

byte IOexpanderRead(int address) 
{
 byte _data;
 Wire.requestFrom(address, 1);
 if(Wire.available()) {
   _data = Wire.read();
 }
 return _data;
}

// Function to set a specific attenuator level
int setAttenuatorLevel (byte level) {
  muteEnabled = false;
  IOexpanderWrite(volResetAddr, ~level);
  IOexpanderWrite(volSetAddr, level);
  delay(5);
  IOexpanderWrite(volSetAddr, B00000000);
  IOexpanderWrite(volResetAddr, B00000000);
}

void volSet()
{
  setAttenuatorLevel(volLevel);
}


void irReceive() 
{
  if (IrReceiver.decode()) {
    // Display IR codes on terminal
    if (irCodeScan == 1) {   
      if (IrReceiver.decodedIRData.protocol == UNKNOWN) {
        IrReceiver.printIRResultRawFormatted(&Serial, true);
      }
        IrReceiver.printIRResultMinimal(&Serial);
      }
     
    if (IrReceiver.decodedIRData.address == 0xCE) {
      if (IrReceiver.decodedIRData.command == 0xC) {
        volLevel = volLevel - 1;
        volSet(); 
        lcdSetup();
        lcd.setCursor(0,0);
        lcd.print(volLevel); 
      } else if (IrReceiver.decodedIRData.command == 0xA) {
        volLevel = volLevel + 1;
        volSet(); 
        lcdSetup();
        lcd.setCursor(0,0);
        lcd.print(volLevel); 
      }
     IrReceiver.resume();  
    }
  }
}


void setup()
{
Serial.begin(9600);
delay(100);  

// IR
IrReceiver.begin(receive_pin);
 
// Display  
lcdSetup();
lcd.setCursor(4,0);
lcd.print("Startup!");

// I2C
Wire.begin(); 
IOexpanderWrite(volResetAddr, B00000000);
IOexpanderWrite(volSetAddr, B00000000);

// Mute volume
volLevel = 0;
volSet(); 

delay(500);
}

void loop()
{

irReceive(); 
// volDemo();
  
}
