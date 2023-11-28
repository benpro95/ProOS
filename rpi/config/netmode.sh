#!/bin/bash
## ProOS for RPi, Network Script by Ben Provenzano III
#### RUN FROM '/opt/rpi/init CMD'

STOP_NET(){
if [ "$BOOTUP" = "yes" ]; then
  ## Unblock Wi-Fi
  rfkill unblock wifi 
  ## Start Networking
  systemctl start networking
else
  ## Clear Tables
  iptables -F
  ## Stop DHCP, Hotspot and Wi-Fi Service
  systemctl stop rpi-wpaempty
  systemctl stop rpi-wpa
  systemctl stop hostapd
  systemctl stop dnsmasq
  ## Restart Networking
  systemctl stop dhcpcd
  systemctl restart networking
  ip addr flush dev eth0
  ip addr flush dev wlan0
fi
## Disable WiFi Power Management
/sbin/iw dev wlan0 set power_save off
## Turn off hotspot LED if exists
/opt/rpi/main apdled-off || :
sleep 2.5
}

CLIENT_MODE(){
## Stop Networking
STOP_NET
## Copy Wi-Fi Settings
CPWIFI_CONF
## DHCP Client Mode
cp -f /etc/dhcpcd.net /etc/dhcpcd.conf
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
systemctl start dhcpcd
## Start Wi-Fi Service
systemctl start rpi-wpa
## Default Firewall Rules
iptables -t mangle -I POSTROUTING 1 -o wlan0 -p udp --dport 123 -j TOS --set-tos 0x00
}

CPWIFI_CONF(){
if [ ! -e /boot/wpa.conf ]; then
    echo "WiFi config not found resetting."
    cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
    chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
    chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
else
	OSVER="$(sed -n 's|^VERSION=".*(\(.*\))"|\1|p' /etc/os-release)"
	if [ "${OSVER}" = "bookworm" ]; then
	  mount -o remount,rw /boot/firmware
	  cp -f /boot/firmware/wpa.conf /etc/wpa_supplicant/wpa_supplicant.conf
	  mount -o remount,ro /boot/firmware
	else
	  mount -o remount,rw /boot
	  cp -f /boot/wpa.conf /etc/wpa_supplicant/wpa_supplicant.conf
	  mount -o remount,ro /boot
	fi
    chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
    chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
fi
}

DELWIFI_MODE(){
## Stop Networking
STOP_NET
## DHCP Client Mode
cp -f /etc/dhcpcd.net /etc/dhcpcd.conf
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
systemctl start dhcpcd
## Start Wi-Fi Service
systemctl start rpi-wpa
## Default Firewall Rules
iptables -t mangle -I POSTROUTING 1 -o wlan0 -p udp --dport 123 -j TOS --set-tos 0x00
## Switch to hotspot if network connection not found
sleep 60
NETDETECT
}

APD_MODE(){
## Stop Networking
STOP_NET
## DHCP Hotspot Mode
cp -f /etc/dhcpcd.apd /etc/dhcpcd.conf
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
systemctl start dhcpcd
## Enable WiFi Network Scanning
systemctl stop rpi-wpa
systemctl start rpi-wpaempty
## Forward Traffic
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
## Hotspot Service
systemctl restart hostapd
## DNS Service
if [ ! -e /boot/apd-routed.enable ]; then
  cp -f /etc/dnsmasq.nodns /etc/dnsmasq.conf
  chmod 644 /etc/dnsmasq.conf
  chown root:root /etc/dnsmasq.conf
else
  cp -f /etc/dnsmasq.routed /etc/dnsmasq.conf
  chmod 644 /etc/dnsmasq.conf
  chown root:root /etc/dnsmasq.conf
fi
systemctl start dnsmasq
}

NETDETECT(){
## Switch to Hotspot mode if network connection lost ###########
################################################################
SERVER=$(/sbin/ip route | awk '/default/ { print $3 }')
date
echo "Gateway IP $SERVER"
########
if [ ! -e /sys/class/net/wlan0 ] ; then
  echo "wlan0 not found, network check has been disabled."
  echo " "
  exit
fi
########
if pgrep -x "hostapd" > /dev/null 2> /dev/null
then
  echo "APD mode, network check has been disabled."
  echo " "
  exit
fi
########
ping -c2 ${SERVER} > /dev/null 2> /dev/null
if [ $? != 0 ]
then
  echo "Network connection down, switching to hotspot..."
  APD_MODE
  exit
fi
echo " "
################################################################
}

case "$1" in

##############################################

boot)
## REQUIRED TO START NETWORKING!!
rfkill unblock wifi
BOOTUP="yes"
OSVER="$(sed -n 's|^VERSION=".*(\(.*\))"|\1|p' /etc/os-release)"
if [ "${OSVER}" = "bookworm" ]; then
  if [ ! -e /boot/firmware/apd.enable ]; then
    echo "Client network mode"
    CLIENT_MODE
  else
    echo "Hotspot network mode"
    APD_MODE
  fi
else
  if [ ! -e /boot/apd.enable ]; then
    echo "Client network mode"
    CLIENT_MODE
  else
    echo "Hotspot network mode"
    APD_MODE
  fi
fi  
exit
;;

client)
## Switch to client network mode
BOOTUP="no"
echo "Client network mode"
CLIENT_MODE
exit
;;

delwifi)
## Delete Wi-Fi credentials
BOOTUP="no"
cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
OSVER="$(sed -n 's|^VERSION=".*(\(.*\))"|\1|p' /etc/os-release)"
if [ "${OSVER}" = "bookworm" ]; then
  mount -o remount,rw /boot/firmware
  cp -f /etc/wpa_supplicant/wpa_supplicant.empty /boot/firmware/wpa.conf
  mount -o remount,ro /boot/firmware
else
  mount -o remount,rw /boot
  cp -f /etc/wpa_supplicant/wpa_supplicant.empty /boot/wpa.conf
  mount -o remount,ro /boot
fi
## Switch to hotspot
APD_MODE
exit
;;

apd)
## Switch to access point mode
BOOTUP="no"
APD_MODE
/opt/rpi/main apdled-on || :
exit
;;

netdetect)
## Switch to hotspot if network down
BOOTUP="no"
NETDETECT
exit
;;


        *)
        echo "RPi Network Startup II"
	      echo "by Ben Provenzano III"
	      echo " "
	      echo "Enter Valid Arguments."
        echo " "
        exit 1
        ;;
    esac   
