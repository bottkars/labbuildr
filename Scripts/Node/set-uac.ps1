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
#### Confguring Firewall
Set-Service MpsSvc -StartupType Automatic
Start-Service  MpsSvc
Set-NetFirewallProfile -Profile Domain,Private -Enabled False
write-verbose "Configuring UAC"
set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 
set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 00000000 