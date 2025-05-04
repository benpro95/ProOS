#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
CALL="$1"
RAMDISK="/mnt/ramdisk"
LOGFILE="$RAMDISK/sysout.txt"
if [[ "$CALL" == "" ]]
then
  echo "no argument."
  exit
fi
if [[ "$ARG" == "" ]]
then
  ARG="NULL"
fi
## run-as specific user
/usr/bin/sudo -u ben /usr/bin/apicmds $CALL $RAMDISK $LOGFILE &>> $LOGFILE
TRAILER=$(date)
TRAILER+=" ("
TRAILER+=$(hostname)
TRAILER+=")"
echo "$TRAILER" &>> $LOGFILE
echo " " &>> $LOGFILE
exit