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
$Domain,
$domainsuffix = ".local"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$MyDomain = $Domain+$domainsuffix
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass3" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\3.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Install-ADDSForest -DomainName $MyDomain -SkipPreChecks -safemodeadministratorpassword (convertto-securestring "Password123!" -asplaintext -force) -DomainMode Win2012 -DomainNetbiosname $Domain -ForestMode Win2012 -InstallDNS  -NoRebootOnCompletion -Force

    Pause

    Restart-Computer
    }
else
    {
    Install-ADDSForest -DomainName $MyDomain -SkipPreChecks -safemodeadministratorpassword (convertto-securestring "Password123!" -asplaintext -force) -DomainMode Win2012 -DomainNetbiosname $Domain -ForestMode Win2012 -InstallDNS -Force
    }