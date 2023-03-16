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
 apt-transport-https wget unzip gnupg curl screen parallel ethtool avahi-daemon \
 libdbus-1-dev libdbus-glib-1-dev locales aptitude sudo scrub binutils

## Remove Packages
apt-get remove -y --purge cron anacron postfix apache2 apache2-data htop
## UniFi controller
if [ ! -e /lib/systemd/system/unifi.service ] || [ "$REINIT_UNIFI" = "yes" ]; then
  wget https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh
  bash unifi-latest.sh
  systemctl enable unifi
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

## System Configuration
cp /tmp/config/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

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
