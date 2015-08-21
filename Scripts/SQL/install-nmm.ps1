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
	[ValidateSet('nmm8212','nmm8214','nmm8216','nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82','nmm85','nmm85.BR1','nmm85.BR2','nmm85.BR3','nmm85.BR4')]
    $nmm_ver,
    [switch]$scvmm
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


if ($Nmm_ver -lt 'nmm85')
    {
    start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmm.log'  -Wait
    start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmmglr.log NW_INSTALLLEVEL=200 REBOOTMACHINE=0 NW_GLR_FEATURE=1 WRITECACHEDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs" MOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System" HYPERVMOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp" SETUPTYPE=Install"' -Wait
    }
else
    {
    Write-Warning "trying nwvss install"
    if ($setup = Get-ChildItem "\\vmware-host\shared folders\Sources\$nmm_ver\win_x64\networkr\nwvss.exe")
        {
        Start-Process -Wait -FilePath "$($Setup.fullname)" -ArgumentList "/s /q /log `"C:\scripts\NMM_nw_install_detail.log`" InstallLevel=200 RebootMachine=0 EnableSSMS=1 EnableSSMSBackupTab=1 EnableSSMSScript=1 NwGlrFeature=1 EnableClientPush=1 WriteCacheFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs`" MountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System`" BBBMountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\BBBMountPoint`" SetupType=Install"
        }
    else
        {
        Write-Error "Networker Setup File could not be evaluated"
        }
    }


if ($scvmm.IsPresent)
    {
    if ($nmm_ver -ge "nmm85" )
        {
        Write-Verbose "Installing Networker Extended Client" 
        $nw_ver = $nmm_ver -replace "nmm","nw"
        $Setuppath = "\\vmware-host\Shared Folders\Sources\$nw_ver\win_x64\networkr\lgtoxtdclnt-8.5.0.0.exe" 
        .$Builddir\test-setup -setup lgtoxtdclnt-8.5.0.0 -setuppath $Setuppath
        Start-Process $Setuppath -ArgumentList "/q" -Wait
        }
    $SCVMMPlugin = $NMM_VER -replace "nmm","scvmm"
    $Setuppath = "\\vmware-host\Shared Folders\Sources\$SCVMMPlugin\win_x64\SCVMM DP Add-in.exe" 
    .$Builddir\test-setup -setup NMM -setuppath $Setuppath
    Start-Process $Setuppath -ArgumentList "/q" -Wait
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
