#!/bin/bash
## Raspberry Pi ProOS Server Setup Script v10.0
## RUN 1st, then Module Installer

# Core Path
BIN=/opt/rpi/config
# Import Hostname
NEWHOST=`cat $BIN/hostname`
# Import Module Name
MODNAME=`cat /opt/rpi/modconf/brand.txt`
## Detect Pi Model
CPUTYPE=$(tr -d '\0' < /sys/firmware/devicetree/base/model)

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
if [ "${OSVER}" = "buster" ] || [ "${OSVER}" = "bullseye" ]; then
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

## Stop RPi Services
systemctl stop rpi-*

###################################################
### Initial configuration #########################
if [ ! -e /etc/rpi-conf.done ]; then
echo "*"
echo "Resettings to defaults..."
echo "*"

## Re-install Manual Sources
REINSTALL="no"
if [ -e /etc/rpi-reinitsource.done ]; then
  echo "Reinstalling manually installed packages..."  
  rm -f /etc/rpi-reinitsource.done
  REINSTALL="yes"
fi

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

## Node.js APT Key
curl --silent -L https://deb.nodesource.com/gpgkey/nodesource.gpg.key | \
  gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --import -

## Custom Source List
if [ "${OSVER}" = "buster" ]; then
  cp -f $BIN/rpi-apt.buster /etc/apt/sources.list.d/rpi-apt.list
  chmod 644 /etc/apt/sources.list.d/rpi-apt.list
  chown root:root /etc/apt/sources.list.d/rpi-apt.list
fi
if [ "${OSVER}" = "bullseye" ]; then
  cp -f $BIN/rpi-apt.bullseye /etc/apt/sources.list.d/rpi-apt.list
  chmod 644 /etc/apt/sources.list.d/rpi-apt.list
  chown root:root /etc/apt/sources.list.d/rpi-apt.list  
fi

## Set boot partition to read/write
mount -o remount,rw /boot

## Update Sources
apt-get -y update --allow-releaseinfo-change

## Essential Packages
apt-get install -y --no-upgrade --ignore-missing locales console-setup \
 aptitude libnss-mdns usbutils zsync v4l-utils libpq5 htop lsb-release \
 avahi-daemon avahi-discover avahi-utils hostapd dnsmasq unzip wget bc \
 rsync screen parallel sudo sed nano curl insserv wireless-regdb wireless-tools \
 uuid-runtime mpg321 mpv mplayer espeak tightvncserver iptables open-cobol \
 iw crda firmware-brcm80211 wpasupplicant dirmngr autofs triggerhappy apt-utils \
 build-essential git autoconf make libtool binutils i2c-tools cmake yasm \
 libmariadb3 texi2html socat nmap autoconf automake pkg-config \
 keyboard-configuration ncftp
 
## Developer Packages 
apt-get install -y --no-upgrade --ignore-missing libgtk2.0-dev libbluetooth3 libbluetooth-dev \
 libavfilter-dev libavdevice-dev libavcodec-dev libavc1394-dev libatlas-base-dev libusb-1.0-0-dev \
 libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev libdbus-glib-1-dev \
 libass-dev libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libssl-dev \
 libva-dev libvdpau-dev libvorbis-dev libx11-dev libxext-dev libxfixes-dev \
 libjack-jackd2-dev portaudio19-dev libffi-dev libxslt1-dev libxml2-dev sqlite3 \
 libxml2-dev libxslt1-dev portaudio19-dev libffi-dev zlib1g-dev libdbus-1-dev

 ## AV Codecs Support
apt-get install -y --no-upgrade --ignore-missing libupnp-dev
apt-get remove -y --purge libgstreamer0.10-dev
apt-get install -y --no-upgrade --ignore-missing libgstreamer1.0-dev gstreamer1.0-plugins-base \
 libx264-dev x264 ffmpeg libswscale-dev libavformat-dev libavcodec-dev \
 gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly \
 gstreamer1.0-tools libgstreamer-plugins-base1.0-0 \
 gstreamer1.0-alsa gstreamer1.0-pulseaudio \
 gstreamer1.0-omx gstreamer1.0-libav

## EGL hardware video decoding libraries
if [ ! -e /usr/lib/arm-linux-gnueabihf/libbrcmEGL.so ]; then
  cd /usr/lib/arm-linux-gnueabihf
  curl -sSfLO 'https://raw.githubusercontent.com/raspberrypi/firmware/master/opt/vc/lib/libbrcmEGL.so'
  curl -sSfLO 'https://raw.githubusercontent.com/raspberrypi/firmware/master/opt/vc/lib/libbrcmGLESv2.so'
  curl -sSfLO 'https://raw.githubusercontent.com/raspberrypi/firmware/master/opt/vc/lib/libopenmaxil.so'
  cd $BIN
fi

## Install X11 and X Programs
apt-get install -y --no-upgrade --ignore-missing xserver-xorg xorg \
 x11-common x11-apps xserver-xorg-input-evdev xvfb \
 libxext6 libxtst6 lxde-core libatlas-base-dev x11-common \
 synaptic lxterminal xprintidle xdotool wmctrl

## Install Chromium
apt-mark unhold chromium-browser chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra
apt-get install -y --no-upgrade --ignore-missing chromium-browser chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra

## Disable Swap
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt-get -y remove --purge dphys-swapfile

## Perl Support
if [ "${OSVER}" = "buster" ]; then
  apt-get install -y --no-upgrade --ignore-missing perl perl-modules
fi
if [ "${OSVER}" = "bullseye" ]; then
  apt-get install -y --no-upgrade --ignore-missing perl perl-modules-5.32
fi

## CPU Specific Packages
if [ "$CPUTYPE" = "Raspberry Pi Zero W Rev 1.1" ]; then
  echo "Pi Zero detected, not installing rclone."
  echo "Removing Java, Arduino, Node.js Support..."
  apt-get remove -y ca-certificates-java default-jre-headless default-jre \
   openjdk-11-jre nodejs arduino avrdude 
else
  echo "ARMv7 CPU detected, installing Java, Arduino, Node.js..."
  ## Note: Tested Node.js version 14.17.1
  apt-get install -y --no-upgrade --ignore-missing nodejs arduino avrdude openjdk-11-jre
  ## Cloud Drive Support
  echo "Installing rclone..."
  apt-get install -y --no-upgrade fuse
  if [ "$REINSTALL" = "yes" ]; then
    rm -f /usr/bin/rclone
  fi 
  if [ ! -e /usr/bin/rclone ]; then
    ## Newest Version
    #curl https://rclone.org/install.sh | sudo bash
    ## 1.58 Version
    dpkg -i /opt/rpi/pkgs/rclone-v1.58.0-linux-arm-v7.deb
    rclone --version
    cd $BIN
  fi
fi

## Python Libraries
apt-get install -y --no-upgrade --ignore-missing net-tools python python3 python3-setuptools \
 python3-pip python3-dev python3-pygame python3-venv python3-gpiozero
pip3 install --disable-pip-version-check setuptools wheel pyserial xmodem RPi.GPIO \
 ipython pssh PyAudio dam1021 virtualenv virtualenvwrapper numpy

## Light Web Server
apt-get install -y --no-upgrade --ignore-missing lighttpd php-common php-cgi php php-mysql
chown www-data:www-data /var/www
chmod 775 /var/www
usermod -a -G www-data pi
mkdir -p /var/www/html
chmod -R 777 /var/www/html
chown -R www-data:www-data /var/www/html

## USB File Service
apt-get install -y --no-upgrade --ignore-missing samba samba-common-bin samba-libs usbmount pmount 
chmod 777 /media
chmod 777 /media/usb*
chown root:root /media/usb*

## Audio Support
apt-get install -y --no-upgrade --ignore-missing alsa-base alsa-utils mpg321 lame sox \
 libasound2 libupnp6 libexpat1 libconfig-dev djmount libexpat1 libsox-dev libsoup2.4-dev \
 libimage-exiftool-perl libcurl4 libsoup2.4-1 libao-dev libglib2.0-dev libreadline-dev \
 xmltoman libsoxr-dev libsndfile1-dev libpulse-dev libavahi-client-dev libssl-dev \
 libdaemon-dev libpopt-dev libconfig-dev libdaemon-dev libpopt-dev \
 libjson-glib-1.0-0 libjson-glib-dev libao-common libasound2-dev \
 xxd libplist-dev libsodium-dev libavutil-dev uuid-dev libgcrypt-dev

## Bluetooth Support
apt-get install -y --no-upgrade --ignore-missing bluetooth pi-bluetooth bluez bluez-tools

## Bluetooth Audio Support
if [ "${OSVER}" = "buster" ]; then
  apt-get install -y --no-upgrade --ignore-missing bluealsa
fi
if [ "${OSVER}" = "bullseye" ]; then
  if [ ! -e /usr/bin/bluealsa-aplay ]; then
    ## Prerequisites
    apt-get install -y --no-upgrade --ignore-missing dh-autoreconf libortp-dev libusb-dev \
     libudev-dev libical-dev libsbc1 libsbc-dev libdbus-1-dev
    ## Compile FDK AAC from source
    git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
    cd fdk-aac
    autoreconf -fiv
    ./configure --enable-shared --enable-static
    make
    make install
    make distclean
    ## Compile BlueALSA from source
    git clone https://github.com/Arkq/bluez-alsa.git
    cd bluez-alsa/
    autoreconf --install
    mkdir build && cd build
    ../configure --enable-aac --enable-ofono
    make && make install
    cd $BIN
  fi
fi

## OMX-Player
if [ "$REINSTALL" = "yes" ]; then
  rm -f /usr/bin/omxplayer
fi
if [ ! -e /usr/bin/omxplayer ]; then
  dpkg -i /opt/rpi/pkgs/omxplayer_20190723_armhf.deb
fi

## Pi 3 Ethernet LED Control 
if [ "$REINSTALL" = "yes" ]; then
  rm -f /usr/bin/lan951x-led-ctl
fi
if [ ! -e /usr/bin/lan951x-led-ctl ]; then
  cd /opt/rpi/pkgs/lan951x-led-ctl-master
  make
  cp -v lan951x-led-ctl /usr/bin/
  cd $BIN
fi

## AirPlay 1 Support
#apt-get install -y --no-upgrade --ignore-missing shairport-sync

## AirPlay 2 Support
if [ "$REINSTALL" = "yes" ]; then
  rm -f /usr/local/bin/shairport-sync
fi
if [ ! -e /usr/local/bin/shairport-sync ]; then
  apt-get remove -y shairport-sync
  rm -f /lib/systemd/system/nqptp.service
  git clone https://github.com/mikebrady/nqptp.git
  cd nqptp
  autoreconf -fi
  ./configure --with-systemd-startup
  make
  make install
  cd -
  #systemctl start nqptp
  git clone https://github.com/mikebrady/shairport-sync.git
  cd shairport-sync
  git checkout development
  autoreconf -fi
  ./configure --sysconfdir=/etc --with-alsa \
    --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2
  make -j
  make install
  cd -
  ln -sf /usr/local/bin/shairport-sync /usr/bin/shairport-sync
fi

## Camera Motion Server
if [ "${OSVER}" = "buster" ]; then
  if [ "$REINSTALL" = "yes" ]; then
    rm -f /usr/bin/motion
  fi
  if [ ! -e /usr/bin/motion ]; then
    apt-get install -y --no-upgrade --ignore-missing libmicrohttpd12
    dpkg -i /opt/rpi/pkgs/pi_buster_motion_4.3.2-1_armhf.deb
    systemctl stop motion
  fi
fi
if [ "${OSVER}" = "bullseye" ]; then
  apt-get install -y --no-upgrade --ignore-missing motion
fi
groupadd motion
useradd motion -g motion --shell /bin/false
groupmod -g 1005 motion
usermod -u 1005 motion

## Remove Conflicts ***
apt-get remove --purge -y cron anacron logrotate fake-hwclock ntp udhcpd usbmuxd
apt-get remove --purge -y exim4 exim4-base exim4-config exim4-daemon-light udisks2 \
  tigervnc-common tigervnc-standalone-server iptables-persistent bridge-utils vlc ntfs-3g \
  lxlock xscreensaver xscreensaver-data gvfs gvfs-backends vnc4server light-locker libudisks2-0 \
  desktop-file-utils exfat-fuse exfat-utils gdisk gnome-mime-data wolfram-engine libssl-doc \
  libatasmart4 libavahi-glib1 gvfs-common gvfs-daemons gvfs-libs mpd mpc
apt-get -y autoremove
dpkg -l | grep unattended-upgrades
dpkg -r unattended-upgrades
rm -rf /var/log/exim4
rm -rf /etc/cron.*

## Install Replacement Logger
apt-get install -y --no-upgrade --ignore-missing busybox-syslogd
echo "Run command 'logread' to check system logs"
dpkg --purge rsyslog
rm -f /var/log/messages
rm -f /var/log/syslog

## Delete custom services
rm -fvr /etc/systemd/system/rpi-*

## Reset hotspot configuration
cp -f $BIN/hostapd.conf /etc/hostapd
chmod 644 /etc/hostapd/hostapd.conf
chown root:root /etc/hostapd/hostapd.conf
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
  echo "Skipping module modification."
else
  ## Set module name to hotspot config
  sed -i "s/RaspberryPi/$MODNAME/g" /etc/hostapd/hostapd.conf
fi

## Reset LED configuration
rm -f /opt/rpi/remotes/leds
rm -f /tmp/global-fc.lock

## Set bootloader RO
mount -o remount,ro /boot

echo "Phase I setup complete."
fi ###### END OF SUB-SCRIPT #######################
###################################################

###################################################
########## Install System Configuration ###########
echo "Installing system configuration."

## Boot partition read-write
mount -o remount,rw /boot

## SSH will be enabled by systemd, do not use this file
rm -f /boot/ssh
## Delete flags, return to default
rm -f /boot/ap-bridge.enable
rm -f /boot/apd-routed.enable
rm -f /boot/apd.enable

## Default Boot Config
cp -f $BIN/config.txt /boot/

## Pi Zero W 2 Support
if [ ! -e /boot/bcm2710-rpi-zero-2.dtb ]; then
  echo "Copying Pi Zero W 2 ROM file to boot partition."
  cp -f /opt/rpi/pkgs/bcm2710-rpi-zero-2.dtb /boot/
fi

## OverlayFS Configuration
cp -f $BIN/fstab /etc
chmod 644 /etc/fstab
chown root:root /etc/fstab
cp -f $BIN/cmdline.ro /boot/
chmod 644 /boot/cmdline.ro
chown root:root /boot/cmdline.ro
cp -f $BIN/cmdline.rw /boot/
chmod 644 /boot/cmdline.rw
chown root:root /boot/cmdline.rw
cp -f $BIN/cmdline.rw /boot/cmdline.txt
chmod 644 /boot/cmdline.txt
chown root:root /boot/cmdline.txt
rm -f /sbin/overlayRoot.sh

## WiFi Configuration
raspi-config nonint do_wifi_country US
cp -f $BIN/wpa.empty /etc/wpa_supplicant/wpa_supplicant.empty
chmod 644 /etc/wpa_supplicant/wpa_supplicant.empty
chown root:root /etc/wpa_supplicant/wpa_supplicant.empty
if [ ! -e /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  echo "WiFi config not installed resetting."
  cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
  chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
  chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
fi
if [ ! -e /boot/wpa.conf ]; then
  echo "Copying Wi-Fi settings to boot partition."
  cp -f /etc/wpa_supplicant/wpa_supplicant.conf /boot/wpa.conf
fi

## Boot partition read-only
mount -o remount,ro /boot

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
cp -f $BIN/sysctl.conf /etc
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

## Journal Configuration
cp -f $BIN/journald.conf /etc/systemd
chmod 644 /etc/systemd/journald.conf
chown root:root /etc/systemd/journald.conf

## Supress Logging (Random Number Generator)
if [ "${OSVER}" = "bullseye" ]; then
  sed -i 's/RNGDOPTIONS=.*/RNGDOPTIONS=--stats-interval=0/' /etc/init.d/rng-tools-debian
fi

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
cp -fvr $BIN/systemd/* /etc/systemd/system/
chmod -fR 644 /etc/systemd/system/*.timer
chown -fR root:root /etc/systemd/system/*.timer
chmod -fR 644 /etc/systemd/system/*.service
chown -fR root:root /etc/systemd/system/*.service

## Startup Scripts (critical)
cp -f $BIN/netmode.sh /etc
chmod 755 /etc/netmode.sh
chown root:root /etc/netmode.sh
cp -f $BIN/preinit.sh /etc
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
cp -f $BIN/lighttpd-noredir.conf /etc/lighttpd/
chmod 644 /etc/lighttpd/lighttpd-noredir.conf
chown root:root /etc/lighttpd/lighttpd-noredir.conf
cp -f $BIN/lighttpd-redirect.conf /etc/lighttpd/lighttpd.conf
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
mv -f $BIN/html/* /var/www/html
chmod -R 775 /var/www/html
chown -R www-data:www-data /var/www/html
mkdir -p /var/www/sessions
chmod -R g+rx /var/www/sessions
chown -R www-data:www-data /var/www/sessions
mkdir -p /var/www/uploads
chmod -R g+rx /var/www/uploads
chown -R www-data:www-data /var/www/uploads

## Set hostname to configurations
if [ ! -e $BIN/hostname ]; then
echo "Skipping hostname modification."
else
## Set module name to light server
sed -i "s/raspberrypi/$NEWHOST/g" /var/www/html/index.php
sed -i "s/raspberrypi/$NEWHOST/g" /var/www/html/picker.html
## Set hostname to unified server
sed -i "s/raspberrypi/$NEWHOST/g" /opt/rpi/manager/client.html
fi
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
echo "Skipping module modification."
else
## Set module name to light server
sed -i "s/RaspberryPi/$MODNAME/g" /var/www/html/index.php
## Set module name to unified server
sed -i "s/RaspberryPi/$MODNAME/g" /opt/rpi/manager/client.html
fi

## WWW Permissions (Network Web UI)
rm -f /etc/sudoers.d/www-perms
rm -f /etc/sudoers.d/www-nopasswd
rm -f /etc/sudoers.d/www-mod-nopasswd
sh -c "touch /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/ifdown wlan0\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/ifup wlan0\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/bin/cat /etc/wpa_supplicant/wpa_supplicant.conf\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant.conf\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli scan_results\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan0 scan\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan0 reconfigure\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/shutdown -h now\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/shutdown -r now\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/sbin/reboot\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init overtemp\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init temp\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init client\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init cpwifi\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init bridge\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/init apd\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/main*\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/leds\" >> /etc/sudoers.d/www-perms"
sh -c "echo \"www-data ALL=(ALL) NOPASSWD:/opt/rpi/xmit\" >> /etc/sudoers.d/www-perms"
chown root:root /etc/sudoers.d/www-perms
chmod u=rwx,g=rx,o=rx /etc/sudoers.d/www-perms
chmod u=r,g=r,o= /etc/sudoers.d/www-perms

## Nobody User Permissions (THD Hotkeys)
rm -f /etc/sudoers.d/nobody-perms
sh -c "touch /etc/sudoers.d/nobody-perms"
sh -c "echo \"nobody ALL=(ALL) NOPASSWD:/opt/rpi/main*\" >> /etc/sudoers.d/nobody-perms"
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
addgroup pi sudo

## X Server Configuration
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
cp -f $BIN/bluealsa.service  /lib/systemd/system/
chown root:root /lib/systemd/system/bluealsa.service
chmod 644 /lib/systemd/system/bluealsa.service
mkdir -p /etc/systemd/system/bluealsa.service.d
cp -f $BIN/bluealsa-override.conf /etc/systemd/system/bluealsa.service.d/override.conf
chown root:root /etc/systemd/system/bluealsa.service.d/override.conf
chmod 644 /etc/systemd/system/bluealsa.service.d/override.conf
# Bluetooth Udev Script
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

## DHCP Configuration
cp -f $BIN/dhcpcd.conf /etc
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
cp -f $BIN/dhcpcd.conf /etc/dhcpcd.net
chmod 644 /etc/dhcpcd.net
chown root:root /etc/dhcpcd.net
cp -f $BIN/dhcpcd.bridge /etc/dhcpcd.bridge
chmod 644 /etc/dhcpcd.bridge
chown root:root /etc/dhcpcd.bridge
rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf

# Hotspot Configuration
cp -f $BIN/dhcpcd.apd /etc/dhcpcd.apd
chmod 644 /etc/dhcpcd.apd
chown root:root /etc/dhcpcd.apd
cp -f $BIN/dnsmasq.nodns /etc/
chmod 644 /etc/dnsmasq.nodns
chown root:root /etc/dnsmasq.nodns
cp -f $BIN/dnsmasq.routed /etc/
chmod 644 /etc/dnsmasq.routed
chown root:root /etc/dnsmasq.routed
cp -f $BIN/dnsmasq.bridge /etc/
chmod 644 /etc/dnsmasq.bridge
chown root:root /etc/dnsmasq.bridge
cp -f $BIN/dnsmasq.hosts /etc/
chmod 644 /etc/dnsmasq.hosts
chown root:root /etc/dnsmasq.hosts
cp -f $BIN/hostapd.conf /etc/hostapd/hostapd.conf
chmod 644 /etc/hostapd/hostapd.conf
chown root:root /etc/hostapd/hostapd.conf
rm -f /etc/init.d/hostapd
rm -f /etc/default/hostapd
rm -f /etc/hostapd/ifupdown.sh
rm -f /etc/network/if-pre-up.d/hostapd
touch /etc/default/hostapd

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
## Set hostname to DNS configuration
sed -i "s/raspberrypi/$NEWHOST/g" /etc/dnsmasq.routed
sed -i "s/raspberrypi/$NEWHOST/g" /etc/dnsmasq.hosts
fi
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
echo "Skipping module modification."
else
## Set module name to default hotspot config
sed -i "s/RaspberryPi/$MODNAME/g" /etc/hostapd/hostapd.conf
echo "Hostname is $NEWHOST"
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

## PulseAudio Configuration
cp -f $BIN/system.pa /etc/pulse
chmod 644 /etc/pulse/system.pa
chown root:root /etc/pulse/system.pa
cp -f $BIN/client.conf /etc/pulse
chmod 644 /etc/pulse/client.conf
chown root:root /etc/pulse/client.conf
rm -r /home/pi/.config/pulse
mkdir -p /home/pi/.config/pulse
cp -f $BIN/client.conf /home/pi/.config/pulse/
chmod 644 /home/pi/.config/pulse/client.conf
chown pi:pi /home/pi/.config/pulse/client.conf

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

## USB Automount Configuration
cp -f $BIN/usbmount.conf /etc/usbmount
chmod 644 /etc/usbmount/usbmount.conf
chown root:root /etc/usbmount/usbmount.conf
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

## Set web server default theme
/opt/rpi/init dred

## Compile COBOL Programs
cobc -x --free /opt/rpi/effects/colorscan.cbl -o /opt/rpi/effects/colorscan

## Services Configuration
systemctl daemon-reload
if [ ! -e /etc/rpi-conf.done ]; then
## Active on startup
systemctl enable ssh avahi-daemon systemd-timesyncd systemd-time-wait-sync
systemctl enable proinit rpi-cleanup.timer
systemctl unmask systemd-journald
## Disabled on startup
systemctl unmask hostapd
systemctl disable hostapd dhcpcd networking wpa_supplicant keyboard-setup \
plymouth sysstat lightdm apache2 lighttpd dnsmasq apt-daily.service wifiswitch plymouth-log \
apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer sysstat-collect.timer motion \
sysstat-summary.timer man-db.service man-db.timer hciuart bluetooth usbplug nmbd smbd autofs \
shairport-sync nqptp triggerhappy.service triggerhappy.socket e2scrub_all.service e2scrub_all.timer
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

## Re-create Null Device
rm -f /dev/null
mknod /dev/null c 1 3
chmod 666 /dev/null

## Re-create Log Files (root)
rm -f /var/log/lastlog
rm -f /var/log/faillog
rm -f /var/log/btmp
rm -f /var/log/wtmp
rm -f /root/.xsession-errors
rm -f /root/.bash_history
echo -n>/var/log/lastlog
echo -n>/var/log/faillog
echo -n>/var/log/btmp
echo -n>/var/log/wtmp
echo -n>/root/.xsession-errors
echo -n>/root/.bash_history
chmod -R 644 /var/log/wtmp /var/log/btmp /var/log/lastlog /var/log/faillog /root/.xsession-errors /root/.bash_history
chown -R root:utmp /var/log/wtmp /var/log/btmp /var/log/lastlog /var/log/faillog
chown -R root:root /root/.xsession-errors /root/.bash_history

## Re-create Log Files (pi)
rm -f /home/pi/.xsession-errors
rm -f /home/pi/.bash_history
rm -f /var/log/Xorg.0.log.old
rm -f /var/log/Xorg.0.log
echo -n>/home/pi/.xsession-errors
echo -n>/home/pi/.bash_history
echo -n>/var/log/Xorg.0.log.old
echo -n>/var/log/Xorg.0.log
chmod -R 777 /var/log/Xorg.0.log /var/log/Xorg.0.log.old
chmod -R 644 /home/pi/.xsession-errors /home/pi/.bash_history
chown -R pi:pi /var/log/Xorg.0.log /var/log/Xorg.0.log.old /home/pi/.xsession-errors /home/pi/.bash_history

## File Permissions
chmod -R 755 /opt/rpi
chown -R root:root /opt/rpi

## Remove Installer Files
rm -rf /opt/rpi/config
rm -rf /opt/rpi/nodeopc
rm -f /opt/rpi/pythproc 
rm -f /opt/rpi/effects/pythproc
rm -f /etc/preinit

## Clean systemd logs
journalctl --flush --rotate
journalctl -m --vacuum-time=1s

echo ""
echo "Configuration Complete."
exit

