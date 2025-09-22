@ECHO OFF
IF EXIST "C:\temp\p2p-on.state" (
    ECHO *** Switching to DisplayPort ***
    START /MIN "DELL_DDM" "C:\Program Files\Dell\Dell Display Manager 2\DDM.exe" /console start /writeactiveinput DP /writesubinput USB-C /writepxp off
    DEL "C:\temp\p2p-on.state"
) ELSE (
    ECHO *** Switching to DisplayPort / USB-C P2P ***
    START /MIN "DELL_DDM" "C:\Program Files\Dell\Dell Display Manager 2\DDM.exe" /console start /writeactiveinput DP /writesubinput USB-C /writepxp pbp-2h-fill
    ECHO ON > "C:\temp\p2p-on.state"
)
TIMEOUT 30
TASKKILL /F /IM DDM.exe
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
TIMEOUT 1
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
TIMEOUT 1
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
EXIT