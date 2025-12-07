#!/bin/bash
## Raspberry Pi ProOS Server Setup Script v13
## run this 1st, then module installer

# Core Path
BIN=/opt/rpi/config
# Import Hostname
NEWHOST=`cat $BIN/hostname`
# Import Module Name
MODNAME=`cat /opt/rpi/modconf/brand.txt`
## Installer Command Line Arguments
APTARGS="install -y --no-upgrade --ignore-missing"

echo "Installing on $NEWHOST..." 

## Pre-installation checks
if [ ! -e "/opt/rpi/init" ]; then
  echo "Core components missing."
  exit
else
  echo "Core components integrity verified."
fi
if [ ! -e "/boot/config.txt" ]; then
  echo "Not running on a Pi !!"
  exit
else
  echo "Raspberry Pi detected."
fi
OSVER="$(sed -n 's|^VERSION=".*(\(.*\))"|\1|p' /etc/os-release)"
if [ "${OSVER}" = "trixie" ] || [ "${OSVER}" = "bullseye" ]; then
  echo "Debian ${OSVER} detected."
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
if [ ! -e "/etc/rpi-conf.done" ]; then
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
apt-get $APTARGS locales console-setup aptitude libnss-mdns libnss3-tools usbutils \
 zsync libpq5 htop lsb-release avahi-daemon avahi-utils hostapd dnsmasq-base pkg-config \
 wget bc uuid-runtime iptables jq rsync screen parallel sudo sed nano curl wireless-regdb \
 wireless-tools overlayroot iw wpasupplicant dirmngr autofs triggerhappy default-jre-headless \
 build-essential autoconf make libtool binutils i2c-tools cmake yasm minicom rclone unzip \
 cryptsetup cryptsetup-bin texi2html socat nmap autoconf gnucobol4 avrdude arduino \
 automake cifs-utils neofetch fuse nodejs apt-utils sqlite3 shairport-sync \
 bluetooth pi-bluetooth bluez bluez-tools bluez-alsa-utils libbluetooth3 \
 samba samba-common-bin samba-libs alsa-base alsa-utils mpg321 lame sox \
 libupnp6 libexpat1 libexpat1 libimage-exiftool-perl xmltoman \
 libjson-glib-1.0-0 libao-common xxd 

## AV Codecs Support
apt-get $APTARGS gstreamer1.0-plugins-base ffmpeg gstreamer1.0-plugins-good \
 gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-libav x264 ffmpeg \
 libgstreamer-plugins-base1.0-0 gstreamer1.0-alsa v4l-utils

## Development Support
apt-get $APTARGS libgtk2.0-dev libbluetooth-dev libpng-dev libtiff-dev \
 libjasper-dev libavfilter-dev libavdevice-dev libavc1394-dev libusb-1.0-0-dev \
 libjack-jackd2-dev portaudio19-dev libffi-dev libass-dev libfreetype6-dev libsdl1.2-dev \
 libtheora-dev libssl-dev libx11-dev libxml2-dev libxslt1-dev zlib1g-dev libdbus-1-dev \
 libva-dev libvdpau-dev libvorbis-dev libxext-dev libxfixes-dev libdbus-glib-1-dev libpopt-dev \
 libjpeg-dev libgstreamer1.0-dev libupnp-dev libx264-dev libswscale-dev libavformat-dev \
 libglib2.0-dev libavutil-dev uuid-dev libsndfile1-dev libpulse-dev libavahi-client-dev \
 libsoxr-dev libao-dev libreadline-dev libsoup2.4-dev libgcrypt-dev libconfig-dev \
 libjson-glib-dev libplist-dev libsodium-dev libdaemon-dev

## Install X11
apt-get $APTARGS xserver-xorg xorg x11-common x11-common xserver-xorg-input-evdev \
 xserver-xorg-legacy xvfb libxext6 libxtst6 xprintidle xdotool wmctrl openbox gpicview \
 lxde-common lxsession pcmanfm lxterminal xfce4-panel xfce4-whiskermenu-plugin

## Disable Swap
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt-get -y remove --purge dphys-swapfile

## Python Libraries
apt-get $APTARGS net-tools python3 python3-pip python3-venv python3-rpi.gpio python3-gpiozero

## Light Web Server
apt-get $APTARGS lighttpd php-common php-cgi php php-mysql perl perl-modules
chown www-data:www-data /var/www
chmod 775 /var/www
usermod -a -G www-data pi
mkdir -p /var/www/html
chmod -R 777 /var/www/html
chown -R www-data:www-data /var/www/html

## Camera Motion Server
apt-get $APTARGS motion libmicrohttpd12t64
groupadd motion
useradd motion -g motion --shell /bin/false
groupmod -g 1005 motion
usermod -u 1005 motion

## v5.0 Random Number Generator
apt-get $APTARGS rng-tools5

## Install Replacement Logger
apt-get $APTARGS busybox-syslogd
echo "Run command 'logread' to check system logs"
dpkg --purge rsyslog
rm -f /var/log/messages
rm -f /var/log/syslog

## Remove Packages 
apt-get remove --purge -y cron anacron logrotate fake-hwclock ntp udhcpd usbmuxd pmount usbmount \
  cups cups-client cups-common cups-core-drivers cups-daemon cups-filters cups-filters-core-drivers \
  cups-ipp-utils cups-ppdc cups-server-common upower exim4 exim4-base exim4-config exim4-daemon-light \
  iptables-persistent bridge-utils ntfs-3g lxlock xscreensaver xscreensaver-data gvfs gvfs-backends \
  libudisks2-0 dnsmasq wolfram-engine libssl-doc libatasmart4 libavahi-glib1 rng-tools rng-tools-debian \
  piwiz plymouth plymouth-label plymouth-themes pulseaudio pulseaudio-utils pavucontrol pipewire pipewire-bin \
  tracker-extract tracker-miner-fs cloud-guest-utils cloud-init rpi-cloud-init-mods rpi-connect-lite rpi-swap \
  rpi-systemd-config systemd-zram-generator apparmor
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
if [ ! -e "/etc/rpi-bootro.done" ]; then
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
if [ ! -e "/etc/systemd/system/proinit.service" ]; then
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
if [ ! -e "/opt/rpi/modconf/brand.txt" ]; then
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
if [ -e "/lib/systemd/system/phpsessionclean.service" ]; then
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
chmod -R 775 /var/www/html
chown -R www-data:www-data /var/www/html
mkdir -p /var/www/sessions
chmod -R g+rx /var/www/sessions
chown -R www-data:www-data /var/www/sessions
mkdir -p /var/www/uploads
chmod -R g+rx /var/www/uploads
chown -R www-data:www-data /var/www/uploads

if [ ! -e "/opt/rpi/modconf/brand.txt" ]; then
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
if [ ! -e "/opt/rpi/modconf/brand.txt" ]; then
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
if [ ! -e "$BIN/hostname" ]; then
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
if [ ! -e "/var/lib/alsa/asound.state" ]; then
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
if [ ! -e "/opt/rpi/modconf/brand.txt" ]; then
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
if [ ! -e "/etc/rpi-conf.done" ]; then
  ## Active on startup
  systemctl unmask NetworkManager-wait-online NetworkManager-dispatcher \
   NetworkManager ModemManager systemd-journald hostapd motion
  systemctl enable ssh avahi-daemon proinit rpi-cleanup.timer \
   systemd-timesyncd systemd-time-wait-sync NetworkManager ModemManager \
   NetworkManager-wait-online NetworkManager-dispatcher
  ## Disabled on startup
  systemctl stop triggerhappy.socket
  systemctl disable apt-daily-upgrade.timer apt-daily.timer e2scrub_all.timer \
   sysstat-summary.timer triggerhappy.socket man-db.timer
  systemctl disable apt-daily-upgrade.service apt-daily.service \
   e2scrub_all.service e2scrub_reap.service hostapd keyboard-setup sysstat \
   lighttpd wifiswitch motion serial-getty@ttyS0.service man-db.service \
   serial-getty@ttyAMA0.service winbind hciuart bluetooth bthelper@hci0 \
   bluealsa-aplay usbplug nmbd smbd samba-ad-dc autofs triggerhappy \
   sshswitch nfs-blkmap
  echo "Initial setup (phase II) complete."
  touch /etc/rpi-conf.done
else
  echo "Skipping services configuration."
fi

## Run module script if found
if [ ! -e "/opt/rpi/modconf/modinit" ]; then
  echo "Module script not found."
else
  echo "Running Module Script..."
  chmod 755 /opt/rpi/modconf/modinit
  sh /opt/rpi/modconf/modinit
  rm -rf /opt/rpi/modconf
fi

## Regenerate Update Database
systemctl start man-db.service

## Z-Term Communication
rm -f /usr/bin/ztermcom
gcc /opt/rpi/ztermcom.c -o /usr/bin/ztermcom
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

## Remove First Boot Wizard
systemctl stop userconfig
systemctl mask userconfig
userdel -f -r rpi-first-boot-wizard
rm -f /etc/sudoers.d/010_wiz-nopasswd
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
apt autoclean
apt clean

## Clean systemd logs
journalctl --flush --rotate
journalctl -m --vacuum-time=300s

echo ""
echo "Configuration Complete."
exit

