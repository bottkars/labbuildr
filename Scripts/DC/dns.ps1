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
Write-Verbose $IPv6PrefixLength
Write-Verbose $IPV6Prefix
$zone = Get-DnsServerzone $env:USERDNSDOMAIN
Write-Host -ForegroundColor Yellow "Generating Reverse Lookup Zone"
if ( $AddressFamily -match 'IPv4')
    {
    $reverse = $IPv4subnet+'.0/'+$IPv4PrefixLength
    Add-DnsServerPrimaryZone -NetworkID $reverse -ReplicationScope "Forest" -DynamicUpdate NonsecureAndSecure
    Add-DnsServerForwarder -IPAddress 8.8.8.8
    Write-Verbose "Setting Ressource Records for EMC VA´s"
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name Vipr1 -IPv4Address "$IPv4Subnet.9" -ZoneName $zone.Zonename
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "NVENode1" -IPv4Address "$IPv4Subnet.12" -ZoneName $zone.Zonename
    foreach ( $N in 1..3)
        {
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "DDVeNode$N" -IPv4Address "$IPv4Subnet.2$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "AveNode$N" -IPv4Address "$IPv4Subnet.3$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "CloudBoost$N" -IPv4Address "$IPv4Subnet.7$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "CloudArray$N" -IPv4Address "$IPv4Subnet.10$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "ECSNode$N" -IPv4Address "$IPv4Subnet.21$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "ScaleIONode$N" -IPv4Address "$IPv4Subnet.19$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "CentOSNode$N" -IPv4Address "$IPv4Subnet.22$N" -ZoneName $zone.Zonename
        }
    }
if ( $AddressFamily -match 'IPv6')
    {
    $reverse = $IPV6Prefix+'/'+$IPv6PrefixLength

    }

# Add-DnsServerPrimaryZone "$reverse.in-addr.arpa" -ZoneFile "$reverse.in-addr.arpa.dns" -DynamicUpdate NonsecureAndSecure

Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFS -NameServer "smartconnect.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.40"
Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFSremote -NameServer "smartconnectremote.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.60"
$reversezone =  Get-DnsServerZone | where { $_.IsDsIntegrated -and $_.IsReverseLookupZone}
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "40" -PtrDomainName "smartconnect.$env:USERDNSDOMAIN"
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "60" -PtrDomainName "smartconnectremote.$env:USERDNSDOMAIN"
## add some hosts vor avamar and ddve  and others. . . 




if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
