<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
[CmdletBinding()]
param(
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Prereq ="Prereq",
[ValidateSet('SQL2012SP1','SQL2012SP2', 'SQL2014')]$SQLVER = "SQL2012SP1"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############ addin Domin Service Accounts
$Domain = $env:USERDOMAIN
net localgroup "Backup Operators" $Domain\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SCVMM /Add
$Files = Get-ChildItem -Path $Builddir -Filter Configuration*.ini
foreach ($file in $Files) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
}
$Setupcmd = "setup.exe"
$Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting $SQLVER"
Start-Process $Setuppath -ArgumentList "/q /ACTION=Install /FEATURES=SQL,SSMS /INSTANCENAME=MSSQL$env:Computername /SQLSVCACCOUNT=`"$Domain\svc_sql`" /SQLSVCPASSWORD=`"Password123!`" /SQLSYSADMINACCOUNTS=`"$Domain\svc_sqladm`" `"$Domain\Administrator`" `"$Domain\svc_sql`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /IACCEPTSQLSERVERLICENSETERMS" -Wait
