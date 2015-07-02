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
[string]$AFTD = "aftd1")
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Domain = (get-addomain).name
$devicepath = Join-Path "C:\" $AFTD
new-item -Type  Directory -Path $devicepath
New-SmbShare -Description "$AFTD Direct Access" -Path $devicepath -Name $AFTD -FullAccess "$Domain\Domain Users"
$device = Get-ChildItem -Path C:\Scripts -Filter nsrdevice.txt
$content = Get-Content -path $device.fullname
$Devicefile = Join-Path "$Builddir" "$AFTD.txt"
$content | foreach {$_ -replace "AFTD", "$AFTD"} | Set-Content $Devicefile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $Devicefile
