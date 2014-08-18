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
$DCName,
$Subnet = "192.168.2",
[switch]$Gateway
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Logfile = New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############

# checking uefi or Normal Machine dirty hack
if ($eth0 = Get-NetAdapter -Name "Ethernet0" -ErrorAction SilentlyContinue) {
[switch]$uefi = $True
}
else
{
$eth0 = Get-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue
}


if ($Gateway.IsPresent)
        {
        New-NetIPAddress –InterfaceIndex $eth0.ifIndex –IPAddress "$Subnet.10" –PrefixLength 24 -DefaultGateway "$subnet.103"
        }
 else {
        New-NetIPAddress –InterfaceIndex $eth0.ifIndex –IPAddress "$Subnet.10" –PrefixLength 24
        }

Set-DnsClientServerAddress –InterfaceIndex $eth0.ifIndex -ServerAddresses "$Subnet.10"
$eth0 | Rename-NetAdapter -NewName "$Subnet"
Rename-Computer -NewName $DCName
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True
Install-WindowsFeature –Name AD-Domain-Services,RSAT-ADDS –IncludeManagementTools
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "FinishDomain" -Value "$PSHOME\powershell.exe -Command `"C:\Scripts\finishdomain.ps1`""
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass2" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\2.pass`""
#New-Item c:\Shares\distr -type directory
#icacls c:\Shares\distr\ /grant 'Everyone:(OI)(CI)F'
#New-SMBShare –Name “distr” –Path “c:\Shares\distr” –FullAccess Everyone
restart-computer -force
