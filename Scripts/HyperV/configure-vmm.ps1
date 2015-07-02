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
[switch]$Cluster
)
Write-Output "Setting user credentials to perform installation and configuration"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = $env:USERDOMAIN
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
Import-Module 'C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
Get-SCVMMServer $Env:COMPUTERNAME
####
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
$runAsAccount = New-SCRunAsAccount -Credential $credential -Name "LabbuildrRunAs" -Description "Labbuildr Admin Runas Account"
Write-Output $runAsAccount
$hostGroup = Get-SCVMHostGroup -Name "All Hosts"
if ($Cluster)
    {
    $hvcluster = get-cluster hv*
    $HostCluster = Add-SCVMHostCluster -Name "$($hvcluster.name).$($hvcluster.Domain)" -VMHostGroup $hostGroup -Reassociate $true -Credential $runAsAccount -RemoteConnectEnabled $true
    Refresh-VMHostCluster -VMHostCluster $HostCluster -RunAsynchronously
    }
$hostGroups = @()
$hostGroups += Get-SCVMHostGroup 
$Newcloud = New-SCCloud -VMHostGroup $hostGroups -Name "Labbuildr" -Description "Labbuildr Cloud" 
$CloudCapacity = Get-SCCloudCapacity -Cloud $Newcloud
$CloudCapacity | Set-SCCloudCapacity -UseCustomQuotaCountMaximum $true -UseMemoryMBMaximum $true -UseCPUCountMaximum $true -UseStorageGBMaximum $true -UseVMCountMaximum $true
$Newcloud | Set-SCCloud
