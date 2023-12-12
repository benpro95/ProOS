#!/bin/bash
## ProOS for RPi, Network Script by Ben Provenzano III
#### RUN FROM '/opt/rpi/init CMD'

STOP_NET(){
## Clear Firewall Tables
iptables -F
if [ -e /sys/class/net/wlan0 ] ; then
  ## Delete Existing Connections
  nmcli con down RPiWiFi
  nmcli con delete RPiWiFi
  nmcli con down RPiHotspot
  nmcli con delete RPiHotspot
  nmcli radio wifi off
  rfkill unblock wifi 
  ## Turn on Wi-Fi
  nmcli radio wifi on
  ## Disable WiFi Power Management
  iw dev wlan0 set power_save off
  ## Default Firewall Rule
  iptables -t mangle -I POSTROUTING 1 -o wlan0 -p udp --dport 123 -j TOS --set-tos 0x00
  ## Turn off hotspot LED if exists
  /opt/rpi/main apdled-off || :
fi
sleep 2.5
}

CLIENT_MODE(){
## Stop Networking
STOP_NET
if [ -e /sys/class/net/wlan0 ] ; then
  ## Read Wi-Fi Configuration
  if [ -e /boot/firmware/wpa.conf ]; then
    WPADATA=`cat /boot/firmware/wpa.conf`
    DELIM="|$|"
    WPA_SSID=${WPADATA%"$DELIM"*}
    WPA_PWD=${WPADATA#*"$DELIM"}
    nmcli con add con-name RPiWiFi ifname wlan0 type wifi ssid "$WPA_SSID"
    nmcli con modify RPiWiFi wifi-sec.key-mgmt wpa-psk
    nmcli con modify RPiWiFi wifi-sec.psk "$WPA_PWD"
    nmcli con modify RPiWiFi connection.autoconnect yes
    nmcli con down RPiWiFi
    nmcli con up RPiWiFi
  else
    echo "No WiFi Configuration Found, Switching to Access Point..."
    APD_MODE
  fi
else
  echo "No WiFi Hardware Found"
fi
}

APD_MODE(){
## Stop Networking
STOP_NET
if [ -e /sys/class/net/wlan0 ] ; then
  ## Read Custom Hotspot Configuration 
  if [ -e /boot/firmware/apd.conf ]; then
    APDDATA=`cat /boot/firmware/apd.conf`
    DELIM="|$|"
    APD_SSID=${APDDATA%"$DELIM"*}
    APD_PWD=${APDDATA#*"$DELIM"}
  else
    APD_SSID=`cat /etc/hostname`
    APD_PWD="raspberry"
  fi
  nmcli device wifi hotspot ifname wlan0 con-name RPiHotspot ssid "$APD_SSID" password "$APD_PWD"
  nmcli con modify RPiHotspot 802-11-wireless-security.key-mgmt wpa-psk
  nmcli con modify RPiHotspot 802-11-wireless-security.pairwise tkip
  nmcli con modify RPiHotspot 802-11-wireless-security.proto wpa
  nmcli con modify RPiHotspot autoconnect no
  nmcli con down RPiHotspot
  nmcli con up RPiHotspot
else
  echo "No Wi-Fi Hardware Found"
fi
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
sleep 10
## REQUIRED TO START NETWORKING!!
if [ ! -e /boot/firmware/apd.enable ]; then
  echo "Client network mode"
  CLIENT_MODE
else
  echo "Hotspot network mode"
  APD_MODE
fi
## Run Boot Script
/etc/preinit.sh
exit
;;

client)
## Switch to client network mode
echo "Client network mode"
CLIENT_MODE
exit
;;

delwifi)
## Delete Wi-Fi credentials
mount -o remount,rw /boot/firmware
rm -fv /boot/firmware/wpa.conf
mount -o remount,ro /boot/firmware
## Switch to hotspot
APD_MODE
exit
;;

apd)
## Switch to access point mode
APD_MODE
/opt/rpi/main apdled-on || :
exit
;;

netdetect)
## Switch to hotspot if network down
NETDETECT
exit
;;


        *)
        echo "RPi Network Startup v3"
	      echo "by Ben Provenzano III"
	      echo " "
	      echo "Enter Valid Arguments."
        echo " "
        exit 1
        ;;
    esac   
