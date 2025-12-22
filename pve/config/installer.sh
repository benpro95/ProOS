#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Proxmox
### by Ben Provenzano III
###

TMPDIR="/tmp/config"

## PVE No-Subscription Enterprise Sources
cp -f $TMPDIR/pve-enterprise.sources /etc/apt/sources.list.d/
chmod 644 /etc/apt/sources.list.d/pve-enterprise.sources
chown root:root /etc/apt/sources.list.d/pve-enterprise.sources
rm -f /etc/apt/sources.list.d/pve-enterprise.list.dpkg-dist
rm -f /etc/apt/sources.list.d/pve-enterprise.list

## Update Sources
apt-get --yes update

## Support Packages
apt-get install -y --no-upgrade --ignore-missing rsync cron zip screen \
 libsasl2-modules intel-microcode postfix ethtool htop apt-transport-https \
 lm-sensors zfs-auto-snapshot smartmontools apcupsd chrony mailutils

## Ethernet Interface Pinning
cp -fvR $TMPDIR/50-pve-*.link /usr/local/lib/systemd/network/
chmod -R 644 /usr/local/lib/systemd/network/*.link
chown -R root:root /usr/local/lib/systemd/network/*.link

## Bonded Trunk 802.3ad Network Config
cp -f $TMPDIR/interfaces /etc/network/interfaces
chmod 644 /etc/network/interfaces
chown root:root /etc/network/interfaces

## SSH Configuration
mkdir -p /root/.ssh
cp -f $TMPDIR/authorized_keys /root/.ssh/
chmod 644 /root/.ssh/authorized_keys > /dev/null 2>&1
chown root:root /root/.ssh/authorized_keys > /dev/null 2>&1
cp -f $TMPDIR/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

## Startup Configuration
cp -f $TMPDIR/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
cp -f $TMPDIR/rc.local /etc/
chmod +x /etc/rc.local
chown root:root /etc/rc.local

## Actions Script Timer
cp -f $TMPDIR/actiontrig.timer /etc/systemd/system/
chmod 644 /etc/systemd/system/actiontrig.timer
chown root:root /etc/systemd/system/actiontrig.timer
cp -f $TMPDIR/actiontrig.service /etc/systemd/system/
chmod 644 /etc/systemd/system/actiontrig.service
chown root:root /etc/systemd/system/actiontrig.service
cp -f $TMPDIR/actiontrig.sh /usr/bin/
chmod +x /usr/bin/actiontrig.sh
chown root:root /usr/bin/actiontrig.sh
rm -f /usr/bin/actiontrig

## Hosts Configuration
cp -f $TMPDIR/hosts /etc/hosts
chmod 644 /etc/hosts
chown root:root /etc/hosts

## DNS Configuration
echo "DNS settings set manually in PVE web UI."
cat /etc/resolv.conf

## Enable Intel IO-MMU (MUST BE USING ZFS RPOOL AS ROOT !!)
cp -f $TMPDIR/grub /etc/default/
chmod +x /etc/default/grub
chown root:root /etc/default/grub
echo "Run update-initramfs -u; proxmox-boot-tool refresh to update GRUB"

## Enable PCI-e Passthrough / GRUB Settings
if [ ! -e "/etc/iommu.enabled" ]; then
  echo "Enabling PCI-e passthrough."
  ## Blacklist Onboard Ethernet Ports
  cp -f $TMPDIR/blacklist.conf /etc/modprobe.d/
  chmod 644 /etc/modprobe.d/blacklist.conf
  chown root:root /etc/modprobe.d/blacklist.conf
  update-initramfs -u
  proxmox-boot-tool refresh
  touch /etc/iommu.enabled
fi

## Non-ZFS Mountpoints
cp -f $TMPDIR/fstab /etc/
chmod 644 /etc/fstab
chown root:root /etc/fstab

## Move Swapfile to Scratch Drive
if [ ! -e "/dev/zvol/rpool/swap" ]; then
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
if [ ! -e "/mnt/extbkps" ]; then
  mkdir -p /mnt/extbkps
else
  echo "Backup mountpoints exist."
fi

## System Check Script
cp -f $TMPDIR/sys-check.sh /usr/bin/sys-check
chmod +x /usr/bin/sys-check
chown root:root /usr/bin/sys-check

## Kernel Cleanup Script
cp -f $TMPDIR/kernelclean.sh /usr/bin/kernelclean
chmod +x /usr/bin/kernelclean
chown root:root /usr/bin/kernelclean

## APC UPS Configuration
cp -f $TMPDIR/apcupsd.conf /etc/apcupsd/
chmod 644 /etc/apcupsd/apcupsd.conf
chown root:root /etc/apcupsd/apcupsd.conf
cp -f $TMPDIR/apcupsd.service /lib/systemd/system/
chmod 644 /lib/systemd/system/apcupsd.service
chown root:root /lib/systemd/system/apcupsd.service

## SMART Automatic Drive Checking
cp -f $TMPDIR/smartd.conf /etc/
chmod 644 /etc/smartd.conf
chown root:root /etc/smartd.conf

## Sensors Configuration
cp -f $TMPDIR/sensors3.conf /etc/
chmod 644 /etc/sensors3.conf
chown root:root /etc/sensors3.conf

## Less Logging
cp -f $TMPDIR/journald.conf /etc/systemd/
chmod 644 /etc/systemd/journald.conf
chown root:root /etc/systemd/journald.conf

## Mail Configuration
cp -f $TMPDIR/postfix.cf /etc/postfix/main.cf
chown root:root /etc/postfix/main.cf
chmod 644 /etc/postfix/main.cf
cp -f $TMPDIR/sasl_passwd /etc/postfix/
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
postconf compatibility_level=3.6
postfix reload

## Network Bug Fix 'https://forum.proxmox.com/threads/invalid-arp-responses-cause-network-problems.118128/'
cp -f $TMPDIR/99-arp_ignore.conf /etc/sysctl.d/
chmod 644 /etc/sysctl.d/99-arp_ignore.conf
chown root:root /etc/sysctl.d/99-arp_ignore.conf

## Drives List
cp -f $TMPDIR/drives.txt /usr/lib/
chmod 644 /usr/lib/drives.txt
chown root:root /usr/lib/drives.txt

## ZFS Snapshot Configuration
if [ ! -e "/etc/zfsautosnap.enabled" ]; then
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
cp -f $TMPDIR/zfs-snap-daily /etc/cron.daily/zfs-auto-snapshot
chmod +x /etc/cron.daily/zfs-auto-snapshot
chown root:root /etc/cron.daily/zfs-auto-snapshot
cp -f $TMPDIR/zfs-snap-hourly /etc/cron.hourly/zfs-auto-snapshot
chmod +x /etc/cron.hourly/zfs-auto-snapshot
chown root:root /etc/cron.hourly/zfs-auto-snapshot
cp -f $TMPDIR/zfs-snap-monthly /etc/cron.monthly/zfs-auto-snapshot
chmod +x /etc/cron.monthly/zfs-auto-snapshot
chown root:root /etc/cron.monthly/zfs-auto-snapshot
cp -f $TMPDIR/zfs-snap-weekly /etc/cron.weekly/zfs-auto-snapshot
chmod +x /etc/cron.weekly/zfs-auto-snapshot
chown root:root /etc/cron.weekly/zfs-auto-snapshot

## Disable Snapshots
#rm -f /etc/cron.daily/zfs-auto-snapshot
#rm -f /etc/cron.hourly/zfs-auto-snapshot
#rm -f /etc/cron.monthly/zfs-auto-snapshot
#rm -f /etc/cron.weekly/zfs-auto-snapshot

## ZFS Scrub, Trim, and System Report Timers
cp -f $TMPDIR/zfsutils-linux /etc/cron.d/
chmod +x /etc/cron.d/zfsutils-linux
chown root:root /etc/cron.d/zfsutils-linux
rm -f /etc/cron.d/zfsutils-linux.dpkg-dist
rm -f /etc/cron.d/rsnapshot

## Disable Replication Service
systemctl mask pvesr.timer

## Disable Sleep Mode
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

## Reload Daemons
systemctl daemon-reload

## Start Services on Boot
systemctl enable rc-local smartmontools apcupsd actiontrig.timer

## Restart Services
systemctl restart cron smartmontools apcupsd actiontrig.timer

## Clean-up
apt-get --yes autoremove
apt-get --yes clean
rm -r $TMPDIR
exit