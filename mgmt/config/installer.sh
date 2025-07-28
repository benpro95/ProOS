#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Management LXC
### by Ben Provenzano III
###

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
 rsync curl screen scrub ethtool aptitude sudo samba sshpass \
 libdbus-1-dev libdbus-glib-1-dev bc git locales neofetch \
 apt-transport-https nmap bpytop binutils iperf3 htop

## Set Locale
if [ ! -e /etc/locales.generated ]; then
  dpkg-reconfigure locales
  touch /etc/locales.generated
fi

## Create 'ben' user
useradd -m ben

## Public key for root user
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys

## Public key for ben user
mkdir -p /home/ben/.ssh
cp -f /tmp/config/auth_key_ben.pub /home/ben/.ssh/authorized_keys
chown -R ben:ben /home/ben/.ssh
chmod 644 /home/ben/.ssh/authorized_keys

## Disable password login
passwd -d root
passwd -d ben

## SSH Configuration
cp /tmp/config/sshd_config /etc/ssh
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

## Quiet Login 
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin
touch /home/ben/.hushlogin
chmod 644 /home/ben/.hushlogin
chown ben:ben /home/ben/.hushlogin

## Login Scripts
cp /tmp/config/profile /root/.profile
chown root:root /root/.profile
chmod +x /root/.profile
cp /tmp/config/profile_ben /home/ben/.profile
chown ben:ben /home/ben/.profile
chmod +x /home/ben/.profile

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

## Supress Slice Log Entries
cp /tmp/config/ignore-session-slice.conf /etc/rsyslog.d/
chmod 644 /etc/rsyslog.d/ignore-session-slice.conf
chown root:root /etc/rsyslog.d/ignore-session-slice.conf

## Deployment Work Folder
mkdir -p /opt/deploy
chmod 777 /opt/deploy
chown ben:ben /opt/deploy

## Reload services
systemctl daemon-reload

## Clean-up
rm -r /tmp/config/
exit