#!/bin/bash
#######################
#### PVE Main Menu ####
#######################
#######################



STATUS="1"

while [[ $STATUS != 0 ]]

RANDOPT=$(( $RANDOM % 3 ))
if [[ $RANDOPT == "0" ]]
then
  echo " "
  echo "    ____             ____  _____"
  echo "   / __ \_________  / __ \/ ___/"
  echo "  / /_/ / ___/ __ \/ / / /\__ \ "
  echo " / ____/ /  / /_/ / /_/ /___/ / "
  echo "/_/   /_/   \____/\____//____/  "
  echo " "
fi
if [[ $RANDOPT == "1" ]]
then
  echo " "
  echo "  _____            ____   _____ "
  echo " |  __ \          / __ \ / ____|"
  echo " | |__) | __ ___ | |  | | (___  "
  echo " |  ___/ '__/ _ \| |  | |\___ \ "
  echo " | |   | | | (_) | |__| |____) |"
  echo " |_|   |_|  \___/ \____/|_____/ "
  echo " "
fi
if [[ $RANDOPT == "2" ]]
then
  echo " "
  echo " ____  ____   ___   ___   _____"
  echo "|    \|    \ /   \ /   \ / ___/"
  echo "|  o  )  D  )     |     (   \_ "
  echo "|   _/|    /|  O  |  O  |\__  |"
  echo "|  |  |    \|     |     |/  \ |"
  echo "|  |  |  .  \     |     |\    |"
  echo "|__|  |__|\_|\___/ \___/  \___|"
  echo " "
fi

sleep 0.5
do true
done
#### END MAIN SCRIPT #####
exit