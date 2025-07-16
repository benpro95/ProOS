#!/bin/bash
###########################################################
## Main Home Automation Script by Ben Provenzano III v31 ##
###########################################################

TARGET=""
XMITCMD=""
RESPOUT=""
DELIM="|"
RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
MAX_PING_WAIT="0.5" ## Max Ping Timeout (s)
LOCAL_DOMAIN="home" ## Local DNS Domain
XMIT_IP="10.177.1.12" ## Living Room Xmit
DESK_IP="10.177.1.14" ## Desktop
BRPI_IP="10.177.1.15" ## Bedroom Pi
BRPC_IP="10.177.1.17" ## Bedroom PC IP
BRPC_MAC="90:2e:16:46:86:43" ## Bedroom PC MAC
 
## Curl Command Line Arguments
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 10 --retry 1 --retry-delay 1 --no-keepalive"

function CALLAPI(){
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

function LOCAL_CMD(){
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
    if [[ "$(LOCALCOM_RESP '01003' '0')" == "1" ]]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  "brtvon")
    LOCALCOM "01001"
    WAKE_BRPC > /dev/null 2>&1 ## Wake Bedroom PC (WOL)
    ;;
  "brtvoff")
    LOCALCOM "01002"
    ;;
  "brpc")
    if [[ "$(LOCAL_PING "$BRPC_IP")" == "1" ]]
    then ## Host Online
      echo "pc_awake"
    else ## Host Offline
      echo "0"
    fi
    ;;
  "brpcoff")
    if [[ "$(LOCAL_PING "$BRPC_IP")" == "1" ]]
    then ## Host Online
      ## Send Sleep Command
      TARGET="$BRPC_IP"
      XMITCMD="sleep"
      CALLAPI
    else ## Host Offline
      echo "$DESK_IP is already offline"
    fi
    ;;
  "brpcon")
    if [[ "$(LOCAL_PING "$BRPC_IP")" == "1" ]]
    then ## Host Online
      echo "$DESK_IP is already online"
    else ## Host Offline
      ## Wake Bedroom PC (WOL)
      WAKE_BRPC > /dev/null 2>&1
    fi
    ;;
  ##
  *)
    echo "invalid local command!"
    ;;
  esac
}

function LOCAL_PING(){
  local LOCAL_PING_ADR="$1"
  if ping -4 -A -c 1 -i "$MAX_PING_WAIT" -W "$MAX_PING_WAIT" "$LOCAL_PING_ADR" > /dev/null 2> /dev/null
  then
    echo "1" ## Online
  else
    echo "0" ## Offline
  fi
}

function LOCALCOM_RESP(){
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
    ## error response
    echo "X"
    ;;
  esac
}

function LOCALCOM(){
  local ZTERM_CMD="$1"
  /usr/bin/singleton ZTERM_PROC /usr/bin/ztermcom $ZTERM_CMD
}

function LED_PRESET(){
  local LED_PRESET_CMD="$1"
  /opt/system/leds "$LED_PRESET_CMD"
}

function WAKE_BRPC() {
  if [[ "$(LOCAL_PING $BRPC_IP)" == "1" ]]
  then
    echo "bedroom PC already online."
  else
    wakeonlan "$BRPC_MAC"
  fi
}

function LRXMIT(){
case "$XMITCMD" in
  ### HiFi Preamp ###
  ## Power
  "hifistate")
    if [[ "$(LOCAL_PING "hifipi.$LOCAL_DOMAIN")" == "1" ]]
    then ## Host Online
      echo "1"
    else ## Host Offline
      echo "0"
    fi
    ;;
  "hifistateoff")
    ## Mute Subwoofer Amp
    XMITCMD="0|0|551520375"
    CALLAPI
    sleep 1.25
    ## Power Off Preamp  
    XMITCMD="0|0|1261859214"
    CALLAPI
    ;;
  "hifistateon")
    XMITCMD="0|0|1261869414"
    CALLAPI
    ;;
  "wkststate")
    if [[ "$(LOCAL_PING "$DESK_IP")" == "1" ]]
    then ## Host Online
      echo "pc_awake"
    else ## Host Offline
      echo "0"
    fi
    ;;
  "wkststateoff")
    if [[ "$(LOCAL_PING "$DESK_IP")" == "1" ]]
    then ## Host Online
      XMITCMD="2|2|32"
      CALLAPI
    else ## Host Offline
      echo "$DESK_IP is already offline"
    fi
    ;;
  "wkststateon")
    if [[ "$(LOCAL_PING "$DESK_IP")" == "1" ]]
    then ## Host Online
      echo "$DESK_IP is already online"
    else ## Host Offline
      XMITCMD="2|2|32"
      CALLAPI
    fi
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
  echo "invalid Xmit command!"
  ;;
esac
}

function LIGHTS_OFF(){
  ## Window Lamp
  XMITCMD="rfc1off"; LRXMIT
  ## Dresser Lamp
  LOCAL_CMD "brlamp1off"
}

function LIGHTS_ON(){
  ## Window Lamp
  XMITCMD="rfc1on"; LRXMIT
  ## Dresser Lamp
  LOCAL_CMD "brlamp1on"
}

function DECODE_RFC3986() { : "${*//+/ }"; echo -e "${_//#/\\x}"; } ## using (#) instead of (%)

########################

## Read command line arguments
FIRST_ARG="${1//$'\n'/}"
SECOND_ARG="${2//$'\n'/}"

case "$FIRST_ARG" in

sitelookup)
## Lookup Website Title from URL
if [ "$SECOND_ARG" != "" ]; then
  DECODED_URL="$(DECODE_RFC3986 $SECOND_ARG)"
  LINKTITLE=$(curl -s -X GET "$DECODED_URL" | xmllint -html -xpath "//head/title/text()" - 2>/dev/null)
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

relax)
## Turn Off TV
LOCALCMD "brtvoff"
## Bedroom Audio
TARGET="$BRPI_IP"; XMITCMD="ampstateon"; CALLAPI
## Relax Sounds on Bedroom Pi
TARGET="$BRPI_IP"; XMITCMD="relax"; CALLAPI
exit
;;

stop-br)
## Stop Relax Sounds
TARGET="$BRPI_IP"; XMITCMD="stoprelax"; CALLAPI
exit
;;

## Forward Command to Bedroom Pi
brpi)
TARGET="$BRPI_IP"; XMITCMD="$SECOND_ARG"; CALLAPI
exit
;;

## Forward Command to Local COM Port
localcmd)
LOCAL_CMD "$SECOND_ARG"
exit
;;

## Forward Command to Living Room Xmit
lrxmit)
XMITCMD="$SECOND_ARG"; LRXMIT
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
XMITCMD="rfc1on"; LRXMIT 
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
## All Lights
LIGHTS_ON
## LEDwalls
LED_PRESET "abstract"
## RetroPi 
LOCAL_CMD "retropion"
## Retro Macs
LOCAL_CMD "brmacson"
## PC Power On
XMITCMD="wkststateon"; LRXMIT 
## Main Room Audio
XMITCMD="hifion"; LRXMIT
## Bedroom Audio
TARGET="$BRPI_IP"; XMITCMD="ampstateon"; CALLAPI
## Bedroom TV & PC
LOCAL_CMD "brtvon"
exit
;;

alloff)
## All Lights
LIGHTS_OFF
## Blank LEDwalls
/opt/system/leds stop
## RetroPi 
LOCAL_CMD "retropioff"
## Retro Macs
LOCAL_CMD "brmacsoff"
## PC Power Off
XMITCMD="wkststateoff"; LRXMIT 
## Main Room Audio
XMITCMD="hifioff"; LRXMIT 
## Bedroom Audio
TARGET="$BRPI_IP"; XMITCMD="ampstateoff"; CALLAPI
## Bedroom TV
LOCAL_CMD "brtvoff"
exit
;;

## Living Room DAC ##

autodac)
## Auto Decoder Input
XMITCMD="inauto"; LRXMIT 
## Preamp DAC Input
XMITCMD="dac"; LRXMIT 
exit
;;

usb)
## USB Decoder Input
XMITCMD="usb"; LRXMIT
## Preamp DAC Input
XMITCMD="dac"; LRXMIT
exit
;;

## Coax Input
coax)
## Coaxial Decoder Input
XMITCMD="coaxial"; LRXMIT 
## Preamp AirPlay Mode
XMITCMD="airplay-preamp"; LRXMIT 
exit
;;

## Optical Input
opt)
## Optical Decoder Input
XMITCMD="optical"; LRXMIT
## Preamp DAC Input
XMITCMD="optical-preamp"; LRXMIT
exit
;;

server)
## server controls
if [[ "${SECOND_ARG}" == "" ]]
then
  echo "server argument cannot be empty!"
  exit
fi
SERVERARG="$SECOND_ARG"
## start / stop legacy services
if [ "$SERVERARG" == "startlegacy" ]; then
  echo "Starting legacy services..." &>> $LOGFILE
  TARGET="$BRPI_IP"; XMITCMD="apd-on"; CALLAPI
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
  TARGET="$BRPI_IP"; XMITCMD="apd-off"; CALLAPI
  exit
fi
## write trigger file
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
  LRXMIT
  exit
;;
esac


