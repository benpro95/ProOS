#!/bin/bash
### AutoConfig - for Bedroom Lenovo ThinkCentre PC
### by Ben Provenzano III

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates htop \
 apt-transport-https wget unzip gnupg rsync curl screen ethtool libdbus-1-dev \
 libdbus-glib-1-dev locales gnupg scrub binutils avahi-daemon kodi autofs \
 cifs-utils playerctl triggerhappy

## SSH Configuration
cp -f /tmp/config/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/
chmod 600 /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys

## Disable Root Password
passwd -d root

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
systemctl enable autofs

## Hotkey Configuration
cp -f /tmp/config/hotkeys.conf /etc/triggerhappy/triggers.d/
chmod 644 /etc/triggerhappy/triggers.d/hotkeys.conf
chown root:root /etc/triggerhappy/triggers.d/hotkeys.conf
systemctl restart triggerhappy

## Install Web Server
apt-get install -y --no-upgrade lighttpd php-cgi php php-common
cp -f /tmp/config/lighttpd.conf /etc/lighttpd/
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf
cp -f /tmp/config/lighttpd.service /lib/systemd/system/
chmod 644 /lib/systemd/system/lighttpd.service
chown root:root /lib/systemd/system/lighttpd.service
lighttpd-enable-mod fastcgi fastcgi-php
lighty-enable-mod fastcgi-php

## HTML Files
mkdir -p /var/www/html
chown -R www-data:www-data /tmp/config/html
rsync -a /tmp/config/html/ /var/www/html/
chmod g+rx /var/www/html
chown www-data:www-data /var/www/html
mkdir -p /var/www/sessions
chmod -R g+rx /var/www/sessions
chown -R www-data:www-data /var/www/sessions
mkdir -p /var/www/uploads
chmod -R g+rx /var/www/uploads
chown -R www-data:www-data /var/www/uploads

## Web API Commands
mkdir -p /opt/system
cp -f /tmp/config/webapi.sh /opt/system/webapi.sh
chmod +x /opt/system/webapi.sh
chown root:root /opt/system/webapi.sh

## WWW Permissions
rm -f /etc/sudoers.d/www-perms
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/webapi.sh\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms

## Restart Web Server
systemctl enable lighttpd
systemctl restart lighttpd

## Clean-up
systemctl daemon-reload
rm -rf /tmp/config
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
