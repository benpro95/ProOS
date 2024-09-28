#!/bin/bash
## Runs every 40 seconds on Proxmox
################################

## VM Log File
TRIGGERS_DIR="/mnt/ramdisk"
LOGFILE="$TRIGGERS_DIR/sysout.txt"

function EXIT_ROUTINE {
  echo " "
  TRAILER=$(date)
  TRAILER+=" ("
  TRAILER+=$(hostname)
  TRAILER+=")"
  echo "$TRAILER"
  chmod 777 $LOGFILE
  rm -f /tmp/actiontrig.lock
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
## Toggle Proxmox Web Interface
if [ -e $TRIGGERS_DIR/pve_webui_toggle.txt ]; then
  echo " "
  rm -f $TRIGGERS_DIR/pve_webui_toggle.txt
  SYSDSTAT="$(systemctl is-active pveproxy.service)"
  if [ "${SYSDSTAT}" == "active" ]; then
    echo "Proxmox web interface running, stopping service..."
    systemctl stop pveproxy.service 
  else 
    echo "Proxmox web interface not running, starting service..." 
    systemctl start pveproxy.service
  fi
  EXIT_ROUTINE  
fi
## List ZFS Snapshots
if [ -e $TRIGGERS_DIR/pve_listsnaps.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/pve_listsnaps.txt
  echo "Snapshots on ZFS pool (tank/datastore):"
  zfs list -t snapshot tank/datastore | grep -o '^\S*'
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
#######################################################
if [ -e $TRIGGERS_DIR/startlegacy.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startlegacy.txt
  echo "starting legacy file share LXC..."
  pct start 108
  chmod 777 $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stoplegacy.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock	
  rm -f $TRIGGERS_DIR/stoplegacy.txt
  echo "shutting down legacy file share LXC..."
  pct stop 108
  EXIT_ROUTINE
fi
#######################################################
if [ -e $TRIGGERS_DIR/startunifi.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock
  rm -f $TRIGGERS_DIR/startunifi.txt
  echo "starting unifi AP LXC..."
  pct start 107
  chmod 777 $LOGFILE
  EXIT_ROUTINE
fi
if [ -e $TRIGGERS_DIR/stopunifi.txt ]; then
  echo " "
  touch /tmp/actiontrig.lock  
  rm -f $TRIGGERS_DIR/stopunifi.txt
  echo "shutting down unifi AP LXC..."
  pct stop 107
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
  VM_CONFS="/mnt/datastore/data/ProOS"
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
  echo "Backing-up Server LXC 102..."
  vzdump 102 --mode snapshot --compress zstd --node pve --storage local \
   --maxfiles 1 --remove 1 --exclude-path /mnt --exclude-path /root/ProOS
  cp -v /etc/pve/lxc/102.conf $VM_CONFS/server/lxc.conf
  chmod 777 $VM_CONFS/server/lxc.conf
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
  echo ""
  echo "Backing-up Legacy LXC 108..."
  vzdump 108 --mode snapshot --compress zstd --node pve --storage local \
    --maxfiles 1 --remove 1 --exclude-path /mnt
  cp -v /etc/pve/lxc/108.conf $VM_CONFS/legacy/lxc.conf
  chmod 777 $VM_CONFS/legacy/lxc.conf  
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
  echo ""
  echo "Backing-up Unifi LXC 107..."
  vzdump 107 --mode snapshot --compress zstd --node pve --storage local \
    --maxfiles 1 --remove 1
  cp -v /etc/pve/lxc/107.conf $VM_CONFS/unifi/lxc.conf
  chmod 777 $VM_CONFS/unifi/lxc.conf
  ### Copy to ZFS Pool
  ###
  echo ""
  echo "Copying VM's to Datastore..."
  chmod -R 777 /var/lib/vz/dump/vzdump-*
  rsync --progress -a --exclude="*qemu-103*" --exclude="*qemu-105*" \
   /var/lib/vz/dump/vzdump-* /mnt/datastore/data/ProOS/pve/vmbkps/
  echo "Backup Complete."
  EXIT_ROUTINE
fi

exit


