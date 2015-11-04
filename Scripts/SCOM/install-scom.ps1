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
    [ValidateSet('SC2012_R2_SCOM')]
    $SCOMver='SC2012_R2_SCOM',
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $Prereq ="Prereq"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

.$Builddir\test-sharedfolders.ps1

$Setupcmd = "SQLSysClrTypes.msi"
$Setuppath = "$SourcePath\$SCOMver$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting SQL Cleartype Setup"
Start-Process $Setuppath -ArgumentList "/q"


$Setupcmd = "ReportViewer.msi"
$Setuppath = "$SourcePath\$SCOMver$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting Report Viewer Setup"
Start-Process $Setuppath -ArgumentList "/q"


if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

