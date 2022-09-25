/// Libraries ///
#include "LiquidCrystal_I2C.h" // modified to support MCP23008 expander chip
#include <IRremote.h>
#include <PCF8574.h>
#include <Wire.h> 

/// Hardware Setup ///
// I2C (0x3E) Volume Reset
// I2C (0x3F) Volume Set
PCF8574 pcf8574_1(0x3E);
PCF8574 pcf8574_2(0x3F);
// I2C (0x27) Display
LiquidCrystal_I2C lcd(0x27);
// IR (pin 8)
int IR_RECEIVE_PIN = 8;
IRrecv IrReceiver(IR_RECEIVE_PIN);

/// Global Variables ///
 bool vBit0;
 bool vBit1;
 bool vBit2;
 bool vBit3;
 bool vBit4;
 bool vBit5;
 bool vBit6;
 bool vBit7;
 bool bitState;
 byte volLevel = 0;

/// Functions ///
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

void volResetBus()
{
  pcf8574_1.digitalWrite(P0, LOW); 
  pcf8574_1.digitalWrite(P1, LOW); 
  pcf8574_1.digitalWrite(P2, LOW); 
  pcf8574_1.digitalWrite(P3, LOW); 
  pcf8574_1.digitalWrite(P4, LOW); 
  pcf8574_1.digitalWrite(P5, LOW); 
  pcf8574_1.digitalWrite(P6, LOW); 
  pcf8574_1.digitalWrite(P7, LOW);
  pcf8574_2.digitalWrite(P0, LOW); 
  pcf8574_2.digitalWrite(P1, LOW); 
  pcf8574_2.digitalWrite(P2, LOW); 
  pcf8574_2.digitalWrite(P3, LOW); 
  pcf8574_2.digitalWrite(P4, LOW); 
  pcf8574_2.digitalWrite(P5, LOW);  
  pcf8574_2.digitalWrite(P6, LOW); 
  pcf8574_2.digitalWrite(P7, LOW); 
}

void volSet()
{
  // Communication setup 
  pcf8574_1.pinMode(P0, OUTPUT); 
  pcf8574_1.pinMode(P1, OUTPUT); 
  pcf8574_1.pinMode(P2, OUTPUT); 
  pcf8574_1.pinMode(P3, OUTPUT); 
  pcf8574_1.pinMode(P4, OUTPUT); 
  pcf8574_1.pinMode(P5, OUTPUT); 
  pcf8574_1.pinMode(P6, OUTPUT); 
  pcf8574_1.pinMode(P7, OUTPUT); 
  pcf8574_2.pinMode(P0, OUTPUT); 
  pcf8574_2.pinMode(P1, OUTPUT); 
  pcf8574_2.pinMode(P2, OUTPUT); 
  pcf8574_2.pinMode(P3, OUTPUT); 
  pcf8574_2.pinMode(P4, OUTPUT); 
  pcf8574_2.pinMode(P5, OUTPUT); 
  pcf8574_2.pinMode(P6, OUTPUT); 
  pcf8574_2.pinMode(P7, OUTPUT); 
  pcf8574_1.begin();
  pcf8574_2.begin();
  // Reset bus state
  volResetBus();
  // Set-reset relays
  for(int bitSel = 0, mask = 1; bitSel < 8; bitSel++, mask = mask << 1)
  {
    // Read state of current bit
    if (volLevel & mask){
      bitState = 1;
    }
    else{
      bitState = 0;
    }
    // Map byte to bits
    if ( bitSel == 0 ){
      vBit0 = bitState;
    }
    if ( bitSel == 1 ){
      vBit1 = bitState;
    }
    if ( bitSel == 2 ){
      vBit2 = bitState;
    }
    if ( bitSel == 3 ){
      vBit3 = bitState;
    }
    if ( bitSel == 4 ){
      vBit4 = bitState;
    }
    if ( bitSel == 5 ){
      vBit5 = bitState;
    }
    if ( bitSel == 6 ){
      vBit6 = bitState;
    }
    if ( bitSel == 7 ){
      vBit7 = bitState;
    }
  } // Reset then set
  pcf8574_1.digitalWrite(P0, !vBit0); 
  pcf8574_1.digitalWrite(P1, !vBit1); 
  pcf8574_1.digitalWrite(P2, !vBit2); 
  pcf8574_1.digitalWrite(P3, !vBit3); 
  pcf8574_1.digitalWrite(P4, !vBit4); 
  pcf8574_1.digitalWrite(P5, !vBit5); 
  pcf8574_1.digitalWrite(P6, !vBit6); 
  pcf8574_1.digitalWrite(P7, !vBit7); 
  pcf8574_2.digitalWrite(P0, vBit0); 
  pcf8574_2.digitalWrite(P1, vBit1); 
  pcf8574_2.digitalWrite(P2, vBit2); 
  pcf8574_2.digitalWrite(P3, vBit3); 
  pcf8574_2.digitalWrite(P4, vBit4); 
  pcf8574_2.digitalWrite(P5, vBit5); 
  pcf8574_2.digitalWrite(P6, vBit6); 
  pcf8574_2.digitalWrite(P7, vBit7);  
  delay(5);
  // Reset bus state
  volResetBus();
}
 

void setup()
{
 Serial.begin(9600);
 delay(100);  

// IR
 IrReceiver.enableIRIn();
 
// Display  
 lcdSetup();
 lcd.setCursor(4,0);
 lcd.print("Startup!");

// Mute volume
 volLevel = 0;
 volSet(); 
}

void loop()
{

  //volDemo();

    if (IrReceiver.decode()) {  // Grab an IR code
        // Check if the buffer overflowed
        if (IrReceiver.results.overflow) {
            Serial.println("IR code too long. Edit IRremoteInt.h and increase RAW_BUFFER_LENGTH");
        } else {
            Serial.println();                               // 2 blank lines between entries
            Serial.println();
            IrReceiver.printIRResultShort(&Serial);
            Serial.println();
            Serial.println(F("Raw result in internal ticks (50 us) - with leading gap"));
            IrReceiver.printIRResultRawFormatted(&Serial, false); // Output the results in RAW format
            Serial.println(F("Raw result in microseconds - with leading gap"));
            IrReceiver.printIRResultRawFormatted(&Serial, true);  // Output the results in RAW format
            Serial.println();                               // blank line between entries
            Serial.println(F("Result as internal ticks (50 us) array - compensated with MARK_EXCESS_MICROS"));
            IrReceiver.compensateAndPrintIRResultAsCArray(&Serial, false);   // Output the results as uint8_t source code array of ticks
            Serial.println(F("Result as microseconds array - compensated with MARK_EXCESS_MICROS"));
            IrReceiver.compensateAndPrintIRResultAsCArray(&Serial, true);    // Output the results as uint16_t source code array of micros
            IrReceiver.printIRResultAsCVariables(&Serial);  // Output address and data as source code variables

            IrReceiver.compensateAndPrintIRResultAsPronto(&Serial);

        }
        IrReceiver.resume();                            // Prepare for the next value
     }
  
}
