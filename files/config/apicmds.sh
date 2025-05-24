#!/bin/bash
###########################################################
###########################################################
#### these are the whitelisted commands that can be called
#### from SSH, ran as the user 'ben' on files.home
CMD="$1"
RAMDISK="$2"
LOGFILE="$3"
STATUSFILE="/mnt/extbkps/status.txt"

CURBKPDTES=()
function SAVEBKPDATES () {
  local _POOL="$1"
  touch /mnt/extbkps/$_POOL/LastSynced.txt
  local _LASTSYNC=$(date -r /mnt/extbkps/$_POOL/LastSynced.txt '+%F %r')
  local _CURBKPLNE=$(echo "$_POOL|$_LASTSYNC" | sed -e 's/ /_/g')
  CURBKPDTES+=( $_CURBKPLNE )
}

### Only run if specific user
if [ "$USER" != "ben" ]; then
  echo "incorrect user, exiting..."
  exit
fi

if [[ $CMD == "last_backup_dates" ]]
then
  echo " " 
  echo "last backup dates: "
  readarray -t LSTBKPARR < "$STATUSFILE"
  for LSTBKPLINE in "${LSTBKPARR[@]}"; do
    echo "$LSTBKPLINE"
  done
  exit
fi

#### BEGIN REGIONS ####

## Regions Mountpoints Folder
REGMNTS="/mnt/regmnts"
## Regions Data Folder
REGDATA="/mnt/.regions"

PATHMOUNTED() { findmnt --target "$1" >/dev/null;} 

function UMNT_FUSEFS () {
  VOLNME="$1"
  FUSEPTH="$REGMNTS/$VOLNME"
  if PATHMOUNTED "$FUSEPTH"
  then
    UNCAPSTR="${VOLNME,,}"
    echo "detaching $UNCAPSTR..."
    fusermount -u "$FUSEPTH"
    sleep 1
    rmdir "$FUSEPTH"
  else 
    echo "FUSE volume not attached."
  fi
}

function MNT_FUSEFS () {
  VOLNME="$1"
  FUSEPTH="$REGMNTS/$VOLNME"
  FUSEPWD="$RAMDISK/fusearch.txt"
  UMNT_FUSEFS "$VOLNME"
  UNCAPSTR="${VOLNME,,}"
  echo "attaching $UNCAPSTR..."
  mkdir -p "$FUSEPTH"
  if [[ -e "$FUSEPWD" ]]
  then
    gocryptfs -quiet -allow_other \
      $REGDATA/"$VOLNME" \
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
if [[ $CMD == "mnt_arch_region" ]]
then
  MNT_FUSEFS "Archive"
  exit
fi

## Volumes Region
if [[ $CMD == "mnt_vol_region" ]]
then
  MNT_FUSEFS "Volumes"
  exit
fi

UMOUNT_ALLFUSE(){
  UMNT_FUSEFS "Archive"
  UMNT_FUSEFS "Volumes"
}

## Detach FUSE Regions
if [[ $CMD == "unmnt_all_fuse" ]]
then
  UMOUNT_ALLFUSE
  exit
fi

## RAM Disk Region
UMOUNT_RAMDSK(){
  if [ -e "$REGMNTS/RAM" ]; then
    echo "detaching RAM disk region..."
    rm $REGMNTS/RAM
  else
    echo "RAM not attached."    
  fi
}
if [[ $CMD == "mnt_ram_region" ]]
then
  if [ ! -e "$REGMNTS/RAM" ]; then
    echo "attaching RAM disk region..."
    ln -s $RAMDISK $REGMNTS/RAM
  else
    echo "RAM already attached."    
  fi
  exit
fi
if [[ $CMD == "unmnt_ram_region" ]]
then
  UMOUNT_RAMDSK
  exit
fi

## Snapshots Region
UMOUNT_SNAP(){
  if [ -e "$REGMNTS/Snapshots" ]; then
    echo "detaching ZFS snapshots region..."
    rm $REGMNTS/Snapshots
  else
    echo "snapshots not attached." 
  fi
}
if [[ $CMD == "mnt_snap_region" ]]
then
  if [ ! -e "$REGMNTS/Snapshots" ]; then
    echo "attaching ZFS snapshots region..."
    ln -s /mnt/snapshots $REGMNTS/Snapshots
  else
    echo "snapshots already attached."
  fi
  exit
fi
if [[ $CMD == "unmnt_snap_region" ]]
then
  UMOUNT_SNAP
  exit
fi

## External Region 
UMOUNT_EXTREG(){
  if [ -e "$REGMNTS/External" ]; then
    echo "detaching external region..."
    rm $REGMNTS/External
  else
    echo "external not attached." 
  fi
}
if [[ $CMD == "mnt_ext_region" ]]
then
  if [ ! -e "$REGMNTS/External" ]; then
    echo "attaching external region..."
    ln -s /mnt/extbkps $REGMNTS/External
  else
    echo "external already attached."
  fi
  exit
fi
if [[ $CMD == "unmnt_ext_region" ]]
then
  UMOUNT_EXTREG
  exit
fi

## Documents Region
UMOUNT_DOCS(){
  if [ -e "$REGMNTS/Documents" ]; then
    echo "detaching documents region..."
    rm $REGMNTS/Documents
  else
    echo "documents not attached." 
  fi
}
if [[ $CMD == "mnt_docs_region" ]]
then
  if [ ! -e "$REGMNTS/Documents" ]; then
    echo "attaching documents region..."
    ln -s $REGDATA/Documents $REGMNTS/Documents
  else
    echo "documents already attached."
  fi
  exit
fi
if [[ $CMD == "unmnt_docs_region" ]]
then
  UMOUNT_DOCS
  exit
fi

## Detach All Regions
if [[ $CMD == "unmnt_all" ]]
then
  UMOUNT_RAMDSK
  UMOUNT_EXTREG
  UMOUNT_NET
  UMOUNT_DOCS
  UMOUNT_SNAP
  UMOUNT_ALLFUSE
  echo "detached all region(s)."
  exit
fi

## END REGIONS ##

## Copy To Media
if [[ $CMD == "scratchcopy" ]]
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
if [[ $CMD == "git_push" ]]
then
  TIMESTMP=$(date '+%Y-%m-%d %H:%M')
  echo "uploading changes to GitHub..."
  git config --global --add safe.directory /mnt/data/ProOS
  cd /mnt/data/ProOS
  git add .
  git commit -m "$TIMESTMP"
  git push
  exit
fi

if [[ $CMD == "lastlog" ]]
then
  lastlog 
  exit
fi

if [[ $CMD == "clearlog" ]]
then
  truncate -s 0 $LOGFILE
  neofetch --ascii_distro debian | \
    sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g' 
  exit
fi

if [[ $CMD == "netscan" ]]
then
  echo "** network scan **"
  nmap --unprivileged -v --open -PT 10.177.1.0/24
  nmap --unprivileged -v --open -sn 10.177.1.0/24
  exit
fi

## External Drive Backups ##
if [[ $CMD == "backupstd" || $CMD == "backupchk" ]]
then
  ## Standard or Checksum RSYNC
  if [[ $CMD == "backupstd" ]]
  then
    CHECKSUM=""
  fi
  if [[ $CMD == "backupchk" ]]
  then
    echo "checksum compare option selected, this backup will take awhile!"
    CHECKSUM="--checksum"
  fi
  ## Time to wait for PVE response
  WAIT_TIME=60
  ### Lock file
  if [ -f "$RAMDISK/backupsvr.lock" ]; then
    echo "already running!"
    echo "delete '$RAMDISK/backupsvr.lock' to remove lock if program failed"
    return
  else
    touch $RAMDISK/backupsvr.lock
  fi
  echo "****************** starting backup **********************"
  echo " "
  ## Turn on LED
  /usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 5 \
  --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
  --url "http://ledwall.home/exec.php?var=&arg=whtledon&action=main" > /dev/null 2>&1 &
  ## Read Backup Drive Names
  readarray -t ZFSPOOLS < $RAMDISK/drives.txt
  #######################
  #######################
  ## RSYNC ##############
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
          if [ ! -e $REGDATA/SFTP ]; then
            echo "'Regions' share not found!"
          else
            echo "syncing 'Regions' share to $POOL drive..."
            rsync $CHECKSUM -aP --exclude="Archive/ALUTqMiuxVtjfuair7WIgQ/" \
            $REGDATA/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
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
          if [ ! -e $REGDATA/SFTP ]; then
            echo "'Regions' share not found!"
          else
            echo "syncing 'Regions' share to $POOL drive..."
            rsync $CHECKSUM -aP \
            $REGDATA/ /mnt/extbkps/$POOL/.Regions/ -delete --delete-excluded
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
  ################################
  ################################
  ## Write backup dates to file ##
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
  ################################
  ## Wait for drives to settle after backup complete ##
  echo "triggering drive detach in $WAIT_TIME second(s)."
  sleep $WAIT_TIME
  ## Write drive detach trigger file
  touch $RAMDISK/detach_bkps.txt
  ## Unlock State File
  rm -f $RAMDISK/backupsvr.lock
  ## Wait for drives to detach
  echo "wait $WAIT_TIME second(s) for drives to detach."
  ## Turn off LED
  /usr/bin/curl --silent --fail --ipv4 --no-buffer --max-time 30 \
  --retry 3 --retry-all-errors --retry-delay 1 --no-keepalive \
  --url "http://ledwall.home/exec.php?var=&arg=whtledoff&action=main" > /dev/null 2>&1 &
  echo "****************** backup complete **********************"
  exit
fi

echo "unknown command!"
exit
