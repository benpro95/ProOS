#!/bin/bash
### Automatically turn off LCD display when idle and turn back on when touched

## Set Idle Threshold
threshold=300000 # 5 min = 5 * 60 * 1000 ms
## Set Initial State
idletime=$(xprintidle)
if [ "$idletime" -gt "$threshold" ]; then
  idleing="0"
fi
if [ "$idletime" -le "$threshold" ]; then
  idleing="1"
fi

## Main Loop
while true
do
## Read X11 Idle Time
idletime=$(xprintidle)
#echo "$idletime"
## Runs When Idle Time Exceeds Threshold
if [ "$idleing" == "0" ]; then
  if [ "$idletime" -gt "$threshold" ]; then
    ## LCD off
    idleing="1"
    sudo sh -c 'echo 1 > /sys/class/backlight/rpi_backlight/bl_power'
    #echo "idle"
  fi
fi
## Runs When Idle Time Below Threshold
if [ "$idleing" == "1" ]; then
  if [ "$idletime" -le "$threshold" ]; then
    ## LCD on
    idleing="0"
    sudo sh -c 'echo 0 > /sys/class/backlight/rpi_backlight/bl_power'
    #echo "in use"
  fi
fi
## Check Every Second
sleep 1
done
