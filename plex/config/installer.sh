#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Plex Container
### by Ben Provenzano III
###

## Add Plex Repo
if [ ! -e /etc/apt/sources.list.d/plexmediaserver.list ]; then
   echo deb https://downloads.plex.tv/repo/deb public main | tee /etc/apt/sources.list.d/plexmediaserver.list
   curl "https://downloads.plex.tv/plex-keys/PlexSign.key" | apt-key add -
fi

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget rsync curl screen \
 parallel ethtool aptitude sudo gnupg iptables libdbus-1-dev libdbus-glib-1-dev \
 locales apt-transport-https plexmediaserver bpytop htop binutils

## Remove Packages
apt-get remove -y --purge shellinabox nginx-full nginx nginx-common

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

## Plex Service Configuration 
mkdir -p /etc/systemd/system/plexmediaserver.service.d
cp -r /tmp/config/override.conf /etc/systemd/system/plexmediaserver.service.d/
chmod 644 /etc/systemd/system/plexmediaserver.service.d/override.conf
chown root:root /etc/systemd/system/plexmediaserver.service.d/override.conf
systemctl disable plexmediaserver.service

## Plex SSL Certificate
rm -f /tmp/config/plex.pfx
rm -f /tmp/config/fullchain.crt
cat /tmp/config/plex.crt /tmp/config/root_ca.crt > /tmp/config/fullchain.crt
openssl pkcs12 -export -out /tmp/config/plex.pfx -inkey /tmp/config/plex.key \
 -in /tmp/config/fullchain.crt -name plex.home -passout pass:"" \
 -certpbe AES-256-CBC -keypbe AES-256-CBC -macalg SHA256
cp -fv /tmp/config/plex.pfx /var/lib/plexmediaserver/certificate.pfx
chown plex:plex /var/lib/plexmediaserver/certificate.pfx
chmod 644 /var/lib/plexmediaserver/certificate.pfx

## Auto SSH Login Key for root
mkdir -p /root/.ssh
cp -r /tmp/config/authorized_keys /root/.ssh/

## SSH Configuration
cp -r /tmp/config/sshd_config /etc/ssh
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
cp -r /tmp/config/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## Logrotate Fix for LXCs
cp /tmp/config/logrotate.service /lib/systemd/system/
chmod 644 /lib/systemd/system/logrotate.service
chown root:root /lib/systemd/system/logrotate.service

## Startup Configuration
cp -r /tmp/config/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
cp -r /tmp/config/rc.local /etc/
chmod 755 /etc/rc.local
chown root:root /etc/rc.local
systemctl enable rc-local

## Clean-up
systemctl daemon-reload
rm -r /tmp/config/
apt-get clean -y
apt-get autoclean -y
exit
