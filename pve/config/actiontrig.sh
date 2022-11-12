#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## External Backup Drives
ZFSPOOL1="usb256-01" # SanDisk Ultra 256GB (2020)
ZFSPOOL2="usb256-02" # SanDisk Ultra 256GB (2021)
ZFSPOOL3="usb256-03" # SanDisk Ultra 256GB (Early 2022)
ZFSPOOL4="usb256-04" # SanDisk Ultra 256GB (Mid 2022)
ZFSPOOL5="usb256-05" # SanDisk Ultra 256GB (Late 2022)
ZFSPOOL6="hdd4tb-01" # HGST 4GB Hard Drive (2016)
ZFSPOOL7="hdd4tb-02" # HGST 4GB Hard Drive (2017)
ZFSPOOL8="hdd4tb-03" # WD 4TB Blue Hard Drive (2018)
ZFSPOOL9="hdd4tb-04" # WD 4TB Red Hard Drive (2017)
ZFSPOOL10="hdd4tb-05" # WD 4TB Red Hard Drive (2022)

## VM Log File
VMLOGFILE="/mnt/extbkps/keytmp/vmlog.txt"

## Server Log Directory
SYSLOGDIR="/mnt/pve/scratch/files/downloads"

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
  for POOL in "${ZFSPOOLS[@]}"; do
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" = "tank" ] || \
         [ "$POOL" = "datastore" ] || \
         [ "$POOL" = "rpool" ] ; then
        echo "invalid pool specified."
      else
        echo "importing ZFS backup volume $POOL."
        zpool import "$POOL"
   	    zfs load-key -L file:///mnt/extbkps/keytmp/pass.txt "$POOL"/extbkp
  	    zfs mount "$POOL"/extbkp
  	    zpool status "$POOL"
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
  for POOL in "${ZFSPOOLS[@]}"; do
    if [ ! "$POOL" == "" ]; then
      if [ "$POOL" = "tank" ] || \
         [ "$POOL" = "datastore" ] || \
         [ "$POOL" = "rpool" ] ; then
        echo "invalid pool specified."
      else
        echo "unmounting ZFS backup volume $POOL."
        zfs unmount /mnt/extbkps/"$POOL"
        zpool export "$POOL"
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
if [ -e /mnt/extbkps/keytmp/createlog.txt ]; then
###### Runs when file exists ##########################
  rm -f /mnt/extbkps/keytmp/createlog.txt
  if [ -e $SYSLOGDIR ]; then
    if [ ! -e $SYSLOGDIR/Server.log ]; then
      touch $SYSLOGDIR/Server.log
    else
      truncate -s 0 $SYSLOGDIR/Server.log
    fi
    /usr/bin/sys-check > $SYSLOGDIR/Server.log 2>&1
    chmod 777 $SYSLOGDIR/Server.log
  fi  
fi

#######################################################
exit


