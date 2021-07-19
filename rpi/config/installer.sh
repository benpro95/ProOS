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

if [ ! -e /opt/rpi/init ]; then
echo "Core components missing or corrupted."
echo "Rebooting..."
reboot
exit
else
echo "Core components integrity verified."
fi
if [ ! -e /boot/config.txt ]; then
echo "Not running on a Raspberry Pi !!."
echo "Rebooting..."
reboot
exit
else
echo "Raspberry Pi detected."
fi
cd $BIN

echo ""
echo "########### Welcome to ProOS ! ###########"
echo "############ Configurator v10 ############"
echo "######### by Ben Provenzano III ##########"
echo ""

## Turn off LEDs if installed
/opt/rpi/leds stop

###################################################
### Initial Configuration #########################
if [ ! -e /etc/rpi-conf.done ]; then
echo "*"
echo "Resettings to defaults..."
echo "*"

## Set location
cp -f $BIN/locale.gen /etc
chmod 644 /etc/locale.gen
chown root:root /etc/locale.gen
update-locale LANG=en_US.UTF-8
dpkg-reconfigure --frontend=noninteractive locales

## Set time zone
rm -f /etc/timezone
timedatectl set-timezone America/New_York
dpkg-reconfigure -f noninteractive tzdata

## Set keyboard layout
sed -i -e "/XKBLAYOUT=/s/gb/us/" /etc/default/keyboard

## Create pi user
adduser pi
chown -R pi:pi /home/pi
chsh -s /bin/bash pi

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

## Reset network settings
rm -f /etc/netchk.disabled
rm -f /etc/apd-mode.enable
rm -f /etc/apd-nodns.enable

## Reset LED configuration
rm -f /opt/rpi/remotes/leds
rm -f /tmp/global-fc.lock

## Remove LSB scripts
insserv -r bootlogs
insserv -r console-setup

## APT Keys
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

## Custom Source List
cp -f $BIN/rpi-apt.list /etc/apt/sources.list.d/
chmod 644 /etc/apt/sources.list.d/rpi-apt.list
chown root:root /etc/apt/sources.list.d/rpi-apt.list

## Set bootloader RW
mount -o remount,rw /boot

## Update Sources
apt-get -y update --allow-releaseinfo-change

## Essential Packages
apt-get install -y --no-upgrade locales console-setup keyboard-configuration apt-utils \
 aptitude libnss-mdns usbutils zsync perl v4l-utils libmariadb3 libpq5 \
 avahi-daemon avahi-discover avahi-utils hostapd dnsmasq unzip wget htop bc \
 rsync screen parallel sudo sed nano curl insserv wireless-regdb wireless-tools \
 uuid-runtime mpg321 omxplayer libdbus-1-dev libdbus-glib-1-dev python-pyudev \
 iw crda firmware-brcm80211 wpasupplicant dirmngr autofs triggerhappy \
 libbluetooth3 libbluetooth-dev lsb-release \
 perl-modules tightvncserver iptables espeak

## Disable Swap
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt-get -y remove --purge dphys-swapfile

## Install X11
apt-get install -y --no-upgrade xserver-xorg xorg \
 x11-common x11-apps xserver-xorg-input-evdev \
 xdotool libxext6 libxtst6 xvfb lxde-core \
 synaptic medit lxterminal florence libatlas-base-dev
dpkg-reconfigure x11-common

## Developer Support
apt-get install -y --no-upgrade build-essential git
apt-get install -y --no-upgrade autoconf make libtool \
 cmake libgtk2.0-dev binutils i2c-tools g++ gcc\
 libavfilter-dev libavdevice-dev libavcodec-dev libavc1394-dev \
 python-dev python-numpy libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev \
 autoconf automake build-essential libass-dev libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool \
 libva-dev libvdpau-dev libvorbis-dev libx11-dev libxext-dev libxfixes-dev pkg-config texi2html zlib1g-dev yasm \
 libjack-jackd2-dev portaudio19-dev libffi-dev python-dev libxslt-dev libxml2-dev \
 libxml2-dev libxslt1-dev python-dev mpv mplayer vlc portaudio19-dev libffi-dev \
 libssl-dev socat mpg123 nmap libatlas-base-dev

## CPU Specific Packages
if [ "$CPUTYPE" = "Raspberry Pi Zero W Rev 1.1" ]; then
	  ##### Install Node.js from 'pkgs' folder #####
	  NODEVERSION="14.17.1"
	  ## Uncomment to reinstall
    #rm -f /usr/bin/node
    echo "Pi Zero detected."
    if [ ! -e /usr/bin/node ]; then
    tar xvfJ /opt/rpi/pkgs/node-v$NODEVERSION-linux-armv6l.tar.xz -C /opt/rpi/pkgs/
    cd /opt/rpi/pkgs/node-v$NODEVERSION-linux-armv6l/
    cp -vR * /usr/local/
    ln -sf /usr/local/bin/node /usr/bin/node
    rm -rf /opt/rpi/pkgs/node-v$NODEVERSION-linux-armv6l
    cd $BIN
    else
    echo "Node already installed."
    fi
    ln -sf /usr/local/bin/node /usr/bin/nodejs
    ###########################
    echo "Removing Java and Arduino Support..."
    apt-get remove -y arduino default-jre openjdk-11-jre
    apt-get remove -y ca-certificates-java default-jre-headless
else
    echo "Pi 3+ detected."
    apt-get install -y --no-upgrade nodejs
    apt-get install -y --no-upgrade arduino arduino-core avrdude
fi

## Python Libraries
apt-get install -y --no-upgrade net-tools python python-pip python3 python3-setuptools
apt-get install -y --no-upgrade python3-pip python3-dev python3-pygame python3-venv
apt-get install -y --no-upgrade python3-gpiozero
pip install --disable-pip-version-check pip==19.1.1 wheel==0.33.4 ipython==5.8.0 setuptools==41.0.1 virtualenv==16.6.1 \
virtualenvwrapper==4.8.4 pssh==2.3.1 numpy==1.16.2 RPi.GPIO==0.7.0 PyAudio==0.2.11 pyserial==3.5 dam1021==0.4 xmodem==0.4.6
pip3 install --disable-pip-version-check pyserial==3.5

## AV Codecs Support
apt-get install -y --no-upgrade libupnp-dev
apt-get remove -y --purge libgstreamer0.10-dev gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-plugins-ugly
apt-get install -y --no-upgrade libgstreamer1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly \
 libgstreamer1.0-0-dbg gstreamer1.0-tools libgstreamer-plugins-base1.0-0 \
 gstreamer1.0-alsa gstreamer1.0-pulseaudio libx264-dev x264 ffmpeg \
 gstreamer1.0-plugins-bad-dbg gstreamer1.0-omx gstreamer1.0-libav \
 libavcodec-dev libavformat-dev libswscale-dev
 
## OpenCV (disabled)
#apt-get install -y opencv-doc opencv-data libopencv-dev libopencv3.2-java libopencv3.2-jni python-opencv
apt-get remove -y --purge opencv-doc opencv-data libopencv-dev libopencv3.2-java libopencv3.2-jni python-opencv

## Light Web Server
apt-get install -y --no-upgrade lighttpd
apt-get install -y --no-upgrade php-common php-cgi php php-mysql
chown www-data:www-data /var/www
chmod 775 /var/www
usermod -a -G www-data pi
mkdir -p /var/www/html
chmod -R 777 /var/www/html
chown -R www-data:www-data /var/www/html

## USB File Service
apt-get install -y --no-upgrade samba samba-common-bin samba-libs usbmount pmount 
chmod 777 /media
chmod 777 /media/usb*
chown root:root /media/usb*

## FTP Client
apt-get install -y --no-upgrade ncftp

## Bluetooth Support
apt-get install -y --no-upgrade bluetooth pi-bluetooth bluez-tools

## Install Audio Support
apt-get install -y --no-upgrade libasound2 alsa-utils alsa-base mpg321 lame sox \
 sqlite3 libupnp6 libmpdclient2 libexpat1 \
 libexpat1 libimage-exiftool-perl libcurl4 \
 libconfig-dev libjsoncpp0 python-requests djmount \
 libao-dev libglib2.0-dev libjson-glib-1.0-0 libjson-glib-dev libao-common \
 libasound2-dev libreadline-dev libsox-dev libsoup2.4-dev libsoup2.4-1 \
 pulseaudio pulseaudio-module-zeroconf pulseaudio-utils pavucontrol paprefs
chmod -x /usr/bin/start-pulseaudio-x11
gpasswd -a root audio
gpasswd -a pulse audio
gpasswd -a pi audio
gpasswd -a pi pulse-access

## Install Music Player Support
apt-get install -y --no-upgrade mpd mpc
update-rc.d mpd remove
gpasswd -a mpd audio
gpasswd -a mpd pulse-access

## AirPlay Support
apt-get install -y --no-upgrade xmltoman \
 libdaemon-dev libpopt-dev libconfig-dev \
 libasound2-dev \
 libpulse-dev \
 libavahi-client-dev \
 libssl-dev \
 libdaemon-dev libpopt-dev \
 libsoxr-dev libsndfile1-dev \
 shairport-sync

## Wi-Fi Fix (not needed anymore)
##apt-mark unhold firmware-brcm80211
#dpkg -i /opt/rpi/pkgs/firmware-brcm80211_20190114-1+rpt4_all.deb
#apt-mark hold firmware-brcm80211

## Remove Conflicts ***
apt-get remove --purge -y exim4 exim4-base exim4-config exim4-daemon-light 
apt-get remove --purge -y tigervnc-common tigervnc-standalone-server iptables-persistent bridge-utils
apt-get remove --purge -y lxlock xscreensaver xscreensaver-data gvfs gvfs-backends vnc4server light-locker
apt-get remove --purge -y desktop-file-utils exfat-fuse exfat-utils gdisk gnome-mime-data gvfs-common gvfs-daemons gvfs-libs
apt-get remove --purge -y libatasmart4 libavahi-glib1 libbonobo2-0 libbonobo2-common libbonoboui2-0 libbonoboui2-common
apt-get remove --purge -y libssl-doc libudisks2-0 libusbmuxd4 ntfs-3g udisks2 usbmuxd udhcpd wolfram-engine motion
apt-get remove --purge -y cron anacron logrotate fake-hwclock ntp
apt-get remove --purge -y wiringpi
apt-get -y autoremove
dpkg -l | grep unattended-upgrades
dpkg -r unattended-upgrades
rm -rf /var/log/exim4
rm -rf /etc/cron.*

## Install Replacement Logger
apt-get install -y --no-upgrade busybox-syslogd
echo "Run command 'logread' to check system logs"
dpkg --purge rsyslog
rm -f /var/log/messages
rm -f /var/log/syslog

## Set bootloader RO
mount -o remount,ro /boot

echo "Phase I setup complete."
###################################################
else
echo ""  > /dev/null 2>&1
fi ###### END OF SUB-SCRIPT #######################
###################################################

###################################################
########## Install System Configuration ###########
echo "Installing system configuration."

## Boot partition read-write
mount -o remount,rw /boot

## SSH will be enabled by systemd, do not use this file
rm -f /boot/ssh
## Delete flag to disable network bridge mode
rm -f /boot/ap-bridge.enable
## Delete flag to disable auto hotspot
rm -f /boot/autohotspot.off

## Default Boot Config
cp -f $BIN/config.txt /boot/

## OverlayFS Configuration
cp -f $BIN/overlayRoot.sh /sbin
chmod 755 /sbin/overlayRoot.sh
chown root:root /sbin/overlayRoot.sh
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

## WiFi Configuration
cp -f $BIN/wpa.empty /etc/wpa_supplicant/wpa_supplicant.empty
chmod 644 /etc/wpa_supplicant/wpa_supplicant.empty
chown root:root /etc/wpa_supplicant/wpa_supplicant.empty
if [ ! -e /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  echo "WiFi config not installed resetting."
  cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
  chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
  chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
else
  echo ""  > /dev/null 2>&1
fi
if [ ! -e /boot/wpa.conf ]; then
  echo "Copying Wi-Fi settings to boot partition."
  cp -f /etc/wpa_supplicant/wpa_supplicant.conf /boot/wpa.conf
else
  echo ""  > /dev/null 2>&1
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

## Kernel Drivers Configuration
cp -f $BIN/modules /etc
chmod 644 /etc/modules
chown root:root /etc/modules

## Detect if proinit service is installed
if [ ! -e /etc/systemd/system/proinit.service ]; then
  echo "proinit.service not found, resetting services."
  rm -f /etc/rpi-conf.done
else
  echo ""  > /dev/null 2>&1
fi

## Original Services (Restoring Stock Files)
cp -f $BIN/systemd-tmpfiles-clean.service /lib/systemd/system/
chmod -f 644 /lib/systemd/system/systemd-tmpfiles-clean.service
chown -f root:root /lib/systemd/system/systemd-tmpfiles-clean.service
cp -f $BIN/systemd-tmpfiles-setup.service /lib/systemd/system/
chmod -f 644 /lib/systemd/system/systemd-tmpfiles-setup.service
chown -f root:root /lib/systemd/system/systemd-tmpfiles-setup.service

## Replacement / New Services
cp -f $BIN/systemd-udevd.service /lib/systemd/system/
chmod -f 644 /lib/systemd/system/systemd-udevd.service
chown -f root:root /lib/systemd/system/systemd-udevd.service
cp -fvr $BIN/systemd/* /etc/systemd/system/
chmod -fR 644 /etc/systemd/system/*.timer
chown -fR root:root /etc/systemd/system/*.timer
chmod -fR 644 /etc/systemd/system/*.service
chown -fR root:root /etc/systemd/system/*.service

## Startup Script
cp -f $BIN/rc.local /etc
chmod 755 /etc/rc.local
chown root:root /etc/rc.local
cp -f $BIN/preinit /etc
chmod 755 /etc/preinit
chown root:root /etc/preinit
cp -f $BIN/netmode.sh /etc
chmod 755 /etc/netmode.sh
chown root:root /etc/netmode.sh

## ShairPort AirPlay Support
rm -f /etc/init.d/shairport-sync
rm -f /lib/systemd/system/shairport-sync.service
if [ ! -e /opt/rpi/modconf/brand.txt ]; then
echo "Skipping module modification."
else
## ShairPort configuration
sed -i "s/RaspberryPi/$MODNAME/g" /etc/systemd/system/rpi-airplay.service
fi

## LightTPD Configuration
cp -f $BIN/lighttpd.conf /etc/lighttpd
chmod 644 /etc/lighttpd/lighttpd.conf
chown root:root /etc/lighttpd/lighttpd.conf
lighttpd-enable-mod fastcgi fastcgi-php; lighty-enable-mod fastcgi-php
ln -sf /etc/lighttpd/conf-available/10-fastcgi.conf /etc/lighttpd/conf-enabled/
ln -sf /etc/lighttpd/conf-available/15-fastcgi-php.conf /etc/lighttpd/conf-enabled/
ln -sf /usr/share/lighttpd/create-mime.conf.pl /usr/share/lighttpd/create-mime.assign.pl

## PHP Configuration v7.3
cp -rf $BIN/php.cgi.ini /etc/php/7.3/cgi/php.ini
chmod 644 /etc/php/7.3/cgi/php.ini
chown root:root /etc/php/7.3/cgi/php.ini
cp -rf $BIN/php.cli.ini /etc/php/7.3/cli/php.ini
chmod 644 /etc/php/7.3/cli/php.ini
chown root:root /etc/php/7.3/cli/php.ini
chown -R www-data:www-data /var/lib/php
chmod -R g+rx /var/lib/php
if [ ! -e /lib/systemd/system/phpsessionclean.service ]; then
  echo ""  > /dev/null 2>&1
else
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
cp -f $BIN/xautostart /home/pi/.config/lxsession/LXDE/autostart
chmod 755 /home/pi/.config/lxsession/LXDE/autostart
chown pi:pi /home/pi/.config/lxsession/LXDE/autostart

## Bluetooth Configuration
cp -f $BIN/btinput.conf /etc/bluetooth/input.conf
chmod 644 /etc/bluetooth/input.conf
chown root:root /etc/bluetooth/input.conf
cp -f $BIN/btmain.conf /etc/bluetooth/main.conf
chmod 644 /etc/bluetooth/main.conf
chown root:root /etc/bluetooth/main.conf

## Udev Network Rules
cp -f $BIN/70-persistent-net.rules /etc/udev/rules.d
chmod 644 /etc/udev/rules.d/70-persistent-net.rules
chown root:root /etc/udev/rules.d/70-persistent-net.rules
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
systemctl unmask hostapd
systemctl disable hostapd

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
else
echo ""  > /dev/null 2>&1
fi

## ALSA Configuration
cp -f $BIN/asound.conf /etc
chmod 644 /etc/asound.conf
chown root:root /etc/asound.conf

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

## MPD/MPC Configuration
cp -f $BIN/mpd.conf /etc
chmod 644 /etc/mpd.conf
chown root:root /etc/mpd.conf
rm -rf /lib/systemd/system/mpd*
rm -rf /lib/systemd/system/mpc*
rm -rf /usr/bin/mpd
rm -rf /usr/bin/mpc

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

## Adafruit Video Looper
if [ ! -e /etc/vidloop.done ]; then
echo "Installing Video Looper..."
cd $BIN/videoloop
/usr/bin/python3 setup.py install --force
cd $BIN
touch /etc/vidloop.done
else
echo "Video looper already installed."
fi

## USB Automount Configuration
cp -f $BIN/usbmount.conf /etc/usbmount
chmod 644 /etc/usbmount/usbmount.conf
chown root:root /etc/usbmount/usbmount.conf

## USB Drive Detect
cp -f $BIN/10-udev-disks.rules /etc/udev/rules.d
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

systemctl daemon-reload
if [ ! -e /etc/rpi-conf.done ]; then
## Services Configuration
systemctl enable avahi-daemon
systemctl enable proinit
systemctl enable ssh
systemctl disable dhcpcd
systemctl disable networking
systemctl disable wpa_supplicant
systemctl disable keyboard-setup
systemctl disable plymouth-log
systemctl disable plymouth
systemctl disable sysstat
systemctl disable lightdm
systemctl disable lighttpd
systemctl disable dnsmasq
systemctl disable systemd-timesyncd
systemctl disable phpsessionclean.timer
systemctl disable phpsessionclean.service
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer
systemctl disable man-db.service
systemctl disable man-db.timer
systemctl disable bluetooth
systemctl disable hciuart
systemctl disable triggerhappy
systemctl disable wifiswitch
systemctl disable usbplug
systemctl disable motion
systemctl disable mpd
systemctl disable nmbd
systemctl disable smbd
systemctl disable autofs
systemctl disable shairport-sync
echo "Initial setup (phase II) complete."
touch /etc/rpi-conf.done
else
echo "Skipping service configuration."
fi

## File Permissions
chmod -R 755 /opt/rpi
chown -R root:root /opt/rpi

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

## Remove Installer Files
rm -rf /opt/rpi/config

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

## Cleanup Obsolete Files\
apt-get remove --purge -y supervisor
rm -rf /etc/supervisor/conf.d
rm -f /etc/systemd/system/systemd-udevd.service
rm -f /etc/systemd/system/tmpfiles-clean.service
rm -f /etc/systemd/system/tmpfiles-setup.service
rm -f /etc/systemd/system/wifiswitch.service
rm -f /etc/systemd/system/rpi-timer.service
rm -f /etc/systemd/system/rpi-timer.timer
rm -f /opt/rpi/leds.txt
rm -f /tmp/gateway.txt
rm -rf /opt/rpi/spectro
rm -rf /opt/rpi/rainbow
rm -f /root/sketchbook

echo "Configuration Complete."
exit