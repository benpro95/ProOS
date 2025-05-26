#!/bin/bash
## Raspberry Pi ProOS Server Setup Script v12.0
## run this 1st, then module installer

# Core Path
BIN=/opt/rpi/config
# Import Hostname
NEWHOST=`cat $BIN/hostname`
# Import Module Name
MODNAME=`cat /opt/rpi/modconf/brand.txt`
## Detect Pi Model
CPUTYPE=$(tr -d '\0' < /sys/firmware/devicetree/base/model)

echo "Installing on $NEWHOST..." 

## Pre-installation checks
if [ ! -e /opt/rpi/init ]; then
  echo "Core components missing."
  exit
else
  echo "Core components integrity verified."
fi
if [ ! -e /boot/config.txt ]; then
  echo "Not running on a Pi !!"
  exit
else
  echo "Raspberry Pi detected."
fi
OSVER="$(sed -n 's|^VERSION=".*(\(.*\))"|\1|p' /etc/os-release)"
if [ "${OSVER}" = "bookworm" ]; then
  echo "OS version ${OSVER} detected."
else
  echo "Unsupported OS version ${OSVER} detected."
  exit
fi

cd $BIN

echo ""
echo "########### Welcome to ProOS ! ###########"
echo "############## Configurator ##############"
echo "######### by Ben Provenzano III ##########"
echo ""

###################################################
### Initial configuration #########################
if [ ! -e /etc/rpi-conf.done ]; then
echo "*"
echo "Resettings to defaults..."
echo "*"

## Set boot partition to read/write
mount -o remount,rw /boot/firmware

## Set locale
raspi-config nonint do_change_locale LANG=en_US.UTF-8

## Set time zone
raspi-config nonint do_change_timezone America/New_York

## Set keyboard layout
raspi-config nonint do_configure_keyboard us

## Create pi user
adduser pi
chown -R pi:pi /home/pi
chsh -s /bin/bash pi

## Update Sources
apt-get -y update --allow-releaseinfo-change

## Essential Packages
apt-get install -y --no-upgrade --ignore-missing locales console-setup \
 aptitude libnss-mdns usbutils zsync v4l-utils libpq5 htop lsb-release \
 avahi-daemon avahi-discover avahi-utils hostapd dnsmasq-base unzip wget bc \
 uuid-runtime mpg321 mpv mplayer espeak tightvncserver iptables libnss3-tools jq \
 rsync screen parallel sudo sed nano curl insserv wireless-regdb wireless-tools \
 iw wpasupplicant dirmngr autofs triggerhappy apt-utils build-essential netatalk \
 autoconf make libtool binutils i2c-tools cmake yasm cryptsetup cryptsetup-bin \
 texi2html socat nmap autoconf automake pkg-config cifs-utils neofetch \
 libmariadb3 keyboard-configuration ncftp inxi gnucobol4 minicom

## Developer Packages 
apt-get install -y --no-upgrade --ignore-missing libgtk2.0-dev libbluetooth3 libbluetooth-dev \
 libavfilter-dev libavdevice-dev libavcodec-dev libavc1394-dev libatlas-base-dev libusb-1.0-0-dev \
 libjack-jackd2-dev portaudio19-dev libffi-dev libxslt1-dev libxml2-dev sqlite3 \
 libass-dev libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libssl-dev \
 libxml2-dev libxslt1-dev portaudio19-dev libffi-dev zlib1g-dev libdbus-1-dev \
 libva-dev libvdpau-dev libvorbis-dev libx11-dev libxext-dev libxfixes-dev \
 libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdbus-glib-1-dev

 ## AV Codecs Support
apt-get install -y --no-upgrade --ignore-missing libgstreamer1.0-dev gstreamer1.0-plugins-base \
 gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-libav \
 libx264-dev x264 ffmpeg libswscale-dev libavformat-dev libavcodec-dev libupnp-dev ffmpeg \
 libgstreamer-plugins-base1.0-0 gstreamer1.0-alsa

## Install X11 
apt-get install -y --no-upgrade --ignore-missing xserver-xorg xorg \
 x11-common x11-common xserver-xorg-input-evdev xserver-xorg-legacy xvfb \
 libxext6 libxtst6 libatlas-base-dev xprintidle xdotool wmctrl openbox lxde-common \
 lxsession pcmanfm lxterminal gpicview xfce4-panel xfce4-whiskermenu-plugin

## Disable Swap
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt-get -y remove --purge dphys-swapfile

## CPU Specific Packages
if [ "$CPUTYPE" = "Raspberry Pi Zero W Rev 1.1" ]; then
  echo "Pi Zero detected, not installing rclone."
  echo "Removing Java, Arduino, Node.js Support..."
  apt-get remove -y ca-certificates-java default-jre-headless default-jre \
   openjdk-11-jre nodejs arduino avrdude 
else
  echo "ARMv7 CPU detected, installing Java, Arduino, Node, Rclone..."
  ## Note: Tested Node.js version 14.17.1
  apt-get install -y --no-upgrade --ignore-missing nodejs arduino avrdude openjdk-11-jre
  ## Cloud Drive Support
  apt-get install -y --no-upgrade --ignore-missing rclone fuse
fi

## Python Libraries
apt-get install -y --no-upgrade --ignore-missing net-tools python3 \
 python3-setuptools python3-pip python3-dev python3-pygame python3-venv \
 python3-gpiozero python3-setuptools python3-wheel python3-serial python3-xmodem \
 python3-rpi.gpio python3-ipython python3-pyaudio python3-numpy

## Light Web Server
apt-get install -y --no-upgrade --ignore-missing lighttpd \
  php-common php-cgi php php-mysql perl perl-modules
chown www-data:www-data /var/www
chmod 775 /var/www
usermod -a -G www-data pi
mkdir -p /var/www/html
chmod -R 777 /var/www/html
chown -R www-data:www-data /var/www/html

## USB File Service
apt-get install -y --no-upgrade --ignore-missing samba samba-common-bin samba-libs 

## Audio Support
apt-get install -y --no-upgrade --ignore-missing alsa-base alsa-utils mpg321 lame sox \
  libasound2 libupnp6 libexpat1 libconfig-dev djmount libexpat1 libsox-dev libsoup2.4-dev \
  libimage-exiftool-perl libcurl4 libsoup2.4-1 libao-dev libglib2.0-dev libreadline-dev \
  xmltoman libsoxr-dev libsndfile1-dev libpulse-dev libavahi-client-dev libssl-dev \
  libdaemon-dev libpopt-dev libconfig-dev libdaemon-dev libpopt-dev libjson-glib-1.0-0 \
  libjson-glib-dev libao-common libasound2-dev xxd libplist-dev libsodium-dev \
  libavutil-dev uuid-dev libgcrypt-dev

## Bluetooth Support
apt-get install -y --no-upgrade --ignore-missing bluetooth pi-bluetooth \
 bluez bluez-tools bluez-alsa-utils

## AirPlay Support
apt-get install -y --no-upgrade --ignore-missing shairport-sync

## Camera Motion Server
apt-get install -y --no-upgrade --ignore-missing libmicrohttpd12 motion
groupadd motion
useradd motion -g motion --shell /bin/false
groupmod -g 1005 motion
usermod -u 1005 motion

## v5.0 Random Number Generator
apt-get install -y --no-upgrade --ignore-missing rng-tools5

## Install Replacement Logger
apt-get install -y --no-upgrade --ignore-missing busybox-syslogd
echo "Run command 'logread' to check system logs"
dpkg --purge rsyslog
rm -f /var/log/messages
rm -f /var/log/syslog

## Remove Packages 
apt-get remove --purge -y cron anacron logrotate fake-hwclock ntp udhcpd usbmuxd pmount usbmount \
  cups cups-client cups-common cups-core-drivers cups-daemon cups-filters cups-filters-core-drivers \
  cups-ipp-utils cups-ppdc cups-server-common upower chromium chromium-browser chromium-common chromium-l10n \
  exim4 exim4-base exim4-config exim4-daemon-light udisks2 tigervnc-common tigervnc-standalone-server \
  iptables-persistent bridge-utils ntfs-3g lxlock xscreensaver xscreensaver-data gvfs gvfs-backends \
  vnc4server libudisks2-0 dnsmasq wolfram-engine libssl-doc libatasmart4 libavahi-glib1 mpd mpc \
  rng-tools rng-tools-debian openjdk-17-jre-headless firefox pocketsphinx-en-us piwiz plymouth \
  plymouth-label plymouth-themes pulseaudio pulseaudio-utils pavucontrol pipewire pipewire-bin \
  tracker-extract tracker-miner-fs
dpkg -l | grep unattended-upgrades
dpkg -r unattended-upgrades
rm -rf /etc/cron.*

## Clean-up Packages
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y

## Delete custom services
rm -fr /etc/systemd/system/rpi-*

## Reset LED configuration
rm -f /opt/rpi/remotes/leds
rm -f /tmp/global-fc.lock

echo "Phase I setup complete."
fi ###### END OF SUB-SCRIPT #######################
###################################################

###################################################
########## Install System Configuration ###########
echo "Installing system configuration."

## Boot partition read-write
mount -o remount,rw /boot/firmware

## SSH will be enabled by systemd, do not use this file
rm -f /boot/ssh
rm -f /boot/firmware/ssh
## Delete flags, return to default
rm -f /boot/firmware/disable.wifi
rm -f /boot/firmware/apd.enable
rm -f /boot/firmware/apd.conf

## Default Boot Config
if [ ! -e /etc/rpi-bootro.done ]; then
  echo "Enabling read-only boot partition.."  
  raspi-config nonint enable_bootro
  touch /etc/rpi-bootro.done
fi
cp -fv /boot/firmware/config.txt /boot/firmware/config.bak
cp -f $BIN/config.txt /boot/firmware/

## Boot to Console
systemctl set-default multi-user.target

## WiFi Configuration
raspi-config nonint do_wifi_country US

## Copy SSH Configuration
cp $BIN/sshd_config /etc/ssh
cp $BIN/ssh_config /etc/ssh
chmod 644 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
chmod 644 /etc/ssh/ssh_config
chown root:root /etc/ssh/ssh_config

## Copy SSH Key for Root
rm -r /root/.ssh
mkdir -p /root/.ssh
cp -f $BIN/authorized_keys /root/.ssh
chmod 644 /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys

## Copy Bash Login Script
cp -f $BIN/bashrc /root/.bashrc
chmod 755 /root/.bashrc
chown root:root /root/.bashrc
cp -f $BIN/bashrc /home/pi/.bashrc
chmod 755 /home/pi/.bashrc
chown pi:pi /home/pi/.bashrc

## Remove Root Password
passwd -d root

## System Configuration
cp -f /etc/sysctl.conf /etc/sysconf.bak
cp -f $BIN/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## Journal Configuration
cp -f /etc/systemd/journald.conf /etc/systemd/journald.bak
cp -f $BIN/journald.conf /etc/systemd/
chmod 644 /etc/systemd/journald.conf
chown root:root /etc/systemd/journald.conf

## Kernel Drivers Configuration
cp -f $BIN/modules /etc
chmod 644 /etc/modules
chown root:root /etc/modules

## Detect if proinit service is installed
if [ ! -e /etc/systemd/system/proinit.service ]; then
  echo "proinit.service not found, resetting services."
  rm -f /etc/rpi-conf.done
fi

## Replacement / New Services
cp -fr $BIN/systemd/* /etc/systemd/system/
chmod -fR 644 /etc/systemd/system/*.timer
chown -fR root:root /etc/systemd/system/*.timer
chmod -fR 644 /etc/systemd/system/*.service
chown -fR root:root /etc/systemd/system/*.service

## Startup Scripts
cp -f $BIN/netmode.sh /etc/
chmod 755 /etc/netmode.sh
chown root:root /etc/netmode.sh
cp -f $BIN/preinit.sh /etc/
chmod 755 /etc/preinit.sh
chown root:root /etc/preinit.sh

## ShairPort AirPlay Support
rm -f /etc/init.d/shairport-sync
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
  echo "Skipping module modification."
else
  ## ShairPort configuration
  sed -i "s/RaspberryPi/$MODNAME/g" /etc/systemd/system/rpi-airplay.service
fi

## Light Web Server Configuration
lighttpd-enable-mod fastcgi fastcgi-php
lighty-enable-mod fastcgi-php
ln -sf /etc/lighttpd/conf-available/10-fastcgi.conf /etc/lighttpd/conf-enabled/
ln -sf /etc/lighttpd/conf-available/15-fastcgi-php.conf /etc/lighttpd/conf-enabled/
ln -sf /usr/share/lighttpd/create-mime.conf.pl /usr/share/lighttpd/create-mime.assign.pl
cp -f $BIN/lighttpd.conf /etc/lighttpd/
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf

## PHP Configuration
PHP_VERSION=$(php -v | tac -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)
cp -rf $BIN/php.cgi.ini /etc/php/$PHP_VERSION/cgi/php.ini
chmod 644 /etc/php/$PHP_VERSION/cgi/php.ini
chown root:root /etc/php/$PHP_VERSION/cgi/php.ini
cp -rf $BIN/php.cli.ini /etc/php/$PHP_VERSION/cli/php.ini
chmod 644 /etc/php/$PHP_VERSION/cli/php.ini
chown root:root /etc/php/$PHP_VERSION/cli/php.ini
chown -R www-data:www-data /var/lib/php
chmod -R g+rx /var/lib/php
if [ -e /lib/systemd/system/phpsessionclean.service ]; then
  systemctl disable phpsessionclean.timer
  systemctl disable phpsessionclean.service
  rm -f /lib/systemd/system/phpsessionclean.timer
  rm -f /lib/systemd/system/phpsessionclean.service
fi

## LightTPD base website files
rm -r /var/www/html
mkdir -p /var/www/html
mv -f $BIN/html-base/* /var/www/html
mv -f $BIN/html/* /var/www/html
mkdir -p /var/www/html/ram
touch /var/www/html/ram/sysout.txt
cp -vf $BIN/thememenu.txt /var/www/html/ram/
chmod -R 775 /var/www/html
chown -R www-data:www-data /var/www/html
mkdir -p /var/www/sessions
chmod -R g+rx /var/www/sessions
chown -R www-data:www-data /var/www/sessions
mkdir -p /var/www/uploads
chmod -R g+rx /var/www/uploads
chown -R www-data:www-data /var/www/uploads

if [ ! -e /opt/rpi/modconf/brand.txt ]; then
  ## No module selected
  sed -i "s/>Automate</>RaspberryPi</g" /var/www/html/index.html
else
  ## Set module name
  sed -i "s/>Automate</>$MODNAME</g" /var/www/html/index.html
fi

## WWW Permissions (Network Web UI)
rm -f /etc/sudoers.d/www-perms
rm -f /etc/sudoers.d/www-nopasswd
rm -f /etc/sudoers.d/www-mod-nopasswd
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/main-www\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/main\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/leds\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/xmit\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms

## Nobody User Permissions (THD Hotkeys)
rm -f /etc/sudoers.d/nobody-perms
sh -c "touch /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/rpi/main\" >> /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/rpi/leds\" >> /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/rpi/xmit\" >> /etc/sudoers.d/nobody-perms"
chown root:root /etc/sudoers.d/nobody-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/nobody-perms
chmod u=r,g=r,o= /etc/sudoers.d/nobody-perms

## Unrestricted Pi Permissions
rm -f /etc/sudoers.d/010_pi-perms
rm -f /etc/sudoers.d/010_pi-nopasswd
sh -c "touch /etc/sudoers.d/010_pi-nopasswd"
sh -c "echo \"pi ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers.d/010_pi-nopasswd"
chown root:root /etc/sudoers.d/010_pi-nopasswd
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/010_pi-nopasswd
chmod u=r,g=r,o= /etc/sudoers.d/010_pi-nopasswd
usermod -a -G sudo pi

## X Server Configuration
usermod -a -G tty pi
usermod -a -G video pi
cp -f $BIN/Xwrapper.config /etc/X11
chmod 644 /etc/X11/Xwrapper.config
chown root:root /etc/X11/Xwrapper.config
mkdir -p /home/pi/.config/lxsession
chown -R pi:pi /home/pi/.config/lxsession
mkdir -p /home/pi/.config/lxsession/LXDE
chown -R pi:pi /home/pi/.config/lxsession/LXDE
cp -f $BIN/xdesktop.conf /home/pi/.config/lxsession/LXDE/desktop.conf
chmod 644 /home/pi/.config/lxsession/LXDE/desktop.conf
chown pi:pi /home/pi/.config/lxsession/LXDE/desktop.conf
cp -f $BIN/xautostart /home/pi/.config/lxsession/LXDE/autostart
chmod 755 /home/pi/.config/lxsession/LXDE/autostart
chown pi:pi /home/pi/.config/lxsession/LXDE/autostart

## Bluetooth Configuration
cp -f $BIN/btmain.conf /etc/bluetooth/main.conf
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
echo "Skip module naming."
else
## Set module name to bluetooth config
sed -i "s/RaspberryPi/$MODNAME/g" /etc/bluetooth/main.conf
fi
chown root:root /etc/bluetooth/main.conf
chmod 644 /etc/bluetooth/main.conf
mkdir -p /etc/systemd/system/bluetooth.service.d
cp -f $BIN/bt-override.conf /etc/systemd/system/bluetooth.service.d/override.conf
chown root:root /etc/systemd/system/bluetooth.service.d/override.conf
chmod 644 /etc/systemd/system/bluetooth.service.d/override.conf
# Make Bluetooth Discoverable
mkdir -p /etc/systemd/system/bthelper@.service.d
cp -f $BIN/bthelper-override.conf /etc/systemd/system/bthelper@.service.d/override.conf
chown root:root /etc/systemd/system/bthelper@.service.d/override.conf
chmod 644 /etc/systemd/system/bthelper@.service.d/override.conf
# BlueALSA Configuration
rm -f /etc/systemd/system/bluealsa.service
cp -f $BIN/bluealsa.service /lib/systemd/system/bluealsa.service  
chown root:root /lib/systemd/system/bluealsa.service
chmod 644 /lib/systemd/system/bluealsa.service
mkdir -p /etc/systemd/system/bluealsa.service.d
cp -f $BIN/bluealsa-override.conf /etc/systemd/system/bluealsa.service.d/override.conf
chown root:root /etc/systemd/system/bluealsa.service.d/override.conf
chmod 644 /etc/systemd/system/bluealsa.service.d/override.conf
# Bluetooth UDEV Script
cp -f $BIN/bluetooth-udev /usr/local/bin/bluetooth-udev
chown root:root /usr/local/bin/bluetooth-udev
chmod 755 /usr/local/bin/bluetooth-udev
cp -f $BIN/bluetooth-udev.rules /etc/udev/rules.d/99-bluetooth-udev.rules
chown root:root /etc/udev/rules.d/99-bluetooth-udev.rules
chmod 644 /etc/udev/rules.d/99-bluetooth-udev.rules
## Bluetooth Input Configuration
cp -f $BIN/btinput.conf /etc/bluetooth/input.conf
chmod 644 /etc/bluetooth/input.conf
chown root:root /etc/bluetooth/input.conf

## Remove unused udev network rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

## Enable Network Time Sync
timedatectl set-ntp true
timedatectl status

## Set hostname to configurations
if [ ! -e $BIN/hostname ]; then
echo "Skipping hostname modification."
else
## Write hostname file
cp -r $BIN/hostname /etc/hostname
chmod 644 /etc/hostname
chown root:root /etc/hostname
## Write hosts file
cp -f $BIN/hosts /etc
chmod 644 /etc/hosts
chown root:root /etc/hosts
sed -i "s/raspberrypi/$NEWHOST/g" /etc/hosts
fi

## Create ALSA state file if not found
if [ ! -e /var/lib/alsa/asound.state ]; then
echo "Creating Alsa state file"
touch /var/lib/alsa/asound.state
echo '#' > /var/lib/alsa/asound.state
chmod 777 /var/lib/alsa/asound.state
fi

## ALSA Configuration
cp -f $BIN/asound.conf /etc/
chmod 644 /etc/asound.conf
chown root:root /etc/asound.conf
cp -f $BIN/aliases.conf /lib/modprobe.d/
chmod 644 /lib/modprobe.d/aliases.conf
chown root:root /lib/modprobe.d/aliases.conf

## Samba USB Share Configuration
cp -f $BIN/smb.conf /etc/samba
chmod 644 /etc/samba/smb.conf
chown root:root /etc/samba/smb.conf
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
echo "Skipping module modification."
else
## Set module name to file share config
sed -i "s/RaspberryPi/$MODNAME/g" /etc/samba/smb.conf
fi

## Automount Fix System Override
mkdir -p /etc/systemd/system/systemd-udevd.service.d
cp -f $BIN/udevd-override.conf /etc/systemd/system/systemd-udevd.service.d/override.conf
chmod -f 644 /etc/systemd/system/systemd-udevd.service.d/override.conf
chown -f root:root /etc/systemd/system/systemd-udevd.service.d/override.conf
## Run script when USB drive plugged in 
cp -f $BIN/10-udev-disks.rules /etc/udev/rules.d/
chmod 644 /etc/udev/rules.d/10-udev-disks.rules
chown root:root /etc/udev/rules.d/10-udev-disks.rules
udevadm control --reload-rules

## Motion Default Configuration
cp -f $BIN/motion /etc/default/motion
chmod 644 /etc/default/motion
chown root:root /etc/default/motion
mkdir -p /etc/motion
cp -f $BIN/motion.conf /etc/motion/motion.conf
chmod 644 /etc/motion/motion.conf
chown root:root /etc/motion/motion.conf

## Link init script to global commands library
ln -sf /opt/rpi/init /usr/bin/rpi
ln -sf /opt/rpi/leds /usr/bin/leds

## Compile COBOL Programs
cobc -x --free /opt/rpi/effects/colorscan.cbl -o /opt/rpi/effects/colorscan

## Services Configuration
cp -f $BIN/timesyncd.conf /etc/systemd/
chmod 644 /etc/systemd/timesyncd.conf
chown root:root /etc/systemd/timesyncd.conf
cp -f $BIN/keyboard-setup.service /lib/systemd/system/
chmod 644 /lib/systemd/system/keyboard-setup.service
chown root:root /lib/systemd/system/keyboard-setup.service
rm -f /lib/systemd/system/shairport-sync.service
systemctl daemon-reload
if [ ! -e /etc/rpi-conf.done ]; then
  ## Active on startup
  systemctl unmask NetworkManager-wait-online NetworkManager-dispatcher \
   NetworkManager ModemManager systemd-journald hostapd motion
  systemctl enable ssh avahi-daemon proinit rpi-cleanup.timer \
   systemd-timesyncd systemd-time-wait-sync NetworkManager ModemManager \
   NetworkManager-wait-online NetworkManager-dispatcher   
  ## Disabled on startup
  systemctl disable hostapd keyboard-setup sysstat lighttpd wifiswitch motion \
    apt-daily.service apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer \
    e2scrub_all.service e2scrub_all.timer serial-getty@ttyS0.service serial-getty@ttyAMA0.service \
    sysstat-summary.timer man-db.service man-db.timer hciuart bluetooth bthelper@hci0 bluealsa \
    usbplug nmbd smbd samba-ad-dc autofs netatalk glamor-test rp1-test rpi-netdetect
  echo "Initial setup (phase II) complete."
  touch /etc/rpi-conf.done
else
  echo "Skipping services configuration."
fi

## Run module script if found
if [ ! -e /opt/rpi/modconf/modinit ]; then
  echo "Module script not found."
else
  echo "Running Module Script..."
  chmod 755 /opt/rpi/modconf/modinit
  sh /opt/rpi/modconf/modinit
  rm -rf /opt/rpi/modconf
fi

## Regenerate Update Database
systemctl start man-db.service

echo "Compiling Z-Term COM Service..."
rm -f /usr/bin/ztermcom
/usr/bin/gcc /opt/rpi/ztermcom.c -o /usr/bin/ztermcom
chmod 755 /usr/bin/ztermcom 
chown root:root /usr/bin/ztermcom

## Reset Null Device
rm -f /dev/null
mknod /dev/null c 1 3
chmod 666 /dev/null

## Reset Log Files
rm -f /var/log/lastlog; touch /var/log/lastlog
rm -f /var/log/faillog; touch /var/log/faillog
rm -f /var/log/btmp; touch /var/log/btmp
rm -f /var/log/wtmp; touch /var/log/wtmp
rm -f /root/.xsession-errors; touch /root/.xsession-errors
chmod -R 644 /var/log/wtmp /var/log/btmp /var/log/lastlog /var/log/faillog /root/.xsession-errors
chown -R root:utmp /var/log/wtmp /var/log/btmp /var/log/lastlog /var/log/faillog
chown -R root:root /root/.xsession-errors
rm -f /home/pi/.xsession-errors; touch /home/pi/.xsession-errors
rm -f /var/log/Xorg.0.log.old; touch /var/log/Xorg.0.log.old
rm -f /var/log/Xorg.0.log; touch /var/log/Xorg.0.log
chmod -R 777 /var/log/Xorg.0.log /var/log/Xorg.0.log.old
chmod -R 644 /home/pi/.xsession-errors
chown -R pi:pi /var/log/Xorg.0.log /var/log/Xorg.0.log.old /home/pi/.xsession-errors

## Execute Permissions
chmod -R 755 /opt/rpi
chown -R root:root /opt/rpi

## Autologin as Pi
cp -f $BIN/autologin.conf /etc/systemd/system/getty@tty1.service.d/
chmod 644 /etc/systemd/system/getty@tty1.service.d/autologin.conf
chown root:root /etc/systemd/system/getty@tty1.service.d/autologin.conf

## Remove First Boot Wizard
systemctl stop userconfig
systemctl disable userconfig
systemctl mask userconfig
userdel -f -r rpi-first-boot-wizard
rm -f /etc/sudoers.d/010_wiz-nopasswd
rm -f /etc/systemd/system/getty@tty1.service.d/raspi-config-override.conf
rm -f /etc/xdg/autostart/tracker-miner-fs-3.desktop
rm -f /etc/ssh/sshd_config.d/rename_user.conf
rm -f /etc/xdg/autostart/piwiz.desktop
rm -f /var/lib/userconf-pi/autologin

## Remove Installer Files
rm -rf /opt/rpi/config
rm -rf /opt/rpi/nodeopc
rm -f /opt/rpi/pythproc
rm -f /etc/dnsmasq.conf
rm -f /opt/rpi/effects/pythproc
rm -f /etc/preinit

## Clean systemd logs
journalctl --flush --rotate
journalctl -m --vacuum-time=300s

echo ""
echo "Configuration Complete."
exit

