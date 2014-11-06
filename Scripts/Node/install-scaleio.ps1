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

[Parameter(Mandatory=$true)][ValidateSet('MDM','TB','SDS')]$role,
[Parameter(Mandatory=$true)]$Disks
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"


switch ($role)
		{
			"MDM" {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-mdm-1.30-426.0.msi" /quiet' -PassThru -Wait
                  }
             "TB" {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-tb-1.30-426.0.msi" /quiet' -PassThru -Wait
                  }
         }
             
Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-sdc-1.30-426.0.msi" /quiet' -PassThru -Wait
Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-sds-1.30-426.0.msi" /quiet' -PassThru -Wait
# Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "\\vmware-host\shared folders\sources\Scaleio\Windows\EMC-ScaleIO-lia-1.30-426.0.msi" /quiet' -PassThru -Wait

Stop-Service ShellHWDetection
foreach ($Disk in (1..$Disks))
    {
    get-Disk  -Number $Disk | Initialize-Disk -PartitionStyle GPT
    get-Disk  -Number $Disk | New-Partition -UseMaximumSize -AssignDriveLetter # -DriveLetter $Driveletter
    }

Start-Service ShellHWDetection