#!/bin/bash
###########################################################
###########################################################
## Launcher for WWW actions script
REPLY="$1"
ARG="$2"

/usr/bin/wwwcmds.run $REPLY $ARG &>> /mnt/.regions/WWW/SystemOutput.txt

exit