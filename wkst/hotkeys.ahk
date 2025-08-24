#KeyHistory 0

; Disable Ctrl+Alt+Tab (Mouse Button)
^!Tab::Return

F1::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrlightsoff&var=&action=main https://automate.home/exec.php, , hide
return

^F1::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lroff&var=&action=main https://automate.home/exec.php, , hide
return

F2::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrlightson&var=&action=main https://automate.home/exec.php, , hide
return

^F2::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lron&var=&action=main https://automate.home/exec.php, , hide
return

F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=shuffle&var=&action=leds https://automate.home/exec.php, , hide
return

!F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=pause&var=&action=leds https://automate.home/exec.php, , hide
return

^F3::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=stop&var=&action=leds https://automate.home/exec.php, , hide
return

;; Mouse Control ################

F4::
Run, PowerShell.exe -ExecutionPolicy Bypass -File "C:\Program Files\Automate\mouse_acc.ps1"
return

;; Monitor Control ################

^F5::
Run, "C:\Program Files\Automate\p2p-off.bat"
return

!F5::
Run, "C:\Program Files\Automate\p2p-on.bat"
return

;; Mute ################

F11::Volume_Mute

!F11::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=mute&action=main https://automate.home/exec.php, , hide
return

^F11::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=hifitoggle&action=main https://automate.home/exec.php, , hide
return

;; Volume Down #########

F12::Volume_Down

!F12::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=dwn&action=main https://automate.home/exec.php, , hide
return

^F12::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=dwnc&action=main https://automate.home/exec.php, , hide
return

;; Volume Up ###########

Insert::Volume_Up

!Insert::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=up&action=main https://automate.home/exec.php, , hide
return

^Insert::
Run, "C:\Program Files\Automate\curl.exe" -k -m 0.5 --data arg=lrxmit&var=upc&action=main https://automate.home/exec.php, , hide
return


