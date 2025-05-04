#!/bin/bash
## File Monitoring API Trigger 
## by Ben Provenzano III | 05/04/25

## monitor RAM disk for file creations
ram_disk="/mnt/ramdisk"
inotifywait -m $ram_disk -e create |
while read -r directory events filename; do
    ## file event occurred
    server=${filename%-*} ## behind the -
    cmd_wext=${filename#*-} ## after the -
    command=${cmd_wext%.*} ## remove extension
    ## find specific pattern in filename
    if [ "$server" == "files" ]; then
      ## delete trigger file
      nohup /usr/bin/runapi "$command" &
      rm -f "$ram_disk/$filename"
    fi
done

exit