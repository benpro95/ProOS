#!/bin/bash
### ONLY RUN ON THE SERVER!!
### AutoConfig - ProOS for Files Container
### by Ben Provenzano III
###

## Update Sources
apt-get --yes update

## Install packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
 rsync curl screen scrub ethtool aptitude sudo samba sshpass \
 libdbus-1-dev libdbus-glib-1-dev bc git locales mailutils \
 neofetch apt-transport-https nmap bpytop binutils iperf3 cron \
 cron-daemon-common fuse gocryptfs inotify-tools avahi-daemon htop

## AppleTalk packages
apt-get install -y --no-upgrade --ignore-missing cracklib-runtime \
 dbus-user-session dconf-gsettings-backend dconf-service libtracker-sparql-3.0-0 \
 glib-networking glib-networking-common glib-networking-services \
 gsettings-desktop-schemas libcrack2 libdconf1 libevent-2.1-7 libjson-glib-1.0-0 \
 libjson-glib-1.0-common libproxy1v5 libsoup-3.0-0 libsoup-3.0-common libstemmer0d
apt-get install -y /tmp/config/netatalk_3.2.2.deb

## Samba / AppleTalk password
SHRPASS="ben1995"

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

## AppleTalk configuration
cp -f /tmp/config/afp.conf /etc/netatalk/
chmod 644 /etc/netatalk/afp.conf 
chown root:root /etc/netatalk/afp.conf

## Reload Services
systemctl daemon-reload

## Enable Services
systemctl enable smbd nmbd avahi-daemon netatalk

## Restart Services
systemctl restart smbd nmbd avahi-daemon netatalk

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

## Clean-up
rm -r /tmp/config/
exit
