<#
.Synopsis
   .\install-isi.ps1 -defaults
.DESCRIPTION
  install-isi is an automated Installer for EMC Isilon OneFS Simulator
      
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
 https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-isi8
.EXAMPLE

#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "install", Mandatory=$false)]
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]
[Parameter(Mandatory=$false)]
$Sourcedir = $Global:labdefaults.Sourcedir,

[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$forcedownload,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$noextract,
[Parameter(ParameterSetName = "import",Mandatory=$true)][switch]$import,
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Nodes =3,
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateRange(3,6)][int32]$Disks = 5,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateRange(1,3)][int32]$SSD_Disks = 3,
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(36GB,72GB,146GB)][uint64]$Disksize = 36GB,
[Parameter(ParameterSetName = "install", Mandatory=$false)]$MasterPath = $Global:labdefaults.masterpath,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$vmnet = $Global:labdefaults.vmnet,
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$ext2,
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$ext3,
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$ext4,
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$ext5,
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$ext6,
#[Parameter(ParameterSetName = "install", Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir
[switch]$Use_default_disks,
####

	[Parameter(Mandatory=$false)]
	$Scriptdir = (join-path (Get-Location) "labbuildr-scripts"),
	[Parameter(Mandatory=$false)]
	$DefaultGateway = $Global:labdefaults.DefaultGateway,
	[Parameter(Mandatory=$false)]
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
	$Host_Name = $VMXName,
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
    $mastername 

####
)
#requires -version 3.0
#requires -module vmxtoolkit 
$Product = "ISILON"
$Product_tag = "8.*"
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        if (!($Sourcedir ))
            {
            $Sourcedir= (Get-labDefaults).Sourcedir
            }
        try
            {
            Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null 
            }
        catch
            [System.Management.Automation.DriveNotFoundException] 
            {
            Write-Warning "Drive not found, make sure to have your Source Stick connected"
            return        
            }
        catch [System.Management.Automation.ItemNotFoundException]
            {
            Write-Warning "no sources directory found named $Sourcedir"
            return
            }
        catch
            {
            Write-Warning "no sources directory found named $Sourcedir"
            return
            }
    if ($Use_default_disks.IsPresent)
        {
        Write-Warning "use_default_diskparameter is experimental, and thus it has to be used for IMPORT and CREATION"
        pause
        }
    if (!($OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -recurse -Include "$Product_tag.ova" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
        {
                write-warning "No $Product OVA found, Checking for Downloaded Package"
                Receive-LABISIlon -Destination $Sourcedir -unzip
        }
           
    $OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -Recurse -include "$Product_tag.ova"  -Exclude ".*" | Sort-Object -Descending
    $OVAPath = $OVApath[0]
    Write-Warning "Creating $Product Master for $($ovaPath.Basename), may take a while"
    Import-VMXOVATemplate -OVA $ovaPath.FullName -Name $($ovaPath.Basename) -destination $Global:labdefaults.Masterpath -acceptAllEulas
    #& $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --name=$($ovaPath.Basename) $ovaPath.FullName $PSScriptRoot  #
    $MasterVMX = get-vmx -path (join-path $Global:labdefaults.Masterpath ($ovaPath.Basename))
    if (!$Use_default_disks.IsPresent)
        {
        foreach ($lun in 2..6)
            {
            Write-Host -ForegroundColor Gray " ==> removing disk SCSI4"
            $MasterVMX | Remove-VMXScsiDisk -LUN $lun -Controller 0 | Out-Null
            }
        }
        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $MasterVMX | Set-VMXTemplate
            }
        Write-Host -ForegroundColor White "Please run .\$($MyInvocation.MyCommand) to install default 3-node setup"
        }
    default
{
$Nodeprefix = "ISINode"
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
              
If (!$Mastername)
    {
    Write-Host -Foregroundcolor Magenta "No mastername Specified, rule is Pic Any available Isilon Master now"
    $MasterVMXs = get-vmx -Path $Global:labdefaults.Masterpath -VMXName $Product_tag -WarningAction SilentlyContinue
    if ($Mastervmxs)
            {
            $Mastervmxs = $MasterVMXs | Sort-Object -Descending
            $MasterVMX = $MasterVMXs[0]
            Write-Verbose "We Found Isilon MasterVMX $MasterVMX.VMXname"
            }
     else
            {
            Write-Warning "Could not find a Master VMX with Tag $Product_tag
Please check if a master was imported with $($MyInvocation.InvocationName) -import"
            return
            }
    }
    else
            {
            If (!($MasterVMX = get-vmx -path $MasterPath -VMXName $mastername))
                {
                Write-Verbose "$mastername is not foun in $MasterPath"
                return
                }
            }
If (!$MasterVMX)
    {
    Write-Warning "could not get $Product Master
    Please Run .\$($MyInvocation.MyCommand) -import to download and Ipmort $Product Master"
    return
    }
$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
if (!$Basesnap) 
    {
    Write-verbose "Base snap does not exist, creating now"
    $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
    write-verbose "Templating Master VMX"
    $template = $MasterVMX | Set-VMXTemplate
    }
####Build Machines#

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    If (!(get-vmx $Nodeprefix$node  -WarningAction SilentlyContinue))
    {
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
    If (!(get-vmx $Nodeprefix$node  -WarningAction SilentlyContinue))
        {
        Write-Warning "node $Nodeprefix$node could not be created. please reach out to @sddc_guy"
        return
        }
    if (!$Use_default_disks.IsPresent)
        {
        $SCSI = 0
        foreach ($LUN in (1..$Disks))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                try
                    {
                    $Newdisk = $NodeClone | New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -ErrorAction Stop #-Debug
                    }
                catch
                    {
                    Write-Warning "Error Creating new disk, maybe orpahn node or disk files with name $Diskname exists ?
try to delete $Nodeprefix$Node Directory and try again"
                    exit
                    }
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }

        }
    else
        {
        Write-Warning "Using Default Disks on request"
        }
    write-verbose "Setting int-b"
    $NodeClone | Set-VMXNetworkAdapter -Adapter 2 -ConnectionType hostonly -AdapterType e1000 | out-null
    # Disconnect-VMXNetworkAdapter -Adapter 1 -config $NodeClone.Config
    write-verbose "Setting ext-1"
    $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
    $NodeClone | Set-VMXVnet -Adapter 1 -vnet $vmnet  | out-null
    
    if ($ext2)
        {
        write-verbose "Setting ext-2"
        $NodeClone | Set-VMXNetworkAdapter -Adapter 3 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
        $NodeClone | Set-VMXVnet -Adapter 3 -vnet $ext2 | out-null
        }
    
     if ($ext3)
        {
        write-verbose "Setting ext-2"
        $NodeClone | Set-VMXNetworkAdapter -Adapter 4 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
        $NodeClone | Set-VMXVnet -Adapter 4 -vnet $ext3 | out-null
        }
    if ($ext4)
        {
        write-verbose "Setting ext-2"
        $NodeClone | Set-VMXNetworkAdapter -Adapter 5 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
        $NodeClone | Set-VMXVnet -Adapter 5 -vnet $ext4 | out-null
        }
    if ($ext5)
        {
        write-verbose "Setting ext-2"
        $NodeClone | Set-VMXNetworkAdapter -Adapter 6 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
        $NodeClone | Set-VMXVnet -Adapter 6 -vnet $ext5 | out-null
        }
    if ($ext6)
        {
        write-verbose "Setting ext-2"
        $NodeClone | Set-VMXNetworkAdapter -Adapter 7 -ConnectionType custom -AdapterType e1000 -WarningAction SilentlyContinue | out-null
        $NodeClone | Set-VMXVnet -Adapter 7 -vnet $ext6 | out-null
        }
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    write-verbose "Setting Display Name $($NodeClone.CloneName)@$Builddomain"
    Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$($Global:labdefaults.BuildDomain)" | out-null
    Write-Verbose "Starting $Nodeprefix$node"
    start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName | out-null
    } # end check vm
    else
    {
    Write-Verbose "VM $Nodeprefix$node already exists"
    }
}
Write-Host -ForegroundColor DarkCyan  "In cluster Setup, please spevcify the following Values already propagated in ad:
Assign internal Addresses from .41 to .56 according to your Subnet

        Cluster Name  ...........: isi2go
        Interface int-a
        Netmask int-a............: 255.255.255.0
        Int-a Low IP .........: 10.10.0.41
        Int-a high IP ........: 10.10.0.56
        Interface int-b
        Netmask int-b............: 255.255.255.0
        Int-b Low IP .........: 10.11.0.41
        Int-b high IP ........: 10.11.0.56
        Interface ext-1
        Netmask ext-1............: 255.255.255.0
        External Low IP .........: $Subnet.41
        External High IP ........: $Subnet.56
        Default Gateway..........: $DefaultGateway
        Configure Smartconnect
        smartconnect Zone Name...:  onefs.$DNS_DOMAIN_NAME
        smartconnect Service IP :  $Subnet.40
        Configure DNS Settings
        DNS Server...............: $DNS1,$DNS2
        Search Domain............: $DNS_DOMAIN_NAME"
}
}
