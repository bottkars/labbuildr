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
    [ValidateSet('3.7.0.0','3.6.0.3')]
    $SRM_VER='3.7.0.0')
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\shared folders\Sources\ViPR_SRM_$($SRM_VER)_Win64.exe"
.$Builddir\test-setup -setup SRM -setuppath $Setuppath
Write-Warning "Installing SRM $SRM_VER"
Start-Process -FilePath $Setuppath -ArgumentList "/S" -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

