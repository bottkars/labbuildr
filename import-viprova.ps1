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
    PS E:\LABBUILDR> .\install-esxi.ps1 -Nodes 2 -Startnode 2 -Disks 3 -Disksize 146GB -subnet 10.0.0.0 -BuildDomain labbuildr -esxiso C:\sources\ESX\ESXi-5.5.0-1331820-labbuildr-ks.iso -ESXIMasterPath '.\VMware ESXi 5' -Verbose
#>
[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$ViprOVA, 
#= 'h:\_EMC-VAs\ViPR v2.2\vipr-2.2.0.0.1043-controller-1+0.ova',
[Parameter(Mandatory=$false)]$targetname = "viprtest"
)

if (get-vmx $targetname)
    {
    Write-Warning " the Virtual Machine already exists"
    Break
    }


$Disks = ('disk1','disk2','disk5')

$masterpath = "$PSScriptRoot\viprmaster"
$Missing = @()
foreach ($Disk in $Disks)
    {
    if (!(Test-Path -Path "$masterpath\*$Disk.vmdk"))
        {
        if (!$Viprova)
            { Write-Warning " wee need a OVA Template to extraxt. Please use -Viprova to specify a valid OVA"
            break
            }

        Write-Verbose "$Disk not found, deflating ViprDisk from OVA"
        & $global:vmwarepath\7za.exe x "-o$masterpath" -y $ViprOVA "*$Disk.vmdk" | out-null
        }

    }
& $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$targetname $masterpath\viprmaster.ovf $PSScriptRoot 

$vmx = get-vmx $targetname

$vmx | Set-VMXNetworkAdapter -Adapter 0 -AdapterType vmxnet3 -ConnectionType custom
$vmx | Set-VMXVnet -Adapter 0 -vnet vmnet2
Write-Verbose "Generating CDROM"
& $Global:vmwarepath\mkisofs.exe -J -R -o "$PSScriptRoot\$Targetname\vipr.iso" e:\vipr2.2\cd

$config = $vmx | get-vmxconfig
    write-verbose "injecting CDROM"
    $config = $config | where {$_ -NotMatch "ide0:0"}
    $config += 'ide0:0.present = "TRUE"'
    $config += 'ide0:0.fileName = "vipr.iso"'
    $config += 'ide0:0.deviceType = "cdrom-image"'
$Config | set-Content -Path $vmx.config

$vmx | Start-VMX

