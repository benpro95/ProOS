#!/bin/bash
###########################################################
###########################################################
## Start Relax Loop (triggered by systemd) ################
###########################################################
###########################################################

WWW_URL="http://files.home/WWW/Relaxation"

## Load settings file into array
##mapfile -t SETTINGS < <(wget -O- -q $WWW_URL/Settings.txt)

ATV_NAME="Bedroom"

## Turn off Apple TV
if [ "$rpi_relaxmode" == "off" ]; then
  ATVSTATE=$(/opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf power_state)
  ## Only turn-off if Apple TV is on  
  if [ "$ATVSTATE" == "PowerState.On" ]; then
    echo "turning off Apple TV..."  
    /opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf turn_off
  fi
  exit
fi

## Pause Apple TV
if [ "$rpi_relaxmode" == "pause" ]; then
  ATVSTATE=$(/opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf power_state)
  if [ "$ATVSTATE" == "PowerState.On" ]; then
    /opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf pause
  fi  
  exit
fi

## Loop on startup / time trigger
if [ "$rpi_relaxmode" == "boot" ]; then
  ## Set default mode from settings
  #rpi_relaxmode="${SETTINGS[0]%$'\n'}"
  rpi_relaxmode="waterfall"
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

## Pause media and return to home screen
/opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf pause home

## Capitialize first letter of argument
FILE="${rpi_relaxmode^}"

## Play audio in loop on Apple TV
echo "starting $FILE sound..."
/opt/pyatv/bin/atvremote -n "$ATV_NAME" --storage-filename /root/.pyatv.conf play_url="$WWW_URL/$FILE.mp4"

exit
