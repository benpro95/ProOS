#!/bin/bash
## ProOS for RPi, Bootup Script by Ben Provenzano III
#### Ran by proinit.service on boot after network startup ####

### Set CPU clock speed scaling
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

### Setup Website System Log File
mkdir -p /var/www/html/ram
/opt/rpi/main-www server clearlog
chmod -R 777 /var/www/html/ram/*
chown -R www-data:www-data /var/www/html/ram/*

### Start network configuration website / automation API
systemctl --no-block start lighttpd.service

## Console On Display
systemctl --no-block start getty@tty1.service

exit