#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
REPLY="$1"
ARG="$2"
LOGFILE="/mnt/ramdisk/sysout.txt"

/usr/bin/www.sh $REPLY $ARG $LOGFILE &>> $LOGFILE
echo " "
TRAILER=$(date)
TRAILER+=" ("
TRAILER+=$(hostname)
TRAILER+=")"
echo "$TRAILER" &>> $LOGFILE

exit