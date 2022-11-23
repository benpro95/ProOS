#!/bin/bash
###########################################################
###########################################################
REPLY="$1"
ARG="$2"
LOGFILE="/mnt/.regions/WWW/sysout.txt"

### Only run if server user
if [ ! "$USER" == "server" ]; then
  echo "this script should only be ran by server user, aborting."
  exit
fi

REGROOT="/home/server/.regions"
## Detach All Regions
if [[ $REPLY == "detach_all_regions" ]]
then
  echo " "	
  echo "detaching all regions..."
  rm -f $REGROOT/Snapshots
  rm -f $REGROOT/Private
  rm -f $REGROOT/Public
  rm -f $REGROOT/WWW
  exit
fi
## WWW Share
if [[ $REPLY == "www_region" ]]
then
  echo " "
  if [ -e "$REGROOT/WWW" ]; then
    echo "detaching WWW root region..."
    rm $REGROOT/WWW
  else
    echo "attaching WWW root region..."
    ln -s /mnt/.regions/WWW $REGROOT/WWW
  fi
  exit
fi
## Private Share
if [[ $REPLY == "private_region" ]]
then
  echo " "
  if [ -e "$REGROOT/Private" ]; then
    echo "detaching private region..."
    rm $REGROOT/Private
  else
    echo "attaching private region..."
    ln -s /mnt/.regions/Private $REGROOT/Private
  fi
  exit
fi
## Public Share
if [[ $REPLY == "public_region" ]]
then
  echo " "
  if [ -e "$REGROOT/Public" ]; then
    echo "detaching public region..."   
    rm $REGROOT/Public
  else
    echo "attaching public region..."
    ln -s /mnt/.regions/Public $REGROOT/Public
  fi
  exit
fi
## Snapshot Share
if [[ $REPLY == "snapshots_region" ]]
then
  echo " "
  if [ -e "$REGROOT/Snapshots" ]; then
    echo "detaching snapshots region..."
    rm $REGROOT/Snapshots
  else
    echo "attaching snapshots region..."
    ln -s /mnt/snapshots $REGROOT/Snapshots
  fi
  exit
fi

if [[ $REPLY == "git_push" ]]
then
  echo ""	
  TIMESTMP=$(date '+%Y-%m-%d %H:%M')
  echo "uploading all changes to GitHub..."
  echo ""
  echo "*** ProOS repository ***"  
  cd /mnt/ben/ProOS
  git add .
  git commit -m "$TIMESTMP"
  git push -u ProOS master
  cd -
  echo ""
  echo "*** EE-Projects repository ***"  
  cd /mnt/ben/Projects
  git add .
  git commit -m "$TIMESTMP"
  git push
  cd -
  exit
fi

if [[ $REPLY == "clearlog" ]]
then
  truncate -s 0 $LOGFILE
  date
  neofetch --stdout
  echo "Log file cleared."
  echo ""   
  exit
fi

if [[ $REPLY == "backupstd" ]]
then
  echo "" 
  /usr/bin/svrbackup.sh 60 no &>> $LOGFILE
  exit
fi

if [[ $REPLY == "backupchk" ]]
then
  echo "" 
  /usr/bin/svrbackup.sh 60 yes &>> $LOGFILE
  exit
fi


exit