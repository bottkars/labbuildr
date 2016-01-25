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
 https://github.com/bottkars/labbuildr/wiki/SolutionPacks/#Install-isi
.EXAMPLE

#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Nodes =3,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateRange(3,6)][int32]$Disks = 5,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$False)][ValidateSet(36GB,72GB,146GB)][uint64]$Disksize = 36GB,
[Parameter(ParameterSetName = "install", Mandatory=$False)]$Subnet = "10.10.0",
[Parameter(ParameterSetName = "install", Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory=$false)]$MasterPath,
[Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "install", Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir
)
#requires -version 3.0
#requires -module vmxtoolkit 

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

try
    {
    Test-Path $Sourcedir
    }
catch [Exception] 
    {
    Write-Output "we need a Sourcedir to Continue
    Consider using -Defaults"
    break
    }
                
If (!$MasterPath)
    {
    write-warning "No master Specified, rule is Pic Any now"
    $MasterVMXs = get-vmx -vmxname "ISIMaster*"
    if ($Mastervmxs)
            {
            $Mastervmxs = $MasterVMXs | Sort-Object -Descending
            $MasterVMX = $MasterVMXs[0]
            Write-Verbose " We Found MasterVMX $MasterVMX.VMXname"
            }
     else
            {
            $sourcemaster = "b.7*.vga"
            }
    }
else
            {
            If (!($MasterVMX = get-vmx -path $MasterPath))
                {
                Write-Verbose "$MasterPath IS NOT A VALID Isilon Master"
                break
                }

            # $sourcemaster = (Split-Path -Leaf $MasterPath) -replace "Isimaster",""
            # Write-Verbose "We found Sourcemaster $sourcemaster"
            }
    
If (!$MasterVMX)
    {
    Write-Warning "No Valid Master Found"
    Write-Warning "we will check for any available Sourcemaster to create a MasterVMX"

    if (!(Test-Path (Join-Path $Sourcedir $sourcemaster )))
            { 
            if (!(Test-Path (Join-path $Sourcedir "EMC*isilon*onefs*.zip")))
                {
                write-warning "No Sourcemaster or Package Found, we need to download ONEFS Simulator from EMC"
                $request = invoke-webrequest http://www.emc.com/getisilon
                $Link = $request.Links | where OuterText -eq Download
                $DownloadLink = $link.href
                $Targetfile = (Join-Path $Sourcedir (Split-Path -Leaf $DownloadLink))
                Get-LABFTPFile -Source $DownloadLink -TarGet $Targetfile -Defaultcredentials
                }
            $Targetfile = Get-ChildItem -Path  (Join-path $Sourcedir "EMC*isilon*onefs*.zip")
            Expand-LABZip -zipfilename $Targetfile.FullName -destination $Sourcedir
            }
        $ISISourcepath = Join-Path $Sourcedir $sourcemaster
        Write-Verbose "Isisourcepath = $ISISourcepath"
        If (!(Test-Path $ISISourcepath))
            {
            Write-Warning "No Valid Sourcemaster found"
            }
        $ISISources = Get-Item -Path $ISISourcepath
        $ISISources = $ISISources | Sort-Object -Descending
        $ISISource = $ISISources[0]
        Write-Verbose "Isisource = $ISISource"
        $Isiver = $ISISource.Name
        $Isiverlatest = $Isiver -replace "b.",""
        $Isiverlatest = $Isiver -replace ".vga",""
        Write-Verbose "Found OneFS  Sourcemaster Version $Isiverlatest"
        $Bootdisk= Get-ChildItem -path $ISISource -Filter "boot0.vmdk"
        Write-Verbose "Found Bootbank $($Bootdisk.fullname)"
        $nvramfile = Get-ChildItem -path $ISISource -Filter "nvram"
        $nvramdisk = Get-ChildItem -path $ISISource -Filter "isi-nvram.vmdk"
        $vmxfile = Get-ChildItem -path $ISISource -Filter "b.7.*vga.vmx"
        $Masterpath = ".\ISIMaster$Isiverlatest"
        Write-Verbose "Masterpath = $MasterPath"
        if (!(Test-Path $MasterPath))
            {
            New-Item -ItemType Directory -Name $MasterPath  | out-null
            }

        Copy-Item ($Bootdisk.FullName,$nvramfile.FullName,$nvramdisk.FullName,$vmxfile.FullName ) -Destination $MasterPath
        $Mastervmx = get-vmx -path $MasterPath
        Write-Verbose "Tweaking VMX File"
        $Config = Get-VMXConfig -config $MasterVMX.Config
        $Config = $Config -notmatch "SCSI0:"
        $Config = $Config -notmatch "ide0:0.fileName"
        $Config += 'ide0:0.fileName = "boot0.vmdk"'
        $Config += 'scsi0:0.redo = ""'
        $Config += 'scsi0:0.present = "TRUE"'
        $Config += 'scsi0:0.fileName = "isi-nvram.vmdk"'
        $Config | set-Content -Path $MasterVMX.Config
        $tweakname = Get-ChildItem $MasterVMX.config
        $tweakdir = Split-Path -Leaf $tweakname.Directory
        If ($tweakname.BaseName -notmatch  $tweakdir)
            {
            Rename-Item $tweakname -NewName "$tweakdir.vmx"
            }
        write-verbose "re-reading Master"
        $MasterVMX = get-vmx -Path $MasterPath
}
If (!$MasterVMX)
    {
    Write-Warning "could not get Mastervmx"
    break
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
    Write-Verbose "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node))
    {
    write-verbose "Creating clone $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
    Write-Verbose "Creating Disks"
    $SCSI = 0
    foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
    write-verbose "Setting ext-1"
    Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config | out-null
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
        Internal Low IP .........: your vmnet1 .41
        Interface ext-1
        Netmask ext-1............: 255.255.255.0
        External Low IP .........: $Subnet.41
        External High IP ........: $Subnet.56
        Default Gateway..........: $DefaultGateway
        Configure Smartconnect
        martconnect Zone Name...:  onefs.$BuildDomain.local
        smartconnect Service IP :  $Subnet.40
        Configure DNS Settings
        DNS Server...............: $Subnet.10
        Search Domain............: $BuildDomain.local"
