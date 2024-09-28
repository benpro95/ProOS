#!/bin/bash
## Save bookmarks file from RAM disk hourly

echo "(savebookmarks) started."

if [ -f /mnt/ramdisk/bookmarks.txt ]; then
  echo "saving bookmarks to disk..."
  mv -f /mnt/data/Documents/Bookmarks.txt /mnt/data/Documents/.Bookmarks.bak
  rsync -a /mnt/ramdisk/bookmarks.txt /mnt/data/Documents/Bookmarks.txt
  chmod 644 /mnt/data/Documents/Bookmarks.txt
  chown ben:shared /mnt/data/Documents/Bookmarks.txt
else
  echo "bookmarks file not found in RAM disk, restoring..."
  if [ -f /mnt/ramdisk/drives.txt ]; then ## check if RAM disk exists
  	if [ -f /mnt/data/Documents/Bookmarks.txt ]; then 
	  cp -fv /mnt/data/Documents/Bookmarks.txt /mnt/ramdisk/bookmarks.txt
	  chmod 777 /mnt/ramdisk/bookmarks.txt
	  chown ben:shared /mnt/ramdisk/bookmarks.txt
	  echo "Restore complete."
    fi
  fi	
fi

exit