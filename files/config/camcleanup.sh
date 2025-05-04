#!/bin/bash

## Cameras Cleanup Script
### run as ben user only!

lockfile='/mnt/scratch/cameras/.camclean.pid'
if [ -e $lockfile ]; then
   pid=`cat $lockfile`
   if kill -0 &>1 > /dev/null $pid; then
      exit 1
    else
      rm $lockfile
    fi
fi
echo $$ > $lockfile

## Delete video files older than two years
find /mnt/scratch/cameras/* -type f -name "*.mp4" -mtime +730 -delete

rm $lockfile
exit 0
