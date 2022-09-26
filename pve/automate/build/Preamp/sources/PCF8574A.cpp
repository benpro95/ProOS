// Experiment of PCF8574 IO expander
// Name:- M.Pugazhendi
// Date:-  27thJul2016
// Version:- V0.1
// e-mail:- muthuswamy.pugazhendi@gmail.com

//Include Wire library
#include <Wire.h>

#define DEVICE_1 B0100000
#define DEVICE_2 B0100001

void setup()
{
    Wire.begin();
    IOexpanderWrite(DEVICE_2, 0x0F);
}

void loop()
{
   byte k;
   for(byte i = 0; i<255; i++)
   {
      IOexpanderWrite(DEVICE_1, i);     
      delay(50); 
      k = IOexpanderRead(DEVICE_2);
      delay(50);       
      IOexpanderWrite(DEVICE_2, (k<<4)|0x0F);
      delay(200); 
   }
      
}

//Write a byte to the IO expander

void IOexpanderWrite(byte address, byte _data ) 
{
 Wire.beginTransmission(address);
 Wire.write(_data);
 Wire.endTransmission(); 
}

//Read a byte from the IO expander

byte IOexpanderRead(int address) 
{
 byte _data;
 Wire.requestFrom(address, 1);
 if(Wire.available()) {
   _data = Wire.read();
 }
 return _data;
}