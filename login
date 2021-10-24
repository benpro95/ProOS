#!/bin/bash
### Raspberry Pi / Server Communication Script - ProOS
### by Ben Provenzano III
###

## Check if host is up
HOSTCHK(){
echo "Attempting connection..."
if ping -c 2 $HOST &> /dev/null
then
  echo "Connection established."
else
  echo "Host $HOST is down, exiting..."
  ## Clean-up on logout
  rm -r $TMPFLDR
  exit
fi
}

## Local domain name
#DOMAIN=".local"
DOMAIN=".home"
#DOMAIN=""

## Set to current directory
ROOTDIR=.

## Read variables
MODULE=$1
ARG2=$2
HOST=$3

## Set Temporary Directory
if [ -e /mnt/scratch/downloads ]; then
  mkdir -p /mnt/scratch/downloads/.ptmp
  TMPFLDR=$(mktemp -d /mnt/scratch/downloads/.ptmp/XXXXXXXXX)
else
  TMPFLDR=$(mktemp -d /tmp/protmp.XXXXXXXXX)
fi

### ProServer Help Menu
if [ "$MODULE" = "" ]; then
printf \
'* Pi / Server Configuration and Login Script
by Ben Provenzano III

Login to ProOS Pi / Server
./login "Hostname"

Sync ProOS (quick run config script) Pi / Server
./login "Hostname" sync

Reset ProOS (full config script) Pi Only
./login "Hostname" reset

Clean/Restore ProOS (delete /opt/rpi and run full config script) Pi Only
./login "Hostname" clean

Initialize ProOS (configure a base Pi or reconfigure one) Pi Only
./login "Module" init "Hostname"

Command Reference List
./login cmds

Clean-up Temporary Files
./login rmtmp
\n'
## Clean-up
rm -r $TMPFLDR
exit
fi

### Exit if matches this hosts
if [ "$MODULE" = "router" ] || [ "$MODULE" = "rpi" ] || [ "$MODULE" = "z97mx" ] || [ "$MODULE" = "sources" ]; then
echo "Hostname not allowed."
## Clean-up
rm -r $TMPFLDR
exit
fi

if [ "$MODULE" = "cmds" ]; then
printf \
'* Linux Command Reference
by Ben Provenzano III

#### Find a specific string in multiple files
grep -RHIni "\<STRING\>" file or folder

#### Convert binary to single line of base64 (PNG to HTML base64)
openssl base64 -A -in file.bin -out file.base64

#### Convert ZFS stored VM disk to RAW disk image
dd bs=128k if=/dev/rpool/proxmox/vm-100-disk-0 of=file.raw

#### Convert ZFS stored VM disk to QCOW2 disk image
qemu-img convert -f raw -O qcow2 /dev/rpool/proxmox/vm-100-disk-0 file.qcow2
\n'
## Clean-up
rm -r $TMPFLDR
exit
fi

### Remove temp files argument
if [ "$MODULE" = "rmtmp" ]; then
echo "Removing temporary files..."
pkill ssh-agent
 if [ -e /mnt/scratch/downloads ]; then
  rm -rfv /mnt/scratch/downloads/.ptmp
 else
  rm -rfv /tmp/protmp.*
 fi
exit
fi

### ProServer Configurator (only these hosts)
if [ "$MODULE" = "files" ] || [ "$MODULE" = "plex" ] || [ "$MODULE" = "pve" ] || [ "$MODULE" = "unifi" ] || [ "$MODULE" = "xana" ] || [ "$MODULE" = "dev" ] || [ "$MODULE" = "automate" ]; then
######################################
  HOST="$MODULE$DOMAIN"
   ## Check if host is up (don't ping these hosts)
  if [ ! "$MODULE" = "pve" ]; then
    HOSTCHK
  fi 
  ## Copy SSH key
  cp -r $ROOTDIR/$MODULE/id_rsa $TMPFLDR/id_rsa
  chmod 600 $TMPFLDR/id_rsa
  ## SSH key prompt
  eval `ssh-agent -s`
  ssh-add $TMPFLDR/id_rsa 2>/dev/null
  ### AutoSync
  if [ "$ARG2" = "sync" ]; then
    echo "ProOS NetInstall for Server"
    ## Copying files to temp
    cp -r $ROOTDIR/$MODULE/config $TMPFLDR/
    ## Compressing files
    cd $TMPFLDR
    export COPYFILE_DISABLE=true
    tar -cvf config.tar config
    cd -
    ## Downloading host bundle
    scp -i $TMPFLDR/id_rsa -p $TMPFLDR/config.tar root@$HOST:/tmp/
    ## Install files
    ssh -t -i $TMPFLDR/id_rsa root@$HOST "cd /tmp/; tar -xvf config.tar; rm -f config.tar; chmod +x /tmp/config/installer; /tmp/config/installer"
    ## Clean-up on logout
    ssh-add -D
    eval $(ssh-agent -k)
    rm -r $TMPFLDR
    exit
  else
  ## Login to SSH
  ssh -t -i $TMPFLDR/id_rsa root@$HOST
  ## Clean-up on logout
  ssh-add -D
  eval $(ssh-agent -k)
  rm -r $TMPFLDR
  exit
  fi
######################################
fi

########## Raspberry Pi Configurator ##########

## Copy SSH key
cp -r $ROOTDIR/rpi/id_rsa $TMPFLDR/id_rsa
chmod 600 $TMPFLDR/id_rsa

## Determine script operation
if [ "$ARG2" = "init" ]; then
  ## Init function
  touch $TMPFLDR/start_sync
  HOST="$HOST$DOMAIN"
else
  ## Sync and reset functions	
  HOST="$MODULE$DOMAIN"
  if [ "$ARG2" = "sync" ] || [ "$ARG2" = "clean" ] || [ "$ARG2" = "restore" ] || [ "$ARG2" = "reset" ] ; then
    touch $TMPFLDR/start_sync
  else
  ## Other argument specified	
    if ! [ "$ARG2" = "" ] ; then
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "/opt/rpi/init $ARG2"
    rm -r $TMPFLDR
    exit
    fi
  fi
fi

### Sync ###############
if [ -e $TMPFLDR/start_sync ]; then
  HOSTCHK
  echo "*** ProOS NetInstall ***"
  echo ""
  echo "System must be in read-write mode."
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "df -h"
  read -p "Do you want to reboot in read-write mode? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
     ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "/opt/rpi/init rw"
     echo "Waiting 30 seconds..."
     sleep 30
     if ping -c 1 $HOST &> /dev/null ; then
       echo "Connection established."
     else
        for run in {1..4}; do
          if ! ping -c 1 $HOST &> /dev/null ; then
          echo "Host is down, waiting 10 more seconds..."
          sleep 10
          fi
        done
        if ping -c 1 $HOST &> /dev/null ; then
          echo "Connection established."
        else
          echo "Host is down, exiting..."
          ## Clean-up
          rm -r $TMPFLDR
          exit
        fi
     fi
  fi

  wait_time=03 # seconds
  temp_cnt=${wait_time}
  while [[ ${temp_cnt} -gt 0 ]];
  do
      printf "\rYou have %2d second(s), to hit Ctrl+C to cancel." ${temp_cnt}
      sleep 1
      ((temp_cnt--))
  done
  echo ""

  ## Check for reset
  if [ "$ARG2" = "reset" ] ||  [ "$ARG2" = "init" ] ; then
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -fv /etc/rpi-conf.done"  
  fi

  ## Check for restore
  if [ "$ARG2" = "restore" ] ||  [ "$ARG2" = "clean" ] ; then
    echo "Erasing software..."
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -fv /etc/rpi-conf.done"  
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -rfv /opt/rpi"
    echo "Downloading software..."
  else 
    echo "Syncing software..."
  fi

  ## Download & sync software
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress --checksum -rtv --exclude=id_rsa --exclude=BaseOS.zip --exclude=photos $ROOTDIR/rpi root@$HOST:/opt/
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress --checksum -rtv --exclude=id_rsa --exclude=photos --exclude=sources $ROOTDIR/$MODULE/* root@$HOST:/opt/rpi/

  ## Make module name hostname
  touch $TMPFLDR/modname
  echo "$MODULE" > $TMPFLDR/modname
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress -a $TMPFLDR/modname root@$HOST:/opt/rpi/config/hostname

  ## Installing on Pi
  echo "Installing software..."
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "chmod +x /opt/rpi/config/installer.sh; /opt/rpi/config/installer.sh"

  ## Reboot in read-only mode
  read -p "Do you want to reboot in read-only mode? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
  	## Clean-up
    rm -r $TMPFLDR
    exit 1
  fi
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "/opt/rpi/init ro"
  ## Clean-up
  rm -r $TMPFLDR
  exit
fi
######### END AUTOSYNC ##########

## Exit if host down
HOSTCHK
## Login to SSH
ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST
## Clean-up
rm -r $TMPFLDR
exit
