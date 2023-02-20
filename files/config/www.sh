#!/bin/bash
###########################################################
###########################################################
#### these are the whitelisted commands that can be called
#### from the HTTP API, ran as the user 'server' on files.home
REPLY="$1"
ARG="$2"
RAMDISK="$3"
LOGFILE="$4"
REGROOT="/home/server/.regions"


function BACKUPSVR {
############################################
#### Server Backup Program #################

## Time to wait for PVE action timer
WAIT_TIME=60

### Lock file
if [ -f "/tmp/backupsvr.lock" ]; then
  echo "already running!"
  echo "delete '/tmp/backupsvr.lock' to remove lock if program failed"
  return
else
  touch /tmp/backupsvr.lock
fi

echo "****************** starting backup **********************"
echo " "

## Turn on LED
/usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 5 \
 --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
 --url "http://ledwall.home:9300/exec.php?var=&arg=whtledon&action=main"

if [[ "$CHECKSUM" == "yes" ]]
then
  echo "checksum compare option selected, this backup will take awhile!"
  echo " "
  CHECKSUM="--checksum"
else
  CHECKSUM="" 
fi

## Read Backup Drive Names
readarray -t ZFSPOOLS < $RAMDISK/drives.txt

#######################
#######################
## Backup #############
for _POOL in "${ZFSPOOLS[@]}"; do
  POOL=$(echo $_POOL | sed -e 's/\r//g')
  if [ ! "$POOL" == "" ]; then
    ## USB Flash Drives
    if [[ ${POOL::3} == "usb" ]]; then
      #################################
      if [ ! -e /mnt/extbkps/$POOL/Ben ]; then
        echo "flash drive not connected $POOL"
      else
        ##### BEGIN BACKUP #####
        if [ -e /mnt/extbkps/$POOL/Ben/LastSynced.txt ]; then
          LASTSYNC=$(date -r /mnt/extbkps/$POOL/Ben/LastSynced.txt -R)
          echo "*** flash drive $POOL last synced on $LASTSYNC ***"
        fi  
        #### Ben Share ####
        if [ ! -e /mnt/ben/ProOS ]; then
          echo "ben folder not found!"
        else
          echo "syncing 'Ben' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          --exclude="Software/Workstation/**.adi" --exclude='Software/Playstation' \
          --exclude='Software/**VM.zip' --exclude='Software/**HD.zip' --exclude='Software/**HD.7z' \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "regions folder not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync $CHECKSUM -aP --exclude="Public/Movies/" \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        #### Media Share ####
        if [ ! -e /mnt/media/Music ]; then
          echo "media folder not found!"
        else
          echo "syncing 'Media' share to $POOL drive..."
          rsync -aP --exclude="Movies/" --exclude="Music/" --exclude="TV Shows/" \
          /mnt/media/ /mnt/extbkps/$POOL/Media/ -delete --delete-excluded
        fi
        ##### END BACKUP #####
        touch /mnt/extbkps/$POOL/Ben/LastSynced.txt
      fi  
    fi
    ## Hard Drives
    if [[ ${POOL::3} == "hdd" ]]; then
      #################################
      if [ ! -e /mnt/extbkps/$POOL/Ben ]; then
        echo "hard drive not connected $POOL"
      else
        ##### BEGIN BACKUP #####
        if [ -e /mnt/extbkps/$POOL/Ben/LastSynced.txt ]; then
          LASTSYNC=$(date -r /mnt/extbkps/$POOL/Ben/LastSynced.txt -R)
          echo "*** hard drive $POOL last synced on $LASTSYNC ***"
        fi        
        #### Ben Share ####
        if [ ! -e /mnt/ben/ProOS ]; then
          echo "ben folder not found!"
        else
          echo "syncing 'Ben' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "regions folder not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        #### Media Share ####
        if [ ! -e /mnt/media/Music ]; then
          echo "media folder not found!"
        else
          echo "syncing 'Media' share to $POOL drive..."
          rsync -aP /mnt/media/ /mnt/extbkps/$POOL/Media/ -delete --delete-excluded
        fi
        ##### END BACKUP #####
        touch /mnt/extbkps/$POOL/Ben/LastSynced.txt 
      fi
    fi
    echo "" 
  fi  
done

################################
## Wait for drives to settle after backup complete
echo "triggering drive detach in $WAIT_TIME second(s)."
sleep $WAIT_TIME

## Write drive detach trigger file
touch $RAMDISK/detach_bkps.txt
## Unlock State File
rm -f /tmp/backupsvr.lock

## Wait for drives to detach
echo "wait $WAIT_TIME second(s) for drives to detach."

## Turn off LED
/usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
 --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
 --url "http://ledwall.home:9300/exec.php?var=&arg=whtledoff&action=main"

echo "****************** backup complete **********************"
}




### Only run if server user
if [ ! "$USER" == "server" ]; then
  echo "this script should only be ran by server user, aborting."
  exit
fi

## Detach All Regions
if [[ $REPLY == "detach_all_regions" ]]
then
  echo "detaching all regions..."
  rm -f $REGROOT/Snapshots
  rm -f $REGROOT/Backups  
  rm -f $REGROOT/Private
  rm -f $REGROOT/Public
  rm -f $REGROOT/WWW
  rm -f $REGROOT/RAM
  exit
fi
## RAM Share
if [[ $REPLY == "ram_region" ]]
then
  if [ -e "$REGROOT/RAM" ]; then
    echo "detaching RAM region..."
    rm $REGROOT/RAM
  else
    echo "attaching RAM region..."
    ln -s /mnt/ramdisk $REGROOT/RAM
  fi
  exit
fi
## WWW Share
if [[ $REPLY == "www_region" ]]
then
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
## Backups Share
if [[ $REPLY == "backups_region" ]]
then
  if [ -e "$REGROOT/Backups" ]; then
    echo "detaching backups region..."
    rm $REGROOT/Backups
  else
    echo "attaching backups region..."
    ln -s /mnt/extbkps $REGROOT/Backups
  fi
  exit
fi
if [[ $REPLY == "git_push" ]]
then
  TIMESTMP=$(date '+%Y-%m-%d %H:%M')
  echo "uploading all changes to GitHub..."
  echo ""
  echo "*** ProOS repository ***"  
  git config --global --add safe.directory /mnt/ben/ProOS
  cd /mnt/ben/ProOS
  git add .
  git commit -m "$TIMESTMP"
  git push
  cd -
  echo ""
  echo "*** EE-Projects repository ***"  
  git config --global --add safe.directory /mnt/ben/Projects
  cd /mnt/ben/Projects
  git add .
  git commit -m "$TIMESTMP"
  git push
  cd -
  exit
fi

if [[ $REPLY == "lastlog" ]]
then
  lastlog
  echo ""   
  exit
fi

if [[ $REPLY == "clearlog" ]]
then
  truncate -s 0 $LOGFILE
  neofetch --ascii_distro debian | \
    sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g'
  echo "Log file cleared."
  echo ""   
  exit
fi

if [[ $REPLY == "backupstd" ]]
then
  CHECKSUM="no"
  BACKUPSVR
  exit
fi

if [[ $REPLY == "backupchk" ]]
then
  CHECKSUM="yes"
  BACKUPSVR
  exit
fi

echo "unknown command!"
exit
