param ($pass,[bool]$reboot = 1)
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass$Pass" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\$Pass.pass`""
if ($reboot){restart-computer -force}
