#!/bin/bash
###########################################################
###########################################################
## Start Relax Loop (triggered by systemd) ################
###########################################################
###########################################################

## Load settings file into array
mapfile -t SETTINGS < <(wget -O- -q http://files.home/Relaxation/Settings.txt)

## Get IP address from hostname
ATVIP=$(getent ahostsv4 "${SETTINGS[3]%$'\n'}" | awk '{print $1}' | head -1)
echo "IP Address: $ATVIP"

## Turn off Apple TV
if [ "$rpi_relaxmode" = "off" ]; then
  ATVSTATE=$(/usr/local/bin/atvremote --address "$ATVIP" --id "${SETTINGS[0]%$'\n'}" \
    --airplay-credentials "${SETTINGS[2]%$'\n'}" power_state)
  ## Only turn-off if Apple TV is on  
  if [ "$ATVSTATE" = "PowerState.On" ]; then
    echo "turning off Apple TV..."  
    /usr/local/bin/atvremote --address "$ATVIP" --id "${SETTINGS[0]%$'\n'}" \
     --airplay-credentials "${SETTINGS[2]%$'\n'}" turn_off
  fi
  exit
fi

## Loop on startup / time trigger
if [ "$rpi_relaxmode" = "boot" ]; then
  ## Set default mode from settings
  rpi_relaxmode="${SETTINGS[4]%$'\n'}"
  ## Read system time  
  DOW=$(date +%u)
  HOUR=$(date +%H)
  ## Start loop based on current time
  if [ "$DOW" = "5" ] || [ "$DOW" = "6" ]; then
    echo "is Fri or Sat, hour is $HOUR"
    if (( 9 <= 10#$HOUR && 10#$HOUR < 23 )); then
      echo "not starting, time is between 9am-11pm"
      exit
    fi
  else
    echo "is Sun or weekday, hour is $HOUR"
    if (( 9 <= 10#$HOUR && 10#$HOUR < 21 )); then
      echo "not starting, time is between 9am-9pm"
      exit
    fi
  fi
  echo "time is between 9pm-9am"
fi

## Capitialize first letter of argument
FILE="${rpi_relaxmode^}"

## Play audio in loop on Apple TV
echo "starting $FILE sound..."
/usr/bin/ffmpeg -re -stream_loop -1 -i http://files.home/Relaxation/$FILE.mp3 -f mp3 - \
 | /usr/local/bin/atvremote --manual --address "$ATVIP" --port 7000 --protocol raop \
 --id "${SETTINGS[0]%$'\n'}" --raop-credentials "${SETTINGS[1]%$'\n'}" stream_file=-

exit
