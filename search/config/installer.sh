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
 ethtool libdbus-glib-1-dev locales aptitude sudo gnupg scrub binutils libssl-dev \
 avahi-daemon pip python3-ament-xmllint etherwake python3-dev python3-babel \
 python3-venv python-is-python3 uwsgi uwsgi-plugin-python3 git build-essential \
 libxslt-dev zlib1g-dev libffi-dev htop neofetch
## Remove Packages
apt-get remove -y --purge cron anacron postfix apache2 apache2-data

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

## SearXNG Search Engine
useradd --shell /bin/bash --system \
  --home-dir "/usr/local/searxng" \
  --comment 'Privacy-respecting metasearch engine' \
  searxng
if [ ! -e "/usr/local/searxng" ]; then
  mkdir -p /usr/local/searxng
  chown -Rv searxng:searxng /usr/local/searxng
fi
cp -fr /tmp/config/searxng /usr/local/searxng/searxng-src
chown -R searxng:searxng /usr/local/searxng/searxng-src

## Clean-up
systemctl daemon-reload
rm -rf /tmp/config
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y
exit
