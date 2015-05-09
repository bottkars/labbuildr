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
$ex_version= "E2013",
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

$Setupcmd = "FilterPack64bit.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart

$Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }