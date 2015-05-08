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
$Domain = $env:USERDOMAIN
Copy-Item -Path 'C:\scripts\Networker User for Microsoft.lnk' C:\Users\Public\Desktop
# Copy-Item -Path 'C:\scripts\ecp.website' C:\Users\Public\Desktop
# C:\scripts\Autologon.exe NMMBackupUser brslab Password123! /accepteula
Start-Process C:\scripts\Autologon.exe -ArgumentList "NMMBackupUser $Domain Password123! /Accepteula"
