#!/bin/bash
###### Server VM Backup Script by Ben Provenzano III ######
###########################################################
###
### Container Backups
###
echo ""
echo "Backing-up Files LXC 101..."
vzdump 101 --mode snapshot --compress zstd --node pve --storage local \
 --maxfiles 1 --remove 1 --exclude-path /mnt --exclude-path /home/server/.regions
cp -v /etc/pve/lxc/101.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-101.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-101.conf
###
echo ""
echo "Backing-up Plex LXC 104..."
vzdump 104 --mode snapshot --compress zstd --node pve --storage local \
 --maxfiles 1 --remove 1 --exclude-path /mnt/transcoding
cp -v /etc/pve/lxc/104.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-104.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-104.conf
###
echo ""
echo "Backing-up Automate LXC 106..."
vzdump 106 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
cp -v /etc/pve/lxc/106.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-106.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/lxc-106.conf
###
### Virtual Machine Backups
###
echo ""
echo "Backing-up Router KVM 100..."
vzdump 100 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
cp -v /etc/pve/qemu-server/100.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-100.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-100.conf
###
echo ""
echo "Backing-up Development KVM 103..."
echo "Only configuration is backed up."
#vzdump 103 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
cp -v /etc/pve/qemu-server/103.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-103.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-103.conf
###
echo ""
echo "Backing-up Xana KVM 105..."
echo "Only configuration is backed up."
#vzdump 105 --mode snapshot --compress zstd --node pve --storage local --maxfiles 1 --remove 1
cp -v /etc/pve/qemu-server/105.conf /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-105.conf
chmod 777 /mnt/datastore/Ben/ProOS/pve/vmconfs/qemu-105.conf
###
### Copy to ZFS Pool
###
echo ""
echo "Copying VM's to Datastore..."
chmod -R 777 /var/lib/vz/dump/vzdump-*
rsync --progress -a --exclude="*qemu-103*" --exclude="*qemu-105*" \
 /var/lib/vz/dump/vzdump-* /mnt/datastore/Ben/ProOS/pve/vmbkps/
echo "Backup Complete."
echo ""
exit