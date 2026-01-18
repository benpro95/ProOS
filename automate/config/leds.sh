#!/bin/bash
#######################################################
####### LED parser script by Ben Provenzano III #######
#######################################################

## Read Input Arguments
VARA=${$1}
VARB=${$2}
MENUFILE="/var/www/html/ram/mainmenu.txt"

if [ -e "$MENUFILE" ]; then
  ## Read file into array
  readarray LED_ARRAY < "$MENUFILE"
  NEWLINE=$'\n'
  for ELM in ${LED_ARRAY[@]}; do
    ## Split data by delimiter
    LINE=( ${ELM//|/ } )
    HOST="${LINE[0]}"  
    STATE="${LINE[1]}"
    ## Append active hosts to array
    if [ "$STATE" == "chkon" ] || [ "$VARA" == "stop" ] || [ "$VARA" == "pause" ]; then
      DATA+="${HOST}"
      DATA+="${NEWLINE}"
    fi  
  done
  ## Dispatch command to active hosts
  if [ "$DATA" != "" ]; then
    echo "$DATA" | xargs -P 5 -I % \
      /usr/bin/curl --fail --ipv4 --no-buffer --max-time 5 --retry 1 --no-keepalive \
        "%/api?var=$VARB&arg=$VARA&action=leds" > /dev/null 2>&1 &
  fi 
else
  echo "mainmenu.txt not found."    
fi
exit