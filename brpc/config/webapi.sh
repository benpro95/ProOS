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

if [[ "${FIRST_ARG}" == "sleep" ]]
then
  echo "entering sleepmode."
  systemctl suspend
  exit
fi
