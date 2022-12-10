#!/bin/bash
##
###########################################################
###########################################################
###########################################################

my_array=(" " 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z "+" "=" "-" "%" "(" ")" ":")

msg=$1
line=$2

## ESP32 Xmit URL
TARGET="10.177.1.17"

function CALLAPI(){
  ## Transmit
  APIDATA="--url http://$TARGET:80/xmit/$XMITCALL"
  /usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
    --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive $APIDATA
  APIDATA=""
  return
}


function SEND_RF {
  char=$1
  ## translate character to array position
  index=$(declare -p my_array | sed -n "s,.*\[\([^]]*\)\]=\"$char\".*,\1,p")
  if [[ ${index} -lt 75 ]] && [[ ${index} -ge 0 ]]; then
    ## add leading zeros
    arg=$(printf "%02d\n" $index)
    ## transmit display character
    XMITCALL="rftx.828$arg$line"
    CALLAPI
    ## transmit end reset character
    XMITCALL="rftx.828009"
    CALLAPI
  fi
}

## transmit reset character
XMITCALL="rftx.828008"
CALLAPI
## transmit one character at a time  
for (( i=0; i<${#msg}; i++ )); do
  char="${msg:$i:1}"
  SEND_RF "$char"
done
exit