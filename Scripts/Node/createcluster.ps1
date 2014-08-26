<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param ([string]$Nodeprefix,$IPaddress)

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = $env:USERDOMAIN
$NodeLIST = @()
$Clusternodes = Get-ADComputer -Filter * | where name -like "$Nodeprefix*"
$Nodeprefix = $Nodeprefix.ToUpper()
$Nodeprefix = $Nodeprefix.TrimEnd("NODE")
$Clustername = $Nodeprefix+"Cluster"
foreach ($Clusternode in $Clusternodes){
$NodeLIST += $Clusternode.Name
write-Host " Enabling Cluster feature on Node $($Clusternode.Name)"
Add-WindowsFeature -Name failover-Clustering -IncludeManagementTools -ComputerName $Clusternode.Name
write-Host " Enabling MPIO on Node $($Clusternode.Name)"
Add-WindowsFeature -Name Multipath-IO -IncludeManagementTools -ComputerName $Clusternode.Name
}
New-Cluster -Name $Clustername -Node $NodeLIST -StaticAddress $IPAddress -NoStorage
Write-Host "Setting Cluster Access"
write-host "Changing PTR Record" 
########## changing cluster to register PTR record 
$res = Get-ClusterResource "Cluster Name" 
Set-ClusterParameter -Name PublishPTRRecords -Value 1 -InputObject $res
Stop-ClusterResource -Name $res
Start-ClusterResource -Name $res