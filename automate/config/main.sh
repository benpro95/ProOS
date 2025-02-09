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
XMITCMD=""
TARGET=""

FILES_IP="10.177.1.4" ## Files IP
XMIT_IP="10.177.1.12" ## Xmit IP
BEDPI_IP="10.177.1.15" ## BedPi IP

CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 3 --retry 1 --retry-delay 1 --no-keepalive"

CALLAPI(){
  ## Default Target
  if [[ "$TARGET" == "" ]]; then
    ## ESP32 Xmit URL
    /usr/bin/curl $CURLARGS http://"$XMIT_IP" -H "Accept: ####?|$XMITCMD"
  else   
    /usr/bin/curl $CURLARGS --data "var=$CMDARG&arg=$XMITCMD&action=main" http://$TARGET/exec.php
  fi
  ## Clear Data
  TARGET=""
  XMITCMD=""
}

CALL_LCDPI(){
  /opt/system/lcdpi "$LCDPI_MSG" &
}

XMIT(){
#### ESP32 Transmit Function
case "$XMITCMD" in
  ### HiFi Preamp
  ##
  ## Power
  "pwrhifi")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1.5
    ## Power Off Preamp  
    XMITCMD="0|0|1270227167"
    CALLAPI   
    LCDPI_MSG="system power"
    CALL_LCDPI
    ;;
  "hifioff")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1.5
    ## Power Off Preamp  
    XMITCMD="0|0|1261859214"
    CALLAPI
    LCDPI_MSG="system off"
    CALL_LCDPI
    ;;
  "hifion")
    XMITCMD="0|0|1261869414"
    CALLAPI
    LCDPI_MSG="system on"   
    CALL_LCDPI
    ;;
  ## DAC
  "dac")
    XMITCMD="0|0|1261793423"
    LCDPI_MSG="DAC in"
    CALLAPI
    CALL_LCDPI
    ;;
  ## Aux
  "aux")
    XMITCMD="0|0|1261826063"
    LCDPI_MSG="aux in"
    CALLAPI   
    CALL_LCDPI
    ;;
  ## Phono
  "phono")
    XMITCMD="0|0|1261766903"
    LCDPI_MSG="phono in"
    CALLAPI   
    CALL_LCDPI
    ;;
  ## Airplay
  "airplay-preamp")
    XMITCMD="0|0|1261799543"
    LCDPI_MSG="AirPlay in"
    CALLAPI   
    CALL_LCDPI
    ;;   
  ## Volume Limit Mode
  "vlimit")
    XMITCMD="0|0|1261783223"
    LCDPI_MSG="volume limiter"
    CALLAPI   
    CALL_LCDPI
    ;;  
  ## Optical Mode
  "optical-preamp")
    XMITCMD="0|0|1261824023"
    LCDPI_MSG="optical in"
    CALLAPI   
    CALL_LCDPI
    ;;
  ## Key Toggle Hi-Pass Filter
  "togglehpf")
    XMITCMD="0|0|1261875534"
    LCDPI_MSG="toggle HPF"
    CALLAPI   
    CALL_LCDPI
    ;;
  ## Key Mute / Toggle
  "mute")
    XMITCMD="0|0|1270259807"
    CALLAPI   
    ;;
  ## Key Vol Down Fine
  "dwn")
    XMITCMD="0|0|1261885734"
    CALLAPI
    ;;
  ## Key Vol Up Fine
  "up")
    XMITCMD="0|0|1261853094"
    CALLAPI
    ;;
  ## Key Vol Down Course
  "dwnc")
    XMITCMD="0|0|1270267967"
    CALLAPI
    ;;
  ## Key Vol Up Course
  "upc")
    XMITCMD="0|0|1270235327"
    CALLAPI
    ;;
  ##
  ### Class D Amp (Philips Universal Remote) NEC 32-bit
  ##
  ## Mute Key
  "submute")
    XMITCMD="0|0|551506095"
    LCDPI_MSG="toggle subwoofer amp"
    CALLAPI   
    CALL_LCDPI
    ;;
  ##
  ## (0) Key
  "subon")
    XMITCMD="0|0|551504055"
    LCDPI_MSG="subwoofer on"
    CALLAPI   
    CALL_LCDPI
    ;;
  ##
  ## (1) Key
  "suboff")
    XMITCMD="0|0|551520375"
    LCDPI_MSG="subwoofer off"
    CALLAPI   
    CALL_LCDPI
    ;;
  ##
  ## Vol (+) Key
  "subup")
    XMITCMD="0|0|551502015"
    CALLAPI
    ;;
  ##
  ## Vol (-) Key
  "subdwn")
    XMITCMD="0|0|551534655"
    CALLAPI
    ;;
  ### DAM1021 DAC (Onn Soundbar Remote) NEC 32-bit
  ##
  ## USB Input (Music Button)
  "usb")
    XMITCMD="0|0|-300872971"
    CALLAPI
    ;;
  ## Coaxial Input (Aux Button)
  "coaxial")
    XMITCMD="0|0|-300816361"
    CALLAPI
    ;;
  ## Optical Input (TV Button)
  "optical")
    XMITCMD="0|0|-300813811"
    CALLAPI
    ;;
  ## Auto Input (Play Button)
  "inauto")
    XMITCMD="0|0|-300833701"
    CALLAPI
    ;;
  ##
  ## RF Power Controller (under dresser)
  ##
  ## Vintage Macs
  "rfa1on")
    XMITCMD="1|0|734733"
    LCDPI_MSG="macs on"
    CALLAPI   
    CALL_LCDPI
    ;;
  "rfa1off")
    XMITCMD="1|0|734734"
    LCDPI_MSG="macs off"
    CALLAPI   
    CALL_LCDPI
    ;;
  ## Dresser Lamp
  "rfa2on")
    XMITCMD="1|0|734731"
    CALLAPI
    ;;
  "rfa2off")
    XMITCMD="1|0|734732"
    CALLAPI
    ;;
  ## RetroPi
  "rfa3on")
    XMITCMD="1|0|734735"
    LCDPI_MSG="accessory on"
    CALLAPI   
    ;;
  "rfa3off")
    XMITCMD="1|0|734736"
    LCDPI_MSG="accessory off"
    CALLAPI   
    ;;
  ##
  ## HeartLED 433Mhz Control
  "htleds_off") # LEDs off
    XMITCMD="1|0|732101"
    CALLAPI   
    ;;
  "htleds_cyc") # Cycle-through LEDs
    XMITCMD="1|0|732102"
    CALLAPI   
    ;;
  "htleds_a") # LEDs mode A:
    XMITCMD="1|0|732103"
    CALLAPI   
    ;;
  "htleds_b") # LEDs mode B:
    XMITCMD="1|0|732104"
    CALLAPI   
    ;;
  "htleds_c") # LEDs mode C:
    XMITCMD="1|0|732105"
    CALLAPI   
    ;;
  "htleds_on") # all LEDs on
    XMITCMD="1|0|732106"
    CALLAPI   
    ;;
  ##
  ## ESP32 Toggle PC Power
  ##
  "rfb3")
    XMITCMD="2|2|32"
    CALLAPI   
    ;;
  ##
  ## RF Relay Controller Board 
  ##
  "rfb1on")
    XMITCMD="1|0|864341"
    CALLAPI
    ;;
  "rfb1off")
    XMITCMD="1|0|864342"
    CALLAPI
    ;;
  "rfb2on")
    XMITCMD="1|0|864343"
    CALLAPI
    ;;
  "rfb2off")
    XMITCMD="1|0|864344"
    CALLAPI
    ;;
  "rfb3on")
    XMITCMD="1|0|864345"
    CALLAPI
    ;;
  "rfb3off")
    XMITCMD="1|0|864346"
    CALLAPI
    ;;
  ## Main Lamp Controller
  "rfc1on")
    XMITCMD="1|0|834511"
    CALLAPI
    ;;
  "rfc1off")
    XMITCMD="1|0|834512"
    CALLAPI
    ;;

*)
  echo "invalid command!"
  ;;
esac

}

########################

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
XMITCMD="rfc1on"; XMIT 
exit
;;

mainoff)
## Window Lamp
XMITCMD="rfc1off"; XMIT 
## Dresser Lamp
XMITCMD="rfa2off"; XMIT
exit
;;

lightson)
## Window Lamp
XMITCMD="rfc1on"; XMIT 
## Dresser Lamp
XMITCMD="rfa2on"; XMIT
exit
;;

lightsoff)
## Window Lamp
XMITCMD="rfc1off"; XMIT 
## Dresser Lamp
XMITCMD="rfa2off"; XMIT
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
XMITCMD="rfc1on" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2on" ; XMIT 
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
XMITCMD="rfc1off" ; XMIT 
## Dresser Lamp
XMITCMD="rfa2off" ; XMIT 
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
    TARGET="$FILES_IP"; 
    XMITCMD="$FILESCMD"; 
    CALLAPI
  fi  
  exit
fi
## start / stop legacy services
if [ "$SERVERARG" == "startlegacy" ]; then
  echo "Starting legacy services..." &>> $LOGFILE
  TARGET="$BEDPI_IP"
  XMITCMD="apd-on"
  CALLAPI
  LCDPI_MSG="Legacy services started."
  CALL_LCDPI
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
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
XMITCMD="$CMD" ; XMIT
exit 0 
  ;; #############################################
esac   


