// Xmit Transmitter v1.1 by Ben Provenzano III
// Communicates over serial interface 9600 baud
// last modified on 5/29/20

#define fet2 5
#define fet0 6
#define fet1 7

// IR Out Pin #2 on Uno / Pin #13 on Micro
#include <IRremote.h>
IRsend irsend;

#include <RCSwitch.h>
RCSwitch mySwitch = RCSwitch();

// AC Power
unsigned int sendbuf1[] = {8400,4100, 550,1550, 600,1500, 600,1500, 600,500, 550,1550, 550,500, 550,1550, 550,1550, 550,4150, 550,1550, 550,1550, 550,500, 550,1550, 550,500, 550,500, 550,500, 600,500, 600};

// AC Temp Up
unsigned int sendbuf2[] = {8400,4100, 550,1550, 550,1550, 550,1550, 550,500, 600,1500, 600,500, 550,1550, 550,1550, 550,4100, 600,450, 600,500, 550,500, 550,1550, 550,500, 550,500, 550,500, 600,500, 600};

// AC Temp Down
unsigned int sendbuf3[] = {8400,4100, 550,1550, 550,1550, 550,1550, 550,500, 550,1550, 550,500, 600,1550, 550,1550, 550,4100, 550,1550, 550,500, 600,500, 550,1550, 550,500, 550,500, 550,500, 550,500, 650};

// AC Fan Up Button
unsigned int sendbuf4[] = {8350,4150, 550,1550, 550,1550, 550,1550, 550,500, 550,1550, 550,500, 550,1550, 550,1550, 600,4100, 550,1550, 550,500, 550,1550, 550,500, 600,500, 550,500, 550,500, 550,500, 650};

// AC Fan Down Button
unsigned int sendbuf5[] = {8400,4100, 550,1550, 550,1550, 550,1550, 550,500, 600,1500, 600,500, 550,1550, 550,1550, 550,4100, 600,450, 600,500, 550,1550, 550,500, 550,500, 550,500, 550,500, 600,500, 600};

// AC Mode Button
unsigned int sendbuf6[] = {8400,4100, 550,1550, 550,1550, 550,1550, 550,500, 600,1500, 600,500, 550,1550, 550,1550, 550,4100, 600,1500, 600,1500, 600,500, 550,500, 550,500, 550,500, 550,500, 600,450, 650};


String readString;

void setup() {
  Serial.begin(9600);
  // FET-2 Pin #5 (Internal Fan)
  pinMode(fet2, OUTPUT);
  digitalWrite(fet2,LOW);
  // FET-0 Pin #6 (Main Light)
  pinMode(fet0, OUTPUT);
  digitalWrite(fet0,LOW);
  // FET-1 Pin #7 (Network Switch)
  pinMode(fet1, OUTPUT);
  digitalWrite(fet1,HIGH);
  // 433MHz Transmitter Pin #10
  mySwitch.enableTransmit(10);
  mySwitch.setPulseLength(183);
  mySwitch.setProtocol(1);
  //mySwitch.setRepeatTransmit(3);
}

void loop() {

  while (Serial.available()) {
    delay(3); 
    char c = Serial.read();
    readString += c;
  }

  if (readString.length() >0) {
    Serial.println(readString);

//////////////////

    if(readString.indexOf("init") >=0)
    {
      Serial.print("IR-Xmit.");
      delay(30);
    }

// HiFi Preamp v4 'Sony RMT-B118A Remote'

    if(readString.indexOf("pwrhifi") >=0)
    {
      irsend.sendSony(0xA8B47, 20); // Power
      delay(30);
    }

    if(readString.indexOf("dac") >=0)
    {
      irsend.sendSony(0xB47, 20); // Key 1
      delay(30);
    }

    if(readString.indexOf("aux") >=0)
    {
      irsend.sendSony(0x80B47, 20); // Key 2
      delay(30);
    }

    if(readString.indexOf("phono") >=0)
    {
      irsend.sendSony(0x40B47, 20); // Key 3
      delay(30);
    }    

    if(readString.indexOf("mute") >=0)
    {
      irsend.sendSony(0x18B47, 20); // Key Stop
      delay(30);
    }

    if(readString.indexOf("dwnf") >=0)
    {
      irsend.sendSony(0xD8B47, 20); // Key Rewind
      delay(30);
    }

    if(readString.indexOf("upf") >=0)
    {
      irsend.sendSony(0x38B47, 20); // Key Forward
      delay(30);
    }

    if(readString.indexOf("dwnc") >=0)
    {
      irsend.sendSony(0x5CB47, 20); // Key Down
      delay(30);
    }
    
    if(readString.indexOf("upc") >=0)
    {
      irsend.sendSony(0x9CB47, 20); // Key Up
      delay(30);
    }

    if(readString.indexOf("preleft") >=0)
    {
      irsend.sendSony(0xDCB47, 20); // Key Left
      delay(30);
    }
    
    if(readString.indexOf("preright") >=0)
    {
      irsend.sendSony(0x3CB47, 20); // Key Right
      delay(30);
    }
    
    if(readString.indexOf("display") >=0)
    {
      irsend.sendSony(0x82B47, 20); // Key Display
      delay(30);
    }
    
    if(readString.indexOf("backlight") >=0)
    {
      irsend.sendSony(0xC6B47, 20); // Key Backlight
      delay(30);
    }

    if(readString.indexOf("menu") >=0)
    {
      irsend.sendSony(0x94B47, 20); // Key Menu
      delay(30);
    }
    
///  Sony BRAVIA TV

    if(readString.indexOf("pwrtv") >=0)
    {
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xA90, 12); // Key Power
        delay(30);
      }
    }

    if(readString.indexOf("tvvolup") >=0)
    {
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(0x490, 12); // TV Volume Up
        delay(30);
      }
    }

    if(readString.indexOf("tvvoldwn") >=0)
    {
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xC90, 12); // TV Volume Down
        delay(30);
      }
    }    

    if(readString.indexOf("hdmi1") >=0)
    {
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(0x70, 12); // Home
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xAF0, 12); // Down
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xA70, 12); // Ok
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xA70, 12); // Ok
        delay(30);
      }
    }  

    if(readString.indexOf("hdmi2") >=0)
    {
      for (int i = 0; i < 3; i++) {
        irsend.sendSony(0x70, 12); // Home
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xAF0, 12); // Down
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xA70, 12); // Ok
        delay(30);
      }
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xAF0, 12); // Down
        delay(30);
      }      
      delay(500);
       for (int i = 0; i < 3; i++) {
        irsend.sendSony(0xA70, 12); // Ok
        delay(30);
      }
    } 

// GE Air Conditioner

    if(readString.indexOf("pwrac") >=0)
    {
      testRaw("RAW1", sendbuf1, sizeof(sendbuf1)/sizeof(int)); // AC Power
      delay(350);
      testRaw("RAW6", sendbuf6, sizeof(sendbuf6)/sizeof(int)); // AC Mode
      delay(30);
    }

    if(readString.indexOf("actmpup") >=0)
    {
      testRaw("RAW2", sendbuf2, sizeof(sendbuf2)/sizeof(int)); // AC Temp Up
      delay(30);
    }

    if(readString.indexOf("actmpdwn") >=0)
    {
      testRaw("RAW3", sendbuf3, sizeof(sendbuf3)/sizeof(int)); // AC Temp Down
      delay(30);
    }

    if(readString.indexOf("acfanup") >=0)
    {
      testRaw("RAW4", sendbuf4, sizeof(sendbuf4)/sizeof(int)); // AC Fan Up
      delay(30);
    }

    if(readString.indexOf("acfandwn") >=0)
    {
      testRaw("RAW5", sendbuf5, sizeof(sendbuf5)/sizeof(int)); // AC Fan Down
      delay(30);
    }

// Class D Subwoofer Amp (Toshiba CT-90302 Remote)
    
    if(readString.indexOf("subpwr") >=0)
    {
      irsend.sendNEC(0x2FD08F7, 32); // Mute Key
      delay(30);
    }

    if(readString.indexOf("subon") >=0)
    {
      irsend.sendNEC(0x2FD00FF, 32); // (0) Key
      delay(30);
    }

    if(readString.indexOf("suboff") >=0)
    {
      irsend.sendNEC(0x2FD807F, 32); // (1) Key
      delay(30);
    }

    if(readString.indexOf("subup") >=0)
    {
      irsend.sendNEC(0x2FD58A7, 32); // Vol (+) Key
      delay(30);
    }

    if(readString.indexOf("subdwn") >=0)
    {
      irsend.sendNEC(0x2FD7887, 32); // Vol (-) Key
      delay(30);
    }   

// DAM1021 DAC (Onn Soundbar Remote)
    
    if(readString.indexOf("usb") >=0)
    {
      irsend.sendNEC(0xEE110AF5, 32); // USB Input (Music Button)
      delay(30);
    }

    if(readString.indexOf("coaxial") >=0)
    {
      irsend.sendNEC(0xEE11E817, 32); // Coaxial Input (Aux Button)
      delay(30);
    }

    if(readString.indexOf("optical") >=0)
    {
      irsend.sendNEC(0xEE11F20D, 32); // Optical Input (TV Button)
      delay(30);
    }    

    if(readString.indexOf("inauto") >=0)
    {
      irsend.sendNEC(0xEE11A45B, 32); // Auto Input (Play Button)
      delay(30);
    }   
    
// 12v External Power Outputs

    if(readString.indexOf("fet0on") >=0)
    {
      digitalWrite(fet0,HIGH);
      delay(30);
    } 
    
    if(readString.indexOf("fet0off") >=0)
    {
      digitalWrite(fet0,LOW);
      delay(30);
    }  

    if(readString.indexOf("fet1on") >=0)
    {
      digitalWrite(fet1,HIGH);
      delay(30);
    } 
    
    if(readString.indexOf("fet1off") >=0)
    {
      digitalWrite(fet1,LOW);
      delay(30);
    }

    if(readString.indexOf("fet2on") >=0)
    {
      digitalWrite(fet2,HIGH);
      delay(30);
    } 
    
    if(readString.indexOf("fet2off") >=0)
    {
      digitalWrite(fet2,LOW);
      delay(30);
    }

// 433MHz RF Controller

    if(readString.indexOf("rfa1on") >=0)
    {
      mySwitch.send(734735, 24);
      delay(30);
    }

    if(readString.indexOf("rfa1off") >=0)
    {
      mySwitch.send(734736, 24);
      delay(30);
    }

    if(readString.indexOf("rfa2on") >=0)
    {
      mySwitch.send(734731, 24);
      delay(30);
    }

    if(readString.indexOf("rfa2off") >=0)
    {
      mySwitch.send(734732, 24);
      delay(30);
    }

    if(readString.indexOf("rfa3on") >=0)
    {
      mySwitch.send(734733, 24);
      delay(30);
    }

    if(readString.indexOf("rfa3off") >=0)
    {
      mySwitch.send(734734, 24);
      delay(30);
    }

    if(readString.indexOf("rfb1on") >=0)
    {
      mySwitch.send(864341, 24);
      delay(30);
    }

    if(readString.indexOf("rfb1off") >=0)
    {
      mySwitch.send(864342, 24);
      delay(30);
    }

    if(readString.indexOf("rfb2on") >=0)
    {
      mySwitch.send(864345, 24);
      delay(30);
    }

    if(readString.indexOf("rfb2off") >=0)
    {
      mySwitch.send(864346, 24);
      delay(30);
    }

    if(readString.indexOf("rfb3") >=0)
    {
      mySwitch.send(864343, 24);
      delay(30);
    }
        
//////////////////

    readString="";
  }
}
void testRaw(char *label, unsigned int *rawbuf, int rawlen) {
    irsend.sendRaw(rawbuf, rawlen, 38 /* kHz */);
delay(50);
}
