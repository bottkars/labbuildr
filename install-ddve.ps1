<#
.Synopsis
   .\install-ddve.ps1 -MasterPath F:\labbuildr\ddve-5.6.0.3-485123\
.DESCRIPTION
  install-ddve only applies to Testers of the Virtual DDVe
  install-ddve is a 1 Step Process.
  Once DDVE is downloaded via feedbckcentral, run 
   .\install-ddve.ps1 -defauls
   This creates a DDVE Master in your labbuildr directory.
   This installs a DDVE using the defaults file and the just extracted ddve Master
    
      
      Copyright 2016 Karsten Bott

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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-ddve
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
.EXAMPLE
    to create a 2TB Node DDvENde2 run
    .\install-ddve.ps1 -MasterPath .\ddve-5.5.1.4-464376  -Defaults -DDVESize 2TB -Verbose -Startnode 2 -Nodes 1
#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ova -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
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
0.5TB   |  6GB    |  2  |  1*500GB
  2TB   |  6GB    |  2  |  4*500GB
  4TB   |  8GB    |  2  |  8*500GB
  8TB   |  16GB   |  2  |  16*500GB

#>
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateSet('0.5TB','2TB','4TB','8TB')][string]$DDVESize = "2TB",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install", Mandatory = $true)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2"


)
#requires -version 3.0
#requires -module vmxtoolkit


switch ($PsCmdlet.ParameterSetName)
{

    "import"
        {
        if (!($mastername)) 
            {
            $OVFfile = Get-Item $ovf
            $mastername = $OVFfile.BaseName
            }
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Magenta  "Use .\install-ddve.ps1 -Masterpath .\$Mastername -Defaults"
        }

     default
        {
        If ($Defaults.IsPresent)
            {
            $labdefaults = Get-labDefaults
            if (!($labdefaults))
                {
                try
                    {
                    $labdefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                    }
                catch
                    {
                Write-Warning "no  defaults or example defaults found, exiting now"
                exit
                    }
            Write-Host -ForegroundColor Magenta " ==>Using generic defaults from labbuildr"
            }
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
            $DNS1 = $labdefaults.DNS2
            $configure = $true
            }
		if ($LabDefaults.custom_domainsuffix)
			{
			$custom_domainsuffix = $LabDefaults.custom_domainsuffix
			}
		else
			{
			$custom_domainsuffix = "local"
			}


        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

        $Builddir = $PSScriptRoot
        $Nodeprefix = "DDvENode"
        if (!$MasterVMX)
            {
            $MasterVMX = get-vmx Ddve-5.7* -WarningAction SilentlyContinue
            iF ($MasterVMX)
                {
                $MasterVMX = $MasterVMX | Sort-Object -Descending
                $MasterVMX = $MasterVMX[-1]
                }
            }
        else
            {
            if ($MasterPath)        
                {
                $MasterVMX = get-vmx -path $MasterPath -WarningAction SilentlyContinue
                }
            }

        if (!$MasterVMX)
            {
            write-Host -ForegroundColor Magenta "Could not find existing DDVEMaster"
            if ($Defaults.IsPresent)
                {
                Write-Host -ForegroundColor Magenta "Trying Latest OVF fom $Sourcedir"
                try
                    {
                    $OVFpath =Join-Path $Sourcedir "ddve-*.ov*" -ErrorAction Stop
                    }
                catch [System.Management.Automation.DriveNotFoundException] 
                    {
                    Write-Warning "Drive not found, make sure to have your Source Stick connected"
                    exit
                    }
                
                    $OVFfile = get-item -Path $OVFpath | Sort-Object -Descending -Property Name
                    If (!$OVFfile)
                        {
                        Write-Warning "No OVF for DDVE found, please conntact feedbackcentral"
                        exit
                        }
                    else 
                        {
                        Write-Host -ForegroundColor Magenta "testing OVA File"
                        $OVFfile = $OVFfile[0]
                        $mastername = $OVFfile.BaseName
                        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $OVFfile.FullName $PSScriptRoot #
                        if ($LASTEXITCODE -ne 0)
                            {
                            Write-Warning "Error Extraxting OVF"
                            exit
                            }
                        $MasterVMX = get-vmx $mastername -WarningAction SilentlyContinue
                        }
                }
            else
                {
                Write-Warning "Please import with -ovf or use -Defaults"
                exit
                }

            }


        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base"

        if (!$Basesnap) 
            {
            Write-Host -ForegroundColor Magenta " ==>Tweaking Base VMX"
            $config = Get-VMXConfig -config $MasterVMX.config
            $config = $config -notmatch "virtualhw.version"
            $config += 'virtualhw.version = "9"'
            $config = $config -notmatch 'scsi0:0.mode = "independent_persistent"'
            $config += 'scsi0:0.mode = "persistent"'
            $config = $config -notmatch 'scsi0:1.mode = "independent_persistent"'
            $config += 'scsi0:1.mode = "persistent"'
            foreach ($scsi in 0..3)
                {
                Write-Host -ForegroundColor Magenta " ==>Adding Adapter SCSI$scsi"
                $config = $config -notmatch "scsi$scsi.virtualDev"
                $config += 'scsi'+$scsi+'.virtualDev = "pvscsi"'
                $config = $config -notmatch "scsi$scsi.present"
                $config += 'scsi'+$scsi+'.present = "true"'
                }
            Set-Content -Path $MasterVMX.config -Value $config
            Write-verbose "Base snap does not exist, creating now"
            $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
            }
            # $Basesnap
            foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            Write-Verbose "Checking VM $Nodeprefix$node already Exists"
            If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
                {
                write-Host -ForegroundColor Magenta "Creating clone $Nodeprefix$node"
                $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
                switch ($DDvESize)
                    {
                "0.5TB"
                    {
                    Write-Verbose "0.5TB DDvE Selected"
                    $NumDisks = 1
                    $NumCrtl = 1
                    [uint64]$Disksize = 500GB
                    $memsize = 6044
                    $Numcpu = 2
                    }
                "2TB"
                    {
                    Write-Verbose "2TB DDvE Selected"
                    $NumDisks = 1
                    $NumCrtl = 4
                    [uint64]$Disksize = 500GB
                    $memsize = 6044
                    $Numcpu = 2
                    }
                "4TB"
                    {
                    Write-Verbose "4TB DDvE Selected"
                    $NumDisks = 2
                    $NumCrtl = 4
                    [uint64]$Disksize = 500GB
                    $memsize = 8192
                    $Numcpu = 2
                    }
                "8TB"
                    {
                    Write-Verbose "8TB DDvE Selected"
                    $NumDisks = 4
                    $NumCrtl = 4
                    [uint64]$Disksize = 500GB
                    $memsize = 8192
                    $Numcpu = 2
                    }

            }
            $scsi = 0
            Write-Host -ForegroundColor Magenta "Adding Disks"
            foreach ($LUN in (2..($NumDisks+1)))
                    {
                    $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                    Write-Host -ForegroundColor Magenta " ==>Building new Disk $Diskname"
                    $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                    Write-Host -ForegroundColor Magenta " ==>Adding Disk $Diskname to $($NodeClone.VMXname)"
                    $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                    }

            if ($NumCrtl -gt 1)
                {
                foreach ($SCSI in 1..($NumCrtl-1))
                    {
                    foreach ($LUN in (0..($NumDisks-1)))
                        {
                        $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                        Write-Host -ForegroundColor Magenta " ==>Building new Disk $Diskname"
                        $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                        Write-Host -ForegroundColor Magenta " ==>Adding Disk $Diskname to $($NodeClone.VMXname)"
                        $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                        }
                    }
                }
        
            Write-Host -ForegroundColor Magenta " ==>Configuring NIC0"
            $Netadater0 = $NodeClone | Set-VMXVnet -Adapter 0 -vnet $VMnet
            Write-Host -ForegroundColor Magenta " ==>Configuring NIC1"
            # $Netadater1 = $NodeClone | Set-VMXVnet -Adapter 1 -vnet vmnet8
            $Netadater1 = $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType nat -AdapterType vmxnet3
            # $Netadater1connected = $NodeClone | Connect-VMXNetworkAdapter -Adapter 1
            $Netadater1connected = $NodeClone | Disconnect-VMXNetworkAdapter -Adapter 1
            
            $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
            $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
            Write-Host -ForegroundColor Magenta " ==>Configuring Memory to $memsize"
            $Memory = $NodeClone | Set-VMXmemory -MemoryMB $memsize
            Write-Host -ForegroundColor Magenta " ==>Configuring $Numcpu CPUs"
            $Processor = $nodeclone | Set-VMXprocessor -Processorcount $Numcpu
            Write-Host -ForegroundColor Magenta " ==>Starting VM $($NodeClone.Clonename)"
            $NodeClone | start-vmx | Out-Null
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
    Write-host
    Write-host -ForegroundColor Blue "****** To Configure  DDVE 5.7 ******
Go to VMware Console an wait for system to boot"
    Write-host -ForegroundColor Blue "
    Please login with 
    localhost login : sysadmin 
    Password: changeme
    Change the Password or type no
    Answer yes for GUI Wizard
    Answer yes for Configure Network at this time
    Answer No for DHCP
    Enter $Nodeprefix$Node.$BuildDomain.$Custom_DomainSuffix as hostname
    Enter $BuildDomain.$Custom_DomainSuffix as DNSDomainname
    (The orde of the next command and Devicenames may vary from Version to Version )
Ethernet Port ethV1
    Enter NO for Enable Ethernet ethV1
Ethernet Port ethV1
    Enter Yes for Enable Ethernet Port ethV0
    Enter NO for DHCP
    Enter IP Address for ethV0:
    $subnet.2$Node as IP Address
    enter the netmask for ethV0:
    255.255.255.0
Default Gateway    
    Enter $DefaultGateway for Gateway IP Address
    Leave IPv6 Gateway Blank
DNS Server
    Enter $DNS1,$DNS2 as DNS Server
    Enter Save to Save

Open Your webbrowser to Configure Licences and Features !!!
"
    }# end default
}

