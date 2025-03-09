#!/bin/bash
###########################################################
###########################################################
#### these are the whitelisted commands that can be called
#### from the HTTP API, ran as the user 'server' on files.home
REPLY="$1"
ARG="$2"
RAMDISK="$3"
LOGFILE="$4"
STATUSFILE="/mnt/extbkps/status.txt"

CURBKPDTES=()
function SAVEBKPDATES () {
  local _POOL="$1"
  touch /mnt/extbkps/$_POOL/LastSynced.txt
  local _LASTSYNC=$(date -r /mnt/extbkps/$_POOL/LastSynced.txt '+%F %r')
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
      if [ ! -e /mnt/extbkps/$POOL/Data ]; then
        echo "flash drive not connected $POOL"
      else
        #### Data Share ####
        if [ ! -e /mnt/data/ProOS ]; then
          echo "Data' share not found!"
        else
          echo "syncing 'Data' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          --exclude="Games/" --exclude="Software/**HD.img" \
          --exclude="Software/**VM.7z" --exclude="Software/**VM.zip" \
          --exclude="Software/**HD.7z" --exclude="Software/**HD.zip" \
          --exclude="Software/**.adi" --exclude="Software/**.vmdk" \
          /mnt/data/ /mnt/extbkps/$POOL/Data/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/SFTP ]; then
          echo "'Regions' share not found!"
        else
          echo "syncing 'Regions' share to $POOL drive..."
          rsync $CHECKSUM -aP --exclude="Archive/ALUTqMiuxVtjfuair7WIgQ/" \
          /mnt/.regions/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
        fi
        ##### END BACKUP #####
        SAVEBKPDATES "$POOL"
      fi  
    fi
    ## Hard Drives
    if [[ ${POOL::3} == "hdd" ]]; then
      #################################
      if [ ! -e /mnt/extbkps/$POOL/Data ]; then
        echo "hard drive not connected $POOL"
      else      
        #### Data Share ####
        if [ ! -e /mnt/data/ProOS ]; then
          echo "Data' share not found!"
        else
          echo "syncing 'Data' share to $POOL drive..."
          rsync $CHECKSUM -aP \
          /mnt/data/ /mnt/extbkps/$POOL/Data/ -delete --delete-excluded
        fi
        #### Regions Share ####
        if [ ! -e /mnt/.regions/SFTP ]; then
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

if [ -f "$STATUSFILE" ]; then
  ## Read status file into array
  echo " " 
  echo "last backup dates: "
  readarray -t STATFILEARR < "$STATUSFILE"
  for STATFILE_LAST in "${STATFILEARR[@]}"; do
    echo "$STATFILE_LAST"
  done
  ## Backup last file
  cp -f "$STATUSFILE" "$STATUSFILE.bak"
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
    ## Add new entry if no exisiting data found
    if [[ "$ENTRY_FOUND" != "yes" ]]; then
      STATFILEARR+=("$CURBKP_DRIVE|$CURBKP_DATE")
    fi
  done
  ## Write array to new file
  echo " " 
  echo "current backup dates: "
  for NEWSTATFILE_ITEM in "${STATFILEARR[@]}"; do
    echo "$NEWSTATFILE_ITEM" >> "$STATUSFILE"
    echo "$NEWSTATFILE_ITEM"
  done
  echo " "
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

if [[ $REPLY == "last_backup_dates" ]]
then
  echo " " 
  echo "last backup dates: "
  readarray -t LSTBKPARR < "$STATUSFILE"
  for LSTBKPLINE in "${LSTBKPARR[@]}"; do
    echo "$LSTBKPLINE"
  done
  exit
fi

REGROOT="/home/server/.regions"

PATHMOUNTED() { findmnt --target "$1" >/dev/null;} 

function UMNT_FUSEFS () {
  VOLNME="$1"
  FUSEPTH="$REGROOT/$VOLNME"
  if PATHMOUNTED "$FUSEPTH"
  then
    echo "detaching $VOLNME..."
    fusermount -u "$FUSEPTH"
    sleep 1
    rmdir "$FUSEPTH"
  else 
    echo "FUSE volume not attached."
  fi
}

function MNT_FUSEFS () {
  VOLNME="$1"
  FUSEPTH="$REGROOT/$VOLNME"
  FUSEPWD="/mnt/ramdisk/fusearch.txt"
  UMNT_FUSEFS "$VOLNME"
  echo "attaching $VOLNME..."
  mkdir -p "$FUSEPTH"
  if [[ -e "$FUSEPWD" ]]
  then
    gocryptfs -quiet -allow_other \
      /mnt/.regions/"$VOLNME" \
      "$FUSEPTH" -passfile "$FUSEPWD"
  else
    echo "password file not found!"
  fi
  if [[ -e "$FUSEPWD" ]]
  then
    rm -f "$FUSEPWD"
  fi
}

## Archive Region
if [[ $REPLY == "mnt_arch_region" ]]
then
  MNT_FUSEFS "Archive"
  exit
fi
## Volumes Region
if [[ $REPLY == "mnt_vol_region" ]]
then
  MNT_FUSEFS "Volumes"
  exit
fi
## Detach FUSE Regions
if [[ $REPLY == "unmnt_all_fuse" ]]
then
  UMNT_FUSEFS "Archive"
  UMNT_FUSEFS "Volumes"
  exit
fi

## RAM Disk Region
if [ $REPLY == "mnt_ram_region" ]
then
  if [ ! -e "$REGROOT/RAM" ]; then
    echo "attaching RAM disk region..."
    ln -s /mnt/ramdisk $REGROOT/RAM
  else
    echo "already attached."    
  fi
  exit
fi
if [ $REPLY == "unmnt_ram_region" ]
then
  if [ -e "$REGROOT/RAM" ]; then
    echo "detaching RAM disk region..."
    rm $REGROOT/RAM
  else
    echo "not attached."    
  fi
  exit
fi

## Snapshots Region
if [ $REPLY == "mnt_snap_region" ]
then
  if [ ! -e "$REGROOT/Snapshots" ]; then
    echo "attaching ZFS snapshots region..."
    ln -s /mnt/snapshots $REGROOT/Snapshots
  else
    echo "already attached."
  fi
  exit
fi
if [ $REPLY == "unmnt_snap_region" ]
then
  if [ -e "$REGROOT/Snapshots" ]; then
    echo "detaching ZFS snapshots region..."
    rm $REGROOT/Snapshots
  else
    echo "not attached." 
  fi
  exit
fi

## External Region 
if [ $REPLY == "mnt_ext_region" ]
then
  if [ ! -e "$REGROOT/External" ]; then
    echo "attaching external region..."
    ln -s /mnt/extbkps $REGROOT/External
  else
    echo "already attached."
  fi
  exit
fi
if [ $REPLY == "unmnt_ext_region" ]
then
  if [ -e "$REGROOT/External" ]; then
    echo "detaching external region..."
    rm $REGROOT/External
  else
    echo "not attached." 
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
    echo "folder not found."  
  fi
  exit
fi
if [[ $REPLY == "git_push" ]]
then
  TIMESTMP=$(date '+%Y-%m-%d %H:%M')
  echo "uploading all changes to GitHub..."
  echo ""
  echo "*** ProOS repository ***"  
  git config --global --add safe.directory /mnt/data/ProOS
  cd /mnt/data/ProOS
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
