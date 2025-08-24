# Check registry for mouse acc enabled/disabled and toggle the registry entries
# Note:
#   Updating the registry entries does not result in a change in the running system,
#   the change will probably only come to effect once the system is restarted.
#   We use the registry for state tracking and for completeness (if the system gets restarted)

# https://www.techblazing.com/turn-off-mouse-acceleration-windows-10-and-mac/

$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser","$env:COMPUTERNAME")
$RegMouse = $RegConnect.OpenSubKey("Control Panel\Mouse",$true)

$acc_enabled = $RegMouse.GetValue("MouseSpeed")

if ( $acc_enabled -eq 1 ) {
    # mouse acc is enabled -> disable mouse acc

    $RegMouse.SetValue("MouseSpeed","0")
    $RegMouse.SetValue("MouseThreshold1","0")
    $RegMouse.SetValue("MouseThreshold2","0")

    $sys_pvParam = @(0,0,0)

    echo "Mouse Acceleration Disabled"

} else {
    # mouse acc is disabled -> enable mouse acc

    $RegMouse.SetValue("MouseSpeed","1")
    $RegMouse.SetValue("MouseThreshold1","6")
    $RegMouse.SetValue("MouseThreshold2","10")

    $sys_pvParam = @(1,6,10)

    echo "Mouse Acceleration Enabled"

}
sleep 2
$RegMouse.Close()
$RegConnect.Close()


# Updates the actual system settings for mouse acceleration
# and propagates the changes to the running system
# 
# https://social.technet.microsoft.com/Forums/ie/en-US/697e6441-eb8e-482e-96a0-2dd4f67c1015/disable-enhance-pointer-precision-with-powershell?forum=ITCG
# https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfoa
# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.2

$code = @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
 public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, int[] pvParam, uint fWinIni);
'@

Add-Type $code -name Win32 -NameSpace System

[System.Win32]::SystemParametersInfo(4,0,$sys_pvParam,2)  # last parameter (2) is used to propagate the changes to the running system
