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
param ()
do {

    $Enabled = Test-Path "\\vmware-host\shared folders"
    if ($Enabled -notmatch $True)
        { 
        write-warning "Shared folders not available. Please run set-vmxsharedfolderstate -enable fom labbuildr commandline or enable from vm ui"
        write-warning "Script will continue once enabled"
        $([char]7)
        Start-Sleep -Seconds 5
        }
    }
until ($Enabled -match $true)
write-warning "Shared-Folders are enabled"
