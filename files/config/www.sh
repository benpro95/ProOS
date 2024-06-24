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


CURBKPDTES=()
function SAVEBKPDATES () {
  local _POOL="$1"
  touch /mnt/extbkps/$_POOL/Ben/LastSynced.txt
  local _LASTSYNC=$(date -r /mnt/extbkps/$_POOL/Ben/LastSynced.txt '+%F %r')
  local _CURBKPLNE=$(echo "$_POOL|$_LASTSYNC" | sed -e 's/ /_/g')
  CURBKPDTES+=( $_CURBKPLNE )
}

function BACKUPSVR () {
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
 --url "http://ledwall.home/exec.php?var=&arg=whtledon&action=main"

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
  ## Remove Invalid Characters
  POOL=$(echo $_POOL | sed -e 's/\r//g')
  if [ ! "$POOL" == "" ]; then
    ## USB Flash Drives
    if [[ ${POOL::3} == "usb" ]]; then
      #################################
      if [ ! -e /mnt/extbkps/$POOL/Ben ]; then
        echo "flash drive not connected $POOL"
      else
        #### Ben Share ####
        if [ ! -e /mnt/ben/ProOS ]; then
          echo "Ben' share not found!"
        else
          echo "syncing 'Ben' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          --exclude="Software/**.adi" --exclude="Games/" \
          --exclude="Software/**VM.7z" --exclude="Software/**VM.zip" \
          --exclude="Software/**HD.zip" --exclude="Software/**HD.7z" \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "'Regions' share not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync $CHECKSUM -aP --exclude="Archive/Movies/" \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        ##### END BACKUP #####
        SAVEBKPDATES "$POOL"
      fi  
    fi
    ## Hard Drives
    if [[ ${POOL::3} == "hdd" ]]; then
      #################################
      if [ ! -e /mnt/extbkps/$POOL/Ben ]; then
        echo "hard drive not connected $POOL"
      else      
        #### Ben Share ####
        if [ ! -e /mnt/ben/ProOS ]; then
          echo "Ben' share not found!"
        else
          echo "syncing 'Ben' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          /mnt/ben/ /mnt/extbkps/$POOL/Ben/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/Private ]; then
          echo "'Regions' share not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        #### Media Share ####
        if [ ! -e /mnt/media/Music ]; then
          echo "'Media' share not found!"
        else
          echo "syncing 'Media' share to $POOL drive..."
          rsync -aP /mnt/media/ /mnt/extbkps/$POOL/Media/ -delete --delete-excluded
        fi
        ##### END BACKUP #####
        SAVEBKPDATES "$POOL"
      fi
    fi
    echo "" 
  fi  
done

STATUSFILE="/mnt/extbkps/status.txt"
if [ -f "$STATUSFILE" ]; then
  ## Read status file into array
  readarray -t STATFILEARR < "$STATUSFILE"
  ## Delete status files content
  truncate -s 0 "$STATUSFILE"
  ## Read through each item in current drive status array
  for CURBKP_ITEM in ${CURBKPDTES[@]}; do
    ENTRY_FOUND=""
    CURBKP_DRIVE=${CURBKP_ITEM%|*}
    CURBKP_DATE=${CURBKP_ITEM#*|}
    ## Read through each item in status file array
    for STATIDX in "${!STATFILEARR[@]}"; do
      STATFILE_ITEM=${STATFILEARR[$STATIDX]}
      STATFILE_DRIVE=${STATFILE_ITEM%|*}
      STATFILE_DATE=${STATFILE_ITEM#*|}
      ## Scan for matching drive entry
      if [[ "$STATFILE_DRIVE" == "$CURBKP_DRIVE" ]]; then
        ## Update existing entry
        STATFILEARR[$STATIDX]="$STATFILE_DRIVE|$CURBKP_DATE"
        ENTRY_FOUND="yes"
        break
      fi
    done
    ## Add new entry if no match found
    if [[ "$ENTRY_FOUND" == "" ]]; then
      STATFILEARR+=("$CURBKP_DRIVE|$CURBKP_DATE")
    fi
  done
  ## Write array to new file
  for NEWSTATFILE_ITEM in "${STATFILEARR[@]}"; do
    echo "$NEWSTATFILE_ITEM" >> "$STATUSFILE"
    echo " " 
    echo "last backup dates: "
    echo "$NEWSTATFILE_ITEM"
    echo " "
  done
fi

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
 --url "http://ledwall.home/exec.php?var=&arg=whtledoff&action=main"

echo "****************** backup complete **********************"
}

### Only run if server user
if [ "$USER" != "server" ]; then
  echo "this script should only be ran by 'server' user, exiting..."
  exit
fi

## Detach All Regions
if [[ $REPLY == "detach_all_regions" ]]
then
  echo "detaching all regions..."
  rm -f $REGROOT/Snapshots
  rm -f $REGROOT/External  
  rm -f $REGROOT/Private
  rm -f $REGROOT/Archive
  rm -f $REGROOT/ArchiveII
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
if [[ $REPLY == "priv_region" ]]
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
## Archive Shares
if [[ $REPLY == "arc_region" ]]
then
  if [ -e "$REGROOT/Archive" ]; then
    echo "detaching archive region..."   
    rm $REGROOT/Archive
  else
    echo "attaching archive region..."
    ln -s /mnt/.regions/Archive $REGROOT/Archive
  fi
  exit
fi
if [[ $REPLY == "arc2_region" ]]
then
  if [ -e "$REGROOT/ArchiveII" ]; then
    echo "detaching archive II region..."   
    rm $REGROOT/ArchiveII
  else
    echo "attaching archive II region..."
    ln -s /mnt/.regions/ArchiveII $REGROOT/ArchiveII
  fi
  exit
fi
## Snapshot Share
if [[ $REPLY == "snap_region" ]]
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
## External Mountpoints Share
if [[ $REPLY == "ext_region" ]]
then
  if [ -e "$REGROOT/External" ]; then
    echo "detaching external mountpoints region..."
    rm $REGROOT/External
  else
    echo "attaching external mountpoints region..."
    ln -s /mnt/extbkps $REGROOT/External
  fi
  exit
fi
## Copy To Media
if [[ $REPLY == "scratchcopy" ]]
then
  if [ -e "/mnt/media/Downloads" ]; then
  	rsync -aPv --exclude='*humbs.db' --exclude='*esktop.ini' \
  	--exclude='.*' --exclude='$RECYCLE.BIN' \
  	/mnt/scratch/downloads/* /mnt/media/Downloads/
  else
    echo "Downloads folder not found."  
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

if [[ $REPLY == "netscan" ]]
then
  echo "** network scan **"
  nmap --unprivileged -v --open -PT 10.177.1.0/24
  nmap --unprivileged -v --open -sn 10.177.1.0/24
  exit
fi

echo "unknown command!"
exit
