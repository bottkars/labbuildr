<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param ($pass,[bool]$reboot = 1)
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass$Pass" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\$Pass.pass`""
if ($reboot){restart-computer -force}
