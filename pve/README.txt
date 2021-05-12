Proxmox Virtual Environment (pve) 10.177.1.8:8006 or :22 for SSH

####################################################################
Create new encrypted ZFS backup drive (on PVE)
BKP-VOL=BKP-POOL

(Format/create a new ZFS dataset)
wipefs -a /dev/disk/by-id/BACKUP-DRIVE
zpool create -o ashift=12 -o feature@log_spacemap=disabled -O mountpoint=none BKP-POOL /dev/disk/by-id/BACKUP-DRIVE
zfs create -o canmount=noauto -o encryption=aes-256-gcm -o keyformat=passphrase -o mountpoint=/mnt/extbkps/BKP-VOL BKP-POOL/extbkp

(Import backup ZFS)
zpool import BKP-POOL
zfs load-key BKP-POOL/extbkp
zfs mount BKP-POOL/extbkp

(Run these in files VM as root)
mkdir -p /mnt/extbkps/BKP-VOL/Ben
mkdir -p /mnt/extbkps/BKP-VOL/Media
mkdir -p /mnt/extbkps/BKP-VOL/.Archive
chown -R server:server /mnt/extbkps/BKP-VOL/*

(Export backup ZFS)
zfs unmount /mnt/extbkps/BKP-VOL
zpool export BKP-POOL
zfs unload-key -a

####################################################################
Super Micro IPMI Network Login

Username: admin
Password: password

####################################################################
Proxmox Web UI Firewall Rule (disables web interface by default)

Use the commands 'pve-firewall stop' to allow login to Web UI
Run 'pve-firewall start' to re-enable the firewall after use

Add this rule from the PVE web interface

Web interface firewall rule options: 
Direction-> In 
Action-> DROP 
Enable-> Checked 
Protocol-> tcp 
Dest. port-> 8006

####################################################################
DNS configuration, set in Proxmox web interface

search home
nameserver 10.177.1.1
nameserver 192.168.1.1

####################################################################

To reattach ZFS drives after system restore,
run these commands with all drives attached.

zpool import tank
zpool upgrade tank

####################################################################
## Replace Faulted Drive 

cd /dev/disk/by-id/
ls -la
(Find new disk drive should be like 'ata-INTEL_SSDSC2KB480G8_PHYF00540242480BGN')
(Only select the whole drive do not select ones with -part* on the end)
(Replace 'NEW-DRIVE' with the name found with the ls command above do not use quotes)

(Erase entire drive and create new GPT table)
sgdisk -og /dev/disk/by-id/'NEW-DRIVE'

(Find the NAME of the old/bad drive should be to the left of the word FAULTED)
(Replace the word 'OLD-DISK' in the next command with name found)
zpool status

(Add the new disk to the rpool ZFS mirror)
(replace the word tank with the name of ZFS pool)
zpool replace tank 'OLD-DISK' /dev/disk/by-id/'NEW-DRIVE'

(Drive will resilver and be added to the mirror, check with the command below)
(This may take a few hours DO NOT TURN OFF OR REBOOT)
zpool status

####################################################################

To merge a new drive to an existing mirrored pool
make sure the tank pool is imported and mounted, and
the new drive has a blank GPT partition table.
Replace tank with the existing mirrored pool name.
Replace NEW_DISK with path of the new blank disk.
Use 'blkid' command to find UUID of disk.
Can also add more drives to a 2 or more drive mirror pool.
Do not use quotes in the actual commands.

zpool attach tank 'Any good drive in pool' /dev/disk/by-id/ata-NEW_DISK

####################################################################
## Remove drive and erase (new GPT partition table)

zpool offline POOL_NAME /dev/disk/by-id/DISK_NAME
zpool detach POOL_NAME /dev/disk/by-id/DISK_NAME
zpool labelclear /dev/disk/by-id/DISK_NAME
sgdisk -og /dev/disk/by-id/DISK_NAME

####################################################################
## Create a new mirror ZFS pool

Find drive names in /dev/disk/by-id/*              
zpool create -o ashift=12 tank mirror /dev/disk/by-id/* /dev/disk/by-id/*
zpool status
zfs list
zfs create -o mountpoint=/mnt/datastore tank/datastore

####################################################################

Run the command 'pvereport' for a detailed
system configuration and status

####################################################################
## Replace Boot Drive on Proxmox ZFS 'rpool'

cd /dev/disk/by-id/
ls -la
(Find new disk drive should be like 'ata-INTEL_SSDSC2KB480G8_PHYF00540242480BGN')
(Only select the whole drive do not select ones with -part* on the end)
(Replace 'NEW-DRIVE' with the name found with the ls command above do not use quotes)

(Erase entire drive and create new GPT table)
sgdisk -og /dev/disk/by-id/'NEW-DRIVE'

(Create boot partiton)
sgdisk -n 1:2048:6140 -c 1:"BIOS Boot Partition" -t 1:ef02 /dev/disk/by-id/'NEW-DRIVE'

(Install GRUB bootloader to new drive)
grub-install /dev/disk/by-id/'NEW-DRIVE'
update-grub

(Show to last sector of the new drive)
sgdisk -E /dev/disk/by-id/'NEW-DRIVE'

(Subtract 20184 from the last sector number)
Use that number to replace the word LAST-SECTOR in the next command

(Create ZFS main partiton on the new drive)
sgdisk -n 2:6144:LAST-SECTOR -c 2:"zfs" -t 2:bf01 /dev/disk/by-id/'NEW-DRIVE'

(Check the new drives partition layout is 1-BIOS Boot and 2-ZFS)
sgdisk -p /dev/disk/by-id/'NEW-DRIVE'

(Find the NAME of the old/bad drive should be to the left of the word FAULTED)
zpool status

(Add the new disk to the rpool ZFS mirror, replace the word 'OLD-DISK' with name found in the last command)
zpool replace rpool 'OLD-DISK' /dev/disk/by-id/'NEW-DRIVE'-part2

(Drive will resilver and be added to the mirror, check with the command below)
zpool status

####################################################################
## UPS Battery Replacement

APC Smart-UPS SC620 4-Outlet 620VA 390W UPS
Back-UPS Models SC620, SU620NET (RBC4)
APC APCRBC4 Replacement Battery Cartridge #4
https://www.amazon.com/APC-Replacement-Battery-Cartridge-RBC4/dp/B00004Z78V

####################################################################

