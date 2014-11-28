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
param(
$IPV6Prefix = 'fd2d:3c46:82b2::',
$IPv4Subnet = "192.168.2",
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily, 
[ValidateSet('24')]$IPv4PrefixLength = '24',
[ValidateSet('8','24','32','48','64')]$IPv6PrefixLength = '8',
[switch]$Gateway
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Logfile  = New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$PSCmdlet.MyInvocation.BoundParameter | Set-Content  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $PSCmdlet.MyInvocation.BoundParameters
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Output $PSCmdlet.MyInvocation.BoundParameters
    }


Write-Host -ForegroundColor Yellow "Generating Reverse Lookup Zone"
if ( $AddressFamily -match 'IPv4')
    {
    $reverse = $IPv4subnet+'.0/'+$IPv4PrefixLength
    Add-DnsServerPrimaryZone -NetworkID $reverse -ReplicationScope "Forest" -DynamicUpdate NonsecureAndSecure
    }
if ( $AddressFamily -match 'IPv6')
    {
    $reverse = $IPV6Prefix+'/'+$IPv6PrefixLength
    Add-DnsServerPrimaryZone -NetworkID $reverse -ReplicationScope "Forest" -DynamicUpdate NonsecureAndSecure
    }
    Write-Verbose $IPv6PrefixLength
    Write-Verbose $reverse
    Write-Verbose $IPV6Prefix

# Add-DnsServerPrimaryZone "$reverse.in-addr.arpa" -ZoneFile "$reverse.in-addr.arpa.dns" -DynamicUpdate NonsecureAndSecure
$zone = Get-DnsServerzone $env:USERDNSDOMAIN
Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFS -NameServer "smartconnect.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.40"
Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFSremote -NameServer "smartconnectremote.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.60"
$reversezone =  Get-DnsServerZone | where { $_.IsDsIntegrated -and $_.IsReverseLookupZone}
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "40" -PtrDomainName "smartconnect.$env:USERDNSDOMAIN"
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "60" -PtrDomainName "smartconnectremote.$env:USERDNSDOMAIN"

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
