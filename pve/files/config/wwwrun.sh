#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
REPLY="$1"
ARG="$2"
LOGFILE="/mnt/ramdisk/sysout.txt"

HEADER=$(date)
HEADER+=$(hostname)
echo "$HEADER" &>> $LOGFILE
/usr/bin/www.sh $REPLY $ARG $LOGFILE &>> $LOGFILE
echo "" &>> $LOGFILE

exit