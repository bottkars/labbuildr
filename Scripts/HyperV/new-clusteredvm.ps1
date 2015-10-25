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
[string]$vmname = "HV-VM1",
[string]$sourcevhd = "\\vmware-host\Shared Folders\Sources\HyperV\9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd",
[string]$Clustervolume = "C:\ClusterStorage\Volume1"
)
if (!(Test-Path $sourcevhd))
    {
    Write-Warning "Source VHD $sourcevhd does not exist, please download a Source VHD"
    break
    }

if  (get-vm $vmname -erroraction silentlycontinue)
    {
    Write-Warning "VM $vmname already exists"
    break
    }



if (!(Test-Path "$Clustervolume\vhds\$vmname"))
    {
    New-Item -ItemType Directory -Path "$Clustervolume\$vmname\" -Force
    }
Write-Warning "Copyig VHD File $Sourcevhd to $Clustervolume, This may Take a While"
$Targetfile = Copy-Item $sourcevhd -Destination "$Clustervolume\$vmname\$vmname.vhd" -PassThru

$NewVM = New-VM -Name $vmname -Path $Clustervolume -Memory 512MB  -VHDPath $Targetfile.FullName -SwitchName External
$NewVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 128MB -StartupBytes 512MB -MaximumBytes 2GB -Priority 80 -Buffer 25
$NewVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
$Newvm | Set-VM –AutomaticStartAction Start
$NewVM | Add-ClusterVirtualMachineRole 
$NewVM | start-vm
$NewVM | Get-VM
