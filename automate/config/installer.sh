#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Automate VM
### by Ben Provenzano III

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
apt-get install -y --no-upgrade --ignore-missing dirmngr ca-certificates bpytop \
 apt-transport-https wget unzip gnupg rsync curl screen parallel libdbus-1-dev \
 ethtool libdbus-glib-1-dev locales aptitude sudo gnupg scrub binutils \
 avahi-daemon ffmpeg pip npm python3-ament-xmllint etherwake wakeonlan

## Remove Packages
apt-get remove -y --purge cron anacron postfix apache2 apache2-data htop

## CSS Minifier
apt-get install -y --no-upgrade --ignore-missing yui-compressor default-jre-headless
mkdir -p /usr/lib/jvm/java-8-openjdk-amd64
ln -sf /usr/lib/jvm/default-java /usr/lib/jvm/java-8-openjdk-amd64/jre
if [ ! -e /usr/local/bin/uglifyjs ]; then
  ## Minify JS
  npm install uglify-js -g
fi  

## Process Monitor
if [ ! -e /usr/local/bin/htop ]; then
  apt-get remove -y htop
  apt-get install -y --no-upgrade --ignore-missing libncursesw5-dev \
   autotools-dev autoconf automake build-essential
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
rm -rf /opt/system
mkdir -p /opt/system
cp -v /tmp/config/atv.sh /opt/system/atv
cp -v /tmp/config/leds.sh /opt/system/leds
cp -v /tmp/config/main.sh /opt/system/main
cp -v /tmp/config/status.sh /opt/system/status
ln -sf /opt/system/status /usr/bin/update-status
cp -vr /tmp/config/menus/*.txt /opt/system/
chmod -R 755 /opt/system
chown -R root:root /opt/system
ln -sf /opt/system/main /opt/system/xmit
ln -sf /opt/system /opt/rpi

## Copy Menu Layouts to RAM Disk
if [ ! -e /var/www/html/ram/mainmenu.txt ]; then
  cp -v /opt/system/*menu.txt /var/www/html/ram/
  chmod -R 777 /var/www/html/ram/*menu.txt
  chown -R www-data:www-data /var/www/html/ram/*menu.txt
fi

## Single Instance with Automic File Lock
cp -v /tmp/config/singleton.sh /usr/bin/singleton
chmod 755 /usr/bin/singleton
chown root:root /usr/bin/singleton

## Install Arduino Support
if [ ! -e /usr/bin/arduino-cli ]; then
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=/usr/bin sh
  arduino-cli core install arduino:avr
fi

## Arduino Firmware
rm -rf /opt/AutomateHub_1
mkdir -p /opt/AutomateHub_1
cp -rv /tmp/config/firmware/AutomateHub_1/* /opt/AutomateHub_1/
chmod -R 644 /opt/AutomateHub_1/*
chown -R root:root /opt/AutomateHub_1/*

## Xmit Serial COM
rm -f /usr/bin/ztermcom
gcc /tmp/config/ztermcom.c -o /usr/bin/ztermcom
chmod 755 /usr/bin/ztermcom 
chown root:root /usr/bin/ztermcom

## Light Web Server
apt-get install -y --no-upgrade lighttpd php-cgi php php-common
cp -f /tmp/config/lighttpd.conf /etc/lighttpd
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf
cp -f /tmp/config/ssl_cert.pem /etc/lighttpd
chmod 644 /etc/lighttpd/ssl_cert.pem
chown root:root /etc/lighttpd/ssl_cert.pem
cp -f /tmp/config/root_ca.crt /etc/lighttpd
chmod 644 /etc/lighttpd/root_ca.crt
chown root:root /etc/lighttpd/root_ca.crt
lighttpd-enable-mod fastcgi fastcgi-php
lighty-enable-mod fastcgi-php
systemctl disable lighttpd
systemctl restart lighttpd

## Base website files
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

## Minify JS/CSS
uglifyjs --verbose --compress --output /var/www/html/main.min.js -- /var/www/html/main.js
yui-compressor /var/www/html/main.css > /var/www/html/main.min.css
cp -fv /var/www/html/main.min.js /var/www/html/main.js
cp -fv /var/www/html/main.min.css /var/www/html/main.css
chown www-data:www-data /var/www/html/main.css
chmod 644 /var/www/html/main.css
chown www-data:www-data /var/www/html/main.js
chmod 644 /var/www/html/main.js
rm -f /var/www/html/main.min.css
rm -f /var/www/html/main.min.js

## WWW Permissions (Network Web UI)
rm -f /etc/sudoers.d/www-perms
rm -f /etc/sudoers.d/www-nopasswd
rm -f /etc/sudoers.d/www-mod-nopasswd
rm -f /etc/sudoers.d/nobody-perms
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/main\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/main\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/leds\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/system/xmit\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms

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
rm -rf /etc/systemd/system/relaxloop.service
rm -rf /tmp/config
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
