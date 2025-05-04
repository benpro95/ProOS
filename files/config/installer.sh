#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Files Container
### by Ben Provenzano III
###

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
 rsync curl screen scrub ethtool aptitude sudo samba sshpass \
 libdbus-1-dev libdbus-glib-1-dev bc git locales mailutils \
 neofetch apt-transport-https nmap bpytop binutils iperf3 cron \
 cron-daemon-common fuse gocryptfs inotify-tools

## Process Monitor
if [ ! -e /usr/local/bin/htop ]; then
  apt-get remove -y htop
  apt-get install -y --no-upgrade --ignore-missing libncursesw5-dev autotools-dev \
   autoconf automake build-essential
  cd /tmp/config/
  wget https://github.com/htop-dev/htop/releases/download/3.2.1/htop-3.2.1.tar.xz
  tar -xf htop-3.2.1.tar.xz
  cd htop-3.2.1
  ./autogen.sh
  ./configure
  make
  make install
  cd -
  ln -sf /usr/local/bin/htop /usr/bin/htop  
fi
ln -sf /usr/bin/bpytop /usr/bin/pytop

## Set Locale
if [ ! -e /etc/locales.generated ]; then
  dpkg-reconfigure locales
  touch /etc/locales.generated
fi

## SSH key for root user
mkdir -p /root/.ssh
cp /tmp/config/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys

## Disable interactive login
usermod --shell /sbin/nologin ben
usermod --shell /sbin/nologin media
usermod --shell /sbin/nologin monitor

## Disable password login
passwd -d root
passwd -d monitor

if [ ! -e /home/ben ]; then
  echo "Creating [ben] home folder..."
  mkdir -p /home/ben
  chown root:root /home/ben
  usermod --home /home/ben ben
fi
if [ ! -e /home/ben/.regions ]; then
  mkdir -p /home/ben/.regions
  chown ben:shared /home/ben/.regions
  chmod g+rx /home/ben/.regions
fi
if [ ! -e /home/media ]; then
  echo "Creating [media] home folder..."
  mkdir -p /home/media
  chown root:root /home/media
  usermod --home /home/media media
fi

## permissions allow running scripts as elevated (ben) user
rm -f /etc/sudoers.d/www-perms
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"monitor ALL=(ben) NOPASSWD:/usr/bin/apicmds\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms
rm -f /etc/sudoers.d/nobody-perms

## API commands
cp -f /tmp/config/apicmds.sh /usr/bin/apicmds
chmod +x /usr/bin/apicmds
chown root:root /usr/bin/apicmds
cp -f /tmp/config/runapi.sh /usr/bin/runapi
chmod +x /usr/bin/runapi
chown root:root /usr/bin/runapi
cp -f /tmp/config/file_monitor.sh /usr/bin/file_monitor
chmod +x /usr/bin/file_monitor
chown root:root /usr/bin/file_monitor
cp -f /tmp/config/savebookmarks.sh /usr/bin/savebookmarks
chmod +x /usr/bin/savebookmarks
chown root:root /usr/bin/savebookmarks

## Server Git Configuration 
cp /tmp/config/git.config /home/ben/.gitconfig
chown ben:shared /home/ben/.gitconfig
chmod 600 /home/ben/.gitconfig

## SSH Configuration
cp /tmp/config/sshd_config /etc/ssh
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

## FUSE Configuration
cp /tmp/config/fuse.conf /etc/fuse.conf
chmod 644 /etc/fuse.conf
chown root:root /etc/fuse.conf

## Quiet Login 
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin

## Login Script
cp /tmp/config/profile /root/.profile
chown root:root /root/.profile
chmod +x /root/.profile

## System Configuration
cp /tmp/config/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## Logrotate Fix for LXCs
cp /tmp/config/logrotate.service /lib/systemd/system/
chmod 644 /lib/systemd/system/logrotate.service
chown root:root /lib/systemd/system/logrotate.service

## Startup Configuration
cp /tmp/config/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
cp /tmp/config/rc.local /etc/
chmod 755 /etc/rc.local
chown root:root /etc/rc.local
systemctl enable rc-local

## Startup Configuration
cp /tmp/config/file-monitor.service /etc/systemd/system/
chmod 644 /etc/systemd/system/file-monitor.service
chown root:root /etc/systemd/system/file-monitor.service
systemctl restart file-monitor

## Main Cron Timer
cp /tmp/config/rootcron.sh /etc/cron.d/rootcron
chmod 644 /etc/cron.d/rootcron
chown root:root /etc/cron.d/rootcron
systemctl restart cron

## Supress Slice Log Entries
cp /tmp/config/ignore-session-slice.conf /etc/rsyslog.d/
chmod 644 /etc/rsyslog.d/ignore-session-slice.conf
chown root:root /etc/rsyslog.d/ignore-session-slice.conf
systemctl restart rsyslog

## Camera Cleanup Script
cp /tmp/config/camcleanup.sh /usr/bin/camcleanup
chmod 755 /usr/bin/camcleanup
chown root:root /usr/bin/camcleanup

## Samba Configuration
cp /tmp/config/smb.conf /etc/samba
chmod 644 /etc/samba/smb.conf
chown root:root /etc/samba/smb.conf

## Bind Mounts
cp -f /tmp/config/fstab /etc/fstab
chmod 644 /etc/fstab
chown root:root /etc/fstab

## Backup Drives List
cp -f /tmp/config/drives.txt /opt/
chmod 644 /opt/drives.txt
chown root:root /opt/drives.txt
cp -v /opt/drives.txt /mnt/ramdisk/
chmod 777 /mnt/ramdisk/drives.txt

## Clean-up
systemctl daemon-reload
rm -r /tmp/config/
exit
