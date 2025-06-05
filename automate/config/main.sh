#!/bin/bash
##
###########################################################
## Main Home Automation Script by Ben Provenzano III v20 ##
###########################################################
###########################################################

XMITCMD=""
TARGET=""
RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
INPUT_REGEX="!A-Za-z0-9_-"
XMIT_IP="10.177.1.12"       ## Xmit IP
DESK_IP="10.177.1.14"       ## Desktop IP
BRPI_IP="10.177.1.15"       ## Bedroom Pi IP
ATV_MAC="3E:08:87:30:B9:A8" ## Bedroom Apple TV MAC

## Curl Command Line Arguments
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 10 --retry 1 --retry-delay 1 --no-keepalive"

TTY_RESP(){
  ## read response character position
  local RESP_CMD="$1"
  local RESP_POS="$2"
  TTY_RAW="$(ztermcom $RESP_CMD)"
  ## extract response data
  DELIM="|"
  TMP_STR="${TTY_RAW#*$DELIM}"
  TTY_OUT="${TMP_STR%$DELIM*}"
  TTY_CHR_CNT="${#TTY_OUT}"
  ## verify response is 3-bytes
  if [[ "$TTY_CHR_CNT" == "3" ]]; then
    ## extract single-byte by position
    TTY_CHR="${TTY_OUT:$RESP_POS:1}"
    ## re-map serial response
    case "$TTY_CHR" in
    "1")
      echo "0"
    ;;
    "9")
      echo "1"
    ;;
    *)
      echo "TTY data error!"
    ;;
    esac
  else
    echo "TTY size error!"
  fi
}

USB_TTY(){
  local TTY_CMD="$1"
  case "$TTY_CMD" in
  ## RF Power Controller (under dresser)
  ##
  ## Dresser Lamp
  "brlamp1")
    TTY_RESP "10007" "0"
    ;;
  "brlamp1on")
    ztermcom "10002"
    ;;
  "brlamp1off")
    ztermcom "10001"
    ;;
  ## Vintage Macs
  "brmacs")
    TTY_RESP "10007" "1"
    ;;
  "brmacson")
    ztermcom "10004"
    ;;
  "brmacsoff")
    ztermcom "10003" 
    ;;
  ## RetroPi
  "retropi")
    TTY_RESP "10007" "2"
    ;;
  "retropion")
    ztermcom "10006" 
    ;;
  "retropioff")
    ztermcom "10005"
    ;;
  ##
  *)
    echo "invalid USB-TTY command!"
    ;;
  esac
}

LED_PRESET(){
  LIGHTS_OFF
  local LED_PRESET_CMD="$1"
  case "$LED_PRESET_CMD" in
  "ambient")
    /opt/system/leds pause
    /opt/system/leds fc 40
    /opt/system/leds candle
    ;;
  "abstract")
    /opt/system/leds pause
    /opt/system/leds fc 50
    /opt/system/leds abstract
    sleep 10
    /opt/system/leds pause
    ;;
  "prism")
    /opt/system/leds pause
    /opt/system/leds fc 70
    /opt/system/leds prism
    sleep 7
    /opt/system/leds pause
    ;;
  "flames")
    /opt/system/leds pause
    /opt/system/leds fc 70
    /opt/system/leds flames
    sleep 5
    /opt/system/leds pause
    ;;
  ##
  *)
    echo "invalid preset!"
    ;;
  esac
}

POWER_PC(){
  local PWR_STATE="$1"
  if [[ "$PWR_STATE" == "off" ]]; then
    if ping -W 2 -c 1 $DESK_IP > /dev/null 2> /dev/null
    then
      XMITCMD="rfb3" ; XMIT 
    else
      echo "$DESK_IP is offline"
    fi
  fi
  if [[ "$PWR_STATE" == "on" ]]; then
    if ping -W 2 -c 1 $DESK_IP > /dev/null 2> /dev/null
    then
      echo "$DESK_IP is online"
    else
      XMITCMD="rfb3" ; XMIT 
    fi
  fi
}

## API Gateway
CALLAPI(){
  if [[ "$XMITCMD" == "" ]]; then
    return
  fi
  ## Default Target 
  if [[ "$TARGET" == "" ]]; then
    ## ESP32 Xmit (discard API response, runs in background)
    SERVER="http://$XMIT_IP:80"
    /usr/bin/curl $CURLARGS --header "Accept: ####?|$XMITCMD" $SERVER > /dev/null 2>&1 &
  else
    ## ProOS home automation Pi
    DATA="var=$SEC_ARG&arg=$XMITCMD&action=main"
    SERVER="http://$TARGET:80/exec.php"
    ## API GET request wait then read response
    DELIM="|"
    APIRESP="$(/usr/bin/curl $CURLARGS --data $DATA $SERVER)"
    TMPSTR="${APIRESP#*$DELIM}"
    RESPOUT="${TMPSTR%$DELIM*}"
    echo "$RESPOUT"
  fi
  ## Clear data
  XMITCMD=""
  TARGET=""
}

## Control Apple TV
ATV_CTL(){
  local ATV_CMD="$1"
  /opt/system/atv $ATV_MAC $ATV_CMD > /dev/null 2>&1 &
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
    CALLAPI   
    ;;
  "hifioff")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1
    ## Power Off Preamp  
    XMITCMD="0|0|1261859214"
    CALLAPI
    ;;
  "hifion")
    XMITCMD="0|0|1261869414"
    CALLAPI
    ;;
  ## DAC
  "dac")
    XMITCMD="0|0|1261793423"
    CALLAPI
    ;;
  ## Aux
  "aux")
    XMITCMD="0|0|1261826063"
    CALLAPI   
    ;;
  ## Phono
  "phono")
    XMITCMD="0|0|1261766903"
    CALLAPI   
    ;;
  ## Airplay
  "airplay-preamp")
    XMITCMD="0|0|1261799543"
    CALLAPI   
    ;;   
  ## Volume Limit Mode
  "vlimit")
    XMITCMD="0|0|1261783223"
    CALLAPI   
    ;;  
  ## Optical Mode
  "optical-preamp")
    XMITCMD="0|0|1261824023"
    CALLAPI   
    ;;
  ## Key Toggle Hi-Pass Filter
  "togglehpf")
    XMITCMD="0|0|1261875534"
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
    CALLAPI   
    ;;
  ##
  ## (0) Key
  "subon")
    XMITCMD="0|0|551504055"
    CALLAPI   
    ;;
  ##
  ## (1) Key
  "suboff")
    XMITCMD="0|0|551520375"
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
  ## ESP32 Toggle PC Power
  ##
  "rfb3")
    XMITCMD="2|2|32"
    CALLAPI
    ;;
  ##
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

LIGHTS_OFF(){
  ## Window Lamp
  XMITCMD="rfc1off" ; XMIT
  ## Dresser Lamp
  USB_TTY "brlamp1off"
}

LIGHTS_ON(){
  ## Window Lamp
  XMITCMD="rfc1on" ; XMIT
  ## Dresser Lamp
  USB_TTY "brlamp1on"
}

########################

## Read command line arguments
FIRST_ARG=$1
SEC_ARG=$2

if [[ "${FIRST_ARG}" = *[$INPUT_REGEX]* ]]
then
  echo "invalid characters in first argument!"
  exit
fi
if [ "$SEC_ARG" != "" ]; then
  if [[ "${SEC_ARG}" = *[$INPUT_REGEX]* ]]
  then
    echo "invalid characters in second argument!"
    exit
  fi
fi

case "$FIRST_ARG" in

sitelookup)
## Lookup Website Title from URL
if [ "$SEC_ARG" != "" ]; then
  LINKTITLE=$(curl -s -X GET "$SEC_ARG" | xmllint -html -xpath "//head/title/text()" - 2>/dev/null)
  if [[ "$LINKTITLE" != "" ]] && [[ "$LINKTITLE" != "\n" ]]; then
    echo "$LINKTITLE"
  fi
fi
exit
;;

brpi)
## API call to Bedroom Pi
TARGET="$BRPI_IP"
XMITCMD="$SEC_ARG"
CALLAPI
exit
;;

relax)
## Pause Apple TV
ATV_CTL "pause"
## Bedroom Audio
TARGET="$BRPI_IP"
XMITCMD="poweron"
CALLAPI
## Relax Sounds on Bedroom Pi
TARGET="$BRPI_IP"
XMITCMD="relax"
CALLAPI
exit
;;

stop)
## Pause Apple TV 
ATV_CTL "pause"
TARGET="$BRPI_IP"
## Stop Sounds
XMITCMD="stoprelax"
CALLAPI
exit
;;

usbtty)
USB_TTY "$SEC_ARG"
exit
;;

status)
## Show System Status
/opt/system/status
exit
;;

## Desktop Keyboard F1,F2 ##

mainon)
## Window Lamp
XMITCMD="rfc1on"; XMIT 
exit
;;

mainoff)
LIGHTS_OFF
exit
;;

## All Lights ##

lightson)
LIGHTS_ON
exit
;;

lightsoff)
LIGHTS_OFF
## Blank LEDwalls
/opt/system/leds stop
exit
;;

## LED Presets ##

led-preset)
LED_PRESET "$SEC_ARG"
exit
;;

## All Power Off ##

allon)
LIGHTS_ON
## LEDwalls
LED_PRESET "abstract"
## RetroPi 
USB_TTY "retropion"
## Retro Macs
USB_TTY "brmacson"
## PC Power On
POWER_PC "on"
## Main Room Audio
XMITCMD="hifion" ; XMIT
## Bedroom Audio
TARGET="$BRPI_IP" 
XMITCMD="poweron"
CALLAPI
exit
;;

alloff)
LIGHTS_OFF
## Blank LEDwalls
/opt/system/leds stop
## RetroPi 
USB_TTY "retropioff"
## Retro Macs
USB_TTY "brmacsoff"
## Pause Apple TV
ATV_CTL "pause"
## PC Power Off
POWER_PC "off"
## Main Room Audio
XMITCMD="hifioff" ; XMIT 
## Bedroom Audio
TARGET="$BRPI_IP" 
XMITCMD="poweroff"
CALLAPI
exit
;;

## PC Power

pcon)
POWER_PC "on"
exit
;;

pcoff)
POWER_PC "off"
exit
;;

## Living Room DAC ##

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

## Server Control ##

server)
## Read argument
SERVERARG=${SEC_ARG//$'\n'/} 
## start / stop legacy services
if [ "$SERVERARG" == "startlegacy" ]; then
  echo "Starting legacy services..." &>> $LOGFILE
  TARGET="$BRPI_IP"
  XMITCMD="apd-on"
  CALLAPI
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
  TARGET="$BRPI_IP"
  XMITCMD="apd-off"
  CALLAPI
  exit
fi
## Pass action file to the hypervisor
echo " " 
echo "$SERVERARG sent." &>> $LOGFILE
touch $RAMDISK/$SERVERARG.txt
exit
;;

active)
echo "Active services."
systemctl list-units --type=service --state=active &>> $LOGFILE
exit
;;

running)
echo "Running services."
systemctl list-units --type=service --state=running &>> $LOGFILE
exit
;;

timers)
## List Active Timers
systemctl list-timers --all &>> $LOGFILE
exit
;;

loadtimes)
## Display list of system daemons and startup times
systemd-analyze blame &>> $LOGFILE
exit
;;

### Examples of URL strings ###
# http://automate.home/exec.php?var=&arg=lightson&action=main
# http://automate.home/exec.php?var=&arg=lightsoff&action=main
# http://automate.home/exec.php?var=prism&arg=video&action=leds
###############################

*)
  ## command not matched above, pass argument to ESP32-Xmit
  XMITCMD="$FIRST_ARG" 
  XMIT
  exit
;;
esac
