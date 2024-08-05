#!/bin/bash
## Save bookmarks file from RAM disk hourly

echo "(savebookmarks) started."

if [ -f /mnt/ramdisk/bookmarks.txt ]; then
  echo "saving bookmarks to disk..."
  mv -f /mnt/ben/Documents/Bookmarks.txt /mnt/ben/Documents/.Bookmarks.bak
  cp -fv /mnt/ramdisk/bookmarks.txt /mnt/ben/Documents/Bookmarks.txt
  chmod 644 /mnt/ben/Documents/Bookmarks.txt
  chown ben:shared /mnt/ben/Documents/Bookmarks.txt
else
  echo "bookmarks file not found in RAM disk, restoring..."
  if [ -f /mnt/ramdisk/drives.txt ]; then ## check if RAM disk exists
  	if [ -f /mnt/ben/Documents/Bookmarks.txt ]; then 
	  cp -fv /mnt/ben/Documents/Bookmarks.txt /mnt/ramdisk/bookmarks.txt
	  chmod 777 /mnt/ramdisk/bookmarks.txt
	  chown ben:shared /mnt/ramdisk/bookmarks.txt
	  echo "Restore complete."
    fi
  fi	
fi

exit