param(
$ex_cu
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
$DB1 = "DB1_"+$env:COMPUTERNAME
$DBpath =  New-Item -ItemType Directory -Path M:\DB1
$LogPath = New-Item -ItemType Directory -Path N:\DB1
."\\vmware-host\Shared Folders\Sources\E2013$ex_cu\Setup.exe" /mode:Install /role:ClientAccess,Mailbox /OrganizationName:"labbuildr" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:M:\DB1\DB1.edb /LogFolderPath:N:\DB1
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\$ScriptName.pass`""
Restart-Computer
