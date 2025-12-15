#!/bin/bash
###########################################################
## Start Relax Loop (triggered by systemd) ################
###########################################################

## Fade-in/out time (in seconds)
FADE_INOUT="3"

## Capitialize first letter of argument
FILE_NAME="${rpi_relaxmode^}"

FILE_PATH="/mnt/smb/Media/Sounds/Relaxation/$FILE_NAME.mp3"

echo "starting $FILE_NAME sound..."

## Capture audio duration
DURATION=$(/usr/bin/ffprobe -i $FILE_PATH -show_entries format=duration -v quiet -of csv="p=0")

## Play audio in loop (fade-in/out)
/usr/bin/mpv --really-quiet --af="afade=in:start_time=0:duration=$FADE_INOUT,afade=out:start_time=$DURATION:duration=$FADE_INOUT" --loop $FILE_PATH

exit
