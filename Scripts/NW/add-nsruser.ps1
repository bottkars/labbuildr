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
[Parameter(mandatory = $true)]$BackupAdmin,
[Parameter(mandatory = $true)]$Hostprefix
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############


foreach ($Client in (Get-ADComputer -Filter * | where name -match "$Hostprefix*").DNSHostname) 
{ 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=$BackupAdmin,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SYSTEM,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=Administrator,host=$Client"
}
