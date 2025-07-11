#!/bin/bash
###########################################################
## Main Home Automation Script by Ben Provenzano III v29 ##
###########################################################

TARGET=""
XMITCMD=""
RESPOUT=""
DELIM="|"
RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
INPUT_REGEX="!A-Za-z0-9_-"
LOCAL_DOMAIN="home"
XMIT_IP="10.177.1.12"
DESK_IP="10.177.1.14"
BRPI_IP="10.177.1.15"
BRPC_IP="10.177.1.17"
BRPC_MAC="90:2e:16:46:86:43" 

## Curl Command Line Arguments
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 10 --retry 1 --retry-delay 1 --no-keepalive"

USB_TTY(){
  local TTY_CMD="$1"
  case "$TTY_CMD" in
  ## RF Power Controller (under dresser)
  ##
  ## Dresser Lamp
  "brlamp1")
    LOCALCOM_RESP "10007" "0"
    ;;
  "brlamp1on")
    LOCALCOM "10002"
    ;;
  "brlamp1off")
    LOCALCOM "10001"
    ;;
  ## Vintage Macs
  "brmacs")
    LOCALCOM_RESP "10007" "1"
    ;;
  "brmacson")
    LOCALCOM "10004"
    ;;
  "brmacsoff")
    LOCALCOM "10003" 
    ;;
  ## RetroPi
  "retropi")
    LOCALCOM_RESP "10007" "2"
    ;;
  "retropion")
    LOCALCOM "10006" 
    ;;
  "retropioff")
    LOCALCOM "10005"
    ;;
  ## Bedroom TV / PC
  "brtv")
    BRTV_OUT="$(LOCALCOM_RESP '01003' '0')"
    BRPC_PING="$(LOCAL_PING $BRPC_IP)"
    if [[ "$BRTV_OUT" == "1" ]]; then
      if [[ "$BRPC_PING" == "1" ]]; then
        ## TV on and PC on
        echo "1"
      else
        ## TV on and PC off
        echo "brtv_on"
      fi
    else
      if [[ "$BRPC_PING" == "1" ]]; then
        ## TV off and PC on
        echo "0"
      else
        ## TV off and PC off
        echo "brpctv_off"
      fi
    fi
    ;;
  "brtvon")
    LOCALCOM "01001"
    WAKE_BRPC > /dev/null 2>&1 ## Wake Bedroom PC (WOL)
    ;;
  "brtvoff")
    LOCALCOM "01002"
    ;;
  ##
  *)
    echo "invalid USB-TTY command!"
    ;;
  esac
}

LOCAL_PING(){
  local LOCAL_PING_ADR="$1"
  if ping -4 -A -c 1 -i 0.25 -W 0.25 "$LOCAL_PING_ADR" > /dev/null 2> /dev/null
  then
    echo "1" ## Online
  else
    echo "0" ## Offline
  fi
}

LOCALCOM_RESP(){
  ## read response character position
  local RESP_CMD="$1"
  local RESP_POS="$2"
  TTY_RAW="$(LOCALCOM $RESP_CMD)"
  ## extract response data
  TMP_STR="${TTY_RAW#*$DELIM}"
  TTY_OUT="${TMP_STR%$DELIM*}"
  TTY_CHR_CNT="${#TTY_OUT}"
  ## process response type
  case "$TTY_CHR_CNT" in
  ## 3-byte response 
  "3")
    ## extract single-byte by position
    TTY_CHR="${TTY_OUT:$RESP_POS:1}"
    ## re-map serial response
    if [[ "$TTY_CHR" == "9" ]]; then
      echo "1" ## Online
    else 
      echo "0"
    fi  
    ;;
  ## single-byte response
  "1")
    TTY_CHR="${TTY_OUT:0:1}"
    if [[ "$TTY_CHR" == "1" ]]; then
      echo "1" ## Online
    else
      echo "0"
    fi
    ;;
  *)
    ## default response
    echo "X"
    ;;
  esac
}

LOCALCOM(){
  local ZTERM_CMD="$1"
  /usr/bin/singleton ZTERM_PROC /usr/bin/ztermcom $ZTERM_CMD
}

LED_PRESET(){
  local LED_PRESET_CMD="$1"
  /opt/system/leds "$LED_PRESET_CMD"
}

POWER_PC(){
  local PWR_STATE="$1"
  if [[ "$PWR_STATE" == "off" ]]; then
    if [[ "$(LOCAL_PING $DESK_IP)" == "1" ]]
    then
      XMITCMD="rfb3" ; XMIT 
    else
      echo "$DESK_IP is offline"
    fi
  fi
  if [[ "$PWR_STATE" == "on" ]]; then
    if [[ "$(LOCAL_PING $DESK_IP)" == "1" ]]
    then
      echo "$DESK_IP is online"
    else
      XMITCMD="rfb3" ; XMIT 
    fi
  fi
}

WAKE_BRPC() {
  if [[ "$(LOCAL_PING $BRPC_IP)" == "1" ]]
  then
    echo "bedroom PC already online."
  else
    wakeonlan "$BRPC_MAC"
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
    RESPOUT=""
  else
    ## ProOS home automation Pi
    DATA="var=$SECOND_ARG&arg=$XMITCMD&action=main"
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

XMIT(){
#### ESP32 Transmit Function
case "$XMITCMD" in
  ### HiFi Preamp
  ## Power
  "pwrhifi")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 0.75
    ## Power Off Preamp  
    XMITCMD="0|0|1270227167"
    CALLAPI   
    ;;
  "hifioff")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 0.75
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
FIRST_ARG="$1"
SECOND_ARG="$2"

if [[ "${FIRST_ARG}" = *[$INPUT_REGEX]* ]]
then
  echo "invalid characters in first argument!"
  exit
fi

case "$FIRST_ARG" in

sitelookup)
## Lookup Website Title from URL
if [ "$SECOND_ARG" != "" ]; then
  LINKTITLE=$(curl -s -X GET "$SECOND_ARG" | xmllint -html -xpath "//head/title/text()" - 2>/dev/null)
  if [[ "$LINKTITLE" != "" ]] && [[ "$LINKTITLE" != "\n" ]]; then
    echo "$LINKTITLE"
  fi
fi
exit
;;

localping)
LOCAL_PING "$SECOND_ARG.$LOCAL_DOMAIN"
exit
;;

wakebrpc)
## Wake-up Bedroom PC
WAKE_BRPC
exit
;;

brpi)
## API Call to Bedroom Pi
TARGET="$BRPI_IP"
XMITCMD="$SECOND_ARG"
CALLAPI
exit
;;

relax)
## Turn Off TV
USB_TTY "brtvoff"
## Bedroom Audio
TARGET="$BRPI_IP"
XMITCMD="ampstateon"
CALLAPI
## Relax Sounds on Bedroom Pi
TARGET="$BRPI_IP"
XMITCMD="relax"
CALLAPI
exit
;;

stop-br)
TARGET="$BRPI_IP"
## Stop Sounds
XMITCMD="stoprelax"
CALLAPI
exit
;;

usbtty)
USB_TTY "$SECOND_ARG"
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
XMITCMD="ampstateon"
CALLAPI
## Bedroom TV
USB_TTY "brtvon"
## Bedroom PC
WAKE_BRPC > /dev/null 2>&1
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
## PC Power Off
POWER_PC "off"
## Main Room Audio
XMITCMD="hifioff" ; XMIT 
## Bedroom Audio
TARGET="$BRPI_IP" 
XMITCMD="ampstateoff"
CALLAPI
## Bedroom TV
USB_TTY "brtvoff"
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
SERVERARG=${SECOND_ARG//$'\n'/} 
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

update-fw)
## Update Arduino over USB
rm -rf /opt/fw-build
mkdir -p /opt/fw-build
arduino-cli -v compile --fqbn arduino:avr:uno \
  /opt/pwr_fw/pwr_fw.ino --build-path /opt/fw-build
arduino-cli -v upload -p /dev/USB-Xmit0 \
  --fqbn arduino:avr:uno --input-dir /opt/fw-build
LOCALCOM "i"
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
