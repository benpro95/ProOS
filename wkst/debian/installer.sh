#!/bin/bash

## Update Sources
apt-get --yes update

## Install Packages
apt-get install -y --no-upgrade --ignore-missing unzip wget \
  rsync curl screen ethtool sshpass bc locales neofetch \
  apt-transport-https nmap bpytop binutils iperf3 sshfs

## Disable Sleep Mode
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

## Remove Password Login
passwd -d ben
