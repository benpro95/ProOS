#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Automate VM
### by Ben Provenzano III

## Reinstall / Upgrade Unifi Controller
REINIT_UNIFI="no"

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates bpytop \
 apt-transport-https wget unzip gnupg rsync curl screen parallel ethtool avahi-daemon \
 libdbus-1-dev libdbus-glib-1-dev locales aptitude sudo gnupg scrub binutils ffmpeg pip

## Remove Packages
apt-get remove -y --purge cron anacron postfix apache2 apache2-data htop
## UniFi controller
if [ ! -e /lib/systemd/system/unifi.service ] || [ "$REINIT_UNIFI" = "yes" ]; then
  wget https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh
  bash unifi-latest.sh
  systemctl disable unifi
fi

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

## Apple TV Control
pip install pyatv

## Install Replacement Logger
apt-get remove --purge -y rsyslog
apt-get install -y --no-upgrade busybox-syslogd
echo "Run command 'logread' to check system logs"
dpkg --purge rsyslog
rm -f /var/log/messages
rm -f /var/log/syslog

## System Configuration
cp /tmp/config/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## System Resources
rm -rf /opt/rpi
rm -rf /opt/system
mkdir -p /opt/system
cp /tmp/config/leds.sh /opt/system/leds
cp /tmp/config/main.sh /opt/system/main
cp /tmp/config/relaxloop.sh /opt/system/relaxloop
cp /tmp/config/ledsync.txt /opt/system/
chmod -R 755 /opt/system/*
chown -R root:root /opt/system
ln -sf /opt/system/main /opt/system/xmit

## Light Web Server
apt-get install -y --no-upgrade lighttpd php-cgi php php-common
cp -f /tmp/config/lighttpd.conf /etc/lighttpd
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf
lighttpd-enable-mod fastcgi fastcgi-php
lighty-enable-mod fastcgi-php
systemctl disable lighttpd
systemctl restart lighttpd

## Base website files
mkdir -p /var/www/html
chown -R www-data:www-data /tmp/config/html
rsync -a --progress=show /tmp/config/html/ /var/www/html/
chmod g+rx /var/www/html
chown www-data:www-data /var/www/html
mkdir -p /var/www/sessions
chmod -R g+rx /var/www/sessions
chown -R www-data:www-data /var/www/sessions
mkdir -p /var/www/uploads
chmod -R g+rx /var/www/uploads
chown -R www-data:www-data /var/www/uploads

## WWW Permissions (Network Web UI)
rm -f /etc/sudoers.d/www-perms
rm -f /etc/sudoers.d/www-nopasswd
rm -f /etc/sudoers.d/www-mod-nopasswd
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/main*\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/leds\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/xmit\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/lcdmsg\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms
##
## Nobody User Permissions (THD Hotkeys)
rm -f /etc/sudoers.d/nobody-perms
sh -c "touch /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/system/main*\" >> /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/system/leds\" >> /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/system/xmit\" >> /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/system/lcdmsg\" >> /etc/sudoers.d/nobody-perms"
chown root:root /etc/sudoers.d/nobody-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/nobody-perms
chmod u=r,g=r,o= /etc/sudoers.d/nobody-perms

## Relax Loop Service
cp -f /tmp/config/relaxloop.service /etc/systemd/system/
chmod 644 /etc/systemd/system/relaxloop.service
chown root:root /etc/systemd/system/relaxloop.service
systemctl disable relaxloop

## Boot Service
cp -f /tmp/config/rc.local /etc/
chmod 755 /etc/rc.local
chown root:root /etc/rc.local
cp -f /tmp/config/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
systemctl enable rc-local

## Disable Root Password
passwd -d root

## Auto SSH Login Key for root
mkdir -p /root/.ssh
cp -f /tmp/config/authorized_keys /root/.ssh/

## SSH Configuration
cp -f /tmp/config/sshd_config /etc/ssh/
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

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