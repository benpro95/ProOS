#!/bin/bash
## ProOS for RPi, Network Script by Ben Provenzano III
#### RUN FROM '/opt/rpi/init CMD'

STOP_NET(){
## Clear Tables
iptables -F
## Stop Hotspot Service
systemctl stop hostapd
systemctl stop dnsmasq
systemctl stop rpi-wpaempty
## Stop Wi-Fi Service
systemctl stop wpa_supplicant
## Stop Networking
systemctl stop dhcpcd
systemctl restart networking
ip addr flush dev eth0
ip addr flush dev wlan0
## Disable WiFi Power Management
/sbin/iw dev wlan0 set power_save off
## Turn off hotspot LED if exists
/opt/rpi/main apdled-off || :
sleep 2.5
}

CPWIFI_CONF(){
if [ ! -e /boot/wpa.conf ]; then
  echo "WiFi config not found resetting."
  cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
  chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
  chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
else
  cp -f /boot/wpa.conf /etc/wpa_supplicant/wpa_supplicant.conf
  chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
  chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
fi
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
systemctl start wpa_supplicant
## Default Firewall Rules
iptables -t mangle -I POSTROUTING 1 -o wlan0 -p udp --dport 123 -j TOS --set-tos 0x00
}

BRIDGE_MODE(){
## Stop Networking
STOP_NET
## Copy Wi-Fi Settings
CPWIFI_CONF
## DHCP Bridge Mode
cp -f /etc/dhcpcd.bridge /etc/dhcpcd.conf
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
systemctl start dhcpcd
## Start Wi-Fi Service
systemctl start wpa_supplicant
## Forward Traffic
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE  
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
## DNS Service
cp -f /etc/dnsmasq.bridge /etc/dnsmasq.conf
chmod 644 /etc/dnsmasq.conf
chown root:root /etc/dnsmasq.conf
systemctl start dnsmasq
}

DELWIFI_MODE(){
## Stop Networking
STOP_NET
## Copy Empty Wi-Fi Settings
cp -f /etc/wpa_supplicant/wpa_supplicant.empty /etc/wpa_supplicant/wpa_supplicant.conf
chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
chown root:root /etc/wpa_supplicant/wpa_supplicant.conf
mount -o remount,rw /boot
cp -f /etc/wpa_supplicant/wpa_supplicant.empty /boot/wpa.conf
mount -o remount,ro /boot
## DHCP Client Mode
cp -f /etc/dhcpcd.net /etc/dhcpcd.conf
chmod 644 /etc/dhcpcd.conf
chown root:root /etc/dhcpcd.conf
systemctl start dhcpcd
## Start Wi-Fi Service
systemctl start wpa_supplicant
## Default Firewall Rules
iptables -t mangle -I POSTROUTING 1 -o wlan0 -p udp --dport 123 -j TOS --set-tos 0x00
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
systemctl stop wpa_supplicant
killall wpa_supplicant
sleep 2.25
systemctl start rpi-wpaempty
sleep 1.25
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
  echo " "
  exit
fi
echo " "
################################################################
}

case "$1" in

##############################################

client)
## Detect standard client or bridge Mode
if [ ! -e /boot/ap-bridge.enable ]; then
  echo "Client network mode"
  CLIENT_MODE
else
  echo "Bridge network mode"
  BRIDGE_MODE
fi
exit
;;

delwifi)
## Delete Wi-Fi credentials
DELWIFI_MODE
sleep 10
systemctl start rpi-netdetect.service
exit
;;

apd)
## Access point mode
/opt/rpi/main apdled-on || :
APD_MODE
/opt/rpi/main apdled-on || :
exit
;;

netdetect)
## Invoked by systemd only
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
