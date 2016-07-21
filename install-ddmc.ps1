<#
.Synopsis
   .\install-ddmc.ps1 -Masterpath .\ddmc-1.4.5.2-535679 -Defaults
  install-ddmc only applies to Testers of the Virtual ddmc
  install-ddmc is a 1 Step Process.
  Once ddmc is downloaded via feedbckcentral, run 
   .\install-ddmc.ps1 -defauls
   This creates a ddmc Master in your labbuildr directory.
   This installs a ddmc using the defaults file and the just extracted ddmc Master
    
      
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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-ddmc
.EXAMPLE
    Importing the ovf template
 .\install-ddmc.ps1 -ovf E:\EMC_VAs\ddmc-1.4.5.2-535679\ddmc-1.4.5.2-535679.ovf
    Opening OVF source: E:\EMC_VAs\ddmc-1.4.5.2-535679\ddmc-1.4.5.2-535679.ovf
    The manifest does not validate
    Opening VMX target: F:\labbuildr_beta
    Warning:
    - Hardware compatibility check is disabled.
    - Line 54: Unsupported virtual hardware device 'VirtualSCSI'.
    Writing VMX file: F:\labbuildr_beta\ddmc-1.4.5.2-535679\ddmc-1.4.5.2-535679.vmx
    Transfer Completed
    Warning:
    - ExtraConfig option 'tools.guestlib.enableHostInfo' is not allowed, will skip it.
    - ExtraConfig option 'sched.mem.pin' is not allowed, will skip it.
    Completed successfully
.EXAMPLE
    Install a ddmcNode with defaults from defaults.xml
   .\install-ddmc.ps1 -Masterpath .\ddmc-1.4.5.2-535679 -Defaults
    WARNING: VM Path does currently not exist
    WARNING: Get-VMX : VM does currently not exist

    VMXname   Status  Starttime
    -------   ------  ---------
    ddmcNode1 Started 07.21.2015 12:27:11
#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ova -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername,

#[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]$MasterPath,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,63)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,63}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
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
        Write-Host -ForegroundColor Magenta  "Use install-ddmc.ps1 -Masterpath .\$Mastername -Defaults"
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
            Write-Host -ForegroundColor Magenta "Using generic defaults from labbuildr"
            }
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
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

        $memsize = 4096
        $Numcpu = 2
        $Startnode = 1
        $Nodes = 1
        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

        $Builddir = $PSScriptRoot
        $Nodeprefix = "DDMCNode"
        if (!$MasterVMX)
            {
            $MasterVMX = get-vmx ddmc-1.4*
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
                $MasterVMX = get-vmx -path $MasterPath
                }
            }

        if (!$MasterVMX)
            {
            write-Host -ForegroundColor Magenta "Could not find existing ddmcMaster"
            if ($Defaults.IsPresent)
                {
                Write-Host -ForegroundColor Magenta "Trying Latest OVF fom $Sourcedir"
                try
                    {
                    $OVFpath =Join-Path $Sourcedir "ddmc-*.ov*" -ErrorAction Stop
                    }
                catch [System.Management.Automation.DriveNotFoundException] 
                    {
                    Write-Warning "Drive not found, make sure to have your Source Stick connected"
                    exit
                    }
                
                    $OVFfile = get-item -Path $OVFpath | Sort-Object -Descending -Property Name
                    If (!$OVFfile)
                        {
                        Write-Warning "No OVF for ddmc found, please conntact feedbackcentral"
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
                        $MasterVMX = get-vmx $mastername
                        }
                }
            else
                {
                Write-Warning "Please import with -ovf or use -Defaults"
                exit
                }

            }
        Write-Host -ForegroundColor Magenta " ==>Checking Base VM Snapshot"
        if (!$MasterVMX.Template) 
            {
            Write-Host -ForegroundColor Magenta " ==>Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base" 

        if (!$Basesnap) 
            {
            Write-Host -ForegroundColor Magenta "Tweaking Base VMX"
            $config = Get-VMXConfig -config $MasterVMX.config
            $config = $config -notmatch "virtualhw.version"
            $config += 'virtualhw.version = "9"'
            $config = $config -notmatch 'scsi0:0.mode = '
            $config += 'scsi0:0.mode = "persistent"'
            $config = $config -notmatch 'scsi0:1.mode = '
            $config += 'scsi0:1.mode = "persistent"'
            foreach ($scsi in 0..1)
                {
                $config = $config -notmatch "scsi$scsi.virtualDev"
                $config += 'scsi'+$scsi+'.virtualDev = "pvscsi"'
                $config = $config -notmatch "scsi$scsi.present"
                $config += 'scsi'+$scsi+'.present = "true"'
                }
            Set-Content -Path $MasterVMX.config -Value $config
            Write-Host -ForegroundColor Magenta " ==>Base snap does not exist, creating now"
            $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
            }
            # $Basesnap
        foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            Write-Host -ForegroundColor Magenta " ==>Checking VM $Nodeprefix$node already Exists"
            If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
                {
                write-Host -ForegroundColor Magenta " ==>Creating clone $Nodeprefix$node"
                $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
        
            Write-Host -ForegroundColor Magenta " ==>Configuring NIC0"
            $Netadater0 = $NodeClone | Set-VMXVnet -Adapter 0 -vnet $VMnet -WarningAction SilentlyContinue
            Write-Host -ForegroundColor Magenta " ==>Configuring NIC1"
            # $Netadater1 = $NodeClone | Set-VMXVnet -Adapter 1 -vnet vmnet8
            $Netadater1 = $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType nat -AdapterType vmxnet3 -WarningAction SilentlyContinue
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
    Write-host -ForegroundColor Blue "****** To Configure  ddmc 1.4 ******
Go to VMware Console an wait for system to boot"
    Write-host -ForegroundColor Blue "
    Please login with 
    localhost login : sysadmin 
    Password: changeme
    Change the Password
    Type No for set system serial number at this time
    Type Yes for Configure Network
    Answer No for DHCP
    Enter $Nodeprefix$Node.$BuildDomain.$Custom_DomainSuffix as hostname
    Enter $BuildDomain.$Custom_DomainSuffix as DNSDomainname
    (The orde of the next command and Devicenames may vary from Version to Version )
Ethernet Port ethV0
    Enter yes for Enable Ethernet ethV0
    Enter NO for DHCP
    Enter IP Address for ethV0:
    $subnet.20 as IP Address
    enter the netmask for ethV0:
    255.255.255.0
Ethernet Port eth0
    Enter Yes for Enable Ethernet Port eth0
Default Gateway    
    Enter $DefaultGateway for Gateway IP Address
    Leave IPv6 Gateway Blank
DNS Server
    Enter $subnet.10 as DNS Server
    Enter Save to Save
Configures System at this Time : no

Open Your webbrowser to Configure Licences and Features !!!
"
    }# end default
}

