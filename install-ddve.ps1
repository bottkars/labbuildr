<#
.Synopsis
   .\install-ddve.ps1 -MasterPath F:\labbuildr\ddve-5.6.0.3-485123\
.DESCRIPTION
  install-ddve only applies to internal Testers of the Virtual DDVe
      
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
   https://community.emc.com/blogs/bottk/
.EXAMPLE
    Importing the ovf template
 .\install-ddve.ps1 -ovf G:\Sources\ddve-5.6.0.3-485123\ddve-5.6.0.3-485123.ovf
    Opening OVF source: G:\Sources\ddve-5.6.0.3-485123\ddve-5.6.0.3-485123.ovf
    The manifest does not validate
    Opening VMX target: F:\labbuildr_beta
    Warning:
    - Hardware compatibility check is disabled.
    - Line 54: Unsupported virtual hardware device 'VirtualSCSI'.
    Writing VMX file: F:\labbuildr_beta\ddve-5.6.0.3-485123\ddve-5.6.0.3-485123.vmx
    Transfer Completed
    Warning:
    - ExtraConfig option 'tools.guestlib.enableHostInfo' is not allowed, will skip it.
    - ExtraConfig option 'sched.mem.pin' is not allowed, will skip it.
    Completed successfully
.EXAMPLE
    Install a DDVeNode with defaults from defaults.xml
    .\install-ddve.ps1 -MasterPath .\ddve-5.6.0.3-485123\ -Defaults
    WARNING: VM Path does currently not exist
    WARNING: Get-VMX : VM does currently not exist

    VMXname   Status  Starttime
    -------   ------  ---------
    DDvENode1 Started 07.21.2015 12:27:11
#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername,

#[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]$MasterPath,
<# specify your desireed DDVE Size 
Valid Parameters:2TB,4TB,8TB
This will result in the following
Machine Configurations:
=================================
Size    | Memory  | CPU | Disk
_____ __|_________|_____|_________
  2TB   |  4GB    |  2  |  1*500GB
  4TB   |  6GB    |  2  |  1*500GB
  8TB   |  8GB    |  2  |  1*500GB

#>
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateSet('2TB')][string]$DDVESize = "2TB",
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install", Mandatory = $true)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2"

# [Parameter(Mandatory = $false)][switch]$configure



)
#requires -version 3.0
#requires -module vmxtoolkit


switch ($PsCmdlet.ParameterSetName)
{

    "import"
        {
        if (!($mastername)) 
            {
            $mastername = (Split-Path -Leaf $ovf).Replace(".ovf","")
            }
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Output "Use install-ddve -Master $Mastername"
        }

     default
        {
        If ($Defaults.IsPresent)
            {
            $labdefaults = Get-labDefaults
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
            $configure = $true
            }


        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

        $Builddir = $PSScriptRoot
        $Nodeprefix = "DDvENode"

        $MasterVMX = get-vmx -path $MasterPath

        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"

        if (!$Basesnap) 
            {
            write-verbose "Tweaking Base VMX"
            $config = Get-VMXConfig -config $MasterVMX.config
            $config = $config -notmatch "scsi0.virtualDev"
            $config += 'scsi0.virtualDev = "pvscsi"'
            $config = $config -notmatch "virtualhw.version"
            $config += 'virtualhw.version = "9"'
            $config = $config -notmatch 'scsi0:0.mode = "independent_persistent"'
            $config += 'scsi0:0.mode = "persistent"'
            Set-Content -Path $MasterVMX.config -Value $config
            Write-verbose "Base snap does not exist, creating now"
            $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
            }
            # $Basesnap
            foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            Write-Verbose "Checking VM $Nodeprefix$node already Exists"
            If (!(get-vmx -path $Nodeprefix$node))
                {
                write-verbose "Creating clone $Nodeprefix$node"
                $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir"
                $SCSI= 0
                switch ($DDvESize)
                    {
                "2TB"
                    {
                    Write-Verbose "2TB DDvE Selected"
                    $NumDisks = 1
                    $Disksize = "500GB"
                    $memsize = 6044
                    $Numcpu = 2
                    }

            }
            
            foreach ($LUN in (2..($NumDisks+1)))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        
    Write-Verbose "Configuring NIC0"
    $Netadater0 = $NodeClone | Set-VMXVnet -Adapter 0 -vnet vmnet2
    Write-Verbose "Configuring NIC1"
    $Netadater1 = $NodeClone | Set-VMXVnet -Adapter 1 -vnet vmnet2
    $Netadater1connected = $NodeClone | Connect-VMXNetworkAdapter -Adapter 1
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
    Write-Verbose "Configuring Memory to $memsize"
    $Memory = $NodeClone | Set-VMXmemory -MemoryMB $memsize
    Write-Verbose "Configuring $Numcpu CPUs"
    $Processor = $nodeclone | Set-VMXprocessor -Processorcount $Numcpu
    Write-Verbose "Starting VM $($NodeClone.Clonename)"
    $NodeClone | start-vmx
    if ($configure.IsPresent)
    {
    $ip="$subnet.2$Node"
    }
    }
    else
        {
        Write-Warning "Node $Nodeprefix$node already exists"
        }

}
}
}

