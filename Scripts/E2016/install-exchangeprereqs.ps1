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
$ex_version= "E2016",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Prereq ="Prereq"
)

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
.$Builddir\test-sharedfolders.ps1


$Setupcmd = "UcmaRuntimeSetup.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart

$Setupcmd = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/passive /norestart" -Wait
<#
$Setupcmd = "FilterPack64bit.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart

$Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart
#>
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
