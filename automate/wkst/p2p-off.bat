@ECHO OFF
ECHO Switching to DisplayPort...
START /MIN "DELL_DDM" "C:\Program Files\Dell\Dell Display Manager 2\DDM.exe" /console start /writeactiveinput DP /writesubinput USB-C /writepxp off
TIMEOUT 30
TASKKILL /F /IM DDM.exe
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
TIMEOUT 1
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
TIMEOUT 1
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
EXIT