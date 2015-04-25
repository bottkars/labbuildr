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

[Parameter(Mandatory=$true)][ValidateSet('MDM','TB','SDS','SDC')]$role,
[Parameter(Mandatory=$true)]$Disks,
[Parameter(Mandatory=$true)][ValidateSet('1.30-426.0','1.31-258.2','1.31-1277.3','1.31-2333.2')][alias('siover')]$ScaleIOVer
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ScaleIOVer.msi"
.$Builddir\test-setup.ps1 -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait

####sds checkup             
$role = "sds"
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ScaleIOVer.msi"
.$Builddir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
####sdc checkup
$role = "sdc"
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ScaleIOVer.msi"
.$Builddir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait

Write-Verbose "Preparing Disks"
# $Disks = (get-disk).count-1
Write-Host $Disks
# Stop-Service ShellHWDetection
$PrepareDisk = "'C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe'" 
foreach ($Disk in 1..$Disks)
    {
    Write-Output $Disk
    $Drive = "\\?\PhysicalDrive$Disk"
    Write-Output $Drive
    do {
        Write-Output "Testing ScaleIO Device"
        Start-Process -FilePath "C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe" -ArgumentList "$Drive" -Wait
        # sleep 5
        }
    until (Test-Path "c:\scaleio_devices\PhysicalDrive$Disk")
    # get-Disk  -Number $Disk | Initialize-Disk -PartitionStyle GPT
    # get-Disk  -Number $Disk | New-Partition -UseMaximumSize -AssignDriveLetter # -DriveLetter $Driveletter
    }
# Start-Service ShellHWDetection