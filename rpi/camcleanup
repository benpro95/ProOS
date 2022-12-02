#!/bin/bash

## Cameras Cleanup Script for Pi
### run as root user only!

FLASH_PATH="/media/usb0"
GDRIVE_PATH="/mnt/ramdisk/gsync"

## Log file path
if [ ! -e $FLASH_PATH/cameras ]; then
  LOGFILE="/tmp/camcleanup.log"
else
  LOGFILE="$FLASH_PATH/cameras/camcleanup.log"
fi  

## Check if Google Drive connected before cleanup
if ping -W 10 -c 1 8.8.8.8 > /dev/null 2> /dev/null
then
  echo "Google Drive connected"
  ## Move videos to archive when Google Drive is larger than 7GB
  rm -f /tmp/camcleanup.vars
  timeout 500 du -sh -t7000000000 $GDRIVE_PATH/Current | awk -F" " '{print $2}' > /tmp/camcleanup.vars
  TM_STATUS=$?
  if [[ ("$TM_STATUS" -gt 100 ) || ("$TM_STATUS" -eq 1) ]]
  then
    echo "Timeout exceeded restarting rclone"
    service rpi-motion stop
    service rpi-rclone restart
    service rpi-motion start   
  fi
  if [[ -s /tmp/camcleanup.vars ]] ; then
	  echo "Google Drive current folder above 6GB limit moving video files $(date)" >> $LOGFILE
	  mkdir -p $GDRIVE_PATH/Archive
      TIMESTAMP="$(date +%H-%m-%d)"
      mkdir -p $GDRIVE_PATH/Archive/$TIMESTAMP
	  mv $GDRIVE_PATH/Current/* $GDRIVE_PATH/Archive/$TIMESTAMP/
  else
    echo "Google Drive current folder under 7GB"
  fi
  ###############################################################
  ## Delete archived videos, when Google Drive is 95% full
  DISKCAP=""
  DISKCAP=$(timeout 500 df -Pk $GDRIVE_PATH | awk 'NR==2 {print $5}')
  DISKCAP=${DISKCAP%\%}
  if [[ "$DISKCAP" -gt "95" ]] ; then
	  echo "Google Drive usage $DISKCAP% deleting archived video files $(date)" >> $LOGFILE
	  rm -rf $GDRIVE_PATH/Archive
	  mkdir -p $GDRIVE_PATH/Archive
	  chmod -R 777 $GDRIVE_PATH/Archive
  else
    echo "Google Drive usage less than 95% not deleting archived"
  fi
else
  echo "Google ping exceeded 10 seconds, cleanup not ran $(date)" >> $LOGFILE
fi

## Check if flash drive is connected before cleanup
if [ ! -e $FLASH_PATH/cameras ]; then
  echo "Flash drive not connected"
else
  echo "Flash drive connected"
  truncate -s '<5MB' /media/usb0/cameras/motioncopy.log
  truncate -s '<5MB' /media/usb0/cameras/camcleanup.log
  ## Delete videos, when flash drive has only 2GB free
  DISKCAP=""
  DISKCAP=$(timeout 500 df -Pk /media/usb0 | awk 'NR==2 {print $5}')
  DISKCAP=${DISKCAP%\%}
  if [[ "$DISKCAP" -gt "95" ]] ; then
	  echo "Flash drive usage $DISKCAP% deleting video files... $(date)" >> $LOGFILE
	  rm -rf $FLASH_PATH/cameras/*/*.mp4
	  chmod -R 777 $FLASH_PATH/cameras
  else
    echo "Flash drive under 95% usage"
  fi
fi

## Log file trim
truncate -s '<256KB' /tmp/motion.log
truncate -s '<128KB' /tmp/motionping.log
truncate -s '<128KB' /tmp/motioncopy.log
truncate -s '<128KB' /tmp/camcleanup.log

exit