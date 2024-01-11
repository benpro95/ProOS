#!/bin/bash
###########################################################
####### LED parser script by Ben Provenzano III v12 #######
###########################################################

CALL_LCDPI(){
  ## Send message to LCDpi
  if [ "$VARA" == "fc" ]; then
    LCDPI_MSG="$VARB% brightness."
  else
    LCDPI_MSG="$VARA."
    if [ "$VARA" == "stop" ]; then
      LCDPI_MSG="stop LEDs."
    fi
    if [ "$VARA" == "pause" ]; then
      LCDPI_MSG="pause LEDs."
    fi
  fi
  /usr/bin/curl -silent --fail --ipv4 --no-buffer \
     --max-time 5 --retry 1 --no-keepalive \
     -X POST http://lcdpi.home/upload.php \
     -H "Content-Type: text/plain" -d "$LCDPI_MSG"
}

## Read Input Arguments
VARA=$1
VARB=$2

if [ -e /opt/system/ledsync.txt ]; then
  ## Send command to all LED Pi's
  cat /opt/system/ledsync.txt | xargs -P 5 -I % \
    /usr/bin/curl --silent --fail --ipv4 --no-buffer \
     --max-time 5 --retry 1 --no-keepalive \
     --data "var=$VARB&arg=$VARA&action=leds" http://%/exec.php
  #CALL_LCDPI     
else
  echo "ledsync.txt not found."    
fi
exit