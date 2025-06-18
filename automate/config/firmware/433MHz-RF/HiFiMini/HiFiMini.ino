/*
 * Ben Provenzano III
 * -----------------
 * v1 09/03/2022
 * v2 10/12/2024
 433MHz Wireless Amplifier Controller
 *
 */

#include <Wire.h>
#include <RCSwitch.h>
#include <BlockNot.h>

#define MAX9744_I2CADDR 0x4B    // 0x4B is the default I2C address
RCSwitch mySwitch = RCSwitch(); // 433MHz receiver
BlockNot RFLockout(400, MILLISECONDS);  // deadtime between receiving RF commands
bool RFLock = 0; // RF lock flag
const int potPin = A0; // pin A0 to read analog input
unsigned long rfvalue = 0; // direct RF sensor reading
int maxByte = 63; // maximum volume to I2C 
int maxRange = 512; // maximum volume value
int theVol = 0; // current volume value
int theLastVol = 0; // last saved volume value
int potThresh = 20; // potentiometer update threshhold
int potMaxRange = 502; // maximum potentiometer value
int potVal = 0; // direct potentiometer value
int potFinal = 0; // potentiometer value after settling
int lastPotVal = 0; // last saved potentiometer value
bool changeVol = 0; // trigger volume update
bool vMute = 0; // mute enable/disable flag
int volFine = 10; // RF control fine volume increment
int volSemiCourse = 30; // RF control semi-course volume increment
int volCourse = 50; // RF control course volume increment
int storedVol = 0; // volume before muting enabled

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
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => [pin #2]
}

// Main
void loop() {
  receiveRF();
  readPot();   
  if (changeVol == 1) {
    if (theVol > maxRange) theVol = maxRange;
    if (theVol < 0) theVol = 0;
    if (theVol != theLastVol) {
      Serial.print("Volume range: ");
      Serial.println(theVol);
      unsigned long _vol = map(theVol, maxRange, 0, maxByte, 0);
      setvolume(_vol);   
      changeVol = 0;
      theLastVol = theVol;
    }  
  }
}

// write the 6-bit volume to the I2C bus
boolean setvolume(int8_t vol) {
  // cant be higher than 63 or lower than 0
  if (vol > maxByte) vol = maxByte;
  if (vol < 0) vol = 0;
  Serial.print("Setting volume to ");
  Serial.println(vol);
  Serial.println("-----------");
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
    // Map raw values to 0-512 range
    potVal = map(potVal, 0, potMaxRange, (maxRange * 2), 0);
    // Return value if pot changes more than threshold 
    if(abs(potVal - lastPotVal) >= potThresh){
      potFinal = (potVal/2);       
      lastPotVal = potVal; 
      // Change the volume to the pot value
      theVol = potFinal;
      if (vMute == 0) {
        changeVol = 1;
      }    
    }
}

void setRFLock() {
  RFLockout.RESET; 
  RFLock = 1;
}

void receiveRF() {
  if (RFLockout.FIRST_TRIGGER) {
    RFLock = 0;
  }
  if (mySwitch.available()) {
    rfvalue = mySwitch.getReceivedValue();
    if (RFLock == 0) {
      if (rfvalue == 696912) //
      {
        // Volume Up (Fine)
        theVol = theVol + volFine;
        changeVol = 1;
        setRFLock();
      }  
      if (rfvalue == 696913) //
      {
        // Volume Down (Fine)
        theVol = theVol - volFine;
        changeVol = 1;
        setRFLock();
      } 
      if (rfvalue == 696922) //
      {
        // Volume Up (Semi-Course)
        theVol = theVol + volSemiCourse;
        changeVol = 1;  
        setRFLock();
      }
      if (rfvalue == 696923) //
      {
        // Volume Down (Semi-Course)
        theVol = theVol - volSemiCourse;
        changeVol = 1;
        setRFLock();
      } 
      if (rfvalue == 696932) //
      {
        // Volume Up (Course)
        theVol = theVol + volCourse;
        changeVol = 1;
        setRFLock();
      }
      if (rfvalue == 696933) //
      {
        // Volume Down (Course)
        theVol = theVol - volCourse;
        changeVol = 1;
        setRFLock();
      } 
      if (rfvalue == 696905) //
      {
        // Set Level (Quietest)
        theVol = 50;
        changeVol = 1;
        setRFLock();
      }    
      if (rfvalue == 696910) //
      {
        // Set Level
        theVol = 100;
        changeVol = 1;
        setRFLock();
      }
      if (rfvalue == 696920) //
      {
        // Set Level
        theVol = 200;
        changeVol = 1;
        setRFLock();
      }
      if (rfvalue == 696930) //
      {
        // Set Level
        theVol = 300;
        changeVol = 1;
        setRFLock();
      }
      if (rfvalue == 696940) //
      {
        // Set Level
        theVol = 400;
        changeVol = 1;
        setRFLock();
      }
      if (rfvalue == 696997) //
      {
        // Set Level (Loudest)
        theVol = 500;
        changeVol = 1;
        setRFLock();
      }
      // Mute
      if (vMute == 1) {
        changeVol = 0;
      }     
      if (rfvalue == 696999) // unmute
      { 
        if (vMute == 1) {
          theVol = storedVol;
          theLastVol = -1;
          vMute = 0;
          changeVol = 1;
        }
        setRFLock();
      }    
      if (rfvalue == 696944) // mute
      { 
        if (vMute == 0) {
          vMute = 1;
          storedVol = theVol;
          theVol = 0;
          changeVol = 1;
        }
        setRFLock();
      }
    } 
    mySwitch.resetAvailable();
  }
}
