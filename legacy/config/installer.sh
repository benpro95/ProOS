#!/bin/bash
### ONLY RUN ON THE SERVER!!
### by Ben Provenzano III
###

## Samba / AppleTalk password
SHRPASS="ben1995"

## Set working directory
cd /tmp/config

## Update sources
apt-get --yes update

## Install packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
  rsync curl screen scrub ethtool aptitude sudo samba sshpass \
  libdbus-1-dev libdbus-glib-1-dev bc git locales mailutils \
  apt-transport-https nmap bpytop binutils iperf3 cron \
  cron-daemon-common autofs cifs-utils avahi-daemon htop

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

## Ben user configuration
SHRUSER1="ben"
groupadd -g 1015 shared
useradd "$SHRUSER1" --password='' --shell=/bin/false
passwd ${SHRUSER1} << EOD
${SHRPASS}
${SHRPASS}
EOD
smbpasswd -a -s ${SHRUSER1} << EOD
${SHRPASS}
${SHRPASS}
EOD
usermod -a -G shared ${SHRUSER1}  

## Media user configuration
SHRUSER2="media"
useradd "$SHRUSER2" --password='' --shell=/bin/false
passwd ${SHRUSER2} << EOD
${SHRPASS}
${SHRPASS}
EOD
smbpasswd -a -s ${SHRUSER2} << EOD
${SHRPASS}
${SHRPASS}
EOD
usermod -a -G shared ${SHRUSER2}  

## Samba configuration 
cp -f /tmp/config/smb.conf /etc/samba/
chmod 644 /etc/samba/smb.conf
chown root:root /etc/samba/smb.conf

## AFP support packages
if [ ! -e "/usr/lib/systemd/system/netatalk.service" ]; then
  ## install dependencies
  apt-get install --assume-yes --no-install-recommends bison ca-certificates \
    cmark-gfm cracklib-runtime file flex gcc libacl1-dev libavahi-client-dev \
    libcrack2-dev libcups2-dev libdb-dev libdbus-1-dev libevent-dev libgcrypt20-dev \
    libglib2.0-dev libiniparser-dev libkrb5-dev libldap2-dev libmariadb-dev \
    libpam0g-dev libsqlite3-dev libtalloc-dev libtirpc-dev libtracker-sparql-3.0-dev \
    libwrap0-dev meson ninja-build quota systemtap-sdt-dev tcpd tracker tracker-miner-fs valgrind
  ## download source code
  tar -xvf ./netatalk-4.3.2.tar.xz
  cd netatalk-4.3.2
  ## compile from source
  meson setup build -Dbuildtype=release -Dwith-appletalk=true -Dwith-cups-pap-backend=true \
    -Dwith-dbus-sysconf-path=/usr/share/dbus-1/system.d -Dwith-init-hooks=false \
    -Dwith-init-style=debian-sysv,systemd -Dwith-pkgconfdir-path=/etc/netatalk \
    -Dwith-tests=true -Dwith-testsuite=true
  meson test -C build
  meson install -C build
  cd -
fi
mkdir -p /opt/afpdb

## AFP configuration
cp -f /tmp/config/afp.conf /etc/netatalk/
chmod 644 /etc/netatalk/afp.conf 
chown root:root /etc/netatalk/afp.conf

## Reload Services
systemctl daemon-reload

## Disable Auto-Starting Services
systemctl disable smbd nmbd avahi-daemon netatalk atalkd

## Set Locale
if [ ! -e /etc/locales.generated ]; then
  dpkg-reconfigure locales
  touch /etc/locales.generated
fi

## SSH Key
mkdir -p /root/.ssh
cp /tmp/config/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys

## Disable Password Login
passwd -d root

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

## Startup Configuration
cp /tmp/config/rc-local.service /etc/systemd/system/
chmod 644 /etc/systemd/system/rc-local.service
chown root:root /etc/systemd/system/rc-local.service
cp /tmp/config/rc.local /etc/
chmod 755 /etc/rc.local
chown root:root /etc/rc.local
systemctl enable rc-local

## Clean-up
rm -r /tmp/config/
exit
