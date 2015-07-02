<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
param(
    [string]$ddname = "ddvenode1",
    [string]$Community = "networker"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = (get-addomain).name
$device = Get-ChildItem -Path C:\Scripts -Filter dd.txt
$content = Get-Content -path $device.fullname
$Devicefile = Join-Path "$Builddir" "$ddname.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $Devicefile
$pool = Get-ChildItem -Path C:\Scripts -Filter ddpool.txt
$content = Get-Content -path $pool.fullname
$poolfile = Join-Path "$Builddir" "$ddname.pool.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $poolfile
$label = Get-ChildItem -Path C:\Scripts -Filter ddlabel.txt
$content = Get-Content -path $label.fullname
$labelfile = Join-Path "$Builddir" "$ddname.label.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $labelfile
$snmp = Get-ChildItem -Path C:\Scripts -Filter ddsnmp.txt
$content = Get-Content -path $snmp.fullname
$snmpfile = Join-Path "$Builddir" "$ddname.snmp.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} 
$content | foreach {$_ -replace "networker", "$Community"} | Set-Content $snmpfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $labelfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $Devicefile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $poolfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $snmpfile
