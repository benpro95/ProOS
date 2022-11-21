#!/bin/bash
##
###########################################################
## Main Home Automation Script by Ben Provenzano III v18 ##
###########################################################
###########################################################
## Do not use the screen command in this script ##

LOCKFOLDER=/var/lock/rpi

CALLAPI(){
#### API Call
## Select API Type
if [[ "$ESP32" == "no" ]]; then
  APIDATA="--data var=$CMDARG&arg=$XMITCMD&action=main http://$TARGET/exec.php"
  CMDARG=""
else
  ## ESP32 Xmit URL
  TARGET="10.177.1.17"
  APIDATA="--url http://$TARGET:80/xmit/$XMITCALL"
fi
## Transmit to API
/usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
 --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive $APIDATA
## Clear Data 
TARGET=""
XMITCMD=""
XMITCALL=""
XMITARG=""
APIDATA=""
ESP32=""
return
}

CALL232(){
### Transmit to RS-232 serial
/usr/bin/python2 - <<END
import serial
import termios
port = '/dev/ttyACM0'
f = open(port)
attrs = termios.tcgetattr(f)
attrs[2] = attrs[2] & ~termios.HUPCL
termios.tcsetattr(f, termios.TCSAFLUSH, attrs)
f.close()
se = serial.Serial()
se.baudrate = 9600
se.port = port
se.open()
se.write(str.encode('$XMITCALL'))
END
XMITCMD=""
XMITCALL=""
XMITARG=""
return
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
   XMITCALL="irtx.nec.1270227167"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "hifioff" ]]; then
   rm -f $LOCKFOLDER/subs.enabled 
   XMITCALL="irtx.nec.1261859214"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "hifion" ]]; then
   rm -f $LOCKFOLDER/subs.enabled 
   XMITCALL="irtx.nec.1261869414"
   CALLAPI
   return
fi
## DAC
if [[ "$XMITCMD" == "dac" ]]; then
   XMITCALL="irtx.nec.1261793423"
   CALLAPI
   return   
fi
## Aux
if [[ "$XMITCMD" == "aux" ]]; then
   XMITCALL="irtx.nec.1261826063"
   CALLAPI
   return
fi
## Phono
if [[ "$XMITCMD" == "phono" ]]; then 
   XMITCALL="irtx.nec.1261766903"
   CALLAPI
   return
fi
## Airplay
if [[ "$XMITCMD" == "airplay" ]]; then
   XMITCALL="irtx.nec.1261799543"
   CALLAPI
   return
fi   
## PC Mode
if [[ "$XMITCMD" == "pcmode" ]]; then
   XMITCALL="irtx.nec.1261783223"
   CALLAPI
   return   
fi   
## Key Mute / Toggle
if [[ "$XMITCMD" == "mute" ]]; then
   XMITCALL="irtx.nec.1270259807"
   CALLAPI
   return
fi
## Key Force Mute 
if [[ "$XMITCMD" == "forcemute" ]]; then
   XMITCALL="irtx.nec.1261824023"
   CALLAPI
   return
fi
## Key Toggle Hi-Pass Filter
if [[ "$XMITCMD" == "togglehpf" ]]; then
   XMITCALL="irtx.nec.1261875534"
   CALLAPI
   return
fi
## Key Down
if [[ "$XMITCMD" == "dwnf" ]]; then
   XMITCALL="irtx.nec.1261885734"
   CALLAPI
   return
fi
## Key Up
if [[ "$XMITCMD" == "upf" ]]; then
   XMITCALL="irtx.nec.1261853094"
   CALLAPI
   return
fi
## Key Vol-
if [[ "$XMITCMD" == "dwnc" ]]; then
   XMITCALL="irtx.nec.1270267967"
   CALLAPI
   return
fi
## Key Vol+
if [[ "$XMITCMD" == "upc" ]]; then
   XMITCALL="irtx.nec.1270235327"
   CALLAPI
   return
fi
##
### Class D Amp (Philips Universal Remote) NEC 32-bit
##
## Mute Key
if [[ "$XMITCMD" == "subpwr" ]]; then
   XMITCALL="irtx.nec.551506095"
   CALLAPI
   return
fi
##
## (0) Key
if [[ "$XMITCMD" == "subon" ]]; then
   XMITCALL="irtx.nec.551504055"
   CALLAPI
   return
fi
##
## (1) Key
if [[ "$XMITCMD" == "suboff" ]]; then
   XMITCALL="irtx.nec.551520375"
   CALLAPI
   return
fi
##
## Vol (+) Key
if [[ "$XMITCMD" == "subup" ]]; then
   XMITCALL="irtx.nec.551502015"
   CALLAPI
   return
fi
##
## Vol (-) Key
if [[ "$XMITCMD" == "subdwn" ]]; then
   XMITCALL="irtx.nec.551534655"
   CALLAPI
   return
fi
##
### DAM1021 DAC (Onn Soundbar Remote) NEC 32-bit
##
## USB Input (Music Button)
if [[ "$XMITCMD" == "usb" ]]; then
   XMITCALL="irtx.nec.-300872971"
   CALLAPI
   return
fi
## Coaxial Input (Aux Button)
if [[ "$XMITCMD" == "coaxial" ]]; then
   XMITCALL="irtx.nec.-300816361"
   CALLAPI
   return
fi
## Optical Input (TV Button)
if [[ "$XMITCMD" == "optical" ]]; then
   XMITCALL="irtx.nec.-300813811"
   CALLAPI
   return
fi
## Auto Input (Play Button)
if [[ "$XMITCMD" == "inauto" ]]; then
   XMITCALL="irtx.nec.-300833701"
   CALLAPI
   return
fi
##
## RF Power Controller (under dresser)
##
## Vintage Macs
if [[ "$XMITCMD" == "rfa1on" ]]; then
   XMITCALL="rftx.734733"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfa1off" ]]; then
   XMITCALL="rftx.734734"
   CALLAPI
   return
fi
## Dresser Lamp
if [[ "$XMITCMD" == "rfa2on" ]]; then
   XMITCALL="rftx.734731"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfa2off" ]]; then
   XMITCALL="rftx.734732"
   CALLAPI
   return
fi
## RetroPi
if [[ "$XMITCMD" == "rfa3on" ]]; then
   XMITCALL="rftx.734735"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfa3off" ]]; then
   XMITCALL="rftx.734736"
   CALLAPI
   return
fi
##
## ESP32 Toggle PC Power
##
if [[ "$XMITCMD" == "rfb3" ]]; then
   XMITCALL="fet.tgl.32"
   CALLAPI
   return
fi
##
## RF Relay Controller Board 
##
if [[ "$XMITCMD" == "rfb1on" ]]; then
   XMITCALL="rftx.864341"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb1off" ]]; then
   XMITCALL="rftx.864342"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb2on" ]]; then
   XMITCALL="rftx.864343"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb2off" ]]; then
   XMITCALL="rftx.864344"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb3on" ]]; then
   XMITCALL="rftx.864345"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfb3off" ]]; then
   XMITCALL="rftx.864346"
   CALLAPI
   return
fi
## Main Lamp Controller
if [[ "$XMITCMD" == "rfc1on" ]]; then
   XMITCALL="rftx.834511"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "rfc1off" ]]; then
   XMITCALL="rftx.834512"
   CALLAPI
   return
fi
##
## HiFi mini
##
if [[ "$XMITCMD" == "miniupf" ]]; then
   XMITCALL="rftx.696912"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minidwnf" ]]; then
   XMITCALL="rftx.696913"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "miniupc" ]]; then
   XMITCALL="rftx.696922"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minidwnc" ]]; then
   XMITCALL="rftx.696923"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minimute" ]]; then
   XMITCALL="rftx.696944"
   CALLAPI
   return
fi
if [[ "$XMITCMD" == "minidefv" ]]; then
   XMITCALL="rftx.696930"
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
  ## Preamp DAC Input
  XMITCMD="dac" ; XMIT 
  ## Play Audio on System
  ESP32="no"; TARGET="hifi.home"; XMITCMD="relax"; CALLAPI
else
  ## Play Audio on Apple TV
  echo "playing $CMDARG on Apple TV"
  systemctl stop relaxloop
  systemctl set-environment rpi_relaxmode=$CMDARG
  systemctl start relaxloop
fi
exit
;;

vmute)
if [ "$CMDARG" == "bedroom" ]; then
  ## Turn Off Apple TV
  systemctl stop relaxloop
  systemctl set-environment rpi_relaxmode=off
  systemctl start relaxloop
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
  XMITCMD="inauto" ; XMIT
  ## Preamp DAC Input
  XMITCMD="dac" ; XMIT
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
  echo "Turning off Apple TV..."
  systemctl stop relaxloop
  systemctl set-environment rpi_relaxmode=off
  systemctl start relaxloop
else
  echo "Service not runnning starting sleep mode..."
  /opt/system/main relax waterfall
  /opt/system/main pcoff
  /opt/system/main alloff
  XMITCMD="hifioff" ; XMIT 
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
exit
;;

lightsoff)
## Turn all lights off
rm -f $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
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
exit
;;

alloff)
## Turn all lights off
rm -f $LOCKFOLDER/lights.save
## Main Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
## Desk Light
XMITCMD="rfb1" ; XMITARG="off" ; XMIT 
## Blank LEDwalls
/opt/system/leds stop
exit
;;

## PC Power
pcon)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  echo "wkst.home is online"
else
  XMITCMD="rfb3" ; XMIT 
fi
exit
;;
##
pcoff)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  XMITCMD="rfb3" ; XMIT 
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
## Preamp DAC Input
XMITCMD="dac" ; XMIT 
exit
;;

usb)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## USB Decoder Input
XMITCMD="usb" ; XMIT 
## Preamp DAC Input
XMITCMD="dac" ; XMIT 
## Preamp PC Mode
XMITCMD="pcmode" ; XMIT 
exit
;;

## Coax Input
coax)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## Coaxial Decoder Input
XMITCMD="coaxial" ; XMIT 
## Preamp DAC Input
XMITCMD="dac" ; XMIT 
## Preamp AirPlay Mode
XMITCMD="airplay" ; XMIT 
exit
;;

## Optical Input
opt)
## Reset volume tokens
rm -f $LOCKFOLDER/subs.enabled
## Optical Decoder Input
XMITCMD="optical" ; XMIT
## Preamp DAC Input
XMITCMD="dac" ; XMIT
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
## Turn Off Apple TV
systemctl stop relaxloop
systemctl set-environment rpi_relaxmode=off
systemctl start relaxloop
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
if [ "$SERVERARG" == "unifi" ]; then
  ## Toggle Unifi Controller
  SYSDSTAT="$(systemctl is-active unifi.service)"
  if [ "${SYSDSTAT}" = "active" ]; then
    echo "UniFi running, stopping service..."
    systemctl stop unifi
  else 
    echo "UniFi not running, starting service..."  
    systemctl start unifi
    echo "access at 'https://automate.home:8443/' "
  fi
  exit
fi
## Pass action file to the hypervisor
touch /mnt/store/$SERVERARG.txt
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


