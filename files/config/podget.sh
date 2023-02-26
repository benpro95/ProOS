#!/bin/bash

cd /home/media
/usr/bin/podget --silent
chown -R media:shared /mnt/media/Podcasts
chmod -R 2775 /mnt/media/Podcasts

exit