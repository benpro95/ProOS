/*
 * Ben Provenzano III
 * -----------------
 * v1 09/03/2022
 433MHz Wireless Amplifier Controller
 *
 */
 
// Libraries
#include <Wire.h>
#include <RCSwitch.h>

// Definitions
#define MAX9744_I2CADDR 0x4B    // 0x4B is the default i2c address
RCSwitch mySwitch = RCSwitch(); // 433Mhz receiver

// Constants
const int potPin = A0;          // pin A0 to read analog input
int potThresh = 2;

// Variables
int8_t theVol = 0; 
int8_t theLastVol = 0; 
int potVal = 0;  
int potFinal = 0; 
int lastPotVal = 0;
int changeVol = 0;
unsigned long rfvalue = 0;

void setup() {
// RS232  
  Serial.begin(9600);
  Serial.println("MAX9744 amp controller");
// I2C  
  Wire.begin();
  if (! setvolume(theVol)) {
    Serial.println("Failed to set volume!");
    while (1);
  }
// 433MHz RF   
  delay(500); 
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => that is [pin #2]
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(183);  
}

// Main
void loop() {
  receiveRF();
  readPot();   
  if (changeVol == 1) {
    if (theVol > 63) theVol = 63;
    if (theVol < 0) theVol = 0;
    if (theVol != theLastVol) {
      setvolume(theVol);   
      changeVol = 0;
      theLastVol = theVol;
    }  
  }
}

// write the 6-bit volume to the I2C bus
boolean setvolume(int8_t vol) {
  // cant be higher than 63 or lower than 0
  if (vol > 63) vol = 63;
  if (vol < 0) vol = 0;
  Serial.print("Setting volume to ");
  Serial.println(vol);
  Wire.beginTransmission(MAX9744_I2CADDR);
  Wire.write(vol);
  if (Wire.endTransmission() == 0) 
    return true;
  else
    return false;
}

void readPot() {
    potVal = 0;  
    potFinal = 0; 
    // Read analog value from potentiometer
    potVal = analogRead(potPin);          
    // Map raw values to 2 x 0-63 range 
    potVal = map(potVal, 0, 502, 127, 0);
    // Return value if pot changes more than threshold 
    if(abs(potVal - lastPotVal) >= potThresh){
      potFinal = (potVal/2);       
      lastPotVal = potVal; 
      // Change the volume to the pot value
      theVol = potFinal;
      changeVol = 1;
    }
}

void receiveRF() {
  if (mySwitch.available()) {
    rfvalue = mySwitch.getReceivedValue();
    if (rfvalue == 696912) //
    {
      // Volume Up (Fine)
      theVol++;
      changeVol = 1;
    }  
    if (rfvalue == 696913) //
    {
      // Volume Down (Fine)
      theVol--;
      changeVol = 1;
    } 
    if (rfvalue == 696922) //
    {
      // Volume Up (Semi-Course)
      theVol++;
      theVol++;
      changeVol = 1;  
    }
    if (rfvalue == 696923) //
    {
      // Volume Down (Semi-Course)
      theVol--;
      theVol--;
      changeVol = 1;
    } 
    if (rfvalue == 696932) //
    {
      // Volume Up (Course)
      theVol++;
      theVol++;
      theVol++;
      changeVol = 1;  
    }
    if (rfvalue == 696933) //
    {
      // Volume Down (Course)
      theVol--;
      theVol--;
      theVol--;
      changeVol = 1;
    } 
    if (rfvalue == 696944) //
    {
      // Mute
      theVol = 0;
      changeVol = 1;
    }
    if (rfvalue == 696905) //
    {
      // Set Level (Quietest)
      theVol = 5;
      changeVol = 1;
    }    
    if (rfvalue == 696910) //
    {
      // Set Level
      theVol = 10;
      changeVol = 1;
    }
    if (rfvalue == 696920) //
    {
      // Set Level
      theVol = 20;
      changeVol = 1;
    }
    if (rfvalue == 696930) //
    {
      // Set Level
      theVol = 30;
      changeVol = 1;
    }
    if (rfvalue == 696940) //
    {
      // Set Level
      theVol = 40;
      changeVol = 1;
    }
    if (rfvalue == 696950) //
    {
      // Set Level
      theVol = 50;
      changeVol = 1;
    }
    if (rfvalue == 696999) //
    {
      // Set Level (Loudest)
      theVol = 63;
      changeVol = 1;
    }    
    mySwitch.resetAvailable();
  }
}
