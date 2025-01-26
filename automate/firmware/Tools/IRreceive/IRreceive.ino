// IR Decoder v1.0 
// by Ben Provenzano III
// 09/28/2022

// Libraries //
#include <IRremote.hpp> // v3+

// IR In
int IRpin = 2;


// reverse byte function 
int reverseByte(uint8_t _inByte) 
{
  uint8_t _revByte;
  for (int _revBit = 0; _revBit < 8; _revBit++) {
    if (bitRead(_inByte, _revBit) == 1) {
      bitWrite(_revByte, (7 - _revBit), 1);
    } else {
      bitWrite(_revByte, (7 - _revBit), 0);
    }
  }
  return _revByte;
}


// receive IR
void irReceive() 
{
    if (IrReceiver.decode()) {
  	  // status on LED
  	  digitalWrite(LED_BUILTIN, HIGH);
      // display IR codes on terminal   
      Serial.println("--------------"); 	
      if (IrReceiver.decodedIRData.protocol == UNKNOWN) {
        IrReceiver.printIRResultRawFormatted(&Serial, true);	
      } else {
        IrReceiver.printIRResultMinimal(&Serial);	
      }  
      Serial.println("--------------"); 
      // store received IR code (v3 format)
      uint32_t irrecv = IrReceiver.decodedIRData.decodedRawData;
      uint32_t irtype = IrReceiver.decodedIRData.protocol;
      // display v3 format codes
      Serial.print(F("Ready to receive IR signals of protocols: "));
      printActiveIRProtocols(&Serial);
      Serial.print("IR protocol: "); 
      Serial.println(irtype);       
      int32_t irrecv_2s = -irrecv;
      irrecv_2s = irrecv_2s * -1;
      Serial.print("IR v3 decimal: "); 
      Serial.println(irrecv, DEC); 
      Serial.print("IR v3 (2's-compliment) decimal: "); 
      Serial.println(irrecv_2s, DEC);  
      Serial.print("IR v3 hex: "); 
      Serial.println(irrecv, HEX); 
      // convert 32-bit code into 4 seperate bytes (pointer)
      uint8_t *irbyte = (uint8_t*)&irrecv;
      Serial.print("IR v3 address: "); 
      Serial.println(irbyte[3], HEX); 
      Serial.print("IR v3 command: "); 
      Serial.println(irbyte[2], HEX); 
      Serial.println("--------------"); 
      // reverse each byte (v3 format to v2 format)
      uint8_t irbyte0 = reverseByte(irbyte[0]); 
      uint8_t irbyte1 = reverseByte(irbyte[1]); 
      uint8_t irbyte2 = reverseByte(irbyte[2]); 
      uint8_t irbyte3 = reverseByte(irbyte[3]); 
      // assemble 4 reversed bytes into 32-bit code
      uint32_t irv2 = irbyte0; // shift in the first byte
      irv2 = irv2 * 256 + irbyte1; // shift in the second byte
      irv2 = irv2 * 256 + irbyte2; // shift in the third byte
      irv2 = irv2 * 256 + irbyte3; // shift in the last byte
      // display v2 format codes
      int32_t irv2_2s = -irv2;
      irv2_2s = irv2_2s * -1;
      Serial.print("IR v2 decimal: "); 
      Serial.println(irv2, DEC); 
      Serial.print("IR v2 (2's-compliment) decimal: "); 
      Serial.println(irv2_2s, DEC);  
      Serial.print("IR v2 hex: "); 
      Serial.println(irv2, HEX);
      Serial.println(" "); 
      Serial.println("v2 2's-comp is used by Automate/Xmit");
      Serial.println("ignore decimal values with Sony codes, use hex");
      Serial.println(" ");
      // resume receiving 
      IrReceiver.resume();      
      digitalWrite(LED_BUILTIN, LOW);     
    }
}


// initialization 
void setup() 
{ 	
  // IR remote
  IrReceiver.begin(IRpin);  
  // serial support
  Serial.begin(9600);
}


// superloop
void loop()
{
  // IR remote
  irReceive();	  
}
