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

XMIT_IP="10.177.1.12" ## Xmit IP Address
BEDPI_IP="10.177.1.15" ## BedPi Address

CALLAPI(){
#### API Call
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 3 --retry 1 --retry-delay 1 --no-keepalive"
## API Type
if [[ "$ESP32" == "no" ]]; then
  /usr/bin/curl $CURLARGS --data "var=$CMDARG&arg=$XMITCMD&action=main" http://$TARGET/exec.php
  CMDARG=""
else ## ESP32 Xmit URL
  /usr/bin/curl $CURLARGS http://"$XMIT_IP" -H "Accept: ####?|$XMITCALL"
fi
## Clear Data
TARGET=""
XMITCMD=""
XMITCALL=""
XMITARG=""
ESP32=""
sleep 0.5
return
}

CALL_LCDPI(){
  /opt/rpi/lcdpi "$LCDPI_MSG" &
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
case "$XMITCMD" in
  "pwrhifi")
   ## Mute Subwoofer Amp
   XMITCALL="0|0|551520375"
   CALLAPI
   sleep 1.5
    ## Power Off Preamp  
   XMITCALL="0|0|1270227167"
   CALLAPI   
   LCDPI_MSG="system power"
   CALL_LCDPI
   return
fi
  "hifioff")
   ## Mute Subwoofer Amp
   XMITCALL="0|0|551520375"
   CALLAPI
   sleep 1.5
   ## Power Off Preamp  
   XMITCALL="0|0|1261859214"
   CALLAPI
   LCDPI_MSG="system off"
   CALL_LCDPI
   return
fi
  "hifion")
   XMITCALL="0|0|1261869414"
   CALLAPI
   LCDPI_MSG="system on"   
   CALL_LCDPI
   return
fi
## DAC
  "dac")
   XMITCALL="0|0|1261793423"
   LCDPI_MSG="DAC in"
   CALLAPI
   CALL_LCDPI
   return   
fi
## Aux
  "aux")
   XMITCALL="0|0|1261826063"
   LCDPI_MSG="aux in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Phono
  "phono")
   XMITCALL="0|0|1261766903"
   LCDPI_MSG="phono in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Airplay
  "airplay-preamp")
   XMITCALL="0|0|1261799543"
   LCDPI_MSG="AirPlay in"
   CALLAPI   
   CALL_LCDPI
   return
fi   
## Volume Limit Mode
  "vlimit")
   XMITCALL="0|0|1261783223"
   LCDPI_MSG="volume limiter"
   CALLAPI   
   CALL_LCDPI
   return   
fi   
## Optical Mode
  "optical-preamp")
   XMITCALL="0|0|1261824023"
   LCDPI_MSG="optical in"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Key Toggle Hi-Pass Filter
  "togglehpf")
   XMITCALL="0|0|1261875534"
   LCDPI_MSG="toggle HPF"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Key Mute / Toggle
  "mute")
   XMITCALL="0|0|1270259807"
   CALLAPI   
   return
fi
## Key Vol Down Fine
  "dwn")
   XMITCALL="0|0|1261885734"
   CALLAPI
   return
fi
## Key Vol Up Fine
  "up")
   XMITCALL="0|0|1261853094"
   CALLAPI
   return
fi
## Key Vol Down Course
  "dwnc")
   XMITCALL="0|0|1270267967"
   CALLAPI
   return
fi
## Key Vol Up Course
  "upc")
   XMITCALL="0|0|1270235327"
   CALLAPI
   return
fi
##
### Class D Amp (Philips Universal Remote) NEC 32-bit
##
## Mute Key
  "submute")
   XMITCALL="0|0|551506095"
   LCDPI_MSG="toggle subwoofer amp"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## (0) Key
  "subon")
   XMITCALL="0|0|551504055"
   LCDPI_MSG="subwoofer on"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## (1) Key
  "suboff")
   XMITCALL="0|0|551520375"
   LCDPI_MSG="subwoofer off"
   CALLAPI   
   CALL_LCDPI
   return
fi
##
## Vol (+) Key
  "subup")
   XMITCALL="0|0|551502015"
   CALLAPI
   return
fi
##
## Vol (-) Key
  "subdwn")
   XMITCALL="0|0|551534655"
   CALLAPI
   return
fi
##
### DAM1021 DAC (Onn Soundbar Remote) NEC 32-bit
##
## USB Input (Music Button)
  "usb")
   XMITCALL="0|0|-300872971"
   CALLAPI
   return
fi
## Coaxial Input (Aux Button)
  "coaxial")
   XMITCALL="0|0|-300816361"
   CALLAPI
   return
fi
## Optical Input (TV Button)
  "optical")
   XMITCALL="0|0|-300813811"
   CALLAPI
   return
fi
## Auto Input (Play Button)
  "inauto")
   XMITCALL="0|0|-300833701"
   CALLAPI
   return
fi
##
## RF Power Controller (under dresser)
##
## Vintage Macs
  "rfa1on")
   XMITCALL="1|0|734733"
   LCDPI_MSG="macs on"
   CALLAPI   
   CALL_LCDPI
   return
fi
  "rfa1off")
   XMITCALL="1|0|734734"
   LCDPI_MSG="macs off"
   CALLAPI   
   CALL_LCDPI
   return
fi
## Dresser Lamp
  "rfa2on")
   XMITCALL="1|0|734731"
   CALLAPI
   return
fi
  "rfa2off")
   XMITCALL="1|0|734732"
   CALLAPI
   return
fi
## RetroPi
  "rfa3on")
   XMITCALL="1|0|734735"
   LCDPI_MSG="accessory on"
   CALLAPI   
   return
fi
  "rfa3off")
   XMITCALL="1|0|734736"
   LCDPI_MSG="accessory off"
   CALLAPI   
   return
fi
##
## HeartLED 433Mhz Control
  "htleds_off") # LEDs off
   XMITCALL="1|0|732101"
   CALLAPI   
   return
fi
  "htleds_cyc") # Cycle-through LEDs
   XMITCALL="1|0|732102"
   CALLAPI   
   return
fi
  "htleds_a") # LEDs mode A:
   XMITCALL="1|0|732103"
   CALLAPI   
   return
fi
  "htleds_b") # LEDs mode B:
   XMITCALL="1|0|732104"
   CALLAPI   
   return
fi
  "htleds_c") # LEDs mode C:
   XMITCALL="1|0|732105"
   CALLAPI   
   return
fi
  "htleds_on") # all LEDs on
   XMITCALL="1|0|732106"
   CALLAPI   
   return
fi
##
## ESP32 Toggle PC Power
##
  "rfb3") then
   XMITCALL="2|2|32"
   CALLAPI   
   return
fi
##
## RF Relay Controller Board 
##
  "rfb1on")
   XMITCALL="1|0|864341"
   CALLAPI
   return
fi
  "rfb1off")
   XMITCALL="1|0|864342"
   CALLAPI
   return
fi
  "rfb2on")
   XMITCALL="1|0|864343"
   CALLAPI
   return
fi
  "rfb2off")
   XMITCALL="1|0|864344"
   CALLAPI
   return
fi
  "rfb3on")
   XMITCALL="1|0|864345"
   CALLAPI
   return
fi
  "rfb3off")
   XMITCALL="1|0|864346"
   CALLAPI
   return
fi
## Main Lamp Controller
  "rfc1on")
   XMITCALL="1|0|834511"
   CALLAPI
   return
fi
  "rfc1off")
   XMITCALL="1|0|834512"
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

case "$CMD" in

bedpi)
ESP32="no"
TARGET="$BEDPI_IP"
XMITCMD="$CMDARG"
CALLAPI
exit
;;

relax)
ESP32="no"
TARGET="$BEDPI_IP"
XMITCMD="relax"
LCDPI_MSG="playing $CMDARG"
CALLAPI
CALL_LCDPI  
exit
;;

lcdpi_message)
LCDPI_MSG="$CMDARG"
CALL_LCDPI  
exit
;;

status)
/opt/system/status > /dev/null 2> /dev/null
exit
;;

mainon)
## Window Lamp
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
exit
;;

mainoff)
## Window Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT
exit
;;

lightson)
## Window Lamp
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="on" ; XMIT
exit
;;

lightsoff)
## Window Lamp
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT
## Blank LEDwalls
/opt/system/leds stop
exit
;;

ambient)
## LEDwalls
/opt/system/leds fc 40
/opt/system/leds candle
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
## Auto Decoder Input
XMITCMD="inauto" ; XMIT 
sleep 0.75
## Preamp DAC Input
XMITCMD="dac" ; XMIT 
exit
;;

usb)
## USB Decoder Input
XMITCMD="usb" ; XMIT
sleep 0.75
## Preamp DAC Input
XMITCMD="dac" ; XMIT
exit
;;

## Coax Input
coax)
## Coaxial Decoder Input
XMITCMD="coaxial" ; XMIT 
sleep 0.75
## Preamp AirPlay Mode
XMITCMD="airplay-preamp" ; XMIT 
exit
;;

## Optical Input
opt)
## Optical Decoder Input
XMITCMD="optical" ; XMIT
sleep 0.75
## Preamp DAC Input
XMITCMD="optical-preamp" ; XMIT
exit
;;

allon)
## Window Lamp On
XMITCMD="rfc1" ; XMITARG="on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="on" ; XMIT 
## PC Power On
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  echo "wkst.home is online"
else
  XMITCMD="rfb3" ; XMIT 
fi
## LEDwalls
/opt/system/leds abstract
## HeartLED mode C:
XMITCMD="htleds_c" ; XMIT
sleep 0.75
## LCDpi message
LCDPI_MSG="all power on"
CALL_LCDPI
exit
;;

alloff)
## Window Lamp Off
XMITCMD="rfc1" ; XMITARG="off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2" ; XMITARG="off" ; XMIT 
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
## HeartLED off
XMITCMD="htleds_off" ; XMIT
sleep 0.75
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
## start / stop legacy services
if [ "$SERVERARG" == "startlegacy" ]; then
  echo "Starting legacy services..." &>> $LOGFILE
  CMDARG=""
  ESP32="no"
  TARGET="$BEDPI_IP"
  XMITCMD="apd-on"
  CALLAPI
  LCDPI_MSG="Legacy services started."
  CALL_LCDPI
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
  CMDARG=""
  ESP32="no"
  TARGET="$BEDPI_IP"
  XMITCMD="apd-off"
  CALLAPI
  LCDPI_MSG="Legacy services stopped."
  CALL_LCDPI
  exit
fi
## Pass action file to the hypervisor
echo "action $SERVERARG submitted." &>> $LOGFILE
touch $RAMDISK/$SERVERARG.txt
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


