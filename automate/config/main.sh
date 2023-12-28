#!/bin/bash
##
###########################################################
## Main Home Automation Script by Ben Provenzano III v18 ##
###########################################################
###########################################################
## Do not use the screen command in this script ##

RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
LCDPI_MSG=""

CALLAPI(){
#### API Call
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 30 --retry 3 --retry-delay 1 --no-keepalive"
## API Type
if [[ "$ESP32" == "no" ]]; then
  /usr/bin/curl $CURLARGS --data "var=$CMDARG&arg=$XMITCMD&action=main" http://$TARGET/exec.php
  CMDARG=""
else ## ESP32 Xmit URL
  /usr/bin/curl $CURLARGS http://xmit.home -H "Accept: ####?|$XMITCALL"
fi
## Clear Data
TARGET=""
XMITCMD=""
XMITCALL=""
XMITARG=""
APIDATA=""
ESP32=""
return
}

CALL_LCDPI(){
  /usr/bin/curl $CURLARGS -X POST http://lcdpi.home/upload.php \
   -H "Content-Type: text/plain" -d "$LCDPI_MSG"
}

XMIT(){
#### ESP32 Transmit Function (Command Translation)
## CMD (no state file created)
## CMD toggle (toggle on/off state & append on/off to end of serial command)
## CMD on (create state file & append on to end of serial command then send)
## CMD off (delete state file & append off to end of serial command then send)
## Do not use the screen command in this script ##
##### TOGGLE SECTION #####
if [[ "$XMITARG" == "on" ]]; then
  touch $LOCKFOLDER/$XMITCMD.save
  XMITCMD=$XMITCMD"on"
fi
if [[ "$XMITARG" == "off" ]]; then
  rm -f $LOCKFOLDER/$XMITCMD.save
  XMITCMD=$XMITCMD"off"
fi
if [[ "$XMITARG" == "toggle" ]]; then
  if [ ! -e $LOCKFOLDER/$XMITCMD.save ]; then
   touch $LOCKFOLDER/$XMITCMD.save
   XMITCMD=$XMITCMD"on"
  else
   rm -f $LOCKFOLDER/$XMITCMD.save
   XMITCMD=$XMITCMD"off"
  fi
fi
##
##### FUNCTIONS SECTION ######
##
### HiFi Preamp (Philips Universal Remote) NEC 32-bit
##
## Power
if [[ "$XMITCMD" == "pwrhifi" ]]; then
   rm -f $LOCKFOLDER/subs.enabled 
   XMITCALL="0|0|1270227167"
   LCDPI_MSG="system power"
   CALLAPI   
   CALL_LCDPI
   return
fi
if [[ "$XMITCMD" == "hifioff" ]]; then
   rm -f $LOCKFOLDER/subs.enabled 
   XMITCALL="0|0|1261859214"
   LCDPI_MSG="system off"
   CALLAPI   
   CALL_LCDPI
   return
fi
if [[ "$XMITCMD" == "hifion" ]]; then
   rm -f $LOCKFOLDER/subs.enabled 
   XMITCALL="0|0|1261869414"
   LCDPI_MSG="system on"
   CALLAPI   
   CALL_LCDPI
   return
fi
## DAC
if [[ "$XMITCMD" == "dac" ]]; then
   XMITCALL="0|0|1261793423"
   LCDPI_MSG="DAC in"
   CALLAPI
   CALL_LCDPI
   return   
fi
## Aux
if [[ "$XMITCMD" == "aux" ]]; then
   XMITCALL="0|0|1261826063"
   LCDPI_MSG="aux in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Phono
if [[ "$XMITCMD" == "phono" ]]; then 
   XMITCALL="0|0|1261766903"
   LCDPI_MSG="phono in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Airplay
if [[ "$XMITCMD" == "airplay-preamp" ]]; then
   XMITCALL="0|0|1261799543"
   LCDPI_MSG="AirPlay in"
   CALLAPI   
   CALL_LCDPI
   return
fi   
## Volume Limit Mode
if [[ "$XMITCMD" == "vlimit" ]]; then
   XMITCALL="0|0|1261783223"
   LCDPI_MSG="volume limiter"
   CALLAPI   
   CALL_LCDPI
   return   
fi   
## Key Mute / Toggle
if [[ "$XMITCMD" == "mute" ]]; then
   XMITCALL="0|0|1270259807"
   CALLAPI   
   return
fi
## Optical Mode
if [[ "$XMITCMD" == "optical-preamp" ]]; then
   XMITCALL="0|0|1261824023"
   LCDPI_MSG="optical in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Key Toggle Hi-Pass Filter
if [[ "$XMITCMD" == "togglehpf" ]]; then
   XMITCALL="0|0|1261875534"
   LCDPI_MSG="toggle HPF"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Key Down
if [[ "$XMITCMD" == "dwnf" ]]; then
   XMITCALL="0|0|1261885734"
   CALLAPI
   return
fi
## Key Up
if [[ "$XMITCMD" == "upf" ]]; then
   XMITCALL="0|0|1261853094"
   CALLAPI
   return
fi
## Key Vol-
if [[ "$XMITCMD" == "dwnc" ]]; then
   XMITCALL="0|0|1270267967"
   CALLAPI
   return
fi
## Key Vol+
if [[ "$XMITCMD" == "upc" ]]; then
   XMITCALL="0|0|1270235327"
   CALLAPI
   return
fi
##
### Class D Amp (Philips Universal Remote) NEC 32-bit
##
## Mute Key
if [[ "$XMITCMD" == "subpwr" ]]; then
   XMITCALL="0|0|551506095"
   LCDPI_MSG="toggle subwoofer power"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## (0) Key
if [[ "$XMITCMD" == "subon" ]]; then
   XMITCALL="0|0|551504055"
   LCDPI_MSG="subwoofer on"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## (1) Key
if [[ "$XMITCMD" == "suboff" ]]; then
   XMITCALL="0|0|551520375"
   LCDPI_MSG="subwoofer off"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## Vol (+) Key
if [[ "$XMITCMD" == "subup" ]]; then
   XMITCALL="0|0|551502015"
   CALLAPI
   return
fi
##
## Vol (-) Key
if [[ "$XMITCMD" == "subdwn" ]]; then
   XMITCALL="0|0|551534655"
   CALLAPI
   return
fi
##
### DAM1021 DAC (Onn Soundbar Remote) NEC 32-bit
##
## USB Input (Music Button)
if [[ "$XMITCMD" == "usb" ]]; then
   XMITCALL="0|0|-300872971"
   CALLAPI
   return
fi
## Coaxial Input (Aux Button)
if [[ "$XMITCMD" == "coaxial" ]]; then
   XMITCALL="0|0|-300816361"
   CALLAPI
   return
fi
## Optical Input (TV Button)
if [[ "$XMITCMD" == "optical" ]]; then
   XMITCALL="0|0|-300813811"
   CALLAPI
   return
fi
## Auto Input (Play Button)
if [[ "$XMITCMD" == "inauto" ]]; then
   XMITCALL="0|0|-300833701"
   CALLAPI
   return
fi
##
## RF Power Controller (under dresser)
##
## Vintage Macs
if [[ "$XMITCMD" == "rfa1on" ]]; then
   XMITCALL="1|0|734733"
   LCDPI_MSG="macs on"
   CALLAPI   
   CALL_LCDPI
   return
fi
if [[ "$XMITCMD" == "rfa1off" ]]; then
   XMITCALL="1|0|734734"
   LCDPI_MSG="macs off"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Dresser Lamp
if [[ "$XMITCMD" == "rfa2on" ]]; then
   XMITCALL="1|0|734731"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfa2off" ]]; then
   XMITCALL="1|0|734732"
   CALLAPI
   return
fi
## RetroPi
if [[ "$XMITCMD" == "rfa3on" ]]; then
   XMITCALL="1|0|734735"
   LCDPI_MSG="accessory on"
   CALLAPI   
   CALL_LCDPI
   return
fi
if [[ "$XMITCMD" == "rfa3off" ]]; then
   XMITCALL="1|0|734736"
   LCDPI_MSG="accessory off"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## ESP32 Toggle PC Power
##
if [[ "$XMITCMD" == "rfb3" ]]; then
   XMITCALL="2|2|32"
   CALLAPI   
   return
fi
##
## RF Relay Controller Board 
##
if [[ "$XMITCMD" == "rfb1on" ]]; then
   XMITCALL="1|0|864341"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb1off" ]]; then
   XMITCALL="1|0|864342"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb2on" ]]; then
   XMITCALL="1|0|864343"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb2off" ]]; then
   XMITCALL="1|0|864344"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb3on" ]]; then
   XMITCALL="1|0|864345"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb3off" ]]; then
   XMITCALL="1|0|864346"
   CALLAPI
   return
fi
## Main Lamp Controller
if [[ "$XMITCMD" == "rfc1on" ]]; then
   XMITCALL="1|0|834511"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfc1off" ]]; then
   XMITCALL="1|0|834512"
   CALLAPI
   return
fi
##
## HiFi mini
##
if [[ "$XMITCMD" == "miniupf" ]]; then
   XMITCALL="1|0|696912"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minidwnf" ]]; then
   XMITCALL="1|0|696913"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "miniupc" ]]; then
   XMITCALL="1|0|696922"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minidwnc" ]]; then
   XMITCALL="1|0|696923"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minimuteon" ]]; then
   XMITCALL="1|0|696944"
   CALLAPI   
   LCDPI_MSG="mute miniHiFi"
   CALL_LCDPI
   return
fi

if [[ "$XMITCMD" == "minimuteoff" ]]; then
   XMITCALL="1|0|696999"
   CALLAPI   
   LCDPI_MSG="unmute miniHiFi"
   CALL_LCDPI
   return
fi

if [[ "$XMITCMD" == "minidefv" ]]; then
   XMITCALL="1|0|696930"
   CALLAPI
   return
fi
##
echo "invalid command!"
return
}

#########################################################

## Read the 2nd argument
CMDARG=$2
## Read the 1st argument
CMD=$1

case "$1" in

relax)
RELAX_MODE=${CMDARG%-*}
RELAX_HOST=${CMDARG#*-}
CMDARG="$RELAX_MODE"
### Relax Sounds Playback
if [ $RELAX_HOST == "hifi" ]; then
  echo "playing $CMDARG on HiFi"
  ## Optical Decoder Input
  XMITCMD="coaxial" ; XMIT
  sleep 0.25
  ## Preamp DAC Input
  XMITCMD="dac" ; XMIT 
  ## Play Audio on System
  ESP32="no"; TARGET="hifi.home"; XMITCMD="relax"; CALLAPI
else
  ## Play Audio on Apple TV
  echo "$LCDPI_MSG"
  systemctl stop relaxloop
  systemctl set-environment rpi_relaxmode=$CMDARG
  systemctl start relaxloop
  LCDPI_MSG="playing $CMDARG"
  CALL_LCDPI  
fi
exit
;;

relaxstop)
echo "Stopping playback on Apple TV..."
systemctl stop relaxloop
## Turn off Apple TV
##systemctl set-environment rpi_relaxmode=off
##systemctl start relaxloop
exit
;;

vmute)
if [ "$CMDARG" == "bedroom" ]; then
  XMITCMD="minimute" ; XMITARG="toggle" ; XMIT 
fi
if [ "$CMDARG" == "subs" ]; then
  XMITCMD="subpwr" ; XMIT
fi  
RELAX_MODE=${CMDARG%-*}
RELAX_HOST=${CMDARG#*-}
CMDARG="$RELAX_HOST"
if [ "$CMDARG" == "hifi" ]; then
  ## Stop Audio on System
  ESP32="no"; TARGET="hifi.home"; XMITCMD="stoprelax"; CALLAPI  
  ## Auto Decoder Input
  XMITCMD="autodac" ; XMIT
fi  
exit
;;

### Relax Sounds Volume Up
vup)
if [ "$CMDARG" == "bedroom" ]; then
  XMITCMD="miniupf" ; XMIT
fi
if [ "$CMDARG" == "subs" ]; then
  XMITCMD="subup" ; XMIT
fi   
RELAX_MODE=${CMDARG%-*}
RELAX_HOST=${CMDARG#*-}
CMDARG="$RELAX_HOST"
if [ "$CMDARG" == "hifi" ]; then
  XMITCMD="upc" ; XMIT
fi
exit
;;

### Relax Sounds Volume Down
vdwn)
if [ "$CMDARG" == "bedroom" ]; then
  XMITCMD="minidwnf" ; XMIT
fi
if [ "$CMDARG" == "subs" ]; then
  XMITCMD="subdwn" ; XMIT
fi
RELAX_MODE=${CMDARG%-*}
RELAX_HOST=${CMDARG#*-}
CMDARG="$RELAX_HOST"
if [ "$CMDARG" == "hifi" ]; then
  XMITCMD="dwnc" ; XMIT
fi
exit
;;

## Sleep Mode
sleep)
## Toggle Sounds On/Off 
if (systemctl is-active --quiet relaxloop.service); then
  echo "Stopping playback on Apple TV..."
  systemctl stop relaxloop
  ## Turn off Apple TV
  ##systemctl set-environment rpi_relaxmode=off
  ##systemctl start relaxloop
else
  CALLAPI   
  echo "Service not runnning starting sleep mode..."
  /opt/system/main relax waterfall
  /opt/system/main pcoff
  /opt/system/main alloff
  XMITCMD="hifioff" ; XMIT 
  LCDPI_MSG="sleep mode" 
  CALL_LCDPI  
fi
exit
;;

####################################
## Automated Multi-Functions

lights)
## Toggle Lamps
if [ ! -e $LOCKFOLDER/lights.save ]; then
  touch $LOCKFOLDER/lights.save
  ## Main Lamp
  XMITCMD="rfc1" ; XMITARG="on" ; XMIT
  ## Dresser Lamp
  XMITCMD="rfa2" ; XMITARG="on" ; XMIT
else
  ## Turn all lights off
  rm -f $LOCKFOLDER/lights.save
  ## Main Lamp
  XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
  ## Dresser Lamp
  XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
fi
exit
;;

lightson)
## Turn all lights on
touch $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="on" ; XMIT
## LCDpi message
LCDPI_MSG="lights on"
CALL_LCDPI
exit
;;

lightsoff)
## Turn all lights off
rm -f $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT
## LCDpi message
LCDPI_MSG="lights off"
CALL_LCDPI
exit
;;

allon)
touch $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="on" ; XMIT 
## Desk Light
XMITCMD="rfb1" ; XMITARG="on" ; XMIT 
## LEDwalls
/opt/system/leds candle
sleep 2.5
/opt/system/leds fc 60
## LCDpi message
LCDPI_MSG="all lights on"
CALL_LCDPI
exit
;;

alloff)
## Turn all lights off
rm -f $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
sleep 1
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
sleep 1
## Desk Light
XMITCMD="rfb1" ; XMITARG="off" ; XMIT 
sleep 1
## Blank LEDwalls
/opt/system/leds stop
## LCDpi message
LCDPI_MSG="all lights off"
CALL_LCDPI
exit
;;

## PC Power
pcon)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  echo "wkst.home is online"
else
  XMITCMD="rfb3" ; XMIT 
  LCDPI_MSG="PC on"
  CALL_LCDPI  
fi
exit
;;
##
pcoff)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  XMITCMD="rfb3" ; XMIT
  LCDPI_MSG="PC off"
  CALL_LCDPI  
else
  echo "wkst.home is offline"
fi
exit
;;

autodac)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## Auto Decoder Input
XMITCMD="inauto" ; XMIT 
sleep 0.75
## Preamp DAC Input
XMITCMD="dac" ; XMIT 
exit
;;

usb)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## USB Decoder Input
XMITCMD="usb" ; XMIT
sleep 0.75
## Preamp DAC Input
XMITCMD="dac" ; XMIT
exit
;;

## Coax Input
coax)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## Coaxial Decoder Input
XMITCMD="coaxial" ; XMIT 
sleep 0.75
## Preamp AirPlay Mode
XMITCMD="airplay-preamp" ; XMIT 
exit
;;

## Optical Input
opt)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## Optical Decoder Input
XMITCMD="optical" ; XMIT
sleep 0.75
## Preamp DAC Input
XMITCMD="optical-preamp" ; XMIT
exit
;;

roomon)
## Main Lamp On
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="on" ; XMIT 
## Desk Light
XMITCMD="rfb1" ; XMITARG="on" ; XMIT 
## PC Power On
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  echo "wkst.home is online"
else
  XMITCMD="rfb3" ; XMIT 
fi
## LEDwalls
/opt/system/leds abstract
/opt/system/leds fc norm
## LCDpi message
LCDPI_MSG="all power on"
CALL_LCDPI
exit
;;

roomoff)
## Main Lamp Off
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
## Desk Light
XMITCMD="rfb1" ; XMITARG="off" ; XMIT 
## PC Power Off
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  XMITCMD="rfb3" ; XMIT 
else
  echo "wkst.home is offline"
fi
## Audio System Power Off
XMITCMD="hifioff" ; XMIT 
## Blank LEDwalls
/opt/system/leds stop
## Stop playback on Apple TV
systemctl stop relaxloop
## Turn off Apple TV
##systemctl set-environment rpi_relaxmode=off
##systemctl start relaxloop
## LCDpi message
LCDPI_MSG="all power off"
CALL_LCDPI
exit
;;

server)
## Read argument
_CMDARG=${CMDARG//$'\n'/} 
SERVERARG=${_CMDARG%-*}
FILESCMD=${_CMDARG#*-}
## transmit action to file server
if [ "$SERVERARG" == "files" ]; then
  if [ "$FILESCMD" != "" ]; then
    ESP32="no"; TARGET="files.home"; XMITCMD="$FILESCMD"; CALLAPI
  fi  
  exit
fi
#if [ "$SERVERARG" == "unifi" ]; then
#  ## Toggle Unifi Controller
#  SYSDSTAT="$(systemctl is-active unifi.service)"
#  if [ "${SYSDSTAT}" = "active" ]; then
#    echo "UniFi running, stopping service..." &>> $LOGFILE
#    systemctl stop unifi &>> $LOGFILE
#  else 
#    echo "UniFi not running, starting service..." &>> $LOGFILE 
#    systemctl start unifi &>> $LOGFILE
#    echo "access at 'https://automate.home:8443/' " &>> $LOGFILE
#  fi
#  exit
#fi
## Pass action file to the hypervisor
echo "action $SERVERARG submitted." &>> $LOGFILE
touch $RAMDISK/$SERVERARG.txt
## LCDpi message
LCDPI_MSG="$SERVERARG cmd sent"
CALL_LCDPI
exit
;;

active)
echo "Active services."
systemctl list-units --type=service --state=active
exit
;;

running)
echo "Running services."
systemctl list-units --type=service --state=running
exit
;;

timers)
## List Active Timers
systemctl list-timers --all
exit
;;

loadtimes)
## Display list of system daemons and startup times
systemd-analyze blame
exit
;;

### Examples of URL strings ###
# http://automate:9300/exec.php?var=&arg=lightson&action=main
# http://automate:9300/exec.php?var=&arg=lightsoff&action=main
# http://automate:9300/exec.php?var=prism&arg=video&action=leds
###############################

*) ###############################################
### If command not matched above, pass argument to Xmit function
XMITCMD="$CMD" ; XMITARG="$2" ; XMIT
exit 0 
  ;; #############################################
esac   


