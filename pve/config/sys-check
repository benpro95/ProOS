#!/bin/bash
###### System Check Script by Ben Provenzano III ##########
###########################################################
echo "*** Server Status ***"
/bin/date -R

echo ""
uptime

echo ""
uname -a
hostname

echo ""
echo "** Public IP **"
wget -qO- http://ipecho.net/plain | xargs echo

echo ""
echo "** Temperatures **"
/usr/bin/sensors -f coretemp-isa-0000
/usr/bin/sensors -f acpitz-acpi-0
/usr/bin/sensors -f nct6776-isa-0a30

echo "** Memory Usage **"
/usr/bin/free -m

echo ""
echo "** Internal Drives **"
DISK_DRIVE="/dev/disk/by-id/ata-INTEL_SSDSC2KB480G8_PHYF00540242480BGN"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*"
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE
##
DISK_DRIVE="/dev/disk/by-id/ata-Samsung_SSD_850_EVO_M.2_250GB_S33CNX0J314914T"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*"
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE
##
DISK_DRIVE="/dev/disk/by-id/ata-WDC_WD40EFZX-68AWUN0_WD-WXA2D81NA45F"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*" 
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE
##
DISK_DRIVE="/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K6XY9HTC"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*"
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE
##
DISK_DRIVE="/dev/disk/by-id/ata-WDC_WD40EFZX-68AWUN0_WD-WX32D80CF0LE"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*"
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE
##
DISK_DRIVE="/dev/disk/by-id/ata-WDC_WD20EZAZ-00GGJB0_WD-WXK2A30CYK73"
/usr/sbin/hddtemp --unit=F $DISK_DRIVE | grep -oP "($DISK_DRIVE: )\K.*"
/usr/sbin/smartctl --all --quietmode=errorsonly $DISK_DRIVE

echo ""
echo "** Drive Usage **"
df -h --type=zfs --type=ext4

echo ""
echo "** ZFS Drive Pools **"
/sbin/zpool status
/sbin/zpool list -v

echo ""
echo "** Top Processes **"
top -b -n 1  | head -n 15

echo ""
echo "** CPU Type **"
lscpu | grep -i Model
lscpu | grep -i "CPU(s)"
lscpu | grep -i MHz

echo ""
echo "** VM / LXC Status **"
/usr/sbin/pct list
echo ""
/usr/sbin/qm list


echo ""
echo "** UPS Battery Backup **"
/sbin/apcaccess status

echo ""
echo "** Network Statistics **"
ip -statistics address
echo ""
cat /proc/net/bonding/bond0

echo ""
echo "** Package Versions **"
pveversion --verbose

echo ""
echo "** PVE Storage Configuration **"
cat /etc/pve/storage.cfg

echo ""
exit 0
