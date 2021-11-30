IF EXIST "C:\Scripts\tmp\monitors.state" (
    echo "File exists deleting."
    del C:\Scripts\tmp\monitors.state
    "C:\Scripts\exes\MultiMonitorTool.exe" /TurnOn \\.\DISPLAY1
    "C:\Scripts\exes\MultiMonitorTool.exe" /TurnOn \\.\DISPLAY2
    "C:\Scripts\exes\MultiMonitorTool.exe" /TurnOn \\.\DISPLAY3
) ELSE (
    echo "File does not exist, creating."
    type NUL > C:\Scripts\tmp\monitors.state
    "C:\Scripts\exes\MultiMonitorTool.exe" /TurnOff \\.\DISPLAY2
    "C:\Scripts\exes\MultiMonitorTool.exe" /TurnOff \\.\DISPLAY3
)