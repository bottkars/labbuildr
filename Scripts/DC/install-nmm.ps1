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
	[ValidateSet('nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82')]$nmm_ver = "nmm821"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\Shared Folders\Sources\$nmm_ver\win_x64\networkr\setup.exe" 
.$Builddir\test-setup -setup NMM -setuppath $Setuppath

start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmm.log"' -wait # -verb "RunAs" | Out-Host
