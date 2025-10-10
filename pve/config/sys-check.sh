#!/bin/bash
###### System Check Script by Ben Provenzano III ##########
###########################################################

echo ""
echo "** Package Versions **"
pveversion --verbose

echo ""
echo "** UPS Battery Backup **"
/sbin/apcaccess status

echo ""
echo "** Internal Network **"
ip -statistics address
echo ""
cat /proc/net/bonding/bond0

echo ""
echo "** Top Processes **"
top -b -n 1  | head -n 15

echo ""
echo "** ZFS Pools **"
/sbin/zpool status
/sbin/zpool list -v

echo ""
echo "** Drive Usage **"
df -h --type=zfs --type=ext4

echo ""
echo "** Drive Status**"
readarray -t DRIVES_TBL < /usr/lib/drives.txt
for DISK_DRIVE in "${DRIVES_TBL[@]}"; do
  echo "==== $DISK_DRIVE ===="
  /usr/sbin/smartctl --attributes --log=selftest --log=error --log=ssd $DISK_DRIVE
  echo ""
done

echo ""
echo "** Public IP **"
wget -qO- http://ipecho.net/plain | xargs echo

echo ""
echo "** VMs / LXCs Status **"
/usr/sbin/pct list
echo ""
/usr/sbin/qm list

echo ""
echo "** Temperatures **"
/usr/bin/sensors -f coretemp-isa-0000
/usr/bin/sensors -f acpitz-acpi-0
/usr/bin/sensors -f nct6776-isa-0a30

echo "** Memory Usage **"
/usr/bin/free -m

echo ""
echo "** CPU Type **"
lscpu | grep -i Model
lscpu | grep -i "CPU(s)"
lscpu | grep -i MHz

echo ""
uname -a
hostname

echo ""
uptime

echo "*** Server Status ***"
/bin/date -R

echo ""
exit 0