by Ben Provenzano III

###############################################
* SAMBA Initial Setup *

## Add Group (1)
groupadd shared
groupadd server

## Add Users (2)
useradd media -g shared --shell /bin/false
useradd cameras -g shared --shell /bin/false
useradd archive -g shared --shell /bin/false
useradd server -g server --shell /bin/bash
useradd ben -g shared --home /sftp --shell /usr/sbin/nologin

## SFTP for 'ben' user
mkdir -p /home/ben
chown -R root:shared /home/ben
mkdir -p /home/ben/sftp
chown -R ben:shared /home/ben/sftp
passwd ben (this is the SFTP password)

## Set SMB Passwords (3)
smbpasswd -a ben
smbpasswd -a media
smbpasswd -a cameras
smbpasswd -a archive

## Reset All Permissions 'Optional' (4)
## !!WILL FORCE ENTIRE NEW DISK BACKUP SNAPSHOT!!
chmod -Rv a-rwX /mnt/datastore
chmod -Rv u=rwX,g=rX,o=rX /mnt/datastore
chmod -Rv a-rwX /mnt/downloads
chmod -Rv u=rwX,g=rX,o=rX /mnt/downloads
chmod -Rv a-rwX /mnt/cameras
chmod -Rv u=rwX,g=rX,o=rX /mnt/cameras

## Reset All Owners 'Optional' (5)
## !!WILL FORCE ENTIRE NEW DISK BACKUP SNAPSHOT!!
chown -Rv ben:shared /mnt/datastore/Ben
chown -Rv ben:shared /mnt/datastore/Media
chown -Rv ben:shared /mnt/downloads
chown -Rv cameras:shared /mnt/cameras
