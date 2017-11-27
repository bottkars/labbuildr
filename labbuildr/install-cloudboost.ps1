<#
.Synopsis
   ./install-cloudboost.ps1
.DESCRIPTION
  install-cloudboost is  the a vmxtoolkit solutionpack for configuring and deploying cloudboost svm´s

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
   https://community.emc.com/blogs/bottk/2015/02/05/labbuildrgoes-emc-cloudboost
.EXAMPLE
./install-cloudboost.ps1 -ovf D:/Sources/cloudboost-ESXi5-5.1.0.6695/cloudboost-ESXi5-5.1.0.6695.ovf
This will convert cloudboost ESX Template
.EXAMPLE
./install-cloudboost.ps1 -MasterPath ./cloudboost-ESXi5-5.1.0.6695 -Defaults
This will Install default Cloud boost
#>
[CmdletBinding()]
Param(
### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf})]$ovf,
[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Master,
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(1,2,4)][int32]$Site_Cache_Disks = 2,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(100GB,200GB)][uint64]$Meta_Data_Disk_Size = 100GB,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(100GB,200GB)][uint64]$Site_Cache_Disk_Size = 200GB,

#### generic labbuildr7
	[Parameter(Mandatory=$false)]
	$DefaultGateway = $Global:labdefaults.DefaultGateway,
	[Parameter(Mandatory=$false)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")]
	[string]$BuildDomain = $Global:labdefaults.builddomain,
	[Parameter(Mandatory=$false)]
	[string]$custom_domainsuffix = $Global:labdefaults.custom_domainsuffix,
	$Masterpath = $Global:labdefaults.Masterpath,
	$guestpassword = "Password123!",
	$Rootuser = 'root',
	$Hostkey = $Global:labdefaults.HostKey,
	$Default_Guestuser = 'labbuildr',
	[Parameter(Mandatory=$false)]
	$Subnet = $Global:labdefaults.MySubnet,
	[Parameter(Mandatory=$false)]
	$DNS1 = $Global:labdefaults.DNS1,
	[Parameter(Mandatory=$false)]
	$DNS2 = $Global:labdefaults.DNS2,
	[Parameter(Mandatory=$false)]
	$Host_Name,
	[Parameter(Mandatory=$false)]
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
	#vmx param
#	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
	$vmnet = $Global:labdefaults.vmnet,
	[switch]$Defaults


)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
$Builddir = $PSScriptRoot
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
		try
			{
			$Masterpath = $LabDefaults.Masterpath
			}
		catch
			{
			# Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
			$Masterpath = $Builddir
			}
        if (!(($Mymaster = Get-Item $ovf).Extension -match "ovf" -or "ova"))
            {
            write-warning "no OVF Template found"
            exit
            }
        # if (!($mastername)) {$mastername = (Split-Path -Leaf $ovf).Replace(".ovf","")}
        # $Mymaster = Get-Item $ovf
        $Mastername = $Mymaster.Basename
        Import-VMXOVATemplate -OVA $ovf -destination $masterpath -acceptAllEulas
        # & $global:vmwarepath/OVFTool/ovftool.exe --lax --skipManifestCheck  --name=$mastername $ovf $PSScriptRoot #
        $Content = Get-Content $masterpath/$mastername/$mastername.vmx
        $Content = $Content -notmatch 'snapshot.maxSnapshots'
        $Content = $Content -notmatch 'vmci0.pciSlotNumber'
        $Content += 'vmci0.pciSlotNumber = "33"'
        $Content | Set-Content $masterpath/$mastername/$mastername.vmx
        $Mastervmx = get-vmx -path $masterpath/$mastername/$mastername.vmx
        $Mastervmx | Set-VMXHWversion -HWversion 7
        $Mastervmx | Get-VMXScsiDisk | where lun -Match 1 | Expand-VMXDiskfile -NewSize $Meta_Data_Disk_Size 
        foreach ($lun in 2..2)
            {
            Write-Host -ForegroundColor Gray " ==> removing disk SCSI$LUN"
            $MasterVMX | Remove-VMXScsiDisk -LUN $lun -Controller 0 | Out-Null
            }

        
        Write-Host -ForegroundColor Yellow " ==>Now run ./install-cloudboost.ps1 -Master $(join-path $masterpath $mastername)"
        }
default
    {
		$vmnet = $labdefaults.vmnet
		$subnet = $labdefaults.MySubnet
		$BuildDomain = $labdefaults.BuildDomain
		try
			{
			$Sourcedir = $labdefaults.Sourcedir
			}
		catch [System.Management.Automation.ValidationMetadataException]
			{
			Write-Warning "Could not test Sourcedir Found from Defaults, USB stick connected ?"
			Break
			}
		catch [System.Management.Automation.ParameterBindingException]
			{
			Write-Warning "No valid Sourcedir Found from Defaults, USB stick connected ?"
			Break
			}
		try
			{
			$Masterpath = $LabDefaults.Masterpath
			}
		catch
			{
			# Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
			$Masterpath = $Builddir
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
    $Nodeprefix = "cloudboost"
    If (!($MasterVMX = get-vmx -path $Master))
      {
       Write-Warning "No Valid Master Found, please import Cloudboost OVA template first with ./install-cloudboost.ps1 -ovf [path to ova template]"
      break
     }
    $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base"
    if (!$Basesnap)
        {
        Write-Host -ForegroundColor Gray " ==> Tweaking Base VMX File"
        $Config = Get-VMXConfig -config $MasterVMX.Config
        $Config = $Config -notmatch 'snapshot.maxSnapshots'
        $Config | set-Content -Path $MasterVMX.Config
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        if (!$MasterVMX.Template)
            {
            Write-Host -ForegroundColor Gray " ==> Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        } #end basesnap
####Build Machines#
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node -Clonepath $Builddir
            Write-Host -ForegroundColor Gray " ==> tweaking $Nodeprefix to run on Workstation"
            $NodeClone | Set-VMXmemory -MemoryMB 8192 | Out-Null
            Write-Host -ForegroundColor Gray " ==> Setting eth0 to e1000/slot32"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType e1000 -PCISlot 32 -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
            $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
            Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain" | Out-Null

            $SCSI = 0
           # $Diskname = "MetaDisk"
           # try
           #     {
           #     $Newdisk = $NodeClone | New-VMXScsiDisk -NewDiskSize $Meta_Data_Disk_Size -NewDiskname $Diskname -ErrorAction Stop
           #     }
           # catch
           #     {
           #     Write-Warning "Error Creating new disk, maybe orpahn node or disk files with name $Diskname exists ?
#try to delete $Nodeprefix$Node Directory and try again"
            #    exit
           #     }            
            # $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN 1 -Controller $SCSI
            
            foreach ($LUN in (2..($Site_Cache_Disks+1)))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                try
                    {
                    $Newdisk = $NodeClone | New-VMXScsiDisk -NewDiskSize $Site_Cache_Disk_Size -NewDiskname $Diskname -ErrorAction Stop #-Debug
                    }
                catch
                    {
                    Write-Warning "Error Creating new disk, maybe orpahn node or disk files with name $Diskname exists ?
try to delete $Nodeprefix$Node Directory and try again"
                    exit
                    }
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }
            start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName
            } # end check vm
        else
            {
            Write-Host -ForegroundColor Yellow " ==>VM $Nodeprefix$node already exists"
            }
        }#end foreach
    Write-Host -ForegroundColor White "change the default password on admin console
    for CloudBoost >= 2.1 run

net config eth0 $subnet.7$Node netmask 255.255.255.0
route add 0.0.0.0 netmask 0.0.0.0 gw $DefaultGateway
dns set primary $DNS1
fqdn $Nodeprefix$Node.$BuildDomain.$Custom_DomainSuffix
"
    } # end default
}# end switch