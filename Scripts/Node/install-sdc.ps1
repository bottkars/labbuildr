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
param (
[Parameter(Mandatory=$true)][ValidateSet('1.30-426.0','1.31-258.2','1.31-1277.3','1.31-2333.2','1.32-277.0','1.32-402.1','1.32-403.2')][alias('siover')]$ScaleIOVer,
[Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$mdma = "192.168.2.221",
[Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$mdmb = "192.168.2.222"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$ScaleIORoot = "\\vmware-host\shared folders\sources\Scaleio\"
$ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
.$Builddir\test-sharedfolders.ps1
$ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*mdm-$ScaleIOVer.msi").Directory.FullName
# $ScaleIOPath = "ScaleIO_$($ScaleIO_Major)_Complete_Windows_SW_Download\ScaleIO_$($ScaleIO_Major)_Windows_Download"
$role = "sdc"
$Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
.$Builddir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
$ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
$mdm_ip = "$mdma,$mdmb"
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --add_mdm --ip $mdm_ip
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --query_mdms
