robocopy   Z:              F:\Data              /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy   X:\Music        F:\Media\Music       /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy   X:\Sounds       F:\Media\Sounds      /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
robocopy  "X:\TV Shows"   "F:\Media\TV Shows"   /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3 /XD "Doctor Who 2005" 
robocopy   X:\Audiobooks   F:\Media\Audiobooks  /E /XJ /DCOPY:DAT /PURGE /R:3 /W:3
timeout 10
exit