#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
TRIGGERS_DIR="/mnt/datastore/.regions/Automate"
LOGFILE="/mnt/datastore/.regions/WWW/SystemOutput.txt"

function TRIM_LOG {
  if [ -e $LOGFILE ]; then
    rm -f $LOGFILE
  fi
  touch $LOGFILE  
}

if [ -e /tmp/actiontrig.lock ]; then
  echo "process locked! exiting."
  exit
fi

### IMPORT ZFS ########################################   
if [ -e /mnt/extbkps/keytmp/pass.txt ]; then
###### Runs when file exists ##########################
  touch /tmp/actiontrig.lock
  if [ ! -e /mnt/extbkps/keytmp/status.txt ]; then
    touch /mnt/extbkps/keytmp/status.txt
  else
    truncate -s 0 /mnt/extbkps/keytmp/status.txt
  fi
  echo ""
  readarray -t ZFSPOOLS < /mnt/extbkps/drives.txt
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
   	    zfs load-key -L file:///mnt/extbkps/keytmp/pass.txt $POOL/extbkp
  	    zfs mount $POOL/extbkp
  	    zpool status $POOL
      fi
      echo ""
    fi
  done
  zfs list
  echo ""
  shred -n 2 -z -u /mnt/extbkps/keytmp/pass.txt
  echo "imported ZFS backup volumes"
  rm -f /tmp/actiontrig.lock
fi

### EXPORT ZFS ########################################
if [ -e /mnt/extbkps/keytmp/unmount.txt ]; then
###### Runs when file exists ##########################
  touch /tmp/actiontrig.lock
  echo ""
  readarray -t ZFSPOOLS < /mnt/extbkps/drives.txt
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
  rm -f /mnt/extbkps/keytmp/unmount.txt
  echo "unmounted ZFS backup volumes"
  date
  echo ""
  rm -f /tmp/actiontrig.lock
fi

### START VMs #########################################
#######################################################
if [ -e $TRIGGERS_DIR/startxana.txt ]; then
  rm -f $TRIGGERS_DIR/startxana.txt
  TRIM_LOG
  echo "starting xana VM..." &>> $LOGFILE
  qm start 105 &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
fi
if [ -e $TRIGGERS_DIR/stopxana.txt ]; then
  rm -f $TRIGGERS_DIR/stopxana.txt
  TRIM_LOG
  echo "shutting down xana VM..." &>> $LOGFILE
  qm stop 105 &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
fi
if [ -e $TRIGGERS_DIR/restorexana.txt ]; then
  rm -f $TRIGGERS_DIR/restorexana.txt
  TRIM_LOG
  echo "restoring xana VM..." &>> $LOGFILE
  qmrestore /var/lib/vz/dump/vzdump-qemu-105-latest.vma.zst \
    105 -force -storage scratch &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
fi
#######################################################
if [ -e $TRIGGERS_DIR/startdev.txt ]; then
  rm -f $TRIGGERS_DIR/startdev.txt
  TRIM_LOG
  echo "starting development VM..." &>> $LOGFILE
  qm start 103 &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
fi
if [ -e $TRIGGERS_DIR/stopdev.txt ]; then
  rm -f $TRIGGERS_DIR/stopdev.txt
  TRIM_LOG
  echo "shutting down development VM..." &>> $LOGFILE
  qm stop 103 &>> $LOGFILE
  date &>> $LOGFILE
  chmod 777 $LOGFILE
fi
### Write Server Log ##################################   
if [ -e $TRIGGERS_DIR/syslog.txt ]; then
  rm -f $TRIGGERS_DIR/syslog.txt
  TRIM_LOG
  /usr/bin/sys-check &>> $LOGFILE 2>&1
  chmod 777 $LOGFILE 
fi

#######################################################
exit


