#!/bin/sh

### This script will mount the root filesystem read-only and overlay it with a temporary tempfs 
### which is read-write mounted. This is done using the overlayFS which is part of the linux kernel 
### since version 3.18. 
### when this script is in use, all changes made to anywhere in the root filesystem mount will be lost 
### upon reboot of the system. The SD card will only be accessed as read-only drive, which significantly
### helps to prolong its life and prevent filesystem coruption in environments where the system is usually
### not shut down properly 
###
### Install: 
### copy this script to /sbin/overlayRoot.sh, make it executable and add "init=/sbin/overlayRoot.sh" to the 
### cmdline.txt file in the raspbian image's boot partition. 
### I strongly recommend to disable swapping before using this.
### To install software, run upgrades and do other changes to the raspberry setup, simply remove the init= 
### entry from the cmdline.txt file and reboot, make the changes, add the init= entry and reboot once more. 
### This can be done by my overlayReboot.sh script, which makes the process quick and easy to do.
###
### Copyright 2017 by Pascal Suter @ DALCO AG, Switzerland
### Copyright 2019, Walter Hüttenmeyer
###  This program is free software: you can redistribute it and/or modify
###     it under the terms of the GNU General Public License as published by
###     the Free Software Foundation, either version 3 of the License, or
###     (at your option) any later version.
### 
###     This program is distributed in the hope that it will be useful,
###     but WITHOUT ANY WARRANTY; without even the implied warranty of
###     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
###     GNU General Public License for more details.
### 
###     You should have received a copy of the GNU General Public License
###     along with this program.  If not, see <http://www.gnu.org/licenses/>.
###


# give us some debugging, if needed. Set to anything but 0
DEBUG=0

#check for exit status and print error messages, plus exit to /bin/bash
checkfail(){
	if [ $? -ne 0 ]; then
		printf "[ERROR]\tOverlayroot: $1\n"
		/bin/bash
	fi
}

#print info messages, if debugging is turned on
info(){
	if [ $DEBUG -ne 0 ]; then
	printf "[INFO]\tOverlayroot: $1\n"
	fi
}

#create directories and call checkfail()
makedir(){
	info "Creating directory $1"
	mkdir $1
	checkfail "Could not create $1"
	}
	
# load module
info "Loading overlay kernel module"
modprobe overlay
checkfail "missing overlay kernel module"

# mount /proc
info "Mounting /proc"
mount -t proc proc /proc
checkfail "could not mount proc"

# create a writable fs to then create our mountpoints
info "Mounting TMPFS at /mnt"
mount -t tmpfs inittemp /mnt
checkfail "could not create a temporary filesystem to mount the base filesystems for overlayfs"

makedir "/mnt/lower"
makedir "/mnt/rw"
checkfail "could not create /mnt/rw"

info "Mounting TMPFS at /mnt/rw"
mount -t tmpfs root-rw /mnt/rw
checkfail "could not create tempfs for upper filesystem"

makedir "/mnt/rw/upper"
makedir "/mnt/rw/work"
makedir /"mnt/newroot"

# mount root filesystem readonly 
rootDev=`awk '$2 == "/" {print $1}' /etc/fstab`
rootMountOpt=`awk '$2 == "/" {print $4}' /etc/fstab`
rootFsType=`awk '$2 == "/" {print $3}' /etc/fstab`
info "rootDev: ${rootDev}"
info "rootMountOpt: ${rootMountOpt}"
info "rootFsType: ${rootFsType}"
info "check if we can locate the root device based on fstab"
blkid $rootDev
if [ $? -gt 0 ]; then
    info "no success, try if a filesystem with label 'rootfs' is avaialble"
    rootDevFstab=$rootDev
    rootDev=`blkid -L "rootfs"`
    if [ $? -gt 0 ]; then
        info "no luck either, try to further parse fstab's root device definition"
        info "try if fstab contains a PARTUUID definition"
        echo "$rootDevFstab" | grep 'PARTUUID=\(.*\)-\([0-9]\{2\}\)'
        info "rootDevFstab: ${rootDevFstab}"
	    checkfail "could not find a root filesystem device in fstab. Make sure that fstab contains a device definition or a PARTUUID entry for / or that the root filesystem has a label 'rootfs' assigned to it"
        device=""
        partition=""
        eval `echo "$rootDevFstab" | sed -e 's/PARTUUID=\(.*\)-\([0-9]\{2\}\)/device=\1;partition=\2/'`
        rootDev=`blkid -t "PTUUID=$device" | awk -F : '{print $1}'`p$(($partition))
        blkid $rootDev
	    checkfail "The PARTUUID entry in fstab could not be converted into a valid device name. Make sure that fstab contains a device definition or a PARTUUID entry for / or that the root filesystem has a label 'rootfs' assigned to it"
    fi
fi

info "Mounting ${rootDev} at /mnt/lower"
mount -t ${rootFsType} -o ${rootMountOpt},ro ${rootDev} /mnt/lower
checkfail "could not ro-mount original root partition"

info "Mounting overlay"
mount -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/rw/upper,workdir=/mnt/rw/work overlayfs-root /mnt/newroot
checkfail "could not mount overlayFS"

# create mountpoints inside the new root filesystem-overlay
makedir "/mnt/newroot/ro"
makedir "/mnt/newroot/rw"

# remove root mount from fstab (this is already a non-permanent modification)
info "Removing root mountpoint from fstab (temporary change already)"
grep -v "$rootDev" /mnt/lower/etc/fstab > /mnt/newroot/etc/fstab
echo "#the original root mount has been removed by overlayRoot.sh" >> /mnt/newroot/etc/fstab
echo "#this is only a temporary modification, the original fstab" >> /mnt/newroot/etc/fstab
echo "#stored on the disk can be found in /ro/etc/fstab" >> /mnt/newroot/etc/fstab

# change to the new overlay root
info "Changing to new overlay root"
cd /mnt/newroot
pivot_root . mnt
info "Chrooting"
exec chroot . sh -c "$(cat <<END
# move ro and rw mounts to the new root
printf "[INFO]\tOverlayroot: Mounting /mnt/mnt/lower as /ro\n"
mount --move /mnt/mnt/lower/ /ro
if [ $? -ne 0 ]; then
    printf "[ERROR]\tOverlayroot: could not move ro-root into newroot\n"
    /bin/bash
fi
mount --move /mnt/mnt/rw /rw
if [ $? -ne 0 ]; then
    printf "[ERROR]\tOverlayroot: could not move tempfs rw mount into newroot\n"
#    /bin/bash
fi
printf "[INFO]\tOverlayroot: Moving /mnt/dev to /dev\n"
mount --move /mnt/dev/ /dev
if [ $? -ne 0 ]; then
    printf "[ERROR]\tOverlayroot: could not move dev into newroot\n"
    /bin/bash
fi
# unmount unneeded mounts so we can unmout the old readonly root
umount /mnt/mnt
umount /mnt/proc
umount /mnt/dev
umount /mnt
# continue with regular init
printf "[INFO]\tOverlayroot: Executing regular /sbin/init\n"
exec /sbin/init
END
)"