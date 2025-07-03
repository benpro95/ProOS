#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - for Bedroom Lenovo ThinkCentre PC
### by Ben Provenzano III

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates htop \
 apt-transport-https wget unzip gnupg rsync curl screen ethtool libdbus-1-dev \
 libdbus-glib-1-dev locales gnupg scrub binutils avahi-daemon

## SSH Configuration
cp /tmp/config/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/
chmod 600 /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys

## Disable Root Password
passwd -d root

## Profile Configuration
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin

## Clean-up
systemctl daemon-reload
rm -rf /tmp/config
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
