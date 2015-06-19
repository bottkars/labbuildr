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
[Parameter(Mandatory=$true)]
[ValidateSet('cu1', 'cu2', 'cu3', 'sp1','cu5','cu6','cu7','cu8','cu9')]$ex_cu,
$ex_version= "E2013",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Setupcmd = "Setup.exe"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"

$DB1 = "DB1_"+$env:COMPUTERNAME
$DBpath =  New-Item -ItemType Directory -Path M:\DB1
$LogPath = New-Item -ItemType Directory -Path N:\DB1

.$Builddir\test-sharedfolders.ps1

$Setuppath = "$SourcePath\$ex_version$ex_cu\$Setupcmd"
.$Builddir\test-setup -setup Exchange -setuppath $Setuppath


Start-Process $Setuppath -ArgumentList "/mode:Install /role:ClientAccess,Mailbox /OrganizationName:`"labbuildr`" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:M:\DB1\DB1.edb /LogFolderPath:N:\DB1" -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
# New-Item -ItemType File -Path "c:\scripts\exchange.pass"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
Restart-Computer