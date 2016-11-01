<#
.Synopsis
   .\install-ubuntu.ps1
.DESCRIPTION
  install-scaleio is  the a vmxtoolkit solutionpack for configuring and deploying scaleio svm´s

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
   https://github.com/bottkars/labbuildr/wiki/ubuntu-bakery.ps1
.EXAMPLE
.\install-Ubuntu.ps1
This will install 3 Ubuntu Nodes Ubuntu1 -Ubuntu3 from the Default Ubuntu Master

#>
[CmdletBinding(DefaultParametersetName = "defaults",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
[Parameter(ParameterSetName = "openstack",Mandatory=$true)]
[switch]$openstack,
[Parameter(ParameterSetName = "defaults",Mandatory=$false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$false)]
[ValidateSet('liberty','mitaka','newton')]
[string]$openstack_release = 'liberty',
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateSet('unity','scaleio')]
[string[]]$cinder = "scaleio",
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $true)]
[switch]$Defaults,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[switch]$docker=$false,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateRange(1,3)]
[int32]$Disks = 1,
#[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "openstack", Mandatory = $false)]
[ValidateSet('16_4','14_4')]
[string]$ubuntu_ver = "16_4",
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('cinnamon','cinnamon-desktop-environment','xfce4','lxde','none')]
[string]$Desktop = "none",
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
$Sourcedir,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateRange(1,9)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[int32]$Startnode = 1,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateScript({$_ -match [IPAddress]$_ })]
[ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")]
[string]$BuildDomain,
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
$vmnet,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ })]
$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[switch]$forcedownload,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $true)]
[Switch]$scaleio,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Switch]$Openstack_Controller,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Switch]$Openstack_Baseconfig = $true,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$Custom_unity_ip,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$custom_unity_vpool_name,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$Custom_Unity_Target_ip,
    <#
    Size for general nodes
    'XS'  = 1vCPU, 512MB
    'S'   = 1vCPU, 768MB
    'M'   = 1vCPU, 1024MB
    'L'   = 2vCPU, 2048MB
    'XL'  = 2vCPU, 4096MB
    'TXL' = 4vCPU, 6144MB
    'XXL' = 4vCPU, 8192MB
    #>
[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
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
[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Compute_Size = "XL",

[int]$ip_startrange = 200,
#[Parameter(ParameterSetName = "install",Mandatory = $false)]
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$SIOGateway
[switch]$use_aptcache = $true,
[ipaddress]$non_lab_apt_ip,
[switch]$do_not_use_lab_aptcache,
[switch]$upgrade
)
#requires -version 3.0
#requires -module vmxtoolkit
[int]$lab_apt_cache_ip = $ip_startrange
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "labbuildr-scripts"
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
if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}

if (!$DNS2)
    {
    $DNS2 = $DNS1
    }
if (!$Masterpath) {$Masterpath = $Builddir}

$ip_startrange = $ip_startrange+$Startnode
$logfile = "/tmp/labbuildr.log"

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
###
	$Devicename = "$Location"+"_Disk_$Driveletter"
	$VolumeName = "Volume_$Location"
	$ProtectionDomainName = "PD_$BuildDomain"
	$StoragePoolName = "SP_$BuildDomain"
	$SystemName = "ScaleIO@$BuildDomain"
	$FaultSetName = "Rack_"
	[int]$mdm_a_byte = $ip_startrange
	[int]$mdm_b_byte = $ip_startrange+1
	[int]$mdm_c_byte = $ip_startrange+2
	$mdm_ipa  = "$subnet.$mdm_a_byte"
	$mdm_ipb  = "$subnet.$mdm_b_byte"
	$MDMPassword = "Password123!"
	$tb_ip = "$subnet.$mdm_c_byte"
	$mdm_name_a = "Manager_A"
	$mdm_name_b = "Manager_B"
	$tb_name = "TB"
	$scaleio_dir = Join-Path $Sourcedir "ScaleIO"
	$Unity_IP = "$subnet.171"
	$Unity_Target_IP ="$subnet.173"
	$Unity_vPool_name = 'vPool'
	if ($Custom_unity_ip)
		{
		$Unity_IP = $Custom_unity_ip
		}
	if ($Custom_Unity_Target_ip)
		{
		$Unity_Target_IP = $Custom_Unity_Target_ip
		}
	if ($custom_unity_vpool_name)
		{
		$Unity_vPool_name= $custom_unity_vpool_name
		}
##

switch ($PsCmdlet.ParameterSetName)
		{
			"openstack"
			{
			if ($openstack_release -eq 'newton')
				{
				$ubuntu_ver = '16_4'
				}
			else
				{
				$ubuntu_ver = '14_4'
				}
			if ($cinder)
				{
				$cinder_parm = " -cb "+($cinder -join ",")
				if ($cinder -contains "scaleio")
					{
					[switch]$Scaleio = $true
					$cinder_parm = "$cinder_parm -spd $ProtectionDomainName -ssp $StoragePoolName -sgw $tb_ip"
					}
				if ($cinder -contains "unity")
					{
					$cinder_parm = "$cinder_parm -up $Unity_vPool_name -uip $Unity_IP"
					}
				}
			[switch]$Openstack_Controller = $true
			}
		}
if ($scaleio.IsPresent -and $Nodes -lt 3)
	{
	Write-Host -ForegroundColor Gray " ==>Setting Nodes to 3"
	$Nodes = 3
	}
if ($scaleio.IsPresent)
	{
	[switch]$sds=$true
	[switch]$sdc=$true
	If ($singlemdm.IsPresent)
        {
        Write-Warning "Single MDM installations with MemoryTweaking  are only for Test Deployments and Memory Contraints/Manager Laptops :-)"
        $mdm_ip="$mdm_ipa"
        }
    else
        {
        $mdm_ip="$mdm_ipa,$mdm_ipb"
        }
	Write-Host -ForegroundColor Gray " ==>using MDM IP´s $mdm_ip"
	$ubuntu_sio_ver = $ubuntu_ver -replace "_",".0"
	$Ubuntu = Get-ChildItem *$ubuntu_sio_ver* -Path $scaleio_dir -Include "*UBUNTU_$ubuntu_sio_ver*" -Recurse -Directory -ErrorAction SilentlyContinue
if (!$ubuntu)
	{
	Receive-LABScaleIO -Destination $Sourcedir -arch linux -unzip -force
	$Ubuntu = Get-ChildItem *$ubuntu_sio_ver* -Path $scaleio_dir -Include "*UBUNTU_$ubuntu_sio_ver*" -Recurse -Directory -ErrorAction SilentlyContinue
	}
if (!$Ubuntu -or $ubuntu -notmatch $ubuntu_sio_ver)
	{
	Write-Warning "could not download / find any valid scaleio ubuntu source"
	exit
	}
	Write-Host " ==>got Ubuntu files"
	Write-Host -ForegroundColor Gray " ==>evaluating ubuntu files"
	$Ubuntu = Get-ChildItem *$ubuntu_sio_ver* -Path $scaleio_dir -Include *UBUNTU* -Exclude "*.zip" -Recurse -Directory
	$Ubuntudir = $Ubuntu | Sort-Object -Descending | Select-Object -First 1
	Write-Host -ForegroundColor Gray " ==>Using Ubuntu Dir $Ubuntudir"
	If ($Ubuntudir -match 2.0.1.0)
		{
		Write-Host -ForegroundColor Magenta " ==>looks like we detected ScaleIO 2.0.1"
		$SIOMajor = "2.0.1"
		}
	if ((Get-ChildItem -Path $Ubuntudir -Filter "*.deb" -Recurse -Include *Ubuntu*).count -ge 9)
		{
		Write-Host -ForegroundColor Gray " ==>found deb files, no siob_extraxt required"
		$debfiles = $true
		}
	else
		{
		Write-Host -ForegroundColor Gray " ==>need to get deb´s from SIOB files"
		if ($siobfiles = Get-ChildItem -Path $Ubuntudir -Filter "*.siob" -Recurse -Include *Ubuntu* -Exclude "*.sig")
			{
			Write-Host -ForegroundColor Gray " ==>found siob files  in $Ubuntudir"
			#$siobfiles.count
			}
		}
	Write-Host -ForegroundColor Gray " ==>evaluationg base path for Gateway"
    $SIOGatewayrpm = Get-ChildItem -Path $scaleio_dir -Recurse -Filter "emc-scaleio-gateway*.deb"  -Exclude ".*" -ErrorAction SilentlyContinue

    try
        {
        $SIOGatewayrpm = $SIOGatewayrpm[-1].FullName
        }
    Catch
        {
        Write-Warning "ScaleIO Gateway RPM not found in $scaleio_dir
        if using 2.x, the Zip files are Packed recursively
        manual action required: expand ScaleIO Gateway ZipFile"
        return
        }
    $Sourcedir_replace = $Sourcedir.Replace("\","/")
	$SIOGatewayrpm = $SIOGatewayrpm.Replace("\","/")
    $SIOGatewayrpm = $SIOGatewayrpm -replace  $Sourcedir_replace,"/mnt/hgfs/Sources/"
	$Ubuntu_guestdir = $Ubuntudir.Fullname.Replace("\","/")
	# = $Ubuntudir.fullname.Replace("\","\\")
	$Ubuntu_guestdir = $Ubuntu_guestdir -replace  $Sourcedir_replace,"/mnt/hgfs/Sources/"
    Write-Host $Ubuntu_guestdir
    Write-Host $SIOGatewayrpm
	$Percentage = [math]::Round(100/$nodes)+1
	if ($Percentage -lt 10)
		{
		$Percentage = 10
		}
	}

switch ($ubuntu_ver)
    {
    "16_4"
        {
        $netdev = "ens160"
        }
    "15_10"
        {
        $netdev= "eno16777984"
        }
    default
        {
        $netdev= "eth0"
        }
    }

$rootuser = "root"
$Guestpassword = "Password123!"
[uint64]$Disksize = 100GB
$scsi = 0
$Nodeprefix = "Ubuntu"
$Nodeprefix = $Nodeprefix.ToLower()
$OS = "Ubuntu"
$Required_Master = "$OS$ubuntu_ver"
$Default_Guestuser = "labbuildr"
if ($use_aptcache.IsPresent)
	{
	if (!$do_not_use_lab_aptcache.IsPresent)
		{
		$apt_ip = "$subnet.$lab_apt_cache_ip"
		if (!($aptvmx = get-vmx aptcache -WarningAction SilentlyContinue))
			{
			Write-Host -ForegroundColor Magenta " ==>installing apt cache"
			.\install-aptcache.ps1 -Defaults -ip_startrange $lab_apt_cache_ip -Size M -upgrade:$($upgrade.IsPresent)
			}
		}
	else
		{
		if (!$apt_ip)
			{
			Write-Warning "A apt ip address must be specified if uning do_not_use_labaptcache"
			}
		}
	Write-Host -ForegroundColor White " ==>Using cacher at $apt_ip"
	}
try
    {
    $MasterVMX = test-labmaster -Masterpath $MasterPath -Master $Required_Master -Confirm:$Confirm -erroraction stop
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
####
if (!$MasterVMX.Template)
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
        if (!$Basesnap)
        {
         Write-verbose "Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        }
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
####Build Machines#
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-output $PSCmdlet.MyInvocation.BoundParameters
	pause
    }
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        try
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node # -clonepath $Builddir
            }
        catch
            {
            Write-Warning "Error creating VM"
            return
            }
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        $Netadapter = Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
        if ($vmnet)
            {
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }

        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
       <# if ($node -eq 3)
            {
            Write-Host -ForegroundColor Gray " ==>Setting Gateway Memory to 3 GB"
            $NodeClone | Set-VMXmemory -MemoryMB 3072 | Out-Null
            }#>
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Ubuntu -Scenario 7
        if ($nodenum -eq 3)
			{
			$mysize = $NodeClone |Set-VMXSize -config $NodeClone.Config -Size $Size
			}
		else
			{
			$mysize = $NodeClone |Set-VMXSize -config $NodeClone.Config -Size $Compute_Size
			}

		$NodeClone | Set-VMXVTBit -VTBit | Out-Null
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
        }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }
    }
Write-Host -ForegroundColor White "Starting Node Configuration"
$ip_startrange_count = $ip_startrange
$installmessage = @()
foreach ($Node in $machinesBuilt)
    {
        $ip="$subnet.$ip_startrange_count"
		if ($node -eq $machinesBuilt[-1])
			{
			$controller_ip = $ip
			}
        $NodeClone = get-vmx $Node

        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
		$installmessage += "Node $node is reachable via ssh $ip with root:$($guestpassword)  or $($Default_Guestuser):$($Guestpassword)`n"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $NodeClone | Set-VMXSharedFolder -add -Sharename Scripts -Folder $Scriptdir  | Out-Null

        If ($ubuntu_ver -match "15")
            {
            $Scriptblock = "systemctl disable iptables.service"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }

        $Scriptblock = "sed -i '/PermitRootLogin without-password/ c\PermitRootLogin yes' /etc/ssh/sshd_config"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null

        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -force"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null

        $Scriptblock = "/usr/bin/ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null

        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null

        if ($Hostkey)
            {
            $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            $Scriptblock = "mkdir /home/$Default_Guestuser/.ssh/;echo '$Hostkey' >> /home/$Default_Guestuser/.ssh/authorized_keys;chmod 0600 /home/$Default_Guestuser/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }

        $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

		Write-Verbose "setting sudoers"
		$Scriptblock = "echo '$Default_Guestuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #  -logfile $Logfile

 		$Scriptblock = "sed -i 's/^.*\bDefaults    requiretty\b.*$/Defaults    !requiretty/' /etc/sudoers"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        $Scriptblock = "echo 'auto lo' > /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'iface lo inet loopback' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'auto $netdev' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'iface $netdev inet static' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'address $ip' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'gateway $DefaultGateway' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'netmask 255.255.255.0' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'network $subnet.0' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'broadcast $subnet.255' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'dns-nameservers $DNS1 $DNS2' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'dns-search $BuildDomain.$Custom_DomainSuffix' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo '127.0.0.1       localhost' > /etc/hosts; echo '$ip $Node $Node.$BuildDomain.$Custom_DomainSuffix' >> /etc/hosts; hostname $Node"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        $Scriptblock = "hostnamectl set-hostname $Node.$BuildDomain.$Custom_DomainSuffix"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        switch ($ubuntu_ver)
            {
            "14_4"
                {
                $Scriptblock = "/sbin/ifdown eth0 && /sbin/ifup eth0"
                }
            default
                {
                $Scriptblock = "/etc/init.d/networking restart"
                }
            }
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        Write-Host -ForegroundColor Cyan " ==>Testing default Route, make sure that Gateway is reachable ( eg. install and start OpenWRT )
        if failures occur, you might want to open a 2nd labbuildr windows and run start-vmx OpenWRT "
        $Scriptblock = "DEFAULT_ROUTE=`$(ip route show default | awk '/default/ {print `$3}');ping -c 1 `$DEFAULT_ROUTE"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
		$NodeClone | Set-LabAPTCacheClient -cache_ip $apt_ip
		if ($upgrade.ispresent)
			{
			$Scriptblock = "apt-get update;DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=`"--force-confdef`" -o Dpkg::Options::=`"--force-confold`" dist-upgrade"
			$nodeclone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
			}
		if ($cinder -contains "unity")
			{
			Write-Host -ForegroundColor Gray " ==>configuring iscsi $($NodeClone.VMXName)"
			$ISCSI_IQN = "iqn.2016-10.org.linux:$($NodeClone.VMXname).$BuildDomain.$custom_domainsuffix.c0"
			$Scriptblocks = (
			"apt-get install -y open-iscsi",
			"echo 'InitiatorName=$ISCSI_IQN' > /etc/iscsi/initiatorname.iscsi",
			"/etc/init.d/open-iscsi restart",
			"iscsiadm -m discovery -t sendtargets -p $Unity_Target_IP",
			"iscsiadm -m node --login")
			foreach ($Scriptblock in $Scriptblocks)
				{
				Write-Verbose $Scriptblock
				$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
				}
			}

        switch ($Desktop)
            {
                default
                {
				$Desktop = $Desktop.ToLower()
                Write-Host -ForegroundColor Gray " ==>downloading and configuring $Desktop as Desktop, this may take a while"
                $Scriptblock = "apt-get update;apt-get install -y $Desktop firefox lightdm xinit"
				Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile| Out-Null
				if ($Desktop -eq 'xfce4')
					{
					$Scriptblock = "apt-get install xubuntu-default-settings -y"
					#$Scriptblock = "/usr/lib/lightdm/lightdm-set-defaults --session xfce4-session"
					Write-Verbose $Scriptblock
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
					}
                Write-Host -ForegroundColor Gray " ==>enabling login manager"
                #$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                $Scriptblock = "systemctl enable lightdm"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
                }
            'none'
                {
                }
            }
        ####
		if ($Desktop -ne 'none')
			{
			Write-Host -ForegroundColor Gray " ==>reconfiguring vmwaretools, system will be ready after login manager restart"
			$Scriptblock = "/usr/bin/vmware-config-tools.pl -d;systemctl restart lightdm"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait| Out-Null
			}
        $ip_startrange_count++
    }

 ## scaleio
 $Nodecounter = 1
if ($scaleio.IsPresent)
    {
	[switch]$configure = $true
	foreach ($Node in $machinesBuilt)
			{
			$NodeClone = get-vmx $Node
			$Primary = get-vmx $machinesBuilt[0]
			$scriptblock = "apt-get update;apt-get install -y libaio1 libnuma1 openssl dos2unix git curl software-properties-common"
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
			if ($Nodecounter -eq 1 -and !$debfiles)
				{
				Write-Host -ForegroundColor Gray " ==>generating debs from siob"
				foreach ($siobfile in $siobfiles)
					{
					$Scriptblock = "$Ubuntu_guestdir/siob_extract $Ubuntu_guestdir/$($siobfile.name)"
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					}
				}
			$ip="$subnet.$ip_startrange_count"
			if (!($PsCmdlet.ParameterSetName -eq "sdsonly"))
				{
				if (($Nodecounter -in 1..2 -and (!$singlemdm)) -or ($Nodecounter -eq 1))
					{
					Write-Host -ForegroundColor Gray " ==>trying MDM Install as manager"
					$NodeClone | Invoke-VMXBash -Scriptblock "MDM_ROLE_IS_MANAGER=1 dpkg -i $ubuntu_guestdir/EMC-ScaleIO-mdm*.deb" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					$installmessage += "MDM installed on $mdm_ip`n"
					}

				if ($Nodecounter -eq 3)
					{
					$GatewayNode = $NodeClone
					Write-Host -ForegroundColor Gray " ==>trying Gateway Install"
					$Scriptblock = "add-apt-repository ppa:webupd8team/java -y;apt-get update -y;echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections;apt-get install oracle-java8-installer -y;apt-get install oracle-java8-set-default -y"
					Write-Host $Scriptblock
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

					$Scriptblock = "GATEWAY_ADMIN_PASSWORD='Password123!' /usr/bin/dpkg -i $SIOGatewayrpm"
					#$NodeClone | Invoke-VMXBash -Scriptblock "export SIO_GW_KEYTOOL=/usr/bin/;export GATEWAY_ADMIN_PASSWORD='Password123!';dpkg -i $SIOGatewayrpm;dpkg -l emc-scaleio-gateway" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					Write-Host $Scriptblock
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword   -nowait| Out-Null #-logfile $Logfile
					#if ($SIOMajor -ne "2.0.1")
					#	{
						Write-Host -ForegroundColor Red " ==>waiting for strings process"
						do {
							$Processlist = $NodeClone | Get-VMXProcessesInGuest -Guestuser $rootuser -Guestpassword $Guestpassword
							sleep 2
							write-verbose "Still Waiting ! "
							}
						until ($Processlist -match 'strings')
						$Scriptblock = "killall strings"
						$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword   -nowait| Out-Null #-logfile $Logfile
					#	}
					Write-Host -ForegroundColor White " ==>waiting for scaleio gateway"
					do {
						$Processlist = $NodeClone | Get-VMXProcessesInGuest -Guestuser $rootuser -Guestpassword $Guestpassword
						sleep 2
						write-verbose "Still Waiting ! "
						}
					until ($Processlist -match 'java' -and $Processlist -notmatch 'dpkg')
					#}
					$installmessage += "Scaleio Gateway can be reached via https://$($tb_ip):443 with admin:$($Guestpassword)`n"
					if (!$singlemdm)
						{
						Write-Host -ForegroundColor Gray " ==>trying MDM Install as tiebreaker"
						$NodeClone | Invoke-VMXBash -Scriptblock "MDM_ROLE_IS_MANAGER=0 dpkg -i $ubuntu_guestdir/EMC-ScaleIO-mdm*.deb" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
						Write-Host -ForegroundColor Gray " ==>adding MDM to Gateway Server Config File"
						$sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$mdm_ipa;$mdm_ipb\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties"
						}
					else
						{
						Write-Host -ForegroundColor Gray " ==>adding MDM's to Gateway Server Config File"
						$sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$mdm_ipa;$mdm_ipa\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties"
						}
					Write-Verbose $sed
					$NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					$MY_CIPHERS="'ciphers='\`"'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256,TLS_DHE_DSS_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384'\`"''"
					$Scriptblock = "MYCIPHERS=$MY_CIPHERS;sed -i '/ciphers=/s/.*/'`$MYCIPHERS'/' /opt/emc/scaleio/gateway/conf/server.xml"
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					$NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/scaleio-gateway restart" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
					}
				Write-Host -ForegroundColor Gray " ==>trying LIA Install"
				$NodeClone | Invoke-VMXBash -Scriptblock "dpkg -i $ubuntu_guestdir/EMC-ScaleIO-lia*.deb" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				}
			if ($sds.IsPresent)
				{
				Write-Host -ForegroundColor Gray " ==>trying SDS Install"
				$NodeClone | Invoke-VMXBash -Scriptblock "dpkg -i $ubuntu_guestdir/EMC-ScaleIO-sds-*.deb" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				}
			if ($sdc.IsPresent)
				{
				Write-Host -ForegroundColor Gray " ==>trying SDC Install"
				$NodeClone | Invoke-VMXBash -Scriptblock "export MDM_IP=$mdm_ip;dpkg -i $ubuntu_guestdir/EMC-ScaleIO-sdc*.deb" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				$Scriptlets = ("cat > /bin/emc/scaleio/scini_sync/driver_sync.conf <<EOF
repo_address        = ftp://ftp.emc.com`
repo_user           = QNzgdxXix`
repo_password       = Aw3wFAwAq3`
local_dir           = /bin/emc/scaleio/scini_sync/driver_cache/`
module_sigcheck     = 0`
emc_public_gpg_key  = /bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO`
repo_public_rsa_key = /bin/emc/scaleio/scini_sync/scini_repo_key.pub`
",
"/usr/bin/dos2unix /bin/emc/scaleio/scini_sync/driver_sync.conf;/etc/init.d/scini restart")
				foreach ($Scriptblock in $Scriptlets)
						{
						Write-Verbose $Scriptblock
						$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
						}
				}
		$Nodecounter++
		}##end nodes
	Write-Host -ForegroundColor Magenta " ==> Now configuring ScaleIO"
	$mdmconnect = "scli --login --username admin --password $MDMPassword --mdm_ip $mdm_ip"
	if ($Primary)
		{
		Write-Host -ForegroundColor Magenta "We are now creating the ScaleIO Cluster"
		Write-Host -ForegroundColor Gray " ==>adding Primary MDM $mdm_ipa"
		$sclicmd =  "scli --create_mdm_cluster --master_mdm_ip $mdm_ipa  --master_mdm_management_ip $mdm_ipa --master_mdm_name $mdm_name_a --approve_certificate --accept_license;sleep 3"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
		Write-Host -ForegroundColor Gray " ==>Setting password"
		$sclicmd =  "scli --login --username admin --password admin --mdm_ip $mdm_ipa;scli --set_password --old_password admin --new_password $MDMPassword --mdm_ip $mdm_ipa"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
		if (!$singlemdm.IsPresent)
			{
			Write-Host -ForegroundColor Gray " ==>adding standby MDM $mdm_ipb"
			$sclicmd = "$mdmconnect;scli --add_standby_mdm --mdm_role manager --new_mdm_ip $mdm_ipb --new_mdm_management_ip $mdm_ipb --new_mdm_name $mdm_name_b --mdm_ip $mdm_ipa"
			Write-Verbose $sclicmd
			$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
			Write-Host -ForegroundColor Gray " ==>adding tiebreaker $tb_ip"
			if ($SIOMajor -eq "2.0.1")
				{
				$sclicmd = "$mdmconnect; scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --add_tb_name $tb_name --mdm_ip $mdm_ipa"
				}
			else
				{
				$sclicmd = "$mdmconnect; scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --tb_name $tb_name --mdm_ip $mdm_ipa"
				}
			Write-Verbose $sclicmd
			$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

			Write-Host -ForegroundColor Gray " ==>switching to cluster mode"
			$sclicmd = "$mdmconnect;scli --switch_cluster_mode --cluster_mode 3_node --add_slave_mdm_ip $mdm_ipb --add_tb_ip $tb_ip  --mdm_ip $mdm_ipa"
			Write-Verbose $sclicmd
			$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
			}
		else
			{
			$mdm_ipb = $mdm_ipa
			}
		Write-Host -ForegroundColor Magenta "Storing SIO Confiuration locally"
		Set-LABSIOConfig -mdm_ipa $mdm_ipa -mdm_ipb $mdm_ipb -gateway_ip $tb_ip -system_name $SystemName -pool_name $StoragePoolName -pd_name $ProtectionDomainName

		Write-Host -ForegroundColor Gray " ==>adding protection domain $ProtectionDomainName"
		$sclicmd = "scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
		$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

		Write-Host -ForegroundColor Gray " ==>adding storagepool $StoragePoolName"
		$sclicmd = "scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
		Write-Host -ForegroundColor Gray " ==>adding renaming system to $SystemName"
		$sclicmd = "scli --rename_system --new_name $SystemName --mdm_ip $mdm_ip"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
	}#end Primary
	foreach ($Node in 1..$Nodes)
				{
				[int]$sds_ip = $ip_startrange+$Node-1
				Write-Host -ForegroundColor Gray " ==>adding sds $subnet.$sds_ip with /dev/sdb"
				$sclicmd = "scli --add_sds --sds_ip $subnet.$sds_ip --device_path /dev/sdb --device_name /dev/sdb  --sds_name $Nodeprefix$Node --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip"
				Write-Verbose $sclicmd
				$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				}
	Write-Host -ForegroundColor Gray " ==>adjusting spare policy"
	$sclicmd = "scli --modify_spare_policy --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --spare_percentage $Percentage --i_am_sure --mdm_ip $mdm_ip"
	Write-Verbose $sclicmd
	$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
	write-host "Connect with ScaleIO UI to $mdm_ipa admin/Password123!"
	## gw tasks start
	Write-Host -ForegroundColor Gray " ==> approving mdm Certificates for gateway"
$scriptblock = "export TOKEN=`$(curl --silent --insecure --user 'admin:$($Guestpassword)' 'https://localhost/api/gatewayLogin' | sed 's:^.\(.*\).`$:\1:') \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipa)' > '/tmp/mdm_a.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_a.cer' 'https://localhost/api/trustHostCertificate/Mdm' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipb)' > '/tmp/mdm_b.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_b.cer' 'https://localhost/api/trustHostCertificate/Mdm' "
	$GatewayNode | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
	}

	if ($Openstack_Controller.IsPresent)
		{
		if ($scaleio.IsPresent)
			{
			$controller_node = $GatewayNode
			$controller_ip = $tb_ip
			}
		else
			{
			$Controller_node = get-vmx $machinesBuilt[-1]
			}
		$ip_startrange_count = $ip_startrange
		Write-Host -ForegroundColor Gray " ==>starting OpenStack controller setup on $($machinesBuilt[-1])"
		$Scriptblock = "cd /mnt/hgfs/Scripts/openstack/$openstack_release/Controller; bash ./install_base.sh $cinder_parm --domain $BuildDomain --suffix $custom_domainsuffix -c $($Openstack_Baseconfig.ispresent.ToString().tolower())"
		$controller_node | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
		$installmessage += "OpenStack Horizon can be reached via http://$($controller_node.vmxname):88/horizon with admin:$($Guestpassword)`n"
		foreach ($Node in $machinesBuilt)
			{
			if ($Node -ne $controller_node.vmxname)
				{
				$NodeClone = Get-VMX $Node
				Write-Host -ForegroundColor Gray " ==>starting nova-compute setup on $($NodeClone.vmxname)"
				$Scriptblock = "cd /mnt/hgfs/Scripts/openstack/$openstack_release/Compute; bash ./install_base.sh -cip $controller_ip --docker $($docker.IsPresent.ToString().tolower()) -cname $($controller_node.vmxname.tolower())"
				Write-Verbose $Scriptblock
				$NodeClone| Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				$installmessage += "OpenStack Nova-Compute is running on $($NodeClone.vmxname)`n"
				$ip_startrange_count++
				}
			}
		}

		## scaleio end
		###
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White $installmessage