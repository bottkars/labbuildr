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
    [ValidateSet('1.2.6')]
    $puppetagentver='1.2.6',
    $Puppetmaster = 'PuppetMaster1'
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

$Puppetmaster = "$Puppetmaster.$env:USERDOMAIN"
.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\Shared Folders\Sources\Puppet\puppet-agent-$puppetagentver-x64.msi"
.$Builddir\test-setup -setup PuppetAgent -setuppath $Setuppath
Write-Warning "Installing Puppet Agent $puppetagentver"
$PuppetArgs = '/qn /norestart /i "'+$Setuppath+'" PUPPET_MASTER_SERVER='+$Puppetmaster
Start-Process -FilePath "msiexec.exe" -ArgumentList $PuppetArgs -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
