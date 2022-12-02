#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
TRIGGERS_DIR="/mnt/ramdisk"
LOGFILE="$TRIGGERS_DIR/sysout.txt"

function EXIT_ROUTINE {
  rm -f /tmp/actiontrig.lock
  echo " "
  TRAILER=$(date)
  TRAILER+=" ("
  TRAILER+=$(hostname)
  TRAILER+=")"
  echo "$TRAILER"
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
  echo " "
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
  echo " "
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
  EXIT_ROUTINE
fi

### START VMs #########################################
#######################################################
if [ -e $TRIGGERS_DIR/startxana.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startxana.txt
  echo "starting xana VM..."
  qm start 105
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopxana.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopxana.txt
  echo "shutting down xana VM..."
  qm stop 105
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/restorexana.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/restorexana.txt
  echo "restoring xana VM..."
  qmrestore /var/lib/vz/dump/vzdump-qemu-105-latest.vma.zst \
    105 -force -storage scratch
  EXIT_ROUTINE
fi
#######################################################
if [ -e $TRIGGERS_DIR/startdev.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startdev.txt
  echo "starting development VM..."
  qm start 103
  chmod 777 $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopdev.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stopdev.txt
  echo "shutting down development VM..."
  qm stop 103
  EXIT_ROUTINE
fi
### Write Server Log ##################################   
if [ -e $TRIGGERS_DIR/syslog.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/syslog.txt
  /usr/bin/sys-check
  EXIT_ROUTINE
fi

  ###### Server VM Backup Script ######################
if [ -e $TRIGGERS_DIR/pve_vmsbkp.txt ]; then
  VM_CONFS="/mnt/datastore/Ben/ProOS"
  echo " "
  touch /tmp/actiontrig.lock  
  rm -f $TRIGGERS_DIR/pve_vmsbkp.txt
  ### Container Backups
  echo ""
  echo "Backing-up Files LXC 101..."
  vzdump 101 --mode snapshot --compress zstd --node pve --storage local \
   --maxfiles 1 --remove 1 --exclude-path /mnt --exclude-path /home/ben/sftp \
   --exclude-path /home/server/.html --exclude-path /home/server/.regions 
  cp -v /etc/pve/lxc/101.conf $VM_CONFS/files/lxc.conf
  chmod 777 $VM_CONFS/files/lxc.conf
  ###
  echo ""
  echo "Backing-up Plex LXC 104..."
  vzdump 104 --mode snapshot --compress zstd --node pve --storage local \
   --maxfiles 1 --remove 1 --exclude-path /mnt/transcoding
  cp -v /etc/pve/lxc/104.conf $VM_CONFS/plex/lxc.conf
  chmod 777 $VM_CONFS/plex/lxc.conf
  ###
  echo ""
  echo "Backing-up Automate LXC 106..."
  vzdump 106 --mode snapshot --compress zstd --node pve --storage local \
    --maxfiles 1 --remove 1 --exclude-path /var/www/html
  cp -v /etc/pve/lxc/106.conf $VM_CONFS/automate/lxc.conf
  chmod 777 $VM_CONFS/automate/lxc.conf
  ###
  ### Virtual Machine Backups
  ###
  echo ""
  echo "Backing-up Router KVM 100..."
  vzdump 100 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
  cp -v /etc/pve/qemu-server/100.conf $VM_CONFS/pve/vmbkps/vzdump-qemu-100.conf
  chmod 777 $VM_CONFS/pve/vmbkps/vzdump-qemu-100.conf
  ###
  echo ""
  echo "Backing-up Development KVM 103..."
  echo "Only configuration is backed up."
  #vzdump 103 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
  cp -v /etc/pve/qemu-server/103.conf $VM_CONFS/dev/qemu.conf
  chmod 777 $VM_CONFS/dev/qemu.conf
  ###
  echo ""
  echo "Backing-up Xana KVM 105..."
  echo "Only configuration is backed up."
  #vzdump 105 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
  cp -v /etc/pve/qemu-server/105.conf $VM_CONFS/xana/qemu.conf
  chmod 777 $VM_CONFS/xana/qemu.conf
  ###
  ### Copy to ZFS Pool
  ###
  echo ""
  echo "Copying VM's to Datastore..."
  chmod -R 777 /var/lib/vz/dump/vzdump-*
  rsync --progress -a --exclude="*qemu-103*" --exclude="*qemu-105*" \
   /var/lib/vz/dump/vzdump-* /mnt/datastore/Ben/ProOS/pve/vmbkps/
  echo "Backup Complete."
  EXIT_ROUTINE
fi


exit


