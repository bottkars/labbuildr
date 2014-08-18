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
$nodeIP,
$subnet,
$nodename,
[switch]$Gateway
)

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$nodeIP, $subnet, $nodename"
write-host $nodeIP
Write-Host $nodename
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
        $NewIP = New-NetIPAddress -InterfaceIndex $eth0.ifIndex –IPAddress $nodeIP –PrefixLength 24 -DefaultGateway "$subnet.103"
        }
        else {
        $NewIP = New-NetIPAddress -InterfaceIndex $eth0.ifIndex –IPAddress $nodeIP –PrefixLength 24
        }
        if ($eth1 = Get-NetAdapter -Name "Ethernet 2" -ErrorAction SilentlyContinue ) {Rename-NetAdapter $eth1.Name -NewName "External DHCP"}
        elseif  ($eth1 = Get-NetAdapter -Name "Ethernet1" -ErrorAction SilentlyContinue ) {Rename-NetAdapter $eth1.Name -NewName "External DHCP"}

        Set-DnsClientServerAddress –InterfaceIndex $eth0.ifIndex -ServerAddresses "$subnet.10"
        $eth0 | Rename-NetAdapter -NewName "Internal Network $subnet"
		Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
		Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
		Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True
        Write-Host "Running Feature Installer"
		$job = Start-Job -ScriptBlock {
		Install-WindowsFeature RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features
		}#job
		Wait-Job $job
        Rename-Computer -NewName $nodename
        New-Item -ItemType File -Path c:\scripts\2.pass
        restart-computer
