#!/bin/bash
## ProOS for RPi, Bootup Script by Ben Provenzano III
#### Ran by proinit.service on boot before network startup ####

### Set CPU clock speed scaling
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

### Start network configuration website / automation API
systemctl --no-block start lighttpd.service

## Console On Display
systemctl --no-block start getty@tty1.service

exit