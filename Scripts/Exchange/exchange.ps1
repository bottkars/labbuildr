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
$ex_cu
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
$DB1 = "DB1_"+$env:COMPUTERNAME
$DBpath =  New-Item -ItemType Directory -Path M:\DB1
$LogPath = New-Item -ItemType Directory -Path N:\DB1
."\\vmware-host\Shared Folders\Sources\E2013$ex_cu\Setup.exe" /mode:Install /role:ClientAccess,Mailbox /OrganizationName:"labbuildr" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:M:\DB1\DB1.edb /LogFolderPath:N:\DB1
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\$ScriptName.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Restart-Computer