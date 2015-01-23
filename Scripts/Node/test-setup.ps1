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
[parameter(Mandatory = $true)]$setup,
[parameter(Mandatory = $true)]$setuppath

)
do {

    $pathok = Test-Path $Setuppath
    if ($pathok -notmatch $True)
        { 
        write-warning "we can not find $setup Sources $Setuppath ! Make sure the you have downloaded the required sources"
        write-warning "Script will continue once the required $setup Sources are in available "
        $([char]7)
        Start-Sleep -Seconds 5
        }
    }
until ($pathok -match $true)
write-warning "found $setuppath"
