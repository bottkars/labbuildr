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

)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
.$Builddir\test-sharedfolders.ps1
$Sourcepath = "\\vmware-host\shared folders\sources\SP2013sp1fndtn"
$Prereqpath = "$Sourcepath"+"Prereq"
$Setuppath = "$Sourcepath\PrerequisiteInstaller.exe"
.$Builddir\test-setup.ps1 -setup "Sharepoint 2013" -setuppath $Setuppath

$arguments = "/SQLNCli:`"$Prereqpath\sqlncli.msi`" /IDFX:`"$Prereqpath\Windows6.1-KB974405-x64.msu`" /IDFX11:`"$Prereqpath\MicrosoftIdentityExtensions-64.msi`" /Sync:`"$Prereqpath\Synchronization.msi`" /AppFabric:`"$Prereqpath\WindowsServerAppFabricSetup_x64.exe`" /KB2671763:`"$Prereqpath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe`" /MSIPCClient:`"$Prereqpath\setup_msipc_x64.msi`" /WCFDataServices:`"$Prereqpath\WcfDataServices.exe`"" #>


Set-Content -Path "$Sourcepath\PrerequisiteInstaller.Arguments.txt" -Value $arguments

Start-Process $Setuppath -ArgumentList "/unattended" -Wait
