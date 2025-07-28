#KeyHistory 0

; Disable Ctrl+Alt+Tab (Mouse Button)
^!Tab::Return

F1::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=mainoff&action=main https://automate.home/exec.php, , hide
return

^F1::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=alloff&action=main https://automate.home/exec.php, , hide
return

F2::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=mainon&action=main https://automate.home/exec.php, , hide
return

^F2::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=allon&action=main https://automate.home/exec.php, , hide
return

F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=shuffle&action=leds https://automate.home/exec.php, , hide
return

!F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=pause&action=leds https://automate.home/exec.php, , hide
return

^F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=stop&action=leds https://automate.home/exec.php, , hide
return

;; Monitor Control ################

^F5::
Run, "C:\Program Files\Automate\p2p-off.bat", , hide
return

!F5::
Run, "C:\Program Files\Automate\p2p-on.bat", , hide
return

;; Mute ################

F11::Volume_Mute

!F11::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=mute&action=main https://automate.home/exec.php, , hide
return

^F11::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=pwrhifi&action=main https://automate.home/exec.php, , hide
return

;; Volume Down #########

F12::Volume_Down

!F12::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=dwn&action=main https://automate.home/exec.php, , hide
return

^F12::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=dwnc&action=main https://automate.home/exec.php, , hide
return

;; Volume Up ###########

Insert::Volume_Up

!Insert::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=up&action=main https://automate.home/exec.php, , hide
return

^Insert::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data var=&arg=upc&action=main https://automate.home/exec.php, , hide
return


