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
param (

)

function Createvolume {
param ($Number,$Label,$letter)
Set-Disk -Number $Number -IsReadOnly  $false 
Set-Disk -Number $Number -IsOffline  $false
Initialize-Disk -Number $Number -PartitionStyle GPT
$Partition = New-Partition -DiskNumber $Number -UseMaximumSize 
$Job = Format-Volume -Partition $Partition -NewFileSystemLabel $Label -AllocationUnitSize 64kb -FileSystem NTFS -Force -AsJob
while ($JOB.state -ne "completed"){}
$Partition | Set-Partition -NewDriveLetter $letter
}

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
###########
Createvolume -Number 1 -Label $env:COMPUTERNAME"_DB1" -letter M
Createvolume -Number 2 -Label $env:COMPUTERNAME"_LOG1" -letter N
Createvolume -Number 3 -Label $env:COMPUTERNAME"_DAG_DB1" -letter O
Createvolume -Number 4 -Label $env:COMPUTERNAME"_DAG_LOG1" -letter P
Createvolume -Number 5 -Label $env:COMPUTERNAME"_RDB" -letter R
Createvolume -Number 6 -Label $env:COMPUTERNAME"_RDBLOG" -letter S
