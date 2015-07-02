<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3

[CmdletBinding()]
Param
(
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = $env:USERDOMAIN
############
$env:PSModulePath = "$env:PSModulePath;C:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules\;C:\Program Files (x86)\Microsoft SQL Server\110\Tools\PowerShell\Modules\"
Import-Module sqlps
$BCMD = "
USE [master]
GO
RESTORE DATABASE [AdventureWorks2012] 
	FROM  DISK = N'\\vmware-host\Shared Folders\Sources\AWORKS\AdventureWorks2012.bak' 
	WITH  FILE = 1,  
	MOVE N'AdventureWorks2012_Data' TO N'm:\AdventureWorks_Data.mdf',  
	MOVE N'AdventureWorks2012_Log' TO N'n:\AdventureWorks_Log.ldf',  
	NOUNLOAD,  STATS = 10
"
Invoke-Sqlcmd -Query $BCMD -ServerInstance "$env:COMPUTERNAME\MSSQL$Domain" -Verbose
