#!/bin/bash
###########################################################
## Main Home Automation Script by Ben Provenzano III v31 ##
###########################################################

DELIM="|"
RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
MAX_PING_WAIT="0.5" ## Max Ping Timeout (s)
LOCAL_DOMAIN="home" ## Local DNS Domain
LRXMIT_IP="10.177.1.12" ## LEDwall
DESK_IP="10.177.1.14" ## Desktop
BRPI_IP="10.177.1.15" ## Bedroom Pi
BRPC_IP="10.177.1.17" ## Bedroom PC IP
BRPC_MAC="90:2e:16:46:86:43" ## Bedroom PC MAC
 
## Curl Command Line Arguments
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 10 --retry 1 --retry-delay 1 --no-keepalive"

function CALLAPI(){
  local TARGET="${1}"
  local API_ARG1="${2}"
  local API_ARG2="${3}"
  if [[ "$API_ARG1" == "" ]]; then
    return
  fi
  ## ProOS home automation Pi
  DATA="var=$API_ARG2&arg=$API_ARG1&action=main"
  SERVER="http://$TARGET:80/exec.php"
  ## API GET request wait then read response
  DELIM="|"
  APIRESP="$(/usr/bin/curl $CURLARGS --data $DATA $SERVER)"
  TMPSTR="${APIRESP#*$DELIM}"
  RESPOUT="${TMPSTR%$DELIM*}"
  echo "$RESPOUT"
}

function LOCAL_CMD(){
  local TTY_CMD="${1}"
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
  ### Room Temperature & Humidity
  "roomth")
    LOCALCOM_RESP "01005" ""
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
      CALLAPI "$BRPC_IP" "sleep" ""
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
  local LOCAL_PING_ADR="${1}"
  if ping -4 -A -c 1 -i "$MAX_PING_WAIT" -W "$MAX_PING_WAIT" "$LOCAL_PING_ADR" > /dev/null 2> /dev/null
  then
    echo "1" ## Online
  else
    echo "0" ## Offline
  fi
}

function LOCALCOM_RESP(){
  ## read character position
  local RESP_CMD="${1}"
  local RESP_POS="${2}"
  TTY_RAW="$(LOCALCOM $RESP_CMD)"
  ## extract response data
  TMP_STR="${TTY_RAW#*$DELIM}"
  TTY_OUT="${TMP_STR%$DELIM*}"
  if [[ "$RESP_POS" == "" ]]; then
    ## send entire response
    echo "$TTY_OUT"
  else
    ## process by response length
    TTY_CHR_CNT="${#TTY_OUT}"
    case "$TTY_CHR_CNT" in
    ## 3-byte response
    "3")
      ## extract single-byte by position
      TTY_CHR="${TTY_OUT:$RESP_POS:1}"
      ## re-map serial response
      if [[ "$TTY_CHR" == "9" ]]; then
        echo "1" ## Online
      else 
        echo "0" ## Offline
      fi  
      ;;
    ## single-byte response
    "1")
      TTY_CHR="${TTY_OUT:0:1}"
      if [[ "$TTY_CHR" == "1" ]]; then
        echo "1" ## Online
      else
        echo "0" ## Offline
      fi
      ;;
    ## 
    *)
      ## invalid response
      echo "X"
      ;;
    esac
  fi
}

function LOCALCOM(){
  local ZTERM_CMD="${1}"
  /usr/bin/singleton ZTERM_PROC /usr/bin/ztermcom $ZTERM_CMD
}

function LED_PRESET(){
  local LED_PRESET_CMD="${1}"
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

function LIGHTS_OFF(){
  ## Window Lamp
  LRXMIT "rfc1off"
  ## Dresser Lamp
  LOCAL_CMD "brlamp1off"
}

function LIGHTS_ON(){
  ## Window Lamp
  LRXMIT "rfc1on"
  ## Dresser Lamp
  LOCAL_CMD "brlamp1on"
}

function LRXMIT(){
local CMD_IN="$1"
case "$CMD_IN" in
  ### Desktop PC ###
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
      CALLAPI "$LRXMIT_IP" "extcom" "02010"  
    else ## Host Offline
      echo "$DESK_IP is already offline"
    fi
    ;;
  "wkststateon")
    if [[ "$(LOCAL_PING "$DESK_IP")" == "1" ]]
    then ## Host Online
      echo "$DESK_IP is already online"
    else ## Host Offline
      CALLAPI "$LRXMIT_IP" "extcom" "02010"  
    fi
    ;;
  ### HiFi Preamp/DAC ###
  "hifistate")
    if [[ "$(LOCAL_PING "hifipi.$LOCAL_DOMAIN")" == "1" ]]
    then ## Host Online
      echo "1"
    else ## Host Offline
      echo "0"
    fi
    ;;
  "hifistateoff")
    CALLAPI "$LRXMIT_IP" "extcom" "02122" ## Subwoofer Amp Off
    sleep 0.5
    CALLAPI "$LRXMIT_IP" "extcom" "02103" ## Preamp Off
    ;;
  "hifistateon")
    CALLAPI "$LRXMIT_IP" "extcom" "02102" ## Preamp On
    ;;
  "hifitoggle")
    CALLAPI "$LRXMIT_IP" "extcom" "02101" ## Preamp On/Off
    ;;
  ## Aux
  "aux")
    CALLAPI "$LRXMIT_IP" "extcom" "02108"   
    ;;
  ## Phono
  "phono")
    CALLAPI "$LRXMIT_IP" "extcom" "02109"
    ;;  
  ## DAC USB Input
  "usb")
    CALLAPI "$LRXMIT_IP" "extcom" "02107" ## Preamp Digital
    CALLAPI "$LRXMIT_IP" "extcom" "02130" ## DAC USB
    ;;
  ## Coaxial Input 
  "coax")
    CALLAPI "$LRXMIT_IP" "extcom" "02110" ## Preamp Digital (AirPlay Label)
    CALLAPI "$LRXMIT_IP" "extcom" "02131" ## DAC Coax
    ;;
  ## Optical Input 
  "opt")
    CALLAPI "$LRXMIT_IP" "extcom" "02112" ## Preamp Digital (Optical Label) 
    CALLAPI "$LRXMIT_IP" "extcom" "02132" ## DAC Optical
    ;;
  ## Auto Input
  "autodac")
    CALLAPI "$LRXMIT_IP" "extcom" "02107" ## Preamp Digital
    CALLAPI "$LRXMIT_IP" "extcom" "02133" ## DAC Auto Select
    ;;
  ## Volume Limit Mode
  "vlimit")
    CALLAPI "$LRXMIT_IP" "extcom" "02111"   
    ;;      
  ## Toggle Hi-Pass Filter
  "togglehpf")
    CALLAPI "$LRXMIT_IP" "extcom" "02106"   
    ;;
  ## Mute / Toggle
  "mute")
    CALLAPI "$LRXMIT_IP" "extcom" "02115"   
    ;;
  ## Vol Down Fine
  "dwn")
    CALLAPI "$LRXMIT_IP" "extcom" "02104"
    ;;
  ## Vol Up Fine
  "up")
    CALLAPI "$LRXMIT_IP" "extcom" "02105"
    ;;
  ## Vol Down Course
  "dwnc")
    CALLAPI "$LRXMIT_IP" "extcom" "02113"
    ;;
  ## Vol Up Course
  "upc")
    CALLAPI "$LRXMIT_IP" "extcom" "02114"
    ;;
  ### Class D Amp ###
  "submute")
    CALLAPI "$LRXMIT_IP" "extcom" "02120"   
    ;;
  "subon")
    CALLAPI "$LRXMIT_IP" "extcom" "02121"   
    ;;
  "suboff")
    CALLAPI "$LRXMIT_IP" "extcom" "02122"   
    ;;
  "subup")
    CALLAPI "$LRXMIT_IP" "extcom" "02123"
    ;;
  "subdwn")
    CALLAPI "$LRXMIT_IP" "extcom" "02124"
    ;;
  ### Window Lamp ###
  "rfc1on")
    CALLAPI "$LRXMIT_IP" "extcom" "02001"
    ;;
  "rfc1off")
    CALLAPI "$LRXMIT_IP" "extcom" "02002"
    ;;
*)
  echo "invalid Xmit command!"
  ;;
esac
}

########################

## Read command line arguments
FIRST_ARG="${1//$'\n'/}"
SECOND_ARG="${2//$'\n'/}"

case "$FIRST_ARG" in

sitelookup)
## Lookup Website Title from URL
if [ "$SECOND_ARG" != "" ]; then
  BASE64_IN=$(echo "$SECOND_ARG" | sed "s|-|+|g" | sed "s|_|/|g" | sed "s|@|=|g")
  DECODED_URL=$(openssl enc -base64 -d <<< "$BASE64_IN")
  LINKTITLE=$(curl -s -X GET "$DECODED_URL" | xmllint -html -xpath "//head/title/text()" - 2>/dev/null)
  if [[ "$LINKTITLE" != "" ]] && [[ "$LINKTITLE" != "\n" ]]; then
    echo "$LINKTITLE"
  else
    echo "Error!"
  fi
fi
exit
;;

localping)
LOCAL_PING "$SECOND_ARG.$LOCAL_DOMAIN"
exit
;;

relax)
## Bedroom Audio
CALLAPI "$BRPI_IP" "ampstateon" ""
## Relax Sounds on Bedroom Pi
CALLAPI "$BRPI_IP" "relax" "$SECOND_ARG"
## Turn Off TV
LOCAL_CMD "brtvoff"
## Send Sleep Command
CALLAPI "$BRPC_IP" "sleep" ""
exit
;;

stop-br)
## Stop Relax Sounds 
CALLAPI "$BRPI_IP" "stoprelax" ""
exit
;;

## Forward Command to Bedroom Pi
brpi)
CALLAPI "$BRPI_IP" "$SECOND_ARG" ""
exit
;;

## Forward Command to Local COM Port
localcmd)
LOCAL_CMD "$SECOND_ARG"
exit
;;

## Forward Command to Living Room Xmit
lrxmit)
LRXMIT "$SECOND_ARG"
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
LRXMIT "rfc1on"
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

## Bedroom Power ##

bron)
## Dresser Lamp
LOCAL_CMD "brlamp1on"
## RetroPi 
LOCAL_CMD "retropion"
## Retro Macs
LOCAL_CMD "brmacson"
## Bedroom Audio
CALLAPI "$BRPI_IP" "ampstateon" ""
## Bedroom TV & PC
LOCAL_CMD "brtvon"
exit
;;

broff)
## Dresser Lamp
LOCAL_CMD "brlamp1off"
## RetroPi 
LOCAL_CMD "retropioff"
## Retro Macs
LOCAL_CMD "brmacsoff"
## Bedroom Audio
CALLAPI "$BRPI_IP" "ampstateoff" ""
## Bedroom TV
LOCAL_CMD "brtvoff"
exit
;;

## Living Room Power ##

lron)
## Window Lamp
LRXMIT "rfc1on"
## LEDwalls
LED_PRESET "abstract"
## PC Power On
LRXMIT "wkststateon"
## Main Room Audio
LRXMIT "hifion"
exit
;;

lroff)
## Window Lamp
LRXMIT "rfc1off"
## Blank LEDwalls
/opt/system/leds stop
## PC Power Off
LRXMIT "wkststateoff"
## Main Room Audio
LRXMIT "hifioff"
exit
;;

## Server Commands ##

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
  CALLAPI "$BRPI_IP" "apd-on" ""
  exit
fi
if [ "$SERVERARG" == "stoplegacy" ]; then
  echo "Stopping legacy services..." &>> $LOGFILE
  CALLAPI "$BRPI_IP" "apd-off" ""
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
  /opt/AutomateHub_1/AutomateHub_1.ino --build-path /opt/fw-build
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
  LRXMIT "$FIRST_ARG" 
  exit
;;
esac

