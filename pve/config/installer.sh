#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Proxmox
### by Ben Provenzano III
###

## PVE No-Subscription Enterprise Sources
if [ ! -e /etc/apt/sources.list.d/pve-enterprise.list ]; then
  echo ""
  echo "Installing PVE enterprise source file..."
  cp -f /tmp/config/pve-enterprise.list /etc/apt/sources.list.d/
  chmod 644 /etc/apt/sources.list.d/pve-enterprise.list
  chown root:root /etc/apt/sources.list.d/pve-enterprise.list
  echo "PVE debian version set to current release."
  echo "Make sure this is correct before updating!"
  echo "Source File: /etc/apt/sources.list.d/pve-enterprise.list"
  cat /etc/apt/sources.list.d/pve-enterprise.list
  echo ""
  echo "" 
else
  echo "PVE enterprise sources already added."
fi

## Update Sources
apt-get --yes update

## Support Packages
apt-get install -y --no-upgrade --ignore-missing rsync cron zip screen \
 libsasl2-modules postfix ethtool htop apt-transport-https lm-sensors \
 zfs-auto-snapshot smartmontools hddtemp apcupsd chrony mailutils ipmitool

## Bonded Trunk 802.3ad Network Config
cp -f /tmp/config/interfaces /etc/network/interfaces
chmod 644 /etc/network/interfaces
chown root:root /etc/network/interfaces

## SSH Configuration
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/
chmod 644 /root/.ssh/authorized_keys > /dev/null 2>&1
chown root:root /root/.ssh/authorized_keys > /dev/null 2>&1
cp -f /tmp/config/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

## Startup Configuration
cp -f /tmp/config/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
cp -f /tmp/config/rc.local /etc/
chmod 755 /etc/rc.local
chown root:root /etc/rc.local

## Actions Script Timer
cp -f /tmp/config/actiontrig.timer /etc/systemd/system/
chmod 644 /etc/systemd/system/actiontrig.timer
chown root:root /etc/systemd/system/actiontrig.timer
cp -f /tmp/config/actiontrig.service /etc/systemd/system/
chmod 644 /etc/systemd/system/actiontrig.service
chown root:root /etc/systemd/system/actiontrig.service
cp -f /tmp/config/actiontrig.sh /usr/bin/
chmod 755 /usr/bin/actiontrig.sh
chown root:root /usr/bin/actiontrig.sh
rm -f /usr/bin/actiontrig

## Hosts Configuration
cp -f /tmp/config/hosts /etc/hosts
chmod 644 /etc/hosts
chown root:root /etc/hosts

## DNS Configuration
echo "DNS settings set manually in PVE web UI."
cat /etc/resolv.conf

## Enable Intel IO-MMU (MUST BE USING ZFS RPOOL AS ROOT !!)
cp -f /tmp/config/grub /etc/default/
chmod +x /etc/default/grub
chown root:root /etc/default/grub
echo "Run update-initramfs -u; proxmox-boot-tool refresh to update GRUB"

## Enable PCI-e Passthrough / GRUB Settings
if [ ! -e /etc/iommu.enabled ]; then
  echo "Enabling PCI-e passthrough."
  ## Blacklist Onboard Ethernet Ports
  cp -f /tmp/config/blacklist.conf /etc/modprobe.d/
  chmod 644 /etc/modprobe.d/blacklist.conf
  chown root:root /etc/modprobe.d/blacklist.conf
  update-initramfs -u
  proxmox-boot-tool refresh
  touch /etc/iommu.enabled
fi

## Non-ZFS Mountpoints
cp -f /tmp/config/fstab /etc/
chmod 644 /etc/fstab
chown root:root /etc/fstab

## Move Swapfile to Scratch Drive
if [ ! -e /dev/zvol/rpool/swap ]; then
  echo "Swap file already moved."
else
  echo "Moving Swapfile to Scratch Drive..."
  swapoff /dev/zvol/rpool/swap
  zfs destroy rpool/swap
  fallocate -l 10G /mnt/pve/scratch/swapfile
  chmod 0600 /mnt/pve/scratch/swapfile
  chown root:root /mnt/pve/scratch/swapfile
  mkswap /mnt/pve/scratch/swapfile
  swapon /mnt/pve/scratch/swapfile
fi

## Backup Mountpoints
if [ ! -e /mnt/extbkps ]; then
  mkdir -p /mnt/extbkps
else
  echo "Backup mountpoints exist."
fi

## System Check Script
cp -f /tmp/config/sys-check.sh /usr/bin/sys-check
chmod 755 /usr/bin/sys-check
chown root:root /usr/bin/sys-check

## APC UPS Configuration
cp -f /tmp/config/apcupsd.conf /etc/apcupsd/
chmod 644 /etc/apcupsd/apcupsd.conf
chown root:root /etc/apcupsd/apcupsd.conf
cp -f /tmp/config/apcupsd.service /lib/systemd/system/
chmod 644 /lib/systemd/system/apcupsd.service
chown root:root /lib/systemd/system/apcupsd.service

## SMART Automatic Drive Checking
cp -f /tmp/config/smartd.conf /etc/
chmod 644 /etc/smartd.conf
chown root:root /etc/smartd.conf

## Sensors Configuration
touch /etc/hddtemp.db
cp -f /tmp/config/sensors3.conf /etc/
chmod 644 /etc/sensors3.conf
chown root:root /etc/sensors3.conf

## Less Logging
cp -f /tmp/config/journald.conf /etc/systemd/
chmod 644 /etc/systemd/journald.conf
chown root:root /etc/systemd/journald.conf

## Mail Configuration
cp -f /tmp/config/main.cf /etc/postfix/
chown root:root /etc/postfix/main.cf
chmod 644 /etc/postfix/main.cf
cp -f /tmp/config/sasl_passwd /etc/postfix/
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
postfix reload

## Network Bug Fix 'https://forum.proxmox.com/threads/invalid-arp-responses-cause-network-problems.118128/'
cp -f /tmp/config/99-arp_ignore.conf /etc/sysctl.d/
chmod 644 /etc/sysctl.d/99-arp_ignore.conf
chown root:root /etc/sysctl.d/99-arp_ignore.conf

## Drives List
cp -f /tmp/config/drives.txt /usr/lib/
chmod 644 /usr/lib/drives.txt
chown root:root /usr/lib/drives.txt

## ZFS Snapshot Configuration
if [ ! -e /etc/zfsautosnap.enabled ]; then
  zfs set com.sun:auto-snapshot=false rpool
  zfs set com.sun:auto-snapshot=false rpool/ROOT
  zfs set com.sun:auto-snapshot=false rpool/data
  zfs set com.sun:auto-snapshot=false tank
  zfs set com.sun:auto-snapshot=true tank/datastore
  ## Disable 15-min Snapshots ###
  zfs set com.sun:auto-snapshot:frequent=false tank/datastore
  rm -f /etc/cron.d/zfs-auto-snapshot
  ###############################
  touch /etc/zfsautosnap.enabled
  echo "Enabling ZFS auto-snapshot..."
else
  echo "ZFS snapshot already enabled."
fi

## Automatic Snapshot Configurations
cp -f /tmp/config/zfs-snap-daily /etc/cron.daily/zfs-auto-snapshot
chmod 755 /etc/cron.daily/zfs-auto-snapshot
chown root:root /etc/cron.daily/zfs-auto-snapshot
cp -f /tmp/config/zfs-snap-hourly /etc/cron.hourly/zfs-auto-snapshot
chmod 755 /etc/cron.hourly/zfs-auto-snapshot
chown root:root /etc/cron.hourly/zfs-auto-snapshot
cp -f /tmp/config/zfs-snap-monthly /etc/cron.monthly/zfs-auto-snapshot
chmod 755 /etc/cron.monthly/zfs-auto-snapshot
chown root:root /etc/cron.monthly/zfs-auto-snapshot
cp -f /tmp/config/zfs-snap-weekly /etc/cron.weekly/zfs-auto-snapshot
chmod 755 /etc/cron.weekly/zfs-auto-snapshot
chown root:root /etc/cron.weekly/zfs-auto-snapshot

## Disable Snapshots
#rm -f /etc/cron.daily/zfs-auto-snapshot
#rm -f /etc/cron.hourly/zfs-auto-snapshot
#rm -f /etc/cron.monthly/zfs-auto-snapshot
#rm -f /etc/cron.weekly/zfs-auto-snapshot

## ZFS Scrub, Trim, and System Report Timers
cp -f /tmp/config/zfsutils-linux /etc/cron.d/
chmod 755 /etc/cron.d/zfsutils-linux
chown root:root /etc/cron.d/zfsutils-linux
rm -f /etc/cron.d/zfsutils-linux.dpkg-dist
rm -f /etc/cron.d/rsnapshot

## Disable PVE Replication Service
systemctl stop pvesr.timer
systemctl disable pvesr.timer
systemctl mask pvesr.timer
rm -f /lib/systemd/system/pvesr.timer

## Disable Sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

## Reload Daemons
systemctl daemon-reload

## Enable Services
systemctl enable rc-local
systemctl enable actiontrig.timer
systemctl enable smartmontools

## Restart Services
systemctl restart apcupsd
systemctl restart actiontrig.timer
systemctl restart smartmontools
systemctl restart cron

## Clean-up
apt-get --yes autoremove
apt-get --yes clean
rm -r /tmp/config
exit