#!/bin/bash
#####################################
#####################################
## Launcher for WWW actions script ##

## Read command line arguments
FIRST_ARG="${1//$'\n'/}"
SECOND_ARG="${2//$'\n'/}"

if [[ "${FIRST_ARG}" == "" ]]
then
  echo "no argument."
  exit
fi

echo "1ST: $FIRST_ARG" 
echo "2ND: $SECOND_ARG" 
exit