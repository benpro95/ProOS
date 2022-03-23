F1::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=lightsoff&action=main http://automate.home:9300/exec.php, , hide
return

^F1::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=roomoff&action=main http://automate.home:9300/exec.php, , hide
return

F2::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=lightson&action=main http://automate.home:9300/exec.php, , hide
return

^F2::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=roomon&action=main http://automate.home:9300/exec.php, , hide
return

F3::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=shuffle&action=leds http://automate.home:9300/exec.php, , hide
return

!F3::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=stop&action=leds http://automate.home:9300/exec.php, , hide
return

^F3::
Run, C:\Scripts\monitors.bat
return

!F5::
Run, C:\Scripts\screenshot.bat
return

;; Mute ################

F11::
SoundSet, +1, , mute
return

!F11::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=mute&action=xmit http://automate.home:9300/exec.php, , hide
return

^F11::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=pwrhifi&action=xmit http://automate.home:9300/exec.php, , hide
return

;; Volume Down #########

F12::
SoundSet, -3
return

!F12::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=dwnc&action=xmit http://automate.home:9300/exec.php, , hide
return

^F12::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=dwnf&action=xmit http://automate.home:9300/exec.php, , hide
return

;; Volume Up ###########

Volume_Up::
SoundSet, +3
return

!Volume_Up::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=upc&action=xmit http://automate.home:9300/exec.php, , hide
return

^Volume_Up::
Run, C:\Scripts\exes\curl.exe -m 0.5 --data var=&arg=upf&action=xmit http://automate.home:9300/exec.php, , hide
return
