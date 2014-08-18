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
New-Item -ItemType file -Path $Builddir\domain.txt -Force
Set-Content -Value (Get-ADDomain).Name -Path $Builddir\domain.txt
New-Item -ItemType file -Path $Builddir\ip.txt -Force
Set-Content -Value (Get-NetIPAddress -AddressFamily IPv4 | where IPAddress -ne "127.0.0.1").ipaddress -Path $Builddir\ip.txt
New-Item -ItemType file -Path $Builddir\gateway.txt -Force
Set-Content -Value (Get-NetIPConfiguration).ipv4DefaultGateway.NextHop -Path $Builddir\Gateway.txt

