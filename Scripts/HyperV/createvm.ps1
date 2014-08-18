<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
$vmname = $env:COMPUTERNAME+"VM1"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
New-Item -Type Directory -Path c:\VHDS
copy-Item "\\vmware-host\Shared Folders\Sources\brs1.vhdx" "c:\vhds\$vmname.vhdx"
New-VM -Name $vmname -VHDPath "c:\vhds\$vmname.VHDX"
