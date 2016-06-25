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
#[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
$Sourcedir,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$forcedownload,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$noextract,
[Parameter(ParameterSetName = "import",Mandatory=$true)][switch]$import,
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Nodes =3,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateRange(3,6)][int32]$Disks = 5,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(36GB,72GB,146GB)][uint64]$Disksize = 36GB,
[Parameter(ParameterSetName = "install", Mandatory=$False)]$Subnet = "192.168.2",
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)]$MasterPath,
[Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
#[Parameter(ParameterSetName = "install", Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir
[switch]$Use_default_disks
)
#requires -version 3.0
#requires -module vmxtoolkit 
$Product = "ISILON"
$Product_tag = "8.*"

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
    Write-Warning "use_defazlt_diskparameter is experimental, and thus it has to be used for IMPORT and CREATION"
    pause
    }
<#
        Try 
            {
            test-Path $Sourcedir
            } 
        Catch 
            { 
            Write-Verbose $_ 
            Write-Warning "We need a Valid Sourcedir, trying Defaults"
            if (!($Sourcedir = (Get-labDefaults).Sourcedir))
                {
                exit
                }
            }
        #>
        if (!($OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -recurse -Include "$Product_tag.ova" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
            {
                    write-warning "No $Product OVA found, Checking for Downloaded Package"
                    Receive-LABISIlon -Destination $Sourcedir -unzip

        }
           
        $OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -Recurse -include "$Product_tag.ova"  -Exclude ".*" | Sort-Object -Descending
        $OVAPath = $OVApath[0]
        Write-Warning "Creating $Product Master for $($ovaPath.Basename), may take a while"
        
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --name=$($ovaPath.Basename) $ovaPath.FullName $PSScriptRoot  #
        $MasterVMX = get-vmx -path ".\$($ovaPath.Basename)"
        Write-Host -ForegroundColor Magenta " ==>Customizing Master VM"
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
        Write-Host -ForegroundColor White "Please run .\$($MyInvocation.MyCommand) -MasterPath .\$($ovaPath.Basename) -Defaults"
        }
    default
{
$Nodeprefix = "ISINode"
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
     }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

               
If (!$MasterPath)
    {
    Write-Host -Foregroundcolor Magenta "No master Specified, rule is Pic Any available Isilon Master now"
    $MasterVMXs = get-vmx -vmxname "$Product_tag" -WarningAction SilentlyContinue
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
            If (!($MasterVMX = get-vmx -path $MasterPath))
                {
                Write-Verbose "$MasterPath IS NOT A VALID $Product Master"
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
    Write-Host -ForegroundColor Magenta "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node  -WarningAction SilentlyContinue))
    {
    Write-Host -ForegroundColor Magenta " ==>Creating clone $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
    If (!(get-vmx $Nodeprefix$node  -WarningAction SilentlyContinue))
        {
        Write-Warning "node $Nodeprefix$node could not be created. please reach out to @sddc_guy"
        return
        }
        
    Write-Host -ForegroundColor Magenta " ==>Creating Disks"
    if (!$Use_default_disks.IsPresent)
        {
        $SCSI = 0
        foreach ($LUN in (1..$Disks))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                Write-Host -ForegroundColor Gray " ==> Building Disk $Diskname"
                try
                    {
                    $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path -ErrorAction Stop -Debug
                    }
                catch
                    {
                    Write-Warning "Error Creating new disk, maybe orpahn node or disk files with name $Diskname exists ?
try to delete $Nodeprefix$Node Directory and try again"
                    exit
                    }
                Write-Host -ForegroundColor Gray " ==> Adding Disk $Diskname to $($NodeClone.VMXname)"
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }
            }
    else
        {
        Write-Warning "Using Default Disks on request"
        }
    write-verbose "Setting int-b"
    Set-VMXNetworkAdapter -Adapter 2 -ConnectionType hostonly -AdapterType e1000 -config $NodeClone.Config | out-null
    # Disconnect-VMXNetworkAdapter -Adapter 1 -config $NodeClone.Config
    write-verbose "Setting ext-1"
    Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config -WarningAction SilentlyContinue | out-null
    Set-VMXVnet -Adapter 1 -vnet $vmnet -config $NodeClone.Config | out-null
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    write-verbose "Setting Display Name $($NodeClone.CloneName)@$Builddomain"
    Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain" | out-null
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
        smartconnect Zone Name...:  onefs.$BuildDomain.local
        smartconnect Service IP :  $Subnet.40
        Configure DNS Settings
        DNS Server...............: $DNS1,$Subnet.10
        Search Domain............: $BuildDomain.local"
}
}
