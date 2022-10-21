SET ARDUINO_CLI=C:\Program Files\Arduino\arduino-cli.exe
SET ARDUINO_LIB=Z:\Arduino\libraries

SET SKETCH_PATH=.
SET SKETCH_NAME=RFDresser.ino

rmdir /s /q "%LocalAppData%\Arduino15\build"
mkdir "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v --libraries %ARDUINO_LIB% compile --fqbn arduino:avr:uno %SKETCH_PATH%\%SKETCH_NAME% --build-path "%LocalAppData%\Arduino15\build"
"%ARDUINO_CLI%" -v upload -p COM4 --fqbn arduino:avr:uno --input-dir "%LocalAppData%\Arduino15\build"
pause
exit