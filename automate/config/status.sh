#!/bin/bash
############################################################
##### Device Status Updater by Ben Provenzano III v1.0 #####
############################################################
FILE="/opt/system/statsmenu.txt"
LOCK="/var/www/html/ram/status.lock"
HOST=""
STATE=""
ACTION=""
NAME=""
OUT=""

UPDATE_STATES () {
  if [ "$ACTION" == "ping" ]; then
    if ping -4 -A -c 1 -i 0.25 -W 0.25 "$HOST"; then
      echo "{$HOST} online"
      STATE="grnind"
    else
      STATE="blkind"
    fi
  fi
}

## only allow one instance
if [ -e $LOCK ]; then
  PID=`cat $LOCK`
  if kill -0 &>1 > /dev/null $PID; then
    echo "already running, exiting..."
    exit 1
  else
    rm $LOCK
  fi
fi
echo $$ > $LOCK

## read file into memory
if [ -e "$FILE" ]; then
  ## create lock file
  touch "$LOCK"
  ## read through each line
  mapfile -t FILE_ARR < "$FILE"
  for LINE in "${FILE_ARR[@]}"; do
    ROWCOUNT=0
    while IFS='|' read -ra ROW; do
      ## read through each row
      for FIELD in "${ROW[@]}"; do
        ## read through each field
        STATE=""
        if [ "$ROWCOUNT" == 0 ]; then
          HOST="$FIELD"
        fi
        if [ "$ROWCOUNT" == 1 ]; then
          NAME="$FIELD"
        fi
        if [ "$ROWCOUNT" == 2 ]; then
          ACTION="$FIELD"
          ## trigger update process
          UPDATE_STATES > /dev/null 2>&1
          NEWLINE="${HOST}|${STATE}|${NAME}|${ACTION}" 
          echo "$NEWLINE"
        fi        
        ROWCOUNT=$((ROWCOUNT + 1))  
      done
    done <<< "$LINE"
  done
fi

exit
