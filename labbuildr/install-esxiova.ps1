<#
.Synopsis
   
.Description
  install-esxiova only applies to Testers of the Virtual esxiova
  install-esxiova is a 2 Step Process.
  Once esxiova is downloaded via vmware, run 
   .\install-esxiova.ps1 -defaults
   This creates a esxiova Master in your labbuildr directory.
   This installs a esxiova using the defaults file and the just extracted esxiova Master
    
      
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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-esxiova.ps1
.EXAMPLE
    Importing the ovf template
	.\install-esxiova.ps1 -import -nestedesx_ver ['Nested_ESXi6','Nested_ESXi5','Nested_ESXi6.5']
 .EXAMPLE
    Install a esxiovaNode with defaults from defaults.json
   .\install-esxiova.ps1 -nestedesx_ver ['Nested_ESXi6.0',Nested_ESXi6.5']

#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "Import", Mandatory = $true)]
[switch]$import,
# ''Nested_ESXi6.0','Nested_ESXi6.5'
[ValidateSet(
'Nested_ESXi6.0','Nested_ESXi6.5'
)]
[string]$nestedesx_ver = "Nested_ESXi6.5",
[String]$Mastername,
[ValidateRange(3,14)]
[int]
$Disks = 3,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateRange(1,6)][int]
$Startnode = 1,
<#
Size for openstack compute nodes
'XS'  = 1vCPU, 512MB
'S'   = 1vCPU, 768MB
'M'   = 1vCPU, 1024MB
'L'   = 2vCPU, 2048MB
'XL'  = 2vCPU, 4096MB
'TXL' = 4vCPU, 6144MB
'XXL' = 4vCPU, 8192MB
#>
[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]
$Size = "XL",
[ValidateRange(1,6)]
[int]$Nodes = 1,
[Parameter(Mandatory = $false)][switch]$Defaults,
[Parameter(Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = $Global:labdefaults.MySubnet,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$VMnet = $Global:labdefaults.vmnet,
$Sourcedir = $Global:labdefaults.sourcedir,
$Masterpath = $Global:LabDefaults.Masterpath
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LabDefaults
	}
$Builddir = $PSScriptRoot
$Password = "Password123!"
$SSO_Domain = "vmware.local"
switch ($PsCmdlet.ParameterSetName)
{
    "import"
    {
    #download template
	Write-Host -ForegroundColor Gray " ==>checking for latest $nestedesx_ver"
	$OVF = Receive-LABnestedesxtemplate -Destination (Join-Path $Sourcedir "OVA") -nestedesx_ver $nestedesx_ver
	$OVFfile = Get-Item $ovf
    $mastername = $OVFfile.BaseName
    $OVA = Import-VMXOVATemplate -OVA $ovf -acceptAllEulas -AllowExtraConfig -quiet -destination $MasterPath 
    #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
    Write-Host -ForegroundColor White  "Use `".\$($MyInvocation.MyCommand) -nestedesx_ver $nestedesx_ver `" to try defaults"
    }

default
    {
    If ($ConfirmPreference -match "none")
		{$Confirm = $false}
	else
		{$Confirm = $true}
	$Builddir = $PSScriptRoot
	$Scriptdir = Join-Path $Builddir "Scripts"
	$BuildDomain = $Global:labdefaults.BuildDomain

	$Hostkey = $Global:labdefaults.HostKey
	$Gateway = $Global:labdefaults.Gateway
	$DefaultGateway = $Global:labdefaults.Defaultgateway
	$DNS1 = $Global:labdefaults.DNS1
	$DNS2 = $Global:labdefaults.DNS2
	$custom_domainsuffix = $Global:labdefaults.custom_domainsuffix
	Write-Verbose $MasterPath
    [System.Version]$subnet = $Subnet.ToString()
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
    $Builddir = $PSScriptRoot
    $Nodeprefix = "NestedESX"
    $MasterVMX = get-vmx -path $Masterpath | where {$_.VMXName -match "$nestedesx_ver"}
 

    if (!$MasterVMX)
        {
        write-Host -ForegroundColor Magenta "Could not find existing esxiovaMaster"
        return
        }
    Write-Host -ForegroundColor Gray " ==>Checking Base VM Snapshot"
    if (!$MasterVMX.Template) 
        {
        $template = $MasterVMX | Set-VMXTemplate
        }
    $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base" 

    if (!$Basesnap) 
        {
        Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
        }

    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        $ipoffset = 80+$Node
        Write-Host -ForegroundColor Gray " ==>Checking VM $Nodeprefix$node already Exists"
        If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
            foreach ($nic in 0..0)
                {
                $Netadater0 = $NodeClone | Set-VMXVnet -Adapter $nic -vnet $VMnet -WarningAction SilentlyContinue
                }
			[string]$ip="$($subnet.ToString()).$($ipoffset.ToString())"
			$config = Get-VMXConfig -config $NodeClone.config
			$config += "guestinfo.hostname = `"$($NodeClone.CloneName).$BuildDomain.$custom_domainsuffix`""
			$config += "guestinfo.ipaddress = `"$ip`""
			$config += "guestinfo.netmask = `"255.255.255.0`""
			$config += "guestinfo.gateway = `"$Gateway`""
			$config += "guestinfo.dns = `"$DNS1`""
			$config += "guestinfo.domain = `"$Nodeprefix$Node.$BuildDomain.$custom_domainsuffix`""
			$config += "guestinfo.ntp = `"$DNS1`""
			$config += "guestinfo.ssh = `"true`""
			$config += "guestinfo.syslog = `"$ip`""
			$config += "guestinfo.password = `"$Password`""
			$config += "guestinfo.createvmfs = `"false`""
			$config | Set-Content -Path $NodeClone.config
			
			if ($Disks -ne 0)
				{
				$SCSI = 1
				[uint64]$Disksize = 100GB
				$NodeClone | Set-VMXScsiController -SCSIController 1 -Type lsilogic | Out-Null
				foreach ($LUN in (0..($Disks-1)))
					{
					if ($LUN -ge 7)
						{
						$LUN = $LUN+1
						}
					$Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
					$Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path
					$AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI -VirtualSSD
					}
				}
			$result = $NodeClone | Set-VMXSize -Size $Size
			$result = $NodeClone | Set-VMXGuestOS -GuestOS vmkernel6
			$result = $NodeClone | Set-VMXVTBit -VTBit:$true
            $result = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
            $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
            $Annotation = $Nodeclone | Set-VMXAnnotation -Line1 "Login Credentials" -Line2 "root" -Line3 "Password" -Line4 "$Password"
            $NodeClone | start-vmx | Out-Null
			Write-host
			Write-host -ForegroundColor White "==>Nested ESXi $($NodeClone.Clonename) Deployed successful,login with root/$Password at console or ssh:$($ip):22"
			Write-host -ForegroundColor White "==>The ESX UI can be reached at https://$($ip)/ui"
            }
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
            }
		}
	}# end default
}

