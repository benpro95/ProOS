#!/bin/bash
###########################################################
####### LED parser script by Ben Provenzano III v12 #######
###########################################################

## Read Input Arguments
VARA=$1
VARB=$2

if [ -e /opt/system/ledsync.txt ]; then
  cat /opt/system/ledsync.txt | xargs -P 5 -I % \
    /usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
     --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
     --data "var=$VARB&arg=$VARA&action=leds" http://%/exec.php
else
  echo "ledsync.txt not found."    
fi
exit