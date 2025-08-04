robocopy     Z:              K:\data              /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy     X:\Music        K:\media\Music       /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy     X:\Sounds       K:\media\Sounds      /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy    "X:\TV Shows"   "K:\media\TV Shows"   /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy     X:\Audiobooks   K:\media\Audiobooks  /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy     D:\Wkst         K:\wkst              /E /XJ /DCOPY:DAT /R:3 /W:3
timeout 10
exit