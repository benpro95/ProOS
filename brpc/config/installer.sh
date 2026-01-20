#!/bin/bash
### AutoConfig - for Bedroom Lenovo ThinkCentre PC
### by Ben Provenzano III

## Add Google Chrome Source
if [ ! -e "/etc/apt/sources.list.d/google-chrome.list" ]; then
  echo "Adding Google Chrome Repo..."
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
fi

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates htop \
 apt-transport-https wget unzip gnupg rsync curl screen ethtool libdbus-1-dev \
 libdbus-glib-1-dev locales gnupg scrub binutils avahi-daemon kodi autofs \
 cifs-utils playerctl triggerhappy google-chrome-stable

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
systemctl restart autofs

## Hotkey Configuration
cp -f /tmp/config/hotkeys.conf /etc/triggerhappy/triggers.d/
chmod 644 /etc/triggerhappy/triggers.d/hotkeys.conf
chown root:root /etc/triggerhappy/triggers.d/hotkeys.conf
systemctl enable triggerhappy
systemctl restart triggerhappy

## Node.JS API Server
apt-get install -y --no-upgrade nodejs npm
mkdir -p /opt/nodeapi
cp -r /tmp/config/nodeapi/* /opt/nodeapi/
mv -f /opt/nodeapi/nodeapi.service /etc/systemd/system/
chmod 644 /etc/systemd/system/nodeapi.service
chown root:root /etc/systemd/system/nodeapi.service
cd /opt/nodeapi
npm install
cd -
systemctl enable nodeapi
systemctl restart nodeapi

## Install Web Server
apt-get install -y --no-upgrade lighttpd
cp -f /tmp/config/lighttpd.conf /etc/lighttpd/
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf
cp -f /tmp/config/lighttpd.service /lib/systemd/system/
chmod 644 /lib/systemd/system/lighttpd.service
chown root:root /lib/systemd/system/lighttpd.service
systemctl enable lighttpd
systemctl restart lighttpd

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

## Clean-up
systemctl daemon-reload
rm -rf /tmp/config
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
