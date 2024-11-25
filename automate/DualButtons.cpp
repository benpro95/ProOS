      int buttonPressed = -1;
      int button_down = button1.getState();
      int button_up = button2.getState();
      int dualClick = (button_up == LOW && button_down == LOW);

  if (button_down != lastb_down) {
      if (button_down == LOW) {
        buttonPressed = 0;
        buttonOneMillis = millis();
      }
      lastb_down = button_down;
  }    
      
  if (button_up != lastb_up) {
      if (button_up == LOW) {
        buttonPressed = 1;
        buttonTwoMillis = millis();
      }
      lastb_up = button_up;
  }
Serial.println("*****");
Serial.println(buttonOneMillis);
Serial.println(buttonTwoMillis);
Serial.println("*****");
  
  if(((buttonTwoMillis - buttonOneMillis) < 50) && ((buttonTwoMillis - buttonOneMillis) >=0)){
    if(dualClick != lastDualClick){
      Serial.println("DUAL CLICK PRESSED");  
      lastDualClick = dualClick;
    }
  } else {
    if(buttonPressed==0){
     if((buttonOneMillis > 1000) && (buttonTwoMillis <=0)){  
      Serial.println("DOWN PRESSED");
     } 
    } else if(buttonPressed == 1){
     if((buttonTwoMillis > 1000) && (buttonOneMillis <=0)){   
      Serial.println("UP PRESSED");
     } 
    }
  }