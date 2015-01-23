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
[Parameter(Mandatory=$true)][ValidateSet('1.30-426.0','1.31-258.2')]$ver
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ver.msi"
.$Builddir\test-setup.ps1 -setup "Saleio$role$ver" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait

####sds checkup             
$role = "sds"
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ver.msi"
.$Builddir\test-setup -setup "Saleio$role$ver" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
####sdc checkup
$role = "sdc"
$Setuppath = "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-$role-$ver.msi"
.$Builddir\test-setup -setup "Saleio$role$ver" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait



Stop-Service ShellHWDetection
foreach ($Disk in (1..$Disks))
    {
    get-Disk  -Number $Disk | Initialize-Disk -PartitionStyle GPT
    get-Disk  -Number $Disk | New-Partition -UseMaximumSize -AssignDriveLetter # -DriveLetter $Driveletter
    }

Start-Service ShellHWDetection