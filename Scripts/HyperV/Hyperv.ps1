$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
Add-WindowsFeature Hyper-V, Hyper-V-Tools, Hyper-V-PowerShell, WindowsStorageManagementService
