#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
REPLY="$1"
ARG="$2"
LOGFILE="/mnt/.regions/WWW/sysout.txt"

date &>> $LOGFILE
/usr/bin/wwwcmds.run $REPLY $ARG &>> $LOGFILE

exit