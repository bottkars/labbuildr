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
############
$nodename = $env:COMPUTERNAME
$Hypervisor = & 'C:\program files\VMware\Vmware Tools\vmtoolsd.exe' --cmd "info-get guestinfo.hypervisor" | Out-String
$Builddate = & 'C:\program files\VMware\Vmware Tools\vmtoolsd.exe' --cmd "info-get guestinfo.builddate" | Out-String
$Powerontime = & 'C:\program files\VMware\Vmware Tools\vmtoolsd.exe' --cmd "info-get guestinfo.powerontime" | Out-String
$Suspendtime = & 'C:\program files\VMware\Vmware Tools\vmtoolsd.exe' --cmd "info-get guestinfo.suspendtime" | Out-String
$object = New-Object psobject
$object | Add-Member -Type 'NoteProperty' -Name Hypervisor -Value $Hypervisor
$object | Add-Member -Type 'NoteProperty' -Name Builddate -Value $Builddate
$object | Add-Member -Type 'NoteProperty' -Name Suspendtime -Value $Suspendtime
$object | Add-Member -Type 'NoteProperty' -Name Powerontime -Value $Powerontime
Write-Output $object
