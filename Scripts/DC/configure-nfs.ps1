<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Dirname = "nfs"
$Sharename = $env:USERDOMAIN+$dirname
$nfsdir = join-path $env:SystemDrive $Dirname
Add-WindowsFeature fs-nfs-service -IncludeManagementTools
New-Item -ItemType directory c:\nfs
New-NfsShare -Name $sharename -Path $nfsdir  -Permission readwrite  -Authentication sys -unmapped $true -AllowRootAccess $true
