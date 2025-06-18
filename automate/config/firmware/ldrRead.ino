/*  

Smoothing LDR test

*/

const int LED1 = 13;
const int LDR1 = A7;
const int sensorMin = 0;
const int sensorMax = 900;
const int numReadings = 10;
int timeNew = 0;
int timePass = 0;
const int timeON = 500;

int readings [numReadings];  // the readings from the analog input
int index = 0;
int total = 0;
int LDR1avg = 0;

void setup ()
{
  
  pinMode (LED1, OUTPUT);        // set the LED pins to output
  Serial.begin(9600);            // initialize serial communication
  // initialize all the readings to 0:
  for (int thisReading = 0; thisReading < numReadings; thisReading++){
    readings[thisReading] = 0;
  }
    
}


void loop() 
{
  // substract the last reading
  total = total - readings[index];
  // read from the sensor
  readings[index] = analogRead(LDR1);
  // add the reading to the total:
  total = total + readings[index];
  // advance to next position in the array:
  index = index + 1;
  
  // if we're at the end of the array...
  if (index >= numReadings)
    // ...wrap around to the beginning:
    index = 0;
           
 // Calculate the average;
 LDR1avg = total / numReadings;
 // print to serial 
 //Serial.println(LDR1avg, DEC);
 
 // get the current time and store it as oldtime
 int timeOld = millis();     
 // map the LDR sensor average reading to a range of 10 options
 int LDR1range = map(LDR1avg, sensorMin, sensorMax, 0, 10);


  // check if LDR1range is higher then 1 if so start recording the time 
  if (LDR1range > 1) {
      timeNew = (millis() - timeOld);
      timePass = (timePass + timeNew);
      
      // If an LDR >= 5 for a by timeON speciefied amount of time set the state
      if (timePass >= timeON && LDR1range < 7 ){
        Serial.println("TRIG");
        timePass = 0;
      }
  }   
    

}
