#!/bin/bash
############################################################
##### Device Status Updater by Ben Provenzano III v1.0 #####
############################################################
FILE="/var/www/html/ram/statsmenu.txt"
HOST=""
STATE=""
NAME=""
ACTION=""
OUT=""

UPDATE_STATES () {
  if [ "$ACTION" == "ping" ]; then
    if ping -c 1 -W 1 "$HOST"; then
      echo "{$HOST} online"
      STATE="4"
    else
      STATE="5"
    fi
  fi
  if [ "$ACTION" == "atv" ]; then
    STATE="3"
  fi  
}

## read file into memory
if [ -e "$FILE" ]; then
  ## open new file
  rm -rf "${FILE}.new"
  touch "${FILE}.new"
  exec 3<> "${FILE}.new"
  ## read each line
  while read -r LINE
  do
    ROWCOUNT=0
    while IFS='|' read -ra ROW; do
      ## read each row
      for FIELD in "${ROW[@]}"; do
        ## read each field
        if [ "$ROWCOUNT" == 0 ]; then
          HOST="$FIELD"
        fi        
        if [ "$ROWCOUNT" == 1 ]; then
          STATE="$FIELD"
        fi
        if [ "$ROWCOUNT" == 2 ]; then
          NAME="$FIELD"
        fi
        if [ "$ROWCOUNT" == 3 ]; then
          ACTION="$FIELD"
          ## trigger update process
          UPDATE_STATES
          ## write changes to new file
          echo "${HOST}|${STATE}|${NAME}|${ACTION}" >&3
        fi        
        ROWCOUNT=$((ROWCOUNT + 1))  
      done
    done <<< "$LINE"
  done < "$FILE"
  ## replace existing file
  rm -rf "$FILE"
  mv -f "${FILE}.new" "$FILE"
fi
exit
