#!/bin/bash
### Raspberry Pi / Server Communication Script - ProOS
### by Ben Provenzano III
###

## DNS domain name
#DOMAIN=".local"
#DOMAIN=".home"
DOMAIN=""
## Modules folder
ROOTDIR="/mnt/ProOS"
## SSH keys folder
KEYS="/mnt/ProOS/mgmt/keys"
## Work folder
WORKDIR="/opt/deploy"
## Read arguments
MODULE=$1
CMD=$2
HOST=$3
## Global variables
INTMODE=""
NOHOSTCHK=""
SSH_ARGS="ServerAliveInterval=5 -o ServerAliveCountMax=5"

EXIT_PRGM(){
  ## Discard Keys
  ssh-add -D
  eval $(ssh-agent -k)
  ## Exit Script
  exit
}

## Ping check
HOSTCHK(){
  echo "Attempting connection..."
  if ping -c 2 $HOST &> /dev/null
  then
    echo "Connection established."
  else
    echo "Host $HOST is down, exiting..."
    EXIT_PRGM
  fi
}

## Shell Login
SSH_LOGIN(){
  if [ "$NOHOSTCHK" == "" ]; then
    ## Exit if host down
    HOSTCHK
  fi
  ## Login to SSH Pi/Server
  if [ "$MODULE" == "router" ]; then
    ssh -t -o $SSH_ARGS admin@$HOST
  else
    ssh -t -o $SSH_ARGS root@$HOST
  fi
}

EXTRA_ARGS(){
### ProServer Help Menu
if [ "$MODULE" == "" ]; then
printf \
'* Pi / Server Configuration and Login Script
by Ben Provenzano III

Logon to ProOS Pi / Server
login "Hostname"

Sync ProOS (quick run config script) Pi / Server
login "Hostname" sync

Reset ProOS (full config script) Pi Only
login "Hostname" reset

Initialize ProOS (configure a base Pi or reconfigure one) Pi Only
login "Module" init "Hostname"

Command Reference List
login cmds

Clean-up Temporary Files
login rmtmp
\n'
exit
fi
### Exit if matches this hosts
if [ "$MODULE" == "logon" ] || \
   [ "$MODULE" == "login" ] || \
   [ "$MODULE" == ".ssh" ] || \
   [ "$MODULE" == "rpi" ] || \
   [ "$MODULE" == "wkst" ] || \
   [ "$MODULE" == "sources" ]; then
echo "Hostname not allowed."
exit
fi
if [ "$MODULE" == "cmds" ]; then
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
echo "deleting temporary files..."
pkill ssh-agent
if [ -e $WORKDIR ]; then
  rm -rfv $WORKDIR/.ptmp
else
  rm -rfv /tmp/protmp.*
fi
exit
fi
}

POST_DEPLOY_MENU(){
  echo "'d' to re-deploy"    
  echo "'u' to update packages"
  if [ "$INTMODE" == "pi" ]; then
    echo "'r' to reboot in read/only mode"
  else
    echo "'r' to reboot system"
  fi
  if [ "$INTMODE" == "pi" ]; then
    echo "'x' to reboot pi"
  fi
  echo "'s' for a shell on $HOST"    
  echo "press (any) other key to exit"
  read -p "enter option: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Ss]$ ]]
  then
    SSH_LOGIN
    EXIT_PRGM
  fi
  if [[ $REPLY =~ ^[Rr]$ ]]
  then
    if [ "$INTMODE" == "pi" ]; then
      ssh -t -o $SSH_ARGS root@$HOST "/opt/rpi/init ro"
      EXIT_PRGM
    else
      echo "Rebooting $HOST..."
      ssh -t -o $SSH_ARGS root@$HOST "reboot"
      EXIT_PRGM
    fi
  fi
  if [[ $REPLY =~ ^[Xx]$ ]]
  then
    if [ "$INTMODE" == "pi" ]; then
      echo "Rebooting $HOST..."
      ssh -t -o $SSH_ARGS root@$HOST "reboot"
      EXIT_PRGM
    fi
  fi
  if [[ $REPLY =~ ^[Dd]$ ]]
  then
    echo "Deploying $HOST..."
    if [ "$INTMODE" == "nonpi" ]; then
      DEPLOY_SERVER
    else
      DEPLOY_PI
    fi
  fi
  if [[ $REPLY =~ ^[Uu]$ ]]
  then
    echo "Updating $HOST..."
    if [ "$INTMODE" == "nonpi" ]; then
      ssh -t -o $SSH_ARGS root@$HOST "apt-get update; apt-get upgrade"
    else
      ssh -t -o $SSH_ARGS root@$HOST "/opt/rpi/init update"
    fi
    EXIT_PRGM
  fi       
  EXIT_PRGM
}

## Raspberry Pi Configurator ##
DEPLOY_PI(){
  HOSTCHK
  echo ""
  STRIN=$(ssh -t -o $SSH_ARGS root@$HOST "df -h")
  if [[ "$STRIN" == *"overlay"* ]]; then
    echo "Read/only root filesystem detected."
    ssh -t -o $SSH_ARGS root@$HOST "/opt/rpi/init rw"
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
          EXIT_PRGM
        fi
    fi
  else
    echo "Read/write root filesystem detected."   
  fi
  WAIT_TIME=03 ## seconds
  WAIT_COUNT=${WAIT_TIME}
  while [[ ${WAIT_COUNT} -gt 0 ]];
  do
      printf "\rYou have %2d second(s), to hit Ctrl+C to cancel." ${WAIT_COUNT}
      sleep 1
      ((WAIT_COUNT--))
  done
  echo ""
  if [ "$CMD" == "reset" ] || [ "$CMD" == "init" ] ; then
    ssh -t -o $SSH_ARGS root@$HOST "rm -fv /etc/rpi-conf.done"
  fi
  EXCLUDED="--exclude=photos --exclude=sources"
  RSYNC_ARGS="--stats --human-readable --recursive --times --checksum"
  echo "Installing base software..."
  rsync -e "ssh -o $SSH_ARGS" $RSYNC_ARGS $EXCLUDED $ROOTDIR/rpi root@$HOST:/opt/
  echo "Installing shared software..."
  rsync -e "ssh -o $SSH_ARGS" $RSYNC_ARGS $ROOTDIR/automate/config/ztermcom.c root@$HOST:/opt/rpi/
  rsync -e "ssh -o $SSH_ARGS" $RSYNC_ARGS --mkpath $ROOTDIR/automate/config/html/ root@$HOST:/opt/rpi/config/html-base/
  echo "Installing module-specific software..."
  rsync -e "ssh -o $SSH_ARGS" $RSYNC_ARGS $EXCLUDED $ROOTDIR/$MODULE/ root@$HOST:/opt/rpi/
  echo "Starting installer..."
  ssh -t -o $SSH_ARGS root@$HOST "cd /opt/rpi/config; echo $MODULE > ./hostname; chmod +x ./installer.sh; ./installer.sh"
  echo "Installing website menu items..."
  rsync -e "ssh -o $SSH_ARGS" $RSYNC_ARGS $ROOTDIR/automate/config/menus/*.txt root@$HOST:/var/www/html/ram/
  POST_DEPLOY_MENU
}

## Deploy server configuration
DEPLOY_SERVER(){
  ## Create work folder
  if [ -e $WORKDIR ]; then
    mkdir -p $WORKDIR/.ptmp
    TMPFLDR=$(mktemp -d $WORKDIR/.ptmp/XXXXXXXXX)
  else
    echo "Scratch path not found, exiting!"
    EXIT_PRGM
  fi
  echo "Copying files to work folder $TMPFLDR..."
  cp -r $ROOTDIR/$MODULE/config $TMPFLDR/
  echo "Compressing files..."
  cd $TMPFLDR
  export COPYFILE_DISABLE=true
  tar -cf config.tar config
  cd -
  echo "Uploading files..."
  scp -p $TMPFLDR/config.tar root@$HOST:/tmp/
  echo "Running $MODULE deployment script..."
  ssh -t root@$HOST \
  "cd /tmp/; tar -xmf config.tar; rm -f config.tar; chmod +x /tmp/config/installer.sh; /tmp/config/installer.sh"
  ## Clean-up installer files
  rm -r $TMPFLDR
  POST_DEPLOY_MENU
}

PRGM_INIT(){
  ## Process Initial Arguments
  EXTRA_ARGS
  ## Check For Proxmox Configuration
  if [ -e $ROOTDIR/$MODULE/qemu.conf ] || \
     [ -e $ROOTDIR/$MODULE/lxc.conf ] || \
     [ -e $ROOTDIR/$MODULE/pc.conf ] || \
     [ "$MODULE" == "router" ]; then
    INTMODE="nonpi"
  else 
    INTMODE="pi"
  fi
  ## Start SSH Agent
  eval `ssh-agent -s`
  if [ "$INTMODE" == "nonpi" ]; then
    if [ "$MODULE" == "router" ]; then
      if [ "$CMD" != "" ]; then
        echo "Router login cannot have contain arguments!"
        EXIT_PRGM
      fi
    fi
    ## Server Configuration ##
    ssh-add $KEYS/$MODULE.rsa 2>/dev/null
    ## Set hostname
    HOST="$MODULE$DOMAIN"
    if [ "$MODULE" == "pve" ]; then
      NOHOSTCHK="yes"
    fi
    if [ "$CMD" == "sync" ]; then
      DEPLOY_SERVER
    fi
  else
    ## Pi Configuration ##
    ssh-add $KEYS/rpi.rsa 2>/dev/null
    if [ "$CMD" == "init" ]; then
      ## Initialize / Rename Pi
      HOST="$HOST$DOMAIN"
      echo "Initializing $HOST with the $MODULE module..."
      DEPLOY_PI
    else
      HOST="$MODULE$DOMAIN"
      ## Deploy to Pi
      if [ "$CMD" == "reset" ] || [ "$CMD" == "sync" ]; then
        echo "Starting $HOST deployment..."
        DEPLOY_PI
      else
        if [ "$CMD" != "" ]; then
          ## Send command to Pi
          ssh -t -o $SSH_ARGS root@$HOST "/opt/rpi/init $CMD"
          EXIT_PRGM
        fi
      fi
    fi
  fi
  ## Console Login
  SSH_LOGIN
  EXIT_PRGM
}

## MAIN ENTRY POINT ##
PRGM_INIT
