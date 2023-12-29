#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Files Container
### by Ben Provenzano III
###

## Update Sources
apt-get --yes update

## Debian Bullseye to Bookworm
#apt dist-upgrade
#apt upgrade
#sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
#apt-get --yes update
#apt dist-upgrade
#apt upgrade
#apt autoremove
#apt autoclean
#apt clean

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
 curl screen ethtool aptitude sudo samba sshpass \
 libdbus-1-dev libdbus-glib-1-dev bc locales \
 neofetch apt-transport-https bpytop

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

## Remove Passwords
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

## Samba Configuration
cp /tmp/config/smb.conf /etc/samba
chmod 644 /etc/samba/smb.conf
chown root:root /etc/samba/smb.conf

## Clean-up
systemctl daemon-reload
rm -r /tmp/config/
apt-get autoremove -y
sleep 2.5
apt-get autoclean -y
exit
