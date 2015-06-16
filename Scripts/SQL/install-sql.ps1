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
[ValidateSet('SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014')]$SQLVER = "SQL2012SP1",
[switch]$DefaultDBpath,
[switch]$reboot
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
Switch ($SQLVER)
    {
    'SQL2012SP1'
        {
        $UpdateSource = "/UpdateSource=`"$SourcePath\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\SQLFULL_x64_ENU\$Setupcmd"
        .$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012SP2'
        {
        $UpdateSource = "/UpdateSource=`"$SourcePath\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\SQLFULL_x64_ENU\$Setupcmd"
        .$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012SP1SLIP'
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012'
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2014'
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    }
if (!$DefaultDBpath.IsPresent)
    {
    $Diskparameter = "/SQLUSERDBDIR=m:\ /SQLUSERDBLOGDIR=n:\ /SQLTEMPDBDIR=o:\ /SQLTEMPDBLOGDIR=p:\"
    }
$Arguments = "/q /ACTION=Install /FEATURES=SQL,SSMS $UpdateSource $Diskparameter /INSTANCENAME=MSSQL$Domain /SQLSVCACCOUNT=`"$Domain\svc_sqladm`" /SQLSVCPASSWORD=`"Password123!`" /SQLSYSADMINACCOUNTS=`"$Domain\svc_sqladm`" `"$Domain\Administrator`" `"$Domain\sql_admins`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /IACCEPTSQLSERVERLICENSETERMS"
Write-Verbose $Arguments
Write-Warning "Starting SQL Setup $SQLVER"
$Time = Measure-Command {Start-Process $Setuppath -ArgumentList  $Arguments -Wait}
$Time | Set-Content "$Builddir\sqlsetup$SQLVER.txt" -Force
If ($LASTEXITCODE -lt 0)
    {
    Write-Warning "Error $LASTEXITCODE during SQL SETUP, Please Check Ibstaller Logfile"
    Set-Content -Value $LASTEXITCODE -Path $Builddir\sqlexit.txt
    Pause
    }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "SQLPASS" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\sql.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
# New-Item -ItemType File -Path c:\scripts\sql.pass
if ($reboot.IsPresent)
    { 
    Restart-Computer
    }

