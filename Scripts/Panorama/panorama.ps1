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

)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
$SMBSERVER = Split-Path -Leaf $env:LOGONSERVER
Invoke-Command -ComputerName $SMBSERVER -ScriptBlock {
    New-Item -ItemType Directory -Path c:\panorama
    New-SmbShare -FullAccess "Domain Users" -Path c:\panorama -Name Panorama
    }
Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\Shared Folders\Sources\Panorama\Syncplicity Panorama.msi" /passive' -PassThru -Wait
Start-Process http://localhost:9000
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
