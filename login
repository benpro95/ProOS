#!/bin/bash
### Raspberry Pi / Server Communication Script - ProOS
### by Ben Provenzano III
###

HOSTCHK(){
echo "Attempting connection to Pi..."
if ping -c 1 $HOST &> /dev/null
then
  echo ""  > /dev/null 2>&1
else
  echo "Host $HOST is down, exiting..."
  ## Clean-up
  rm -r $TMPFLDR
  exit
fi
}

## Set to current directory
ROOTDIR=.

## Read Variables
MODULE=$1
ARG2=$2
HOST=$3

## Set Temporary Directory
TMPFLDR=$(mktemp -d /tmp/proostmp.XXXXXXXXX)

### ProServer Configuration
if [ "$MODULE" = "" ]; then
echo ""
echo "Pi / Server Configuration and Login Script"
echo "by Ben Provenzano III"
echo ""
echo "Login to ProOS Pi / Server"
echo "./login 'Hostname'"
echo ""
echo "Sync ProOS (quick run config script) Pi / Server"
echo "./login 'Hostname' sync"
echo ""
echo "Reset ProOS (full config script) Pi Only"
echo "./login 'Hostname' reset"
echo ""
echo "Clean/Restore ProOS (delete /opt/rpi and run full config script) Pi Only"
echo "./login 'Hostname' clean"
echo ""
echo "Initialize ProOS (configure a base Pi or reconfigure one) Pi Only"
echo "./login 'Module' init 'Hostname'"
echo ""
## Clean-up
rm -r $TMPFLDR
exit
else
echo ""  > /dev/null 2>&1
fi

### Exit if matches this hostnames
if [ "$MODULE" = "router" ] || [ "$MODULE" = "rpi" ] || [ "$MODULE" = "z97mx" ] || [ "$MODULE" = "sources" ]; then
echo "Hostname not allowed."
## Clean-up
rm -r $TMPFLDR
exit
else
echo ""  > /dev/null 2>&1
fi

### Remove temp files
if [ "$MODULE" = "rmtmp" ]; then
echo "Removing temporary files..."
rm -rfv /tmp/proostmp.*
exit
else
echo ""  > /dev/null 2>&1
fi

### ProServer Configuration
if [ "$MODULE" = "files" ] || [ "$MODULE" = "plex" ] || [ "$MODULE" = "pve" ] || [ "$MODULE" = "unifi" ] || [ "$MODULE" = "xana" ]; then
  echo "Attempting connection to server..."
  ## Copy SSH key
  cp -r $ROOTDIR/$MODULE/id_rsa $TMPFLDR/id_rsa
  chmod 600 $TMPFLDR/id_rsa
  ## SSH Key Password
  eval `ssh-agent -s`
  ssh-add $TMPFLDR/id_rsa
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
    ## Downloading module bundle
    scp -i $TMPFLDR/id_rsa -p $TMPFLDR/config.tar root@$MODULE:/tmp/
    ## Install files
    ssh -t -i $TMPFLDR/id_rsa root@$MODULE "cd /tmp/; tar -xvf config.tar; sleep 1; rm config.tar; chmod +x /tmp/config/installer; /tmp/config/installer"
    ## Clean-up on logout
    ssh-add -D
    eval $(ssh-agent -k)
    rm -r $TMPFLDR
    exit
  else
  ## Login to SSH
  ssh -t -i $TMPFLDR/id_rsa root@$MODULE
  ## Clean-up on logout
  ssh-add -D
  eval $(ssh-agent -k)
  rm -r $TMPFLDR
  exit
  fi
######### END AUTOSYNC ##########
else
echo ""  > /dev/null 2>&1
fi

## Copy SSH key to temp
cp -r $ROOTDIR/rpi/id_rsa $TMPFLDR/id_rsa
chmod 600 $TMPFLDR/id_rsa

## Set env variables
touch $TMPFLDR/hostname
echo "$MODULE" > $TMPFLDR/hostname

## Check for Read-write
if [ "$ARG2" = "rw" ]; then
HOST=`cat $TMPFLDR/hostname`
ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "/opt/rpi/init rw"
rm -r $TMPFLDR
exit
else
echo ""  > /dev/null 2>&1
fi

## Check for Read-only
if [ "$ARG2" = "ro" ]; then
HOST=`cat $TMPFLDR/hostname`
ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "/opt/rpi/init ro"
rm -r $TMPFLDR
exit
else
echo ""  > /dev/null 2>&1
fi

## Check for Clean
if [ "$ARG2" = "clean" ]; then
HOST=`cat $TMPFLDR/hostname`
touch $TMPFLDR/start_sync
else
echo ""  > /dev/null 2>&1
fi

## Check for Reset
if [ "$ARG2" = "reset" ]; then
HOST=`cat $TMPFLDR/hostname`
touch $TMPFLDR/start_sync
else
echo ""  > /dev/null 2>&1
fi

## Check for Init
## DON'T CHANGE HOST VARIABLE
if [ "$ARG2" = "init" ]; then
touch $TMPFLDR/start_sync
else
echo ""  > /dev/null 2>&1
fi

## Check for Sync
if [ "$ARG2" = "sync" ]; then
HOST=`cat $TMPFLDR/hostname`
touch $TMPFLDR/start_sync
else
echo ""  > /dev/null 2>&1
fi

### Sync ###############
if [ ! -e $TMPFLDR/start_sync ]; then
  echo ""  > /dev/null 2>&1
else
  ## Exit if host down
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
     ### Wait for Connection
     if ping -c 1 $HOST &> /dev/null
     then
       echo ""  > /dev/null 2>&1
     else
       echo "Host is down, waiting 10 more seconds..."
       sleep 10
     fi
     if ping -c 1 $HOST &> /dev/null
     then
      echo ""  > /dev/null 2>&1
     else
       echo "Host is down, waiting 10 more seconds..."
       sleep 10
     fi
     if ping -c 1 $HOST &> /dev/null
     then
       echo ""  > /dev/null 2>&1
     else
       echo "Host is down, waiting 10 more seconds..."
       sleep 10
     fi
     if ping -c 1 $HOST &> /dev/null
     then
       echo "Connection established."
     else
       echo "Host is down, waiting 10 more seconds..."
       sleep 10
     fi
     if ping -c 1 $HOST &> /dev/null
     then
       echo "Connection established."
     else
       echo "Host is down, exiting..."
       ## Clean-up
       rm -r $TMPFLDR
       exit
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

  ## Check for Reset
  if [ "$ARG2" = "init" ]; then
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -fv /etc/rpi-conf.done"  
  else
  echo ""  > /dev/null 2>&1
  fi  

  ## Check for Reset
  if [ "$ARG2" = "reset" ]; then
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -fv /etc/rpi-conf.done"  
  else
  echo ""  > /dev/null 2>&1
  fi

  ## Check for Restore
  if [ "$ARG2" = "clean" ]; then
  echo "Erasing software..."
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -fv /etc/rpi-conf.done"  
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "rm -rfv /opt/rpi"
  else
  echo ""  > /dev/null 2>&1
  fi

  echo "Syncing software..."
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress --checksum -rtv --exclude=id_rsa --exclude=BaseOS.zip --exclude=photos $ROOTDIR/rpi root@$HOST:/opt/
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress --checksum -rtv --exclude=id_rsa --exclude=photos --exclude=sources $ROOTDIR/$MODULE/* root@$HOST:/opt/rpi/

  ## Make module name hostname
  touch $TMPFLDR/modname
  echo "$MODULE" > $TMPFLDR/modname
  rsync -e "ssh -i $TMPFLDR/id_rsa" --progress -a $TMPFLDR/modname root@$HOST:/opt/rpi/config/hostname

  ## Installing on Pi
  echo "Installing software."
  ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST "chmod +x /opt/rpi/config/installer.sh; /opt/rpi/config/installer.sh"

  ## Reboot in Read-only mode
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

## Read Hostname
HOST=`cat $TMPFLDR/hostname`
## Exit if host down
HOSTCHK
## Login to SSH
ssh -t -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -i $TMPFLDR/id_rsa root@$HOST
## Clean-up
rm -r $TMPFLDR
exit
