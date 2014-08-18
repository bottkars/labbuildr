<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param(
$subnet = "192.168.2"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Write-Host -ForegroundColor Yellow "Generating Reverse Lookup Zone"
$MyIP = (Get-NetIPAddress -AddressFamily IPv4 | where IPaddress -match $Subnet).IPAddress
$MyIPObject = [System.Version][String]([System.Net.IPAddress]$MyIP)
$reverse = $MyIPObject.Build.ToString()+"."+$MyIPObject.Minor+"."+$MyIPObject.Major
Add-DnsServerPrimaryZone "$reverse.in-addr.arpa" -ZoneFile "$reverse.in-addr.arpa.dns" -DynamicUpdate NonsecureAndSecure
$zone = Get-DnsServerzone $env:USERDNSDOMAIN
# Add-DnsServerResourceRecordA -Name smartconnect -ZoneName $zone.ZoneName -CreatePtr -IPv4Address "$subnet.40"
Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFS -NameServer "smartconnect.$env:USERDNSDOMAIN" -IPAddress "$subnet.40"
