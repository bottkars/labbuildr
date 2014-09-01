<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
[CmdletBinding()]
param (
$nodeIP,
$nodename,
$IPv4Subnet = "192.168.2",
[ValidateSet('24')]$IPv4PrefixLength = '24',
$IPv6Prefix = "",
[ValidateSet('8','24','32','48','64')]$IPv6PrefixLength = '8',
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
[switch]$Gateway
)
$IPv6subnet = "$IPv6Prefix$IPv4Subnet"
$IPv6Address = "$IPv6Prefix$nodeIP"
Write-Verbose $IPv6PrefixLength
Write-Verbose $IPv6Address
Write-Verbose $IPv6subnet

# Write-Verbose $AddressFamily
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$nodeIP, $IPv4Subnet, $nodename"


# checking uefi or Normal Machine dirty hack
if ($eth0 = Get-NetAdapter -Name "Ethernet0" -ErrorAction SilentlyContinue) {
[switch]$uefi = $True
}
else
{
$eth0 = Get-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue
}



If ($AddressFamily -match 'IPv4')
{

    if ($Gateway.IsPresent)
            {
        # New-NetIPAddress –InterfaceIndex $eth0.ifIndex –IPAddress "$Subnet.10" –PrefixLength 24 -DefaultGateway "$subnet.103"
        # $NewIP = 
        New-NetIPAddress -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4 –IPAddress "$nodeIP" –PrefixLength $IPv4PrefixLength -DefaultGateway "$IPv4subnet.103"
        }
    else
        {
        # New-NetIPAddress –InterfaceIndex $eth0.ifIndex –IPAddress "$Subnet.10" –PrefixLength 24
        New-NetIPAddress -InterfaceIndex $eth0.ifIndex -AddressFamily IPv4 –IPAddress "$nodeIP" –PrefixLength $IPv4PrefixLength 
        }
Set-DnsClientServerAddress –InterfaceIndex $eth0.ifIndex -ServerAddresses "$IPv4Subnet.10"
}

If ($AddressFamily -match 'IPv6')
{

    if ($Gateway.IsPresent)
            {
        New-NetIPAddress -InterfaceIndex $eth0.ifIndex -AddressFamily IPv6 –IPAddress $IPv6Address –PrefixLength $IPv6PrefixLength -DefaultGateway "$IPv6subnet.103"
        }
    else
        {
        New-NetIPAddress -InterfaceIndex $eth0.ifIndex -AddressFamily IPv6 –IPAddress $IPv6Address –PrefixLength $IPv6PrefixLength
        }
Set-DnsClientServerAddress –InterfaceIndex $eth0.ifIndex -ServerAddresses "$IPv6subnet.10"

}


if ( $AddressFamily -notmatch 'IPv4')
    {
    $eth0 | Disable-NetAdapterBinding -ComponentID ms_tcpip
    }



if ($eth1 = Get-NetAdapter -Name "Ethernet 2" -ErrorAction SilentlyContinue ) 
    {
    Rename-NetAdapter $eth1.Name -NewName "External DHCP"
    }
elseif  ($eth1 = Get-NetAdapter -Name "Ethernet1" -ErrorAction SilentlyContinue ) 
    {
    Rename-NetAdapter $eth1.Name -NewName "External DHCP"
    }



Set-DnsClientServerAddress –InterfaceIndex $eth0.ifIndex -ServerAddresses "$subnet.10"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Write-Host "Running Feature Installer"
$job = Start-Job -ScriptBlock {Install-WindowsFeature RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features}#job
Wait-Job $job
Rename-Computer -NewName $nodename
New-Item -ItemType File -Path c:\scripts\2.pass

restart-computer