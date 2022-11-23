#!/bin/bash
############################################
#### Server Backup Program #################
# (do not run standalone, svrutil runs this)

## Time to wait for PVE action timer
## read from first command line argument
wait_time=$1
## read from second command line argument
chksum=$2

### Lock file
if [ -f "/tmp/backupsvr.lock" ]; then
  echo "already running!"
  echo "delete '/tmp/backupsvr.lock' to remove lock if program failed"
  exit
else
  touch /tmp/backupsvr.lock
fi

echo "****************** starting backup **********************"
echo " "
echo "*********************************************************"
echo "run 'screen -r' on files.home to attach to this terminal"
echo "*********************************************************"
echo " "

## Turn on LED
/usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 5 \
 --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
 --url "http://ledwall.home:9300/exec.php?var=&arg=whtledon&action=main"

if [[ "$chksum" == "yes" ]]
then
  echo "checksum compare option selected, this backup will take awhile!"
  echo " "
  CHECKSUM="--checksum"
fi

## Read Backup Drive Names
readarray -t ZFSPOOLS < /mnt/.regions/WWW/drives.txt

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
          rsync --progress $CHECKSUM -aP \
          --exclude="Software/Workstation/**.adi" --exclude='Software/Playstation' \
          --exclude='Software/**VM.zip' --exclude='Software/**HD.zip' --exclude='Software/**HD.7z' \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "regions folder not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync --progress $CHECKSUM -aP --exclude="Public/Movies/" \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        #### Media Share ####
        if [ ! -e /mnt/media/Music ]; then
          echo "media folder not found!"
        else
          echo "syncing 'Media' share to $POOL drive..."
          rsync --progress -aP --exclude="Movies/" --exclude="Music/" --exclude="TV Shows/" \
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
          rsync --progress $CHECKSUM -aP \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "regions folder not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync --progress $CHECKSUM -aP \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        #### Media Share ####
        if [ ! -e /mnt/media/Music ]; then
          echo "media folder not found!"
        else
          echo "syncing 'Media' share to $POOL drive..."
          rsync --progress -aP /mnt/media/ /mnt/extbkps/$POOL/Media/ -delete --delete-excluded
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
echo "triggering drive detach in $wait_time second(s)."


## Write drive detach trigger file
touch /mnt/.regions/Automate/detach_bkps.txt
## Unlock State File
rm -f /tmp/backupsvr.lock

## Wait for drives to detach
echo "wait $wait_time second(s) for drives to detach."

## Turn off LED
/usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
 --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
 --url "http://ledwall.home:9300/exec.php?var=&arg=whtledoff&action=main"

echo "backup complete."
exit