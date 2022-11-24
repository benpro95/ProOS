#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
TRIGGERS_DIR="/mnt/ramdisk"
LOGFILE="$TRIGGERS_DIR/sysout.txt"

function EXIT_ROUTINE {
  rm -f /tmp/actiontrig.lock
  chmod 777 $LOGFILE
  exit
}

## Lock file
if [ -e /tmp/actiontrig.lock ]; then
  echo "process locked! exiting. (pve.home)"
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
  if [ ! -e $TRIGGERS_DIR/pwd.txt ]; then
	echo "password file not found, exiting."
	EXIT_ROUTINE
  fi
  if [ ! -e $TRIGGERS_DIR/drives.txt ]; then
	echo "drives file not found, exiting."
	EXIT_ROUTINE
  fi
  echo ""
  readarray -t ZFSPOOLS < $TRIGGERS_DIR/drives.txt
  for _POOL in "${ZFSPOOLS[@]}"; do
    POOL=$(echo $_POOL | sed -e 's/\r//g')
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" == "tank" ] || \
         [ "$POOL" == "datastore" ] || \
         [ "$POOL" == "rpool" ] ; then
        echo "invalid pool specified."
      else
        echo "importing ZFS backup volume $POOL."
        zpool import $POOL
   	    zfs load-key -L file://$TRIGGERS_DIR/pwd.txt $POOL/extbkp
  	    zfs mount $POOL/extbkp
  	    zpool status $POOL
      fi
      echo ""
    fi
  done
  zfs list
  echo ""
  shred -n 2 -z -u $TRIGGERS_DIR/pwd.txt
  echo "imported ZFS backup volumes"
  EXIT_ROUTINE
fi

### EXPORT ZFS ########################################
if [ -e $TRIGGERS_DIR/detach_bkps.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/detach_bkps.txt
  if [ ! -e $TRIGGERS_DIR/drives.txt ]; then
	echo "drives file not found, exiting."
	EXIT_ROUTINE
  fi  
  echo ""
  readarray -t ZFSPOOLS < $TRIGGERS_DIR/drives.txt
  for _POOL in "${ZFSPOOLS[@]}"; do
    POOL=$(echo $_POOL | sed -e 's/\r//g')
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" == "tank" ] || \
         [ "$POOL" == "datastore" ] || \
         [ "$POOL" == "rpool" ] ; then
        echo "invalid pool specified."
      else
        echo "unmounting ZFS backup volume $POOL."
        zfs unmount /mnt/extbkps/$POOL
        zpool export $POOL
      fi
      echo ""  
    fi  
  done 
  zfs unload-key -a
  zpool status
  zfs list
  echo ""
  echo "unmounted ZFS backup volumes"
  date
  echo ""
  EXIT_ROUTINE
fi

### START VMs #########################################
#######################################################
if [ -e $TRIGGERS_DIR/startxana.txt ]; then
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startxana.txt
  echo "starting xana VM..."
  qm start 105
  date
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopxana.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopxana.txt
  echo "shutting down xana VM..."
  qm stop 105
  date
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/restorexana.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/restorexana.txt
  echo "restoring xana VM..."
  qmrestore /var/lib/vz/dump/vzdump-qemu-105-latest.vma.zst \
    105 -force -storage scratch
  date
  EXIT_ROUTINE
fi
#######################################################
if [ -e $TRIGGERS_DIR/startdev.txt ]; then
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startdev.txt
  echo "starting development VM..."
  qm start 103
  date
  chmod 777 $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopdev.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopdev.txt
  echo "shutting down development VM..."
  qm stop 103
  date
  EXIT_ROUTINE
fi
### Write Server Log ##################################   
if [ -e $TRIGGERS_DIR/syslog.txt ]; then
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/syslog.txt
  /usr/bin/sys-check
  EXIT_ROUTINE
fi

exit


