SET ARDUINO_CLI=C:\Program Files\Arduino\arduino-cli.exe
SET ARDUINO_LIB=Z:\Projects\Libraries\Arduino

SET SKETCH_PATH=Z:\ProOS\pve\automate\build\IRreceive
SET SKETCH_NAME=IRreceive.ino
SET ARDUINO_PORT=COM9

rmdir /s /q "%LocalAppData%\Arduino15\build"
mkdir "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v --libraries %ARDUINO_LIB% compile --fqbn arduino:avr:uno %SKETCH_PATH%\%SKETCH_NAME% --build-path "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v upload -p %ARDUINO_PORT% --fqbn arduino:avr:uno --input-dir "%LocalAppData%\Arduino15\build"
pause
exit