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
$SCVMMVER = "SCVMM2012R2",
$SourcePath = "\\vmware-host\Shared Folders\Sources"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = $env:USERDOMAIN
$Setupcmd = "setup.exe"
$Setuppath = "$SourcePath\$SCVMMVER\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting $SCVMMVER setup, this may take a while"
start-process "$Setuppath" -ArgumentList "/server /i /f C:\scripts\VMServer.ini /SqlDBAdminDomain $Domain /SqlDBAdminName SVC_SQL /SqlDBAdminPassword Password123! /VmmServiceDomain $Domain /VmmServiceUserName SVC_SCVMM /VmmServiceUserPassword Password123! /IACCEPTSCEULA" -Wait 
write-verbose "Checking for Updates"
foreach ($Updatepattern in ("*vmmserver*.msp","*Admin*.msp"))
    {
    $VMMUpdate = Get-ChildItem "$SourcePath\$SCVMMVER\updates"  -Filter $Updatepattern
    if ($VMMUpdate)
        {
        $VMMUpdate = $VMMUpdate | Sort-Object -Property Name -Descending
	    $LatestVMMUpdate = $VMMUpdate[0]
        .$Builddir\test-setup -setup $LatestVMMUpdate.BaseName -setuppath $LatestVMMUpdate.FullName
        Write-Warning "Starting VMM Patch setup, this may take a while"
        start-process $LatestVMMUpdate.FullName -ArgumentList "/Passive" -Wait 
        }
    }
