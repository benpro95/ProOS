#!/bin/bash
###########################################################
####### LED parser script by Ben Provenzano III v12 #######
###########################################################

CALL_LCDPI(){
	LCDPI_MSG=""
	if [ "$VARA" == "fc" ]; then
	  LCDPI_MSG="LEDs: $VARB%"
	else
	  LCDPI_MSG="LEDs: $VARA"
	  if [ "$VARA" == "stop" ]; then
	    LCDPI_MSG="stopped LEDs"
	  fi
	  if [ "$VARA" == "pause" ]; then
	    LCDPI_MSG="paused LEDs"
	  fi
	fi
    /opt/rpi/lcdpi "$LCDPI_MSG" > /dev/null 2>&1 &
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
       --data "var=$VARB&arg=$VARA&action=leds" %/exec.php > /dev/null 2>&1 &
  fi
  CALL_LCDPI     
else
  echo "mainmenu.txt not found."    
fi
exit