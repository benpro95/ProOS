#!/bin/bash
###########################################################
####### LED parser script by Ben Provenzano III v12 #######
###########################################################

CALL_LCDPI(){
  ## Send message to LCDpi
  LCD_HOST="lcdpi.home"
  if [ "$VARA" == "fc" ]; then
    LCDPI_MSG="$VARB% brightness."
  else
    LCDPI_MSG="$VARA."
    if [ "$VARA" == "stop" ]; then
      LCDPI_MSG="stopped LEDs."
    fi
    if [ "$VARA" == "pause" ]; then
      LCDPI_MSG="paused LEDs."
    fi
  fi
  ## Convert Text
  JSONDATA=$(echo "$LCDPI_MSG" | jq -Rsc '. / "\n" - [""]')
  RAWDATA=$(echo "$JSONDATA" | base64)
  ## Send Message
  /usr/bin/curl -silent --fail --ipv4 --no-buffer \
     --max-time 5 --retry 1 --no-keepalive \
     -X POST "http://$LCD_HOST/update.php?file=message&action=update" \
     -H "Content-Type", "text/plain" --data "$RAWDATA"
  ## Display Message
  /usr/bin/curl -silent --fail --ipv4 --no-buffer \
     --max-time 5 --retry 1 --no-keepalive \
     --data "var=&arg=message&action=main" "http://$LCD_HOST/exec.php"
}

## Read Input Arguments
VARA=$1
VARB=$2

if [ -e /var/www/html/ram/mainmenu.txt ]; then
  ## Read file into array
  readarray LED_ARRAY < /var/www/html/ram/mainmenu.txt
  NEWLINE=$'\n'
  for ELM in ${LED_ARRAY[@]}; do
    ## Split data by delimiter
    LINE=( ${ELM//|/ } )
    HOST="${LINE[0]}"  
    STATE="${LINE[1]}"
    ## Append active hosts to array
    if [ "$STATE" == "1" ] || [ "$VARA" == "stop" ] || [ "$VARA" == "pause" ]; then
      DATA+="${HOST}"
      DATA+="${NEWLINE}"
    fi  
  done
  ## Dispatch command to active hosts
  if [ "$DATA" != "" ]; then
    echo "$DATA" | xargs -P 5 -I % \
      /usr/bin/curl --fail --ipv4 --no-buffer \
      --max-time 5 --retry 1 --no-keepalive \
       --data "var=$VARB&arg=$VARA&action=leds" http://%/exec.php
    DATAECHO="sending $VARA:$VARB $DATA..."  
    DATAECHO=$(echo $DATAECHO|tr -d '\n')
    echo "$DATAECHO"
  fi
  CALL_LCDPI     
else
  echo "mainmenu.txt not found."    
fi
exit