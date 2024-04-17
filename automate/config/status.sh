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

WRITE_FILE () {
  exec 3<> /var/www/html/ram/statsmenu-1.txt
  OUT+="${HOST}|${STATE}|${NAME}|${ACTION}"
  OUT+=$(printf "\n")
}

## read file into memory
if [ -e "$FILE" ]; then
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
          WRITE_FILE
        fi        
        ROWCOUNT=$((ROWCOUNT + 1))  
      done
    done <<< "$LINE"
  done < "$FILE"
  echo $OUT
fi
exit
