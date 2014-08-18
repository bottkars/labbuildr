<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############

$Domain = (get-addomain).name
foreach ($Client in (Get-ADComputer -Filter *).DNSHOSTname)
{
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SYSTEM,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=Administrator,host=$Client"
}


foreach ($Client in (Get-ADComputer -Filter * | where name -match "E2013*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=NMMBAckupUser,host=$Client"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "*DAG*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=NMMBAckupUser,host=$Client"
}

foreach ($SID in (Get-ADGroup -Filter * | where name -eq "Administrators").SID.Value) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "Group=Administrators,Groupsid=$SID"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "AAG*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SVC_SQLADM,host=$Client"
}
