<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
[cmdletBinding()] 
Param( 
[Parameter(Mandatory=$false)][string]$computer = ".",
[Parameter(Mandatory=$True)][string]$group, 
[Parameter(Mandatory=$false)][string]$domain = $Env:USERDOMAIN,
[Parameter(Mandatory=$True)][string]$user 
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot

$de = [ADSI]"WinNT://$computer/$Group,group" 
$de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path)