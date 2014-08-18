<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
.'\\vmware-host\shared Folders\sources\NDP451-KB2858728-x86-x64-AllOS-ENU' /passive /norestart
.'\\vmware-host\shared Folders\sources\WAIK\adksetup.exe' /ceip off /features OptionID.DeploymentTools OptionID.WindowsPreinstallationEnvironment /quiet /forcerestart
Start-Sleep  -Seconds 30
while (Get-Process | where {$_.ProcessName -eq "adksetup"}){
Start-Sleep -Seconds 2
}
