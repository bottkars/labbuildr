<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3



param (
$Domain="vlab2go",
$domainsuffix = ".local"
)

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$Domain"
C:\scripts\Autologon.exe Administrator $Domain Password123!
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass3" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\3.pass`""
$Mydomain = "$Domain$domainsuffix"
$password = "Password123!" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\Administrator" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $Mydomain -Credential $credential
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "Computerinfo" -Value "$PSHOME\powershell.exe -file c:\scripts\set-computerinfo.ps1"
# Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools
Start-Process C:\scripts\Autologon.exe -ArgumentList "Administrator $Domain Password123! /Accepteula"
Restart-Computer