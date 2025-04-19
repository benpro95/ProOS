#!/bin/bash
## Save bookmarks file from RAM disk hourly

echo "(savebookmarks) started."
DS_PATH="/mnt/data/Documents"

if [ -f /mnt/ramdisk/bookmarks.txt ]; then
  echo "saving bookmarks to disk..."
  mv -f $DS_PATH/Bookmarks.txt $DS_PATH/.Bookmarks.bak
  rsync -a /mnt/ramdisk/bookmarks.txt $DS_PATH/Bookmarks.txt
  chmod 644 $DS_PATH/Bookmarks.txt
  chown ben:shared $DS_PATH/Bookmarks.txt
else
  echo "bookmarks file not found in RAM disk, restoring..."
  if [ -f /mnt/ramdisk/drives.txt ]; then ## check if RAM disk exists
  	if [ -f $DS_PATH/Bookmarks.txt ]; then 
	  cp -fv $DS_PATH/Bookmarks.txt /mnt/ramdisk/bookmarks.txt
	  chmod 777 /mnt/ramdisk/bookmarks.txt
	  chown ben:shared /mnt/ramdisk/bookmarks.txt
	  echo "Restore complete."
    fi
  fi	
fi

exit