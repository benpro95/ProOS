#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
TRIGGERS_DIR="/mnt/datastore/.regions/Automate"
WWWROOT="/mnt/datastore/.regions/WWW"
LOGFILE="/$WWWROOT/sysout.txt"

function EXIT_ROUTINE {
  rm -f /tmp/actiontrig.lock
  chmod 777 $LOGFILE
  exit
}

## Lock file
if [ -e /tmp/actiontrig.lock ]; then
  echo "process locked! exiting. (pve.home)" &>> $LOGFILE
  exit
fi

## Log file
if [ ! -e $LOGFILE ]; then
  touch $LOGFILE 
  chmod 777 $LOGFILE 
fi

### IMPORT ZFS ########################################   
if [ -e $TRIGGERS_DIR/attach_bkps.txt ]; then
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/attach_bkps.txt
  if [ ! -e $WWWROOT/pwd.txt ]; then
	echo "password file not found, exiting." &>> $LOGFILE
	EXIT_ROUTINE
  fi
  if [ ! -e $WWWROOT/drives.txt ]; then
	echo "drives file not found, exiting." &>> $LOGFILE
	EXIT_ROUTINE
  fi
  echo "" &>> $LOGFILE
  readarray -t ZFSPOOLS < $WWWROOT/drives.txt &>> $LOGFILE
  for _POOL in "${ZFSPOOLS[@]}"; do
    POOL=$(echo $_POOL | sed -e 's/\r//g')
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" == "tank" ] || \
         [ "$POOL" == "datastore" ] || \
         [ "$POOL" == "rpool" ] ; then
        echo "invalid pool specified." &>> $LOGFILE
      else
        echo "importing ZFS backup volume $POOL." &>> $LOGFILE
        zpool import $POOL &>> $LOGFILE
   	    zfs load-key -L file://$WWWROOT/pwd.txt $POOL/extbkp &>> $LOGFILE
  	    zfs mount $POOL/extbkp &>> $LOGFILE
  	    zpool status $POOL &>> $LOGFILE
      fi
      echo "" &>> $LOGFILE
    fi
  done
  zfs list &>> $LOGFILE
  echo "" &>> $LOGFILE
  shred -n 2 -z -u $WWWROOT/pwd.txt &>> $LOGFILE
  echo "imported ZFS backup volumes" &>> $LOGFILE
  EXIT_ROUTINE
fi

### EXPORT ZFS ########################################
if [ -e $TRIGGERS_DIR/detach_bkps.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/detach_bkps.txt
  if [ ! -e $WWWROOT/drives.txt ]; then
	echo "drives file not found, exiting." &>> $LOGFILE
	EXIT_ROUTINE
  fi  
  echo "" &>> $LOGFILE
  readarray -t ZFSPOOLS < /mnt/extbkps/drives.txt &>> $LOGFILE
  for _POOL in "${ZFSPOOLS[@]}"; do
    POOL=$(echo $_POOL | sed -e 's/\r//g')
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" == "tank" ] || \
         [ "$POOL" == "datastore" ] || \
         [ "$POOL" == "rpool" ] ; then
        echo "invalid pool specified." &>> $LOGFILE
      else
        echo "unmounting ZFS backup volume $POOL." &>> $LOGFILE
        zfs unmount /mnt/extbkps/$POOL &>> $LOGFILE
        zpool export $POOL &>> $LOGFILE
      fi
      echo "" &>> $LOGFILE  
    fi  
  done 
  zfs unload-key -a &>> $LOGFILE
  zpool status &>> $LOGFILE
  zfs list &>> $LOGFILE
  echo "" &>> $LOGFILE
  echo "unmounted ZFS backup volumes" &>> $LOGFILE
  date &>> $LOGFILE
  echo "" &>> $LOGFILE
  EXIT_ROUTINE
fi

### START VMs #########################################
#######################################################
if [ -e $TRIGGERS_DIR/startxana.txt ]; then
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startxana.txt
  echo "starting xana VM..." &>> $LOGFILE
  qm start 105 &>> $LOGFILE
  date &>> $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopxana.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopxana.txt
  echo "shutting down xana VM..." &>> $LOGFILE
  qm stop 105 &>> $LOGFILE
  date &>> $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/restorexana.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/restorexana.txt
  echo "restoring xana VM..." &>> $LOGFILE
  qmrestore /var/lib/vz/dump/vzdump-qemu-105-latest.vma.zst \
    105 -force -storage scratch &>> $LOGFILE
  date &>> $LOGFILE
  EXIT_ROUTINE
fi
#######################################################
if [ -e $TRIGGERS_DIR/startdev.txt ]; then
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startdev.txt
  echo "starting development VM..." &>> $LOGFILE
  qm start 103 &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopdev.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopdev.txt
  echo "shutting down development VM..." &>> $LOGFILE
  qm stop 103 &>> $LOGFILE
  date &>> $LOGFILE
  EXIT_ROUTINE
fi
### Write Server Log ##################################   
if [ -e $TRIGGERS_DIR/syslog.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/syslog.txt
  /usr/bin/sys-check &>> $LOGFILE
  EXIT_ROUTINE
fi

exit


