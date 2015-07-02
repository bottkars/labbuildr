<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[CmdletBinding()]
param(
$IPV6Prefix = 'fd2d:3c46:82b2::',
$IPv4Subnet = "192.168.2",
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Domain = $env:USERDOMAIN

New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$nodeIP, $subnet, $nodename"
add-windowsfeature -Name RemoteAccess -IncludeAllSubFeature -IncludeManagementTools
Write-Verbose "getting next hop on DHCP"
$HopIP = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias "External DHCP" -AddressFamily IPv4 | Select-Object -ExpandProperty "NextHop"
Write-Verbose "Setting hop on DC"
Invoke-Command -ComputerName $env:USERDOMAIN"DC" -ScriptBlock {param($HopIP) Add-DnsServerForwarder -ipaddress $HopIP} -ArgumentList "$HopIP"
write-verbose "trying RRAS Configuration"

$content = Get-Content -path "$Builddir\rras.txt"
$content | foreach {$_ -replace "Ethernet", "$Domain"} | Set-Content "$Builddir\rras.txt"


netsh.exe -f "$Builddir\rras.txt"
Set-Service RemoteAccess -StartupType Automatic
start-Service RemoteAccess


