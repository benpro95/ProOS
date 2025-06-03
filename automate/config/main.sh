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
READ_RESP=false
ATV_CMD=""
XMITCMD=""
TARGET=""

FILES_IP="10.177.1.4" ## Files IP
XMIT_IP="10.177.1.12" ## Xmit IP
BRPI_IP="10.177.1.15" ## Bedroom Pi IP
ATV_MAC="3E:08:87:30:B9:A8" ## Bedroom Apple TV MAC

CURLARGS="--silent --fail --ipv4 --no-buffer --max-time 10 --retry 1 --retry-delay 1 --no-keepalive"

DECODE_TTY_RESP(){
  DELIM="|"
  local RESP_POS="$1"
  TTY_RAW="$(ztermcom "10007")"
  ## extract response data
  TMPSTR="${TTY_RAW#*$DELIM}"
  TTY_OUT="${TMPSTR%$DELIM*}"
  TTY_CHR_CNT=${#TTY_OUT}
  ## verify response is 3-bytes
  if [[ "$TTY_CHR_CNT" == "3" ]]; then
    ## extract single-byte by position
    TTY_CHR="${TTY_OUT:$RESP_POS:1}"
    case "$TTY_CHR" in
    "1")
      echo "0"
    ;;
    "9")
      echo "1"
    ;;
    *)
      echo "TTY response data error!"
    ;;
    esac
  else
    echo "TTY response size error!"
  fi
}

USB_TTY(){
  local TTY_CMD="$1"
  case "$TTY_CMD" in
  ## RF Power Controller (under dresser)
  ##
  ## Dresser Lamp
  "brlamp1")
    DECODE_TTY_RESP "0"
    ;;
  "brlamp1on")
    ztermcom "10002"
    ;;
  "brlamp1off")
    ztermcom "10001"
    ;;
  ## Vintage Macs
  "brmacs")
    DECODE_TTY_RESP "1"
    ;;
  "brmacson")
    ztermcom "10004"
    ;;
  "brmacsoff")
    ztermcom "10003" 
    ;;
  ## RetroPi
  "retropi")
    DECODE_TTY_RESP "2"
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

RESETVARS(){
  READ_RESP=false
  XMITCMD=""
  TARGET=""
}

## API Gateway
CALLAPI(){
  if [[ "$XMITCMD" == "" ]]; then
    return
  fi
  ## Xmit Default Target 
  if [[ "$TARGET" == "" ]]; then
    ## ESP32 Xmit (discard API response, runs in background)
    SERVER="http://$XMIT_IP:80"
    /usr/bin/curl $CURLARGS --header "Accept: ####?|$XMITCMD" $SERVER > /dev/null 2>&1 &
  else
    ## ProOS home automation Pi
    DATA="var=$SEC_ARG&arg=$XMITCMD&action=main"
    SERVER="http://$TARGET:80/exec.php"
    if [[ "$READ_RESP" == true ]]; then
      ## wait then parse API response
      DELIM="|"
      APIRESP="$(/usr/bin/curl $CURLARGS --data $DATA $SERVER)"
      TMPSTR="${APIRESP#*$DELIM}"
      RESPOUT="${TMPSTR%$DELIM*}"
      echo "$RESPOUT"
    else
      ## discard API response (runs in background)
      /usr/bin/curl $CURLARGS --data $DATA $SERVER > /dev/null 2>&1 &
    fi
  fi
  ## Clear data
  READ_RESP=false
  XMITCMD=""
  TARGET=""
}

## Control Apple TV
ATV_CTL(){
  /opt/system/atv $ATV_MAC $ATV_CMD > /dev/null 2>&1 &
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

########################

## Read command line arguments
FIRST_ARG=$1
SEC_ARG=$2

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

play)
## Play Current on Apple TV
ATV_CMD="play"; ATV_CTL
exit
;;

brpi)
## API call to Bedroom Pi
READ_RESP=true
TARGET="$BRPI_IP"
XMITCMD="$SEC_ARG"
CALLAPI
exit
;;

relax)
## Relax Sounds on Bedroom Pi
TARGET="$BRPI_IP"
XMITCMD="relax"
CALLAPI
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
exit
;;

stop)
## Pause Apple TV / Stop Sounds
ATV_CMD="pause"; ATV_CTL
TARGET="$BRPI_IP"
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
  CALLAPI  
fi
exit
;;
##
pcoff)
if ping -W 2 -c 1 wkst.home > /dev/null 2> /dev/null
then
  XMITCMD="rfb3" ; XMIT
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
## Pause Apple TV
ATV_CMD="pause"; ATV_CTL
exit
;;

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
