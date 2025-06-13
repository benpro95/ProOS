robocopy   Z:              K:\Data              /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy   X:\Music        K:\Media\Music       /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy   X:\Sounds       K:\Media\Sounds      /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy  "X:\TV Shows"   "K:\Media\TV Shows"   /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3 /XD "Doctor Who 2005" 
robocopy   X:\Audiobooks   K:\Media\Audiobooks  /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
timeout 10
exit