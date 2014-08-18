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
$Domain = $env:USERDOMAIN


start-process "\\vmware-host\Shared Folders\Sources\SC2012 R2 SCVMM\setup.exe" -ArgumentList "/server /i /f C:\scripts\VMServer.ini /SqlDBAdminDomain $Domain /SqlDBAdminName SVC_SQL /SqlDBAdminPassword Password123! /VmmServiceDomain $Domain /VmmServiceUserName SVC_SCVMM /VmmServiceUserPassword Password123! /IACCEPTSCEULA" -Wait -Verb RunAs
while (Get-Process | where {$_.ProcessName -eq "SetupVM"}){
Start-Sleep -Seconds 2
}
#Start-Process C:\scripts\Autologon.exe -ArgumentList "Administrator $Domain Password123! /accepteula"
#Restart-Computer
