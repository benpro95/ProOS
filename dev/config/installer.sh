#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Development VM
### by Ben Provenzano III

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates \
 apt-transport-https wget unzip gnupg bpytop htop rsync curl screen parallel ethtool \
 libdbus-1-dev libdbus-glib-1-dev locales cifs-utils iptables aptitude sudo \
 gnupg mailutils scrub avahi-daemon autofs binutils

## Process Monitor Symlink
ln -sf /usr/bin/bpytop /usr/bin/htop 

## Disable Root Password
passwd -d root

## Auto SSH Login Key for root
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/

## SSH Configuration
cp -f /tmp/config/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

## System Configuration
cp /tmp/config/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## AutoFS Configuration
cp -f /tmp/config/auto.master /etc/
chmod 644 /etc/auto.master
chown root:root /etc/auto.master
cp -f /tmp/config/auto.map /etc/
chmod 644 /etc/auto.map
chown root:root /etc/auto.map
cp -f /tmp/config/auto.creds /etc/
chmod 400 /etc/auto.creds
chown root:root /etc/auto.creds
mkdir -p /mnt/smb

## Profile Configuration
cp -f /tmp/config/profile /root/.profile
chmod 755 /root/.profile
chown root:root /root/.profile
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin

## Clean-up
systemctl daemon-reload
rm -rf /tmp/config/
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
