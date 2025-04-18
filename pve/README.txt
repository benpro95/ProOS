####################################################################
# Proxmox Virtual Environment (pve) 10.177.1.8:8006 or :22 for SSH #
####################################################################

PVE Web Interface 
(Run 'pve-firewall stop' in SSH to enable)
Web interface, console password, and SSH keyphrase is master key

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
List Memory Information:
dmidecode --type 17 | more

####################################################################
DNS configuration, set in Proxmox web interface

search home
nameserver 10.177.1.1
nameserver 192.168.1.1

####################################################################
UPS Battery Replacement

APC Smart-UPS SC620 4-Outlet 620VA 390W UPS
Back-UPS Models SC620, SU620NET (RBC4)
APC APCRBC4 Replacement Battery Cartridge #4
https://www.amazon.com/APC-Replacement-Battery-Cartridge-RBC4/dp/B00004Z78V

####################################################################

####################################################################
################## ZFS Filesystem Instructions #####################
####################################################################

(To reattach ZFS data drives after system restore)
zpool import -f tank

####################################################################
## Format a new drive, make ready to add to ZFS pool

(Remove drive label, only if was a ZFS drive)
zpool labelclear /dev/disk/by-id/DISK_NAME

(Erase entire drive, randomize UUID and create new GPT table)
wipefs -a /dev/disk/by-id/DISK_NAME
sgdisk -G /dev/disk/by-id/DISK_NAME
sgdisk -og /dev/disk/by-id/DISK_NAME

####################################################################
## Create a new mirror ZFS pool (RAID 1)

# Find drive names
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Use those names for *)

(Format both drives * using the above command)

zpool create -o ashift=12 POOL-NAME mirror /dev/disk/by-id/* /dev/disk/by-id/*
zpool status
zfs list
zfs create -o mountpoint=/mnt/MNT-POINT POOL-NAME/MNT-POINT

####################################################################
## Create new encrypted ZFS backup drive (on PVE)

(Format/create a new ZFS dataset)
(Find disk name)
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Use that name for BACKUP_DRIVE)

(Erase entire drive, randomize UUID and create new GPT table)
wipefs -a /dev/disk/by-id/BACKUP_DRIVE
sgdisk -G /dev/disk/by-id/BACKUP_DRIVE
sgdisk -og /dev/disk/by-id/BACKUP_DRIVE

(Create a new pool and dataset on the drive)
(BKP_VOL=BKP_POOL volume and pool name should be the same) 
zpool create -o ashift=12 -o feature@log_spacemap=disabled -O mountpoint=none BKP_POOL /dev/disk/by-id/BACKUP_DRIVE
zfs create -o canmount=noauto -o encryption=aes-256-gcm -o keyformat=passphrase -o mountpoint=/mnt/extbkps/BKP_VOL BKP_POOL/extbkp

(Attach backup ZFS)
zpool import BKP_POOL
zfs load-key BKP_POOL/extbkp
zfs mount BKP_POOL/extbkp

(Disable auto snapshots)
zfs set com.sun:auto-snapshot=false BKP_POOL
zfs set com.sun:auto-snapshot=false BKP_POOL/extbkp

(Create directories)
mkdir -p /mnt/extbkps/BKP_VOL/Ben
mkdir -p /mnt/extbkps/BKP_VOL/Media
mkdir -p /mnt/extbkps/BKP_VOL/.Regions

(Run these in files VM as root)
chown -R server:server /mnt/extbkps/BKP_VOL/Ben
chown -R server:server /mnt/extbkps/BKP_VOL/Media
chown -R server:server /mnt/extbkps/BKP_VOL/.Regions

(Detach backup ZFS)
zfs unmount /mnt/extbkps/BKP_VOL
zpool export BKP_POOL
zfs unload-key -a

####################################################################
## Replace Faulted Datastore Drive

(Unplug the bad drive when server off, don't run the 'detach' command)

(Find disk name)
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Use that name for NEW_DRIVE)

(Format the NEW_DRIVE using the above command)

(Find the NAME of the bad drive should be to the left of the word FAULTED)
(Replace the word 'BAD_DISK' in the next command with name found)
zpool status

(Add the new disk to the rpool ZFS mirror)
(replace the word tank with the name of ZFS pool)
zpool replace POOL-NAME 'BAD_DISK' /dev/disk/by-id/NEW_DRIVE

(Drive will resilver and be added to the mirror, check with the command below)
(This may take a few hours DO NOT TURN OFF OR REBOOT)
zpool status

####################################################################
## Replace Faulted Boot Drive on Proxmox 'rpool'

(Unplug the bad drive when server off, don't run the 'detach' command)

(Find disk name)
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Some of the commands below require you to specify the -part*)
(Use that name for NEW_DRIVE)

(Format the NEW_DRIVE using the above command)

(Create bootloader partition)
sgdisk -n 1:2048:6140 -c 1:"BIOS Boot Partition" -t 1:ef02 /dev/disk/by-id/$NEW_DRIVE$

(Create kernel partition)
sgdisk -n 2:6144:1054719 -c 2:"EFI Partition" -t 2:ef00 /dev/disk/by-id/$NEW_DRIVE$

(Install bootloader to new disk)
proxmox-boot-tool format /dev/disk/by-id/$NEW_DRIVE$-part2
proxmox-boot-tool init /dev/disk/by-id/$NEW_DRIVE$-part2
proxmox-boot-tool clean

(Check if both drives are listed here)
proxmox-boot-tool status

(Show to last sector of the new drive)
sgdisk -E /dev/disk/by-id/$NEW_DRIVE$

(!! Subtract 20184 from the last sector number)
Use that new number to replace the word LAST_SECTOR in the next command

(Create ZFS main partition on the new drive)
sgdisk -n 3:1054720:$LAST_SECTOR$ -c 3:"zfs" -t 3:bf01 /dev/disk/by-id/$NEW_DRIVE$

(Check the new drives partition layout is 1-BIOS Boot, 2-EFI and 3-zfs)
sgdisk -p /dev/disk/by-id/$NEW_DRIVE$

(Find the NAME of the bad drive should be to the left of the word FAULTED)
zpool status

(Add the new disk to the rpool ZFS mirror with a FAULTED disk)
(replace the word BAD_DISK with name found in the last command)
zpool replace rpool $BAD_DISK$ /dev/disk/by-id/$NEW_DRIVE$-part3

(Drive will resilver and be added to the mirror, check with the command below)
zpool status

## Update boot partitions
proxmox-boot-tool refresh

####################################################################
## Add another drive to an existing mirror pool
## (or) convert a single drive pool to a mirrored pool

(Find disk name)
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Use that name for NEW_DISK)

ata-WDC_WD40EFPX-68C6CN0_WD-WX72AC26FDJP

(Format the NEW_DISK using the above command)

(Replace the word GOOD_DISK in the next command with name found in 'zpool status')
** GOOD_DISK can be any drive in the mirror pool

zpool attach POOL-NAME GOOD_DISK /dev/disk/by-id/NEW_DISK

####################################################################
## Remove a drive from pool in mirror (DON'T USE TO REPLACE A BAD DRIVE)
(after running this drive should be unplugged from system)

(Find disk name)
cd /dev/disk/by-id/
ls -la
(Select the drive name without -part* on the end)
(Use that name for DISK_NAME)

zpool offline POOL_NAME /dev/disk/by-id/DISK_NAME
zpool detach POOL_NAME /dev/disk/by-id/DISK_NAME

####################################################################
## PVE Storage Configuration

dir: local
	path /var/lib/vz
	content vztmpl,backup,iso
	shared 0

zfspool: local-zfs
	pool rpool/data
	content images,rootdir
	sparse 1

dir: scratch
	path /mnt/pve/scratch
	content images,rootdir
	prune-backups keep-all=1
	shared 0

####################################################################