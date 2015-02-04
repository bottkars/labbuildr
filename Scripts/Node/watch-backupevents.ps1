<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>

[CmdletBinding()]
param (
[string]$Computername
)
#requires -version 3

$Host.UI.RawUI.WindowTitle = "$Computername"
do {Get-EventLog -LogName Application -Newest 20 -ComputerName $Computername -Source VSS,Networker,Nmm;Sort-Object Time -Descending; sleep 5 ;Clear-Host } 
until ($false)