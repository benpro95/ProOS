#!/bin/bash
#######################################################
## Main Home Automation Script by Ben Provenzano III ##
#######################################################

DELIM="|"
RAMDISK="/var/www/html/ram"
LOCKFOLDER="$RAMDISK/locks"
LOGFILE="$RAMDISK/sysout.txt"
MAX_PING_WAIT="0.5" ## Max Ping Timeout (s)
LOCAL_DOMAIN="home" ## Local DNS Domain
NET_RANGE="192.168.1.0" ## Network IP Range
PICOLAMP1_IP="192.168.1.18" ## Window Lamp
LRXMIT_IP="192.168.1.12" ## LEDwall Pi
DESK_IP="192.168.1.14" ## Desktop PC
BRPI_IP="192.168.1.15" ## Bedroom Pi
BRPC_IP="192.168.1.17" ## Bedroom PC
BRPC_MAC="90:2e:16:46:86:43" ## Bedroom PC MAC
DELIMITER="|"

## Curl Command Line Arguments
CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 3 --retry 1 --retry-delay 1 --no-keepalive"

function CALLAPI(){
  local TARGET="${1}"
  local API_ARG1="${2}"
  local API_ARG2="${3}"
  if [[ "$API_ARG1" == "" ]]; then
    return
  fi
  SERVER="http://$TARGET:80/api?var=$API_ARG2&arg=$API_ARG1&action=main"
  APIRESP=$(/usr/bin/curl $CURLARGS $SERVER)
  TMPSTR="${APIRESP#*$DELIMITER}"
  RESPOUT="${TMPSTR%$DELIMITER*}"
  echo "$RESPOUT"
}

function CALLPICO(){
  local TARGET="${1}"
  local API_ARG1="${2}"
  local API_ARG2="${3}"
  if [[ "$API_ARG1" == "" ]]; then
    return
  fi
  SERVER="http://$TARGET:4000/api?$API_ARG1,,$API_ARG2~"
  RESPOUT=$(/usr/bin/curl $CURLARGS $SERVER)
  echo "$RESPOUT"
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

function BRXMIT(){
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
    sleep 1.0
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
    sleep 0.5
    CALLAPI "$LRXMIT_IP" "extcom" "02130" ## DAC USB
    ;;
  ## Coaxial Input 
  "coax")
    CALLAPI "$LRXMIT_IP" "extcom" "02110" ## Preamp Digital (AirPlay Label)
    sleep 0.5
    CALLAPI "$LRXMIT_IP" "extcom" "02131" ## DAC Coax
    ;;
  ## Optical Input 
  "opt")
    CALLAPI "$LRXMIT_IP" "extcom" "02112" ## Preamp Digital (Optical Label) 
    sleep 0.5
    CALLAPI "$LRXMIT_IP" "extcom" "02132" ## DAC Optical
    ;;
  ## Auto Input
  "autodac")
    CALLAPI "$LRXMIT_IP" "extcom" "02107" ## Preamp Digital
    sleep 0.5
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
*)
  echo "invalid Xmit command!"
  ;;
esac
}

function WINDOW_LAMP1(){
  local CMD_IN="$1"
  case "$CMD_IN" in
  "wl_led1")
    CALLPICO "$PICOLAMP1_IP" "1" "0"
    ;;
  "wl_led1off")
    CALLPICO "$PICOLAMP1_IP" "1" "2"
    ;;
  "wl_led1on")
    CALLPICO "$PICOLAMP1_IP" "1" "3"
    ;;
  "wl_led2")
    CALLPICO "$PICOLAMP1_IP" "2" "20"
    ;;
  "wl_led2off")
    CALLPICO "$PICOLAMP1_IP" "2" "0"
    ;;
  "wl_led2on")
    CALLPICO "$PICOLAMP1_IP" "2" "10"
    ;; 
*)
  ## invalid response
  echo "invalid command!"
  ;;
esac
}

########################

## Read command line arguments
FIRST_ARG="${1//$'\n'/}"
SECOND_ARG="${2//$'\n'/}"

case "$FIRST_ARG" in

## Bedroom Power ##

bron)
## Dresser Lamp
BRXMIT "brlamp1on"
## RetroPi 
BRXMIT "retropion"
## Retro Macs
BRXMIT "brmacson"
## Bedroom Audio
CALLAPI "$BRPI_IP" "ampstateon" ""
## Bedroom TV & PC
BRXMIT "brtvon"
exit
;;

broff)
## Dresser Lamp
BRXMIT "brlamp1off"
## RetroPi 
BRXMIT "retropioff"
## Retro Macs
BRXMIT "brmacsoff"
## Bedroom Audio
CALLAPI "$BRPI_IP" "ampstateoff" ""
## Bedroom TV
BRXMIT "brtvoff"
## Sleep PC
CALLAPI "$BRPC_IP" "sleep" ""
exit
;;

## All Lights ##

lightson)
## Window Lamp
WINDOW_LAMP1 "wl_led1on"
WINDOW_LAMP1 "wl_led2on"
## Dresser Lamp
BRXMIT "brlamp1on"
exit
;;

lightsoff)
## Window Lamp
WINDOW_LAMP1 "wl_led1off"
WINDOW_LAMP1 "wl_led2off"
## Dresser Lamp
BRXMIT "brlamp1off"
## Blank LEDwalls
/opt/system/leds stop
exit
;;

## PC Keyboard F1/F2

lrlightson)
## Window Lamp #1
WINDOW_LAMP1 "wl_led1on"
exit
;;

lrlightsoff)
## Window Lamp
WINDOW_LAMP1 "wl_led1off"
## Blank LEDwalls
/opt/system/leds stop
exit
;;

## Living Room ##

lron)
## Window Lamp
WINDOW_LAMP1 "wl_led1on"
WINDOW_LAMP1 "wl_led2on"
## LEDwalls
LED_PRESET "abstract"
## PC Power On
LRXMIT "wkststateon"
## Main Room Audio
LRXMIT "hifistateon"
exit
;;

lroff)
## Window Lamp
WINDOW_LAMP1 "wl_led1off"
WINDOW_LAMP1 "wl_led2off"
## Blank LEDwalls
/opt/system/leds stop
## PC Power Off
LRXMIT "wkststateoff"
## Main Room Audio
LRXMIT "hifistateoff"
exit
;;

## Forward to Window Lamp Pi
wlpi)
WINDOW_LAMP1 "$SECOND_ARG"
exit
;;

## Forward to Bedroom Xmit
brxmit)
BRXMIT "$SECOND_ARG"
exit
;;

## Forward to Living Room Xmit
lrxmit)
LRXMIT "$SECOND_ARG"
exit
;;

## Forward to Bedroom Amplifer Pi
brpi)
CALLAPI "$BRPI_IP" "$SECOND_ARG" ""
exit
;;

## Sleep Sounds
relax)
## Relax Sounds on Bedroom Pi
CALLAPI "$BRPI_IP" "relax" "$SECOND_ARG"
## Send Sleep Command
CALLAPI "$BRPC_IP" "sleep" ""
## Turn Off TV
BRXMIT "brtvoff"
exit
;;

## Stop Relax Sounds 
stop-br)
CALLAPI "$BRPI_IP" "stoprelax" ""
exit
;;

localping)
LOCAL_PING "$SECOND_ARG.$LOCAL_DOMAIN"
exit
;;

## Show System Status
status)
/opt/system/status
exit
;;

## Lookup Website Title from URL
sitelookup)
BASE64_IN=$(echo "$SECOND_ARG" | sed "s|-|+|g" | sed "s|_|/|g" | sed "s|@|=|g")
DECODED_URL=$(openssl enc -base64 -d <<< "$BASE64_IN")
URL_DOMAIN=$(echo "$DECODED_URL" | awk -F/ '{print $3}')
case "$URL_DOMAIN" in
  "www.ups.com" | "ups.com")
    echo "UPS Tracking"
    ;;
  "tools.usps.com")
    echo "USPS Tracking"
    ;;
  *)
    LINKTITLE=$(curl -s -X GET "$DECODED_URL" | xmllint -html -xpath "//head/title/text()" - 2>/dev/null)
    if [[ "$LINKTITLE" == "" ]] || [[ "$LINKTITLE" == "\n" ]]; then
      echo "Site Lookup Error!"
    else
      echo "$LINKTITLE"
    fi
    ;;
esac
exit
;;

## Server Functions
server)
SERVERARG="$SECOND_ARG"
if [[ "${SERVERARG}" == "" ]]
then
  echo "server argument cannot be empty!"
  exit
fi
## Network Scanner
if [[ "${SERVERARG}" == "netscan" ]]
then
  echo "** network scan **"
  nmap -v --open -sn $NET_RANGE/24 &>> $LOGFILE
  exit
fi
echo " " 
echo "$SERVERARG sent." &>> $LOGFILE
## Write Trigger File
touch $RAMDISK/$SERVERARG.txt
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
  ## command not matched above
  echo "invalid command!"
  exit
;;
esac

