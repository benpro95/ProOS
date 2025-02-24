#!/bin/bash
###########################################################
###### LED Effects Script by Ben Provenzano III v16 #######
###########################################################
## Runs in background ##

## Stop effects function
LEDSTOP(){
if [ ! -e /tmp/fc-paused ]; then
  echo "Stopping LEDs daemon"
  /usr/bin/curl --fail --no-buffer --max-time 5 --silent \
   --retry 5 --retry-all-errors --retry-delay 1 \
   -X POST 127.0.0.1:9387/api/anim/stop
  systemctl stop rpi-fcleds
else
  echo "Skipping stop, already paused."
fi
}

## Read Input Arguments
VARA=$1
VARB=$2

## Main Path
BIN_PATH=/opt/rpi

if [ "$VARA" = "" ]; then
  echo "no argument, exiting."
  exit
fi

## Read LED Type
if [ ! -e $BIN_PATH/ledtype.txt ]; then
  exit
fi
LEDTYPE=`cat $BIN_PATH/ledtype.txt`

## Pick a random effect
if [ "$VARA" = "shuffle" ]; then
  SHUF_IN=$BIN_PATH/effects/shuffle.txt
  SHUF_OUT=$(<$SHUF_IN sort | uniq | sort -R | head -n 1)
  VARA="${SHUF_OUT//$'\r'/}"
  echo "Choosing random effect"
fi

## Brightness control
if [ "$VARA" = "fc" ]; then
  ## Stop Effects & OPC Servers
  LEDSTOP
  rm -f /tmp/fc-paused
  rm -f /tmp/ledstate.lock
  systemctl stop rpi-fcserver
  systemctl stop rpi-nodeopc
  ## Reset Fadecandy
  usbreset 1d50:607a
  ## Start OPC Servers
  systemctl set-environment rpi_ledtype=$LEDTYPE rpi_fcsetup=fc$VARB.json
  systemctl start rpi-fcserver
  systemctl start rpi-nodeopc
  echo "LEDs brightness changed to $VARB%"
  ## Restart Effects
  if [[ -f /tmp/fc-last ]]; then
  	echo "files exist, restarting effect..."
    VARA=$(cat /tmp/fc-last)
  else
    exit 
  fi
fi

## Stop function (1st)
if [ "$VARA" = "stop" ]; then
  echo "Blanking effects"
  rm -f /tmp/ledstate.lock
  VARA="black"
fi

## Pause function (2nd)
if [ "$VARA" = "pause" ]; then
  LEDSTOP
  touch /tmp/fc-paused  
  exit
fi

## Store last effect (3rd)
if [ "$VARA" = "black" ] ; then
 rm -f /tmp/fc-last
else
 echo "$VARA" > /tmp/fc-last
fi

## Node.js effect parser
if [ ! -e $BIN_PATH/effects/$LEDTYPE/$VARA.opc ]; then
  echo "Node.js effect not found"
else
  LEDSTOP
  if [ -f "/tmp/ledstate.lock" ]; then
    echo "already running"
    exit
  else
    touch /tmp/ledstate.lock
  fi
  ## Link Effect
  ln -sf $BIN_PATH/effects/$LEDTYPE/$VARA.opc \
   $BIN_PATH/effects/nodeopc/server/animations/opc
  ## Start Request
  /usr/bin/curl --fail --no-buffer --max-time 5 --silent \
   --retry 5 --retry-all-errors --retry-delay 1 \
   -d '{"playlistname":"Playlist"}' -H "Content-Type: application/json" \
   -X POST 127.0.0.1:9387/api/playlists/play
  echo "Set LEDs to Node.js effect"
  rm -f /tmp/ledstate.lock
  rm -f /tmp/fc-paused  
  exit
fi

## Python LED Effects
if [ "$VARA" = "rave" ] || [ "$VARA" = "chase" ] || \
   [ "$VARA" = "miami" ] || [ "$VARA" = "spark" ] || \
   [ "$VARA" = "stripes" ] || [ "$VARA" = "lava" ] ; then
  LEDSTOP
  if [ -f "/tmp/ledstate.lock" ]; then
    echo "already running"
    exit
  else
    touch /tmp/ledstate.lock
  fi
  ## Start Effect
  systemctl set-environment rpi_fceffect=pyth-$VARA
  systemctl start rpi-fcleds
  echo "Set LEDs to Python effect"
  rm -f /tmp/ledstate.lock
  rm -f /tmp/fc-paused  
  exit
fi

## Perl Effects
if [ "$VARA" = "noise3" ] || [ "$VARA" = "blocks" ] || \
   [ "$VARA" = "mandelbrot" ] || [ "$VARA" = "multitomaton" ] || \
   [ "$VARA" = "ripple" ] || [ "$VARA" = "random" ] ; then
  LEDSTOP 	
  if [ -f "/tmp/ledstate.lock" ]; then
    echo "already running"
    exit
  else
    touch /tmp/ledstate.lock
  fi
  ## Start Effect  
  systemctl set-environment rpi_fceffect=perl-$VARA
  systemctl start rpi-fcleds
  echo "Set LEDs to Perl effect"
  rm -f /tmp/ledstate.lock
  rm -f /tmp/fc-paused  
  exit
fi

## Java Effects
if [ "$VARA" = "rainbow" ] || [ "$VARA" = "spectro" ] ; then
  LEDSTOP
  if [ -f "/tmp/ledstate.lock" ]; then
    echo "already running"
    exit
  else
    touch /tmp/ledstate.lock
  fi
  ## Start Effect
  systemctl set-environment rpi_fceffect=java-$VARA
  systemctl start rpi-fcleds
  echo "Set LEDs to Java effect"
  rm -f /tmp/ledstate.lock
  rm -f /tmp/fc-paused  
  exit
fi

# Spectro Gain Adjust
if [ "$VARA" = "plus" ]; then
  export DISPLAY=":1"
  xdotool key plus
  exit
fi

if [ "$VARA" = "minus" ]; then
  export DISPLAY=":1"
  xdotool key minus
  exit
fi

## Solid Color
LEDSTOP
if [ -f "/tmp/ledstate.lock" ]; then
  echo "already running"
  exit
else
  touch /tmp/ledstate.lock
fi
## Start Effect
$BIN_PATH/effects/colorscan "$VARA" | $BIN_PATH/effects/opc_client 127.0.0.1:7890
echo "Set LEDs to solid color"
rm -f /tmp/ledstate.lock
exit 
