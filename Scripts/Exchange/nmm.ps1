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
	[ValidateSet('nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82')]$nmm_ver = "nmm821"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

$Domain = $env:USERDOMAIN
Write-Verbose $Domain

.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\Shared Folders\Sources\$nmm_ver\win_x64\networkr\setup.exe" 
.$Builddir\test-setup -setup NMM -setuppath $Setuppath

$argumentlist = '/s /v" /qn /l*v c:\scripts\nmm.log RMEXCHDOMAIN='+$Domain+' RMEXCHUSER=NMMBackupUser RMEXCHPASSWORD=Password123! RMCPORT=6730 RMDPORT=6731"'
start-process -filepath "$Setuppath" -ArgumentList $argumentlist -wait
 #| out-host
# start-process -filepath "\\vmware-host\Shared Folders\Sources\$nmm_ver\win_x64\networkr\setup.exe" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmmglr.log NW_INSTALLLEVEL=200 REBOOTMACHINE=0 NW_GLR_FEATURE=1 WRITECACHEDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs" MOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System" HYPERVMOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp" SETUPTYPE=Install"' -Wait