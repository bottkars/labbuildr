<#
.Synopsis

.DESCRIPTION
   import-viprva

   The Required vmware Master can be downloaded fro https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released#OtherTable,
   the customized esxi installimage can be found in https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released#SoftwareTable

   Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
.EXAMPLE
#>
[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$ViprOVA, 
[Parameter(Mandatory=$false)]$targetname = "vipr1",
[Parameter(Mandatory=$false)]$viprmaster = "viprmaster-2.2.1.0",
[Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0"


)
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

if (get-vmx $targetname)
    {
    Write-Warning " the Virtual Machine already exists"
    Break
    }


$Disks = ('disk1','disk2','disk5')
$masterpath = "$PSScriptRoot\$viprmaster"
$Missing = @()
foreach ($Disk in $Disks)
    {
    if (!(Test-Path -Path "$masterpath\*$Disk.vmdk"))
        {
        if (!$Viprova)
            { Write-Warning " wee need a OVA Template to extraxt. Please use -Viprova to specify a valid OVA"
            break
            }


        Write-warning "$Disk not found, deflating ViprDisk from OVA"
        & $global:vmwarepath\7za.exe x "-o$masterpath" -y $ViprOVA "*$Disk.vmdk" | out-null
        }

    }


Write-Warning "importing the disks "

if(!(Test-Path $PSScriptRoot\$targetname))
    {
    New-Item -ItemType Directory $PSScriptRoot\$targetname | Out-Null
    }
foreach ($Disk in $Disks)
    {
    
    $SOURCEDISK = Get-ChildItem -Path "$masterpath\vipr-*$disk.vmdk"
    $TargetDisk = "$PSScriptRoot\$targetname\$Disk.vmdk"
    if (Test-Path $TargetDisk)
        { 
        write-warning "Master $TargetDisk already present, no conversion needed"
        }
    else
        {
        write-warning "converting $TargetDisk"
        & $VMwarepath\vmware-vdiskmanager.exe -r $SOURCEDISK.FullName -t 0 $TargetDisk  2>&1 | Out-Null
        If ($Disk -match "Disk5")
            {
            # will need this for the storageos installer once figure out ovf-env disk :-)
            # & $VMwarepath\vmware-vdiskmanager.exe $PSScriptRoot\$targetname\disk3.vmdk -x 122GB
            }
        }
    }


# & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$targetname $masterpath\viprmaster.ovf $PSScriptRoot 
Write-Verbose " Copy base vm config to new master"

Copy-Item $PSScriptRoot\scripts\viprmaster\viprmaster.vmx $targetname\$targetname.vmx
$vmx = get-vmx $targetname
$vmx | Set-VMXNetworkAdapter -Adapter 0 -AdapterType vmxnet3 -ConnectionType custom
$vmx | Set-VMXVnet -Adapter 0 -vnet vmnet2
$vmx | Set-VMXDisplayName -DisplayName $targetname
Write-Verbose "Generating CDROM"
$ovfenv = Get-Content $PSScriptRoot\scripts\viprmaster\ovf-env.xml
$ovfenv -replace "192.168.2",$subnet | Set-Content -Path $PSScriptRoot\scripts\viprmaster\cd\ovf-env.xml -Force
convert-VMXdos2unix -Sourcefile $PSScriptRoot\scripts\viprmaster\cd\ovf-env.xml -Verbose
& $Global:vmwarepath\mkisofs.exe -J -R -o "$PSScriptRoot\$Targetname\vipr.iso" $PSScriptRoot\scripts\viprmaster\cd 2>&1 | Out-Null
$config = $vmx | get-vmxconfig
    write-verbose "injecting CDROM"
    $config = $config | where {$_ -NotMatch "ide0:0"}
    $config += 'ide0:0.present = "TRUE"'
    $config += 'ide0:0.fileName = "vipr.iso"'
    $config += 'ide0:0.deviceType = "cdrom-image"'
$Config | set-Content -Path $vmx.config
$vmx | Start-VMX
Write-Host -ForegroundColor Yellow "
wait a view minutes for storageos to be up and running
point your browser to https://vipr1 and follow the wizard steps
"

