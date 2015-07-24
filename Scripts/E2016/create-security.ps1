$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
$SeService = "SeServiceLogonRight = *"
$SID = (get-aduser nmmbackupuser).SID.Value
$AddSecurity = @('[Unicode]','Unicode=yes','[Version]','signature="$CHICAGO$"','Revision =1','[Privilege Rights]',"$SeService$Sid")
$AddSecurity |  Add-Content -path c:\scripts\security.inf
secedit.exe /import /db secedit.sdb /cfg "C:\scripts\security.inf"
gpupdate.exe /force
