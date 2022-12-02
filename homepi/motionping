#!/bin/bash
## This is ran every 4 minutes
#########################
## Detect if Driveway Camera is connected
if ! ping -c 1 192.168.1.3 > /dev/null 2> /dev/null
then
  date
  echo "Driveway camera is down restarting motion..."
  systemctl restart motion
  echo " "
fi
sleep 5.25
#########################
## Detect if Porch Camera is connected
if ! ping -c 1 192.168.1.2 > /dev/null 2> /dev/null
then
  date
  echo "Porch camera is down restarting motion..."
  systemctl restart motion
  echo " "
fi
#########################
exit