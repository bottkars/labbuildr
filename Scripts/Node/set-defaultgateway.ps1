<#
.Synopsis
   Change Default gateway for Known Hosts
.DESCRIPTION
   Long description
.EXAMPLE
   set-defaultgateway.ps1 -Computername HVNode3 -gateway 10.10.0.3
.EXAMPLE
#>


param (
    $gateway = "10.10.0.103",
    $Computername = $null
    )



$ScriptBlock = {
param 
    (
    $Gateway
    )
$Newgateway = (Get-WmiObject -Class win32_networkAdapterconfiguration | where InterfaceIndex -Match (Get-NetIPAddress -AddressState Preferred -InterfaceAlias "Ethernet*" -SkipAsSource $false -AddressFamily IPv4 | where Prefixorigin -ne "DHCP").InterfaceIndex).SetGateways("$Gateway") 
(Get-WmiObject -Class win32_networkAdapterconfiguration | where InterfaceIndex -Match (Get-NetIPAddress -AddressState Preferred -InterfaceAlias "Ethernet*" -SkipAsSource $false -AddressFamily IPv4 | where Prefixorigin -ne "DHCP").InterfaceIndex) | Select-Object -SkipLast 1 PSComputername, DefaultIPGateway 
} # end Scriptblock

if ($Computername)
    {
    Invoke-Command -ScriptBlock $ScriptBlock -computerName $Computername -ArgumentList $gateway
    } 
else 
    {
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $gateway
    }
