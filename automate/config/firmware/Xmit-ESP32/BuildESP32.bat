SET ARDUINO_CLI=C:\Program Files\Arduino\arduino-cli.exe
SET ARDUINO_LIB=Z:\Projects\libraries

SET SKETCH_PATH=.
SET SKETCH_NAME=ESP32-Xmit.ino
SET BOARD_TYPE=esp32:esp32:lolin32
SET COM_PORT=COM5

rmdir /s /q "%LocalAppData%\Arduino15\build"
mkdir "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v --libraries %ARDUINO_LIB% compile --fqbn %BOARD_TYPE% %SKETCH_PATH%\%SKETCH_NAME% --build-path "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v upload -p %COM_PORT% --fqbn %BOARD_TYPE% --input-dir "%LocalAppData%\Arduino15\build"
pause
exit