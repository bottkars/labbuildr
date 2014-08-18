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
$nodename = $env:COMPUTERNAME
$Computerinfo = c:\scripts\get-vmxcomputerinfo.ps1
$Arglist = 'Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters -Name "srvcomment" -Value "'+$Computerinfo.nodename+'running on '+$Computerinfo.Hypervisor+'"'
Start-Process -Verb "RunAs" "$PSHOME\powershell.exe"  -ArgumentList $Arglist
Set-ADComputer -identity $nodename -Description "VMHost: $($Computerinfo.Hypervisor), Builddate: $($Computerinfo.Builddate), last Powered on: $($Computerinfo.Powerontime), last Suspended: $($Computerinfo.Suspendtime)"