#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
REPLY="$1"
ARG="$2"
RAMDISK="/home/server/.html/RAM"
LOGFILE="$RAMDISK/sysout.txt"

/usr/bin/www.sh $REPLY $ARG $RAMDISK $LOGFILE &>> $LOGFILE
TRAILER=$(date)
TRAILER+=" ("
TRAILER+=$(hostname)
TRAILER+=")"
echo "$TRAILER" &>> $LOGFILE
echo " " &>> $LOGFILE
exit