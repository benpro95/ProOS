#!/bin/bash

## Apple TV Control Script

ATV_MAC=$1 
ATV_CMD=$2

if [[ "$ATV_CMD" == "" || "$ATV_CMD" == "" ]]; then
  exit
fi

source /opt/pyatv/bin/activate

atvremote --id "$ATV_MAC" "$ATV_CMD"

deactivate

exit