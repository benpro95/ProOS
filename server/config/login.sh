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
  exit
fi
}


## Deploy server configuration
DEPLOY_SERVER(){
echo "Deploying server $MODULE..."
## Create work folder
if [ -e /mnt/scratch/downloads ]; then
  mkdir -p /mnt/scratch/downloads/.ptmp
  TMPFLDR=$(mktemp -d /mnt/scratch/downloads/.ptmp/XXXXXXXXX)
else
  echo "Scratch drive not connected using /tmp" 	
  TMPFLDR=$(mktemp -d /tmp/protmp.XXXXXXXXX)
fi
echo "created work directory $TMPFLDR"
## Copying files to work folder
cp -r $ROOTDIR/$MODULE/config $TMPFLDR/
## Compressing files
cd $TMPFLDR
export COPYFILE_DISABLE=true
tar -cvf config.tar config
cd -
## Downloading host bundle
scp -i $KEYS/$MODULE.rsa -p $TMPFLDR/config.tar root@$HOST:/tmp/
## Install files
ssh -t -i $KEYS/$MODULE.rsa root@$HOST \
 "cd /tmp/; tar -xvf config.tar; rm -f config.tar; chmod +x /tmp/config/installer.sh; /tmp/config/installer.sh"
## Clean-up installer files
rm -r $TMPFLDR
}


## Local domain name
#DOMAIN=".local"
#DOMAIN=".home"
DOMAIN=""

## Modules folder
ROOTDIR="/root/ProOS"

## SSH keys folder
KEYS="/root/.ssh"

## Read variables
MODULE=$1
ARG2=$2
HOST=$3

### ProServer Help Menu
if [ "$MODULE" == "" ]; then
printf \
'* Pi / Server Configuration and Login Script
by Ben Provenzano III

Login to ProOS Pi / Server
./login "Hostname"

Sync ProOS (quick run config script) Pi / Server
./login "Hostname" sync

Reset ProOS (full config script) Pi Only
./login "Hostname" reset

Reset ProOS & Reinstall Packages (full config script) Pi Only
./login "Hostname" reinstall

Clean/Restore ProOS (delete /opt/rpi and run full config script) Pi Only
./login "Hostname" clean

Initialize ProOS (configure a base Pi or reconfigure one) Pi Only
./login "Module" init "Hostname"

Command Reference List
./login cmds

Clean-up Temporary Files
./login rmtmp
\n'
exit
fi

### Exit if matches this hosts
if [ "$MODULE" == "router" ] || \
   [ "$MODULE" == "login" ] || \
   [ "$MODULE" == ".ssh" ] || \
   [ "$MODULE" == "rpi" ] || \
   [ "$MODULE" == "wkst" ] || \
   [ "$MODULE" == "sources" ]; then
echo "Hostname not allowed."
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
exit
fi

### Remove temp files argument
if [ "$MODULE" == "rmtmp" ]; then
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
if [ -e $MODULE/qemu.conf ] || [ -e $MODULE/lxc.conf ] ; then
######################################
  ## Set hostname
  HOST="$MODULE$DOMAIN"
  ## Translate hostname to IP
  if [ "$MODULE" == "pve" ]; then
    HOST="10.177.1.8" 
  fi 
  if [ "$MODULE" == "files" ]; then
    HOST="10.177.1.4" 
  fi
  ## SSH key prompt
  eval `ssh-agent -s`
  ssh-add $KEYS/$MODULE.rsa 2>/dev/null
  ### AutoSync
  if [ "$ARG2" == "sync" ]; then
    DEPLOY_SERVER
    echo "'d' to re-deploy server $HOST"    
    echo "'u' to update server $HOST"   
    echo "'r' to reboot server $HOST"
    echo "'s' for a shell on server $HOST"    
    echo "any other key to exit"
    read -p "enter option: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Rr]$ ]]
    then
      echo "Rebooting server..."
      ssh -t -i $KEYS/$MODULE.rsa root@$HOST "reboot"
    fi
    if [[ $REPLY =~ ^[Ss]$ ]]
    then
      ssh -t -i $KEYS/$MODULE.rsa root@$HOST
    fi
    if [[ $REPLY =~ ^[Dd]$ ]]
    then
      DEPLOY_SERVER
    fi    
    if [[ $REPLY =~ ^[Uu]$ ]]
    then
      echo "Running update program..."
      ssh -t -i $KEYS/$MODULE.rsa root@$HOST "apt-get update; apt-get upgrade"
    fi       
    if [[ ! $REPLY =~ ^[RrSs]$ ]]  
    then
      ## Exit
      ssh-add -D
      eval $(ssh-agent -k)   
      exit
    fi 
  else
    ## Login to SSH
    ssh -t -i $KEYS/$MODULE.rsa root@$HOST
  fi
  ## Clean-up on logout
  ssh-add -D
  eval $(ssh-agent -k)   
  exit
######################################
fi

########## Raspberry Pi Configurator ##########

SYNCSTATE="no"

## Determine script operation
if [ "$ARG2" == "init" ]; then
  ## Init function
  HOST="$HOST$DOMAIN"
  SYNCSTATE="start"
else
  ## Sync and reset functions	
  HOST="$MODULE$DOMAIN"
  if [ "$ARG2" == "sync" ] || \
     [ "$ARG2" == "clean" ] || \
     [ "$ARG2" == "reinstall" ] || \
     [ "$ARG2" == "reset" ] ; then
    SYNCSTATE="start"
  else
  ## Other argument specified	
    if ! [ "$ARG2" = "" ] ; then
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
     $KEYS/rpi.rsa root@$HOST "/opt/rpi/init $ARG2"
    exit
    fi
  fi
fi

######### START AUTOSYNC ##########
if [ "$SYNCSTATE" == "start" ]; then
  HOSTCHK
  echo ""
  STRIN=$(ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $KEYS/rpi.rsa root@$HOST "df -h")
  SUBSTR="overlay"
  if [[ "$STRIN" == *"$SUBSTR"* ]]; then
  	 echo "Read/only root filesystem detected."
     ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
      $KEYS/rpi.rsa root@$HOST "/opt/rpi/init rw"
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
          exit
        fi
     fi
  else
    echo "Read/write root filesystem detected."   
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
  if [ "$ARG2" == "reset" ] || \
  	 [ "$ARG2" == "restore" ] || \
     [ "$ARG2" == "reinstall" ] || \
     [ "$ARG2" == "clean" ] || \
     [ "$ARG2" == "init" ] ; then
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
    $KEYS/rpi.rsa root@$HOST "rm -fv /etc/rpi-conf.done"
    if [ "$ARG2" = "reinstall" ] ; then
      ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
      $KEYS/rpi.rsa root@$HOST "touch /etc/rpi-reinitsource.done"
    fi   
  fi

  ## Check for restore
  if [ "$ARG2" == "restore" ] || [ "$ARG2" == "clean" ] ; then
    echo "Erasing software..."
    ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
     $KEYS/rpi.rsa root@$HOST "rm -rfv /opt/rpi"
    echo "Downloading software..."
  else 
    echo "Syncing software..."
  fi

  ## Install base software
  rsync -e "ssh -i $KEYS/rpi.rsa" --progress --checksum -rtv \
   --exclude=photos --exclude=sources $ROOTDIR/rpi root@$HOST:/opt/
  rsync -e "ssh -i $KEYS/rpi.rsa" --progress --checksum -rtv \
   --mkpath $ROOTDIR/automate/config/html/* root@$HOST:/opt/rpi/config/html-base/ 
  ## Install module-specific software
  rsync -e "ssh -i $KEYS/rpi.rsa" --progress --checksum -rtv \
   --exclude=photos --exclude=sources $ROOTDIR/$MODULE/* root@$HOST:/opt/rpi/

  ## Write hostname to Pi
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
   $KEYS/rpi.rsa root@$HOST "echo $MODULE > /opt/rpi/config/hostname"

  ## Installing on Pi
  echo "Installing software..."
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
   $KEYS/rpi.rsa root@$HOST "cd /opt/rpi/config; chmod +x installer.sh; ./installer.sh"

  ## Reboot in read-only mode
  read -p "Do you want to reboot in read-only mode? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
   $KEYS/rpi.rsa root@$HOST "/opt/rpi/init ro"
  exit

######### END AUTOSYNC ##########
fi

## Exit if host down
HOSTCHK
## Login to SSH
ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i \
 $KEYS/rpi.rsa root@$HOST
exit
