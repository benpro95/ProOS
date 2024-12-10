#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Server Container
### by Ben Provenzano III
###

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget rsync curl screen ethtool \
 sshpass bc locales mailutils neofetch apt-transport-https nmap bpytop binutils iperf3

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

## SSH keys
mkdir -p /root/.ssh
cp /tmp/config/authorized_keys /root/.ssh/
cp -Rvf /tmp/config/keys/*.rsa /root/.ssh/
chown root:root -R /root/.ssh/*
chmod 600 -R /root/.ssh/*

## Quiet Login 
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin

## Login Script
cp /tmp/config/profile /root/.profile
chown root:root /root/.profile
chmod +x /root/.profile
cp /tmp/config/login.sh /usr/local/bin/
chown root:root /usr/local/bin/login.sh 
chmod +x /usr/local/bin/login.sh

## Remove Passwords
passwd -d root

## SSH Configuration
cp /tmp/config/sshd_config /etc/ssh
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
systemctl enable ssh

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
systemctl restart rsyslog

## Clean-up
systemctl daemon-reload
rm -r /tmp/config/
apt-get autoremove -y
sleep 2.5
apt-get autoclean -y
exit
