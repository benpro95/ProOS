#!/bin/bash
###########################################################
###########################################################
#### these are the whitelisted commands that can be called
#### from the HTTP API, ran as the user 'server' on files.home
REPLY="$1"
ARG="$2"
LOGFILE="$3"

### Only run if server user
if [ ! "$USER" == "server" ]; then
  echo "this script should only be ran by server user, aborting."
  exit
fi

REGROOT="/home/server/.regions"
## Detach All Regions
if [[ $REPLY == "detach_all_regions" ]]
then
  echo "detaching all regions..."
  rm -f $REGROOT/Snapshots
  rm -f $REGROOT/Private
  rm -f $REGROOT/Public
  rm -f $REGROOT/HTML
  exit
fi
## HTML Share
if [[ $REPLY == "html_region" ]]
then
  if [ -e "$REGROOT/HTML" ]; then
    echo "detaching HTML root region..."
    rm $REGROOT/HTML
  else
    echo "attaching HTML root region..."
    ln -s /mnt/server/.html $REGROOT/HTML
  fi
  exit
fi
## Private Share
if [[ $REPLY == "private_region" ]]
then
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
  neofetch --ascii_distro debian | sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g'
  echo "Log file cleared."
  echo ""   
  exit
fi

if [[ $REPLY == "backupstd" ]]
then
  /usr/bin/svrbackup.sh 60 no
  exit
fi

if [[ $REPLY == "backupchk" ]]
then
  /usr/bin/svrbackup.sh 60 yes
  exit
fi

echo "unknown command!"
exit