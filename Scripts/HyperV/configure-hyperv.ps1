<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
   configure-hyperv does some basic post install configuration tasks
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
Write-Verbose "Setting Switches"
New-VMSwitch -Name External -NetAdapterName $env:USERDOMAIN -AllowManagementOS $True -Notes "Management,VM´s and External"
New-VMSwitch -Name Internal -SwitchType Internal -Notes "VM´s and VMHost"
New-VMSwitch -Name Internal -SwitchType Private -Notes "VM´s only"

