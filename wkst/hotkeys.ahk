#KeyHistory 0

; Disable Ctrl+Alt+Tab (Mouse Button)
^!Tab::Return

F1::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrlightsoff&var=&action=main", , hide
return

^F1::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lroff&var=&action=main", , hide
return

F2::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrlightson&var=&action=main", , hide
return

^F2::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lron&var=&action=main", , hide
return

F3::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=shuffle&var=&action=leds", , hide
return

!F3::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=pause&var=&action=leds", , hide
return

^F3::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=stop&var=&action=leds", , hide
return

;; Mouse Control ################

F5::
Run, PowerShell.exe -ExecutionPolicy Bypass -File "C:\Program Files\Automate\mouse_acc.ps1"
return

;; Monitor Control ################

^F5::
Run, "C:\Program Files\Automate\p2p_toggle.bat"
return

;; Mute ################

F11::Volume_Mute

!F11::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=mute&action=main", , hide
return

^F11::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=hifitoggle&action=main", , hide
return

;; Volume Down #########

F12::Volume_Down

!F12::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=dwn&action=main", , hide
return

^F12::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=dwnc&action=main", , hide
return

;; Volume Up ###########

Insert::Volume_Up

!Insert::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=up&action=main", , hide
return

^Insert::
Run, C:\PROGRA~1\Automate\curl.exe "http://automate.home/api?arg=lrxmit&var=upc&action=main", , hide
return


