param(
$nmm_ver
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
start-process -filepath "\\vmware-host\Shared Folders\Sources\$nmm_ver\win_x64\networkr\setup.exe" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmm.log' -verb "RunAs" | Out-Host
start-process -filepath "\\vmware-host\Shared Folders\Sources\$nmm_ver\win_x64\networkr\setup.exe" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmmglr.log NW_INSTALLLEVEL=200 REBOOTMACHINE=0 NW_GLR_FEATURE=1 WRITECACHEDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs" MOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System" HYPERVMOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp" SETUPTYPE=Install"' -verb "RunAs" | Out-Host
