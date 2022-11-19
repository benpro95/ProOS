#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
VMLOGFILE="/mnt/extbkps/keytmp/vmlog.txt"

## Server Log Directory
SYSLOGDIR="/mnt/datastore/.regions/WWW"  

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
if [ -e /mnt/extbkps/keytmp/startxana.txt ]; then
###### Runs when file exists ##########################
  rm -f /mnt/extbkps/keytmp/startxana.txt
  if [ ! -e $VMLOGFILE ]; then
    touch $VMLOGFILE
  else
    truncate -s 0 $VMLOGFILE
  fi
  echo "starting xana VM..." &>> $VMLOGFILE
  qm start 105 &>> $VMLOGFILE
  date &>> $VMLOGFILE
fi
if [ -e /mnt/extbkps/keytmp/restorexana.txt ]; then
###### Runs when file exists ##########################
  rm -f /mnt/extbkps/keytmp/restorexana.txt
  if [ ! -e $VMLOGFILE ]; then
    touch $VMLOGFILE
  else
    truncate -s 0 $VMLOGFILE
  fi
  echo "restoring xana VM..." &>> $VMLOGFILE
  qmrestore /var/lib/vz/dump/vzdump-qemu-105-latest.vma.zst \
    105 -force -storage scratch &>> $VMLOGFILE
  date &>> $VMLOGFILE
fi
#######################################################
if [ -e /mnt/extbkps/keytmp/startdev.txt ]; then
###### Runs when file exists ##########################
  rm -f /mnt/extbkps/keytmp/startdev.txt
  if [ ! -e $VMLOGFILE ]; then
    touch $VMLOGFILE
  else
    truncate -s 0 $VMLOGFILE
  fi
  echo "starting development VM..." &>> $VMLOGFILE
  qm start 103 &>> $VMLOGFILE
  date &>> $VMLOGFILE
fi

### Write Server Log ##################################   
if [ -e /mnt/.regions/Automate/CreateLog.txt ]; then
###### Runs when file exists ##########################
  rm -f /mnt/.regions/Automate/CreateLog.txt
  if [ -e $SYSLOGDIR ]; then
    if [ ! -e $SYSLOGDIR/Server.txt ]; then
      touch $SYSLOGDIR/Server.txt
    else
      truncate -s 0 $SYSLOGDIR/Server.txt
    fi
    /usr/bin/sys-check > $SYSLOGDIR/Server.txt 2>&1
    chmod 777 $SYSLOGDIR/Server.txt
  fi  
fi

#######################################################
exit


