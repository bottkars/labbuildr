<#
.Synopsis

.DESCRIPTION
   install-esxi is a standalone installer for esxi on vmware workstation
   the current devolpement requires a customized ESXi Image built for labbuildr
   currently, not all parameters will e supported / verified

   The script will generate a kickstart cd with all required parameters, clones a master vmx and injects disk drives and cd´d into is.

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
	https://github.com/bottkars/labbuildr/wiki/install-esxi.ps1
.EXAMPLE
#>
[CmdletBinding()]
Param(
	[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][int32]$Nodes =1,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][int32]$Startnode = 1,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateRange(1,6)][int32]$Disks = 1,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet(36GB,72GB,146GB)][uint64]$Disksize = 146GB,
	<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet,
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
	[Parameter(ParameterSetName = "defaults", Mandatory = $true)]
	[Parameter(ParameterSetName = "install",Mandatory = $true)]
    [ValidateSet(
    '6.0.0.update01','6.0.0.update02'
        )]
    [string]$esxi_ver,
	 <# NFS Parameter configures the NFS Default Datastore from DCNODE#>
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$nfs,
	<# future use, initializes nfs on DC#>
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$initnfs,
	<# should we use a differnt vmnet#>
	[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
	$vmnet = "vmnet2",
	<# injects the kdriver for recoverpoint #>
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$kdriver,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$esxui,
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[ValidateScript({ Test-Path -Path $_ })]
	$Defaultsfile=".\defaults.xml",
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[Parameter(ParameterSetName = "install", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL"
)
#requires -version 3.0
#requires -module vmxtoolkit 
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "Scripts"
If ($Defaults.IsPresent)
    {
    $labdefaults = Get-labDefaults
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
        # Write-Host -ForegroundColor Gray " ==>No Masterpath specified, trying default"
        $Masterpath = $Builddir
        }
     $Hostkey = $labdefaults.HostKey
     $Gateway = $labdefaults.Gateway
     $DefaultGateway = $labdefaults.Defaultgateway
     $DNS1 = $labdefaults.DNS1
     $DNS2 = $labdefaults.DNS2
    }
if (!$DNS2)
    {
    $DNS2 = $DNS1
    }

if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}

if (!$Masterpath) {$Masterpath = $Builddir}
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
write-verbose "Subnet will be $subnet"
$Nodeprefix = "ESXiNode"
$Password = "Password123!"
$Builddir = $PSScriptRoot
$Required_Master = "esximaster"
$SCSI = 0
try
    {
    $MasterVMX = test-labmaster -Masterpath $MasterPath -Master $Required_Master -Confirm:$false -erroraction stop
    }
catch
    {
    Write-Warning "Required Master $Required_Master not found
    please download and extraxt $Required_Master to .\$Required_Master
    see: 
    ------------------------------------------------
    get-help $($MyInvocation.MyCommand.Name) -online
    ------------------------------------------------"
    exit
    }

$ESX_ISO_PATH = Receive-LABlabbuildresxiISO -labbuildresxi_ver $esxi_ver -Destination "$Sourcedir\ISO"
Write-Verbose "Builddir is $Builddir"
if ($nfs.IsPresent -or $initnfs.IsPresent)
    {
    try {
    (Get-vmx -path $Builddir\dcnode).state -eq 'running'
    }
    catch
        {
        
        }
    }


if ($esxui.IsPresent)
	{
	try
		{
		$esxui_vib = (Receive-LABFling -Destination "$Sourcedir\ESX" -FLING esxi-embedded-host-client).filename 
		}
	catch
		{
		write-host "no fling available"
		}
	}
####Build Machines#

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Verbose "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
    {
    Write-Verbose "Clearing out old content"
    if (Test-Path .\iso\ks) { Remove-Item -Path .\iso\ks -Recurse }
    $KSDirectory = New-Item -ItemType Directory .\iso\KS
    $Content = Get-Content .\Scripts\ESX\KS.CFG
    ####modify $content
    #$Content = $Content | where {$_ -NotMatch "network"}
    $Content += "network --bootproto=static --device=vmnic0 --ip=$subnet.8$Node --netmask=255.255.255.0 --gateway=$DefaultGateway --nameserver=$DNS1 --hostname=$Nodeprefix$node.$Builddomain.$custom_domainsuffix"
    $Content += "keyboard German"
    foreach ( $Disk in 1..$Disks)
        {
        Write-Host -ForegroundColor Gray " ==>Customizing Datastore$Disk"
        $Content += "partition Datastore$Disk@$Nodeprefix$node --ondisk=mpx.vmhba1:C0:T$Disk"+":L0"
        }
    $Content += Get-Content .\Scripts\ESX\KS_PRE.cfg
    $Content += "echo 'network --bootproto=static --device=vmnic0 --ip=$subnet.8$Node --netmask=255.255.255.0 --gateway=$DefaultGateway --nameserver=$DNS1 --hostname=$Nodeprefix$node.$Builddomain.$custom_domainsuffix' /tmp/networkconfig" 
    if ($esxui.IsPresent)
        {
        $Content += Get-Content .\Scripts\ESX\KS_POST.cfg
        $Post_section = $true
        ### everything here goes to post
        Write-Host -ForegroundColor Gray " ==>injecting ESX-UI"
        try 
            {
            $Drivervib = Get-ChildItem "$Sourcedir\ESX\$esxui_vib" -ErrorAction Stop
            }
 
        catch [Exception] 
            {
            Write-Warning "could not copy ESXUI, please make sure to have Package in $Sourcedir"
            write-host $_.Exception.Message
            break
            }
        $Drivervib| Copy-Item -Destination .\iso\KS\ESXUI.VIB
        $Content += "cp -a /vmfs/volumes/mpx.vmhba32:C0:T0:L0/KS/ESXUI.VIB /vmfs/volumes/Datastore1@$Nodeprefix$node"
        }
        if ($kdriver.IsPresent)
        {
        if (!$Post_section)
            {
            $Content += Get-Content .\Scripts\ESX\KS_POST.cfg
            }
        Write-Host -ForegroundColor Gray " ==>injecting K-Driver"
        try 
            {
            $Drivervib = Get-ChildItem "$Sourcedir\ESX\kdriver_RPESX-00.4.2*.vib" -ErrorAction Stop
            }
 
        catch [Exception] 
            {
            Write-Warning "could not copy K-Driver VIB, please make sure to have Kdriver/RP vor VM´s Package in $Sourcedir or specify right -driveletter"
            write-host $_.Exception.Message
            break
            }
        $Drivervib| Sort-Object -Descending | Select-Object -First 1 | Copy-Item -Destination .\iso\KS\KDRIVER.VIB
        $Content += "cp -a /vmfs/volumes/mpx.vmhba32:C0:T0:L0/KS/KDRIVER.VIB /vmfs/volumes/Datastore1@$Nodeprefix$node"
        }

    $Content += Get-Content .\Scripts\ESX\KS_FIRSTBOOT.cfg
    if ($kdriver.IsPresent)
        {
        $Content += "esxcli software acceptance set --level=CommunitySupported"
        $Content += "esxcli software vib install -v /vmfs/volumes/Datastore1@$Nodeprefix$node/KDRIVER.VIB"
        }
    if ($esxui.IsPresent)
        {
        $Content += "esxcli software acceptance set --level=CommunitySupported"
        $Content += "esxcli software vib install -v /vmfs/volumes/Datastore1@$Nodeprefix$node/ESXUI.VIB"
        }

    #$Content += "esxcli software acceptance set --level=CommunitySupported"
    $Content += "cp /var/log/hostd.log /vmfs/volumes/Datastore1@$Nodeprefix$node/firstboot-hostd.log"
    $Content += "cp /var/log/esxi_install.log /vmfs/volumes/Datastore1@$Nodeprefix$node/firstboot-esxi_install.log" 
    $Content += Get-Content .\Scripts\ESX\KS_REBOOT.cfg
    ######

    $Content += Get-Content .\Scripts\ESX\KS_SECONDBOOT.cfg
    #### finished
if ($nfs.IsPresent)
    {
    $Content += "esxcli storage nfs add --host $Subnet.10 --share /$BuildDomain"+"nfs --volume-name=SWDEPOT --readonly"
    $Content += "tar xzfv  /vmfs/volumes/SWDEPOT/ovf.tar.gz  -C /vmfs/volumes/Datastore1@$Nodeprefix$Node/"
    $Content += '/vmfs/volumes/Datastore1@ESXiNode1/ovf/tools/ovftool --diskMode=thin --datastore=Datastore1@'+$Nodeprefix+$Node+' --noSSLVerify --X:injectOvfEnv --powerOn "--net:Network 1=VM Network" --acceptAllEulas --prop:vami.ip0.VMware_vCenter_Server_Appliance='+$Subnet+'.89 --prop:vami.netmask0.VMware_vCenter_Server_Appliance=255.255.255.0 --prop:vami.gateway.VMware_vCenter_Server_Appliance='+$Subnet+'.103 --prop:vami.DNS.VMware_vCenter_Server_Appliance='+$Subnet+'.10 --prop:vami.hostname=vcenter1.labbuildr.'+$custom_domainsuffix+' /vmfs/volumes/SWDEPOT/VMware-vCenter-Server-Appliance-5.5.0.20200-2183109_OVF10.ova "vi://root:'+$Password+'@127.0.0.1"'
    }
    $Content | Set-Content $KSDirectory\KS.CFG 

    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Host -ForegroundColor Yellow "Kickstart Config:"
    $Content | Write-Host -ForegroundColor DarkGray
    pause
    }
    
    ####create iso, ned to figure out license of tools
    # Uppercasing files for joliet
    Get-ChildItem $KSDirectory -Recurse | Rename-Item -newname { $_.name.ToUpper() } -ErrorAction SilentlyContinue


    ####have to work on abs pathnames here

    IF (!(Test-Path $VMWAREpath\mkisofs.exe))
        {
        Write-Warning "VMware ISO Tools not found, exiting"
        }

    Write-Verbose "Node Clonepath =  $($NodeClone.Path)"
    Write-Host -ForegroundColor Gray "Creating VM $Nodeprefix$Node"
    write-verbose "Cloning $Nodeprefix$node"
		try
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node  -clonepath $Builddir
            }
        catch
            {
            Write-Warning "Error creating VM"
            return
            }    
		write-verbose "Config : $($Nodeclone.config)"
		Write-Host -ForegroundColor Gray " ==>Creating Kickstart CD"
		.$VMWAREpath\mkisofs.exe -o "$($NodeClone.path)\ks.iso"  "$Builddir\iso"   | Out-Null
		switch ($LASTEXITCODE)
			{
				2
					{
					Write-Warning "could not create CD"
					$NodeClone | Remove-vmx -Confirm:$false
					Break
					}
			}
        Write-Host -ForegroundColor Gray " ==>Creating Disks"
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            Write-Host -ForegroundColor Gray " ==>Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Host -ForegroundColor Gray " ==>Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }

    Write-Host -ForegroundColor Gray " ==>injecting kickstart CDROM"
    $Nodeclone | Set-VMXIDECDrom -IDEcontroller 1 -IDElun 0 -ISOfile "$($NodeClone.path)\ks.iso" | Out-Null
    Write-Host -ForegroundColor Gray " ==>injecting $esxi_ver CDROM"
    $Nodeclone | Set-VMXIDECDrom -IDEcontroller 0 -IDElun 0 -ISOfile $ESX_ISO_PATH | Out-Null
    $Nodeclone | Set-VMXSize -Size $Size | Out-Null

    Write-Host -ForegroundColor Gray " ==>Setting NICs"
    if ($vmnet)
         {
         Write-Verbose "Configuring NIC 2 and 3 for $vmnet"
         write-verbose "Setting NIC0"
         Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config  -WarningAction SilentlyContinue | Out-Null
         Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config  -WarningAction SilentlyContinue | Out-Null
        }
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname ESXi -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    Write-Verbose "Starting $Nodeprefix$node"
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    Set-VMXDisplayName -config $NodeClone.Config -Value "$($NodeClone.CloneName)@$Builddomain" | Out-Null
    Write-Host -ForegroundColor Gray " ==>Starting $($NodeClone.CloneName)"
    start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
    Write-Host -ForegroundColor Gray "The ESX Build may take 2 Minutes ... "
    if ($esxui)
        {
        Write-Host -ForegroundColor Gray "Connect to ESX UI Using https://$subnet.8$Node/ui"
        }
    } # end check vm
    else
    {
    Write-Warning "VM $Nodeprefix$node already exists"
    }
    }






