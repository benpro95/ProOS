#!/bin/bash
##
###########################################################
## Main Home Automation Script by Ben Provenzano III v20 ##
###########################################################
###########################################################
## Do not use the screen command in this script ##

RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
LCDPI_MSG=""
ATV_CMD=""
XMITCMD=""
TARGET=""

FILES_IP="10.177.1.4" ## Files IP
XMIT_IP="10.177.1.12" ## Xmit IP
BEDPI_IP="10.177.1.15" ## BedPi IP
ATV_MAC="3E:08:87:30:B9:A8" ## Bedroom Apple TV MAC

CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 3 --retry 1 --retry-delay 1 --no-keepalive"

CALLAPI(){
  ## Default Target
  if [[ "$TARGET" == "" ]]; then
    ## ESP32 Xmit API
    /usr/bin/curl $CURLARGS --header "Accept: ####?|$XMITCMD" http://"$XMIT_IP":80
  else
    ## Pi PHP API 
    /usr/bin/curl $CURLARGS --data "var=$SEC_ARG&arg=$XMITCMD&action=main" http://"$TARGET":80/exec.php
  fi
  ## Display Message
  if [[ "$LCDPI_MSG" != "" ]]; then
    /opt/system/lcdpi "$LCDPI_MSG" > /dev/null 2>&1
  fi
  TARGET=""
  XMITCMD=""
  LCDPI_MSG=""
}

## Control Apple TV
ATV_CTL(){
  if [[ "$ATV_CMD" != "" ]]; then
    source /opt/pyatv/bin/activate
    atvremote --id "$ATV_MAC" "$ATV_CMD" 
    deactivate
  fi
  ATV_CMD=""
}

XMIT(){
#### ESP32 Transmit Function
case "$XMITCMD" in
  ### HiFi Preamp
  ## Power
  "pwrhifi")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1
    ## Power Off Preamp  
    XMITCMD="0|0|1270227167"
    LCDPI_MSG="system power"
    CALLAPI   
    ;;
  "hifioff")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1
    ## Power Off Preamp  
    XMITCMD="0|0|1261859214"
    LCDPI_MSG="system off"
    CALLAPI
    ;;
  "hifion")
    XMITCMD="0|0|1261869414"
    CALLAPI
    LCDPI_MSG="system on"   
    CALLAPI
    ;;
  ## DAC
  "dac")
    XMITCMD="0|0|1261793423"
    LCDPI_MSG="DAC in"
    CALLAPI
    ;;
  ## Aux
  "aux")
    XMITCMD="0|0|1261826063"
    LCDPI_MSG="aux in"
    CALLAPI   
    ;;
  ## Phono
  "phono")
    XMITCMD="0|0|1261766903"
    LCDPI_MSG="phono in"
    CALLAPI   
    ;;
  ## Airplay
  "airplay-preamp")
    XMITCMD="0|0|1261799543"
    LCDPI_MSG="AirPlay in"
    CALLAPI   
    ;;   
  ## Volume Limit Mode
  "vlimit")
    XMITCMD="0|0|1261783223"
    LCDPI_MSG="volume limiter"
    CALLAPI   
    ;;  
  ## Optical Mode
  "optical-preamp")
    XMITCMD="0|0|1261824023"
    LCDPI_MSG="optical in"
    CALLAPI   
    ;;
  ## Key Toggle Hi-Pass Filter
  "togglehpf")
    XMITCMD="0|0|1261875534"
    LCDPI_MSG="toggle HPF"
    CALLAPI   
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
    ;;
  ##
  ## (0) Key
  "subon")
    XMITCMD="0|0|551504055"
    LCDPI_MSG="subwoofer on"
    CALLAPI   
    ;;
  ##
  ## (1) Key
  "suboff")
    XMITCMD="0|0|551520375"
    LCDPI_MSG="subwoofer off"
    CALLAPI   
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
    ;;
  "rfa1off")
    XMITCMD="1|0|734734"
    LCDPI_MSG="macs off"
    CALLAPI   
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

## Read command line arguments
FIRST_ARG=$1
SEC_ARG=$2

case "$FIRST_ARG" in

sleep)
## Send Command
TARGET="$BEDPI_IP"
LCDPI_MSG="sleep mode"
XMITCMD="sleepmode"
CALLAPI
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
;;

relax)
## Send Command
TARGET="$BEDPI_IP"
XMITCMD="relax"
LCDPI_MSG="playing $SEC_ARG"
CALLAPI
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
exit
;;

toggletv)
## Send Command
TARGET="$BEDPI_IP"
XMITCMD="toggletv"
CALLAPI
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
;;

bedpi)
TARGET="$BEDPI_IP"
XMITCMD="$SEC_ARG"
CALLAPI
exit
;;

lcdpi_message)
LCDPI_MSG="$SEC_ARG"
CALLAPI
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
/opt/system/leds fc 40 > /dev/null 2> /dev/null
/opt/system/leds candle > /dev/null 2> /dev/null
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
  CALLAPI  
fi
exit
;;
##
pcoff)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  XMITCMD="rfb3" ; XMIT
  LCDPI_MSG="PC off"
  CALLAPI  
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
CALLAPI
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
CALLAPI
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
exit
;;

server)
## Read argument
_SEC_ARG=${SEC_ARG//$'\n'/} 
SERVERARG=${_SEC_ARG%-*}
FILESCMD=${_SEC_ARG#*-}
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
  LCDPI_MSG="Legacy services started."
  CALLAPI
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
  TARGET="$BEDPI_IP"
  XMITCMD="apd-off"
  LCDPI_MSG="Legacy services stopped."
  CALLAPI
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

*)
  ## command not matched above, pass argument to Xmit function
  XMITCMD="$FIRST_ARG" 
  XMIT
  exit
;;
esac
