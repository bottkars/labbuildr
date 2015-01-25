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
[ValidateSet('nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81', 'nwunknown')]$nw_ver = "nw821"

)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############

.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\Shared Folders\Sources\$NW_ver\win_x64\networkr\setup.exe"
.$Builddir\test-setup -setup NetworkerClient -setuppath $Setuppath



start-process -filepath "$Setuppath" -ArgumentList '/S /v" /passive /l*v c:\scripts\nwclientsetup.log NW_INSTALLLEVEL=100 NW_FIREWALL_CONFIG=1 INSTALLBBB=1 NWREBOOT=0 setuptype=Install"' -wait 