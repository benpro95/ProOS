/*
 * Ben Provenzano III
 * -----------------
 * March 21 2016
 433MHz Wireless Receiver Pair
 ** Patent Pending **
 * Wireless 433Mhz 8-LED Lamp
 * v2
 *
 */
 
#include <RCSwitch.h>

RCSwitch mySwitch = RCSwitch();

#define fet1 5
#define fet2 6
#define fet3 7
#define fet4 8
#define fet5 9
#define fet6 10
#define fet7 11
#define fet8 12
#define led 13


void setup() {
  Serial.begin(9600);
  mySwitch.enableReceive(0);  // Receiver on interrupt 0 => that is [pin #2]
  mySwitch.setProtocol(1);
  mySwitch.setPulseLength(183);
  pinMode(fet1, OUTPUT);    
  pinMode(fet2, OUTPUT);  
  pinMode(fet3, OUTPUT);  
  pinMode(fet4, OUTPUT);    
  pinMode(fet5, OUTPUT);  
  pinMode(fet6, OUTPUT);  
  pinMode(fet7, OUTPUT);    
  pinMode(fet8, OUTPUT);  
  pinMode(led, OUTPUT);
}

void loop () {

  if (mySwitch.available()) {
    
    unsigned long value = mySwitch.getReceivedValue();

     if (value == 873151 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, LOW); 
      digitalWrite(fet5, LOW);
      digitalWrite(fet6, LOW);
      digitalWrite(fet7, LOW);
      digitalWrite(fet8, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873152 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, LOW);
      digitalWrite(fet5, LOW);
      digitalWrite(fet6, LOW); 
      digitalWrite(fet7, LOW);
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }    

     if (value == 873153 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, LOW); 
      digitalWrite(fet5, LOW);
      digitalWrite(fet6, LOW);
      digitalWrite(fet7, HIGH); 
      delay(250); 
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }    

     if (value == 873154 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, LOW); 
      digitalWrite(fet5, LOW);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250); 
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873155 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, LOW);
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250);  
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873156 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, LOW);
      digitalWrite(fet4, HIGH);
      delay(250); 
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250);  
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873157 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, LOW);
      digitalWrite(fet3, HIGH);
      delay(250);
      digitalWrite(fet4, HIGH);
      delay(250);
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250);  
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873158 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      digitalWrite(fet2, HIGH);
      delay(250);
      digitalWrite(fet3, HIGH);
      delay(250);
      digitalWrite(fet4, HIGH); 
      delay(250);
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250);  
      digitalWrite(fet8, HIGH);
      delay(250);     
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873159 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, HIGH);
      delay(250);
      digitalWrite(fet2, HIGH);
      delay(250);
      digitalWrite(fet3, HIGH);
      delay(250);
      digitalWrite(fet4, HIGH);
      delay(250);
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(fet6, HIGH);
      delay(250); 
      digitalWrite(fet7, HIGH);
      delay(250);  
      digitalWrite(fet8, HIGH);     
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }
    
     if (value == 873160 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, HIGH);   
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873161 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet1, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }
    
     if (value == 873162 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet2, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    } 

     if (value == 873163 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet2, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    } 
    
     if (value == 873164 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet3, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873165 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet3, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }
    
     if (value == 873166 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet4, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);   
    }

     if (value == 873167 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet4, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);   
    }
        
     if (value == 873168 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet5, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    }

     if (value == 873169 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet5, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    }    
    
     if (value == 873170 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet6, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);   
    } 

     if (value == 873171 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet6, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);   
    } 
    
     if (value == 873172 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet7, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }

     if (value == 873173 ) 
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet7, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250); 
    }
    
     if (value == 873174 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet8, HIGH);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    }

     if (value == 873175 )
    {
      digitalWrite(led, HIGH);
      digitalWrite(fet8, LOW);
      delay(250);
      digitalWrite(led, LOW); 
      delay(250);  
    }
    
  }   
    {
       mySwitch.resetAvailable();
  }
}
 


