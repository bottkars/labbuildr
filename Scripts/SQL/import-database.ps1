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