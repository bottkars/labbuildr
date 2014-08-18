$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log"
$nsrmsg = ""
## doing dirty checks :-)
$Domain = (get-addomain).DNSRoot
$nwlabel = "nwserver."+$Domain

do { ($nsrmsg = & 'C:\Program Files\EMC NetWorker\nsr\bin\nsrmm.exe' -l -b Default -m) 2>&1 | Out-Null 
write-host $nsrmsg
  }
until (($nwlabel.Length+43) -eq $nsrmsg.length)
# until ($nsrmsg -match "Using volume name")
& 'C:\Program Files\EMC NetWorker\nsr\bin\savegrp.exe' Exchange_DAG
pause
