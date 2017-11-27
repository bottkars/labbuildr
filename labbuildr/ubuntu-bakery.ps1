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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks//ubuntu-bakery.ps1
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
[Parameter(ParameterSetName = "kubernetes",Mandatory=$true)]
[switch]$kubernetes,
[Parameter(ParameterSetName = "openstack",Mandatory=$false)]
[ValidateSet('liberty','mitaka','newton','ocata')]
[string]$openstack_release = 'liberty',
[Parameter(ParameterSetName = "openstack",Mandatory=$False)] 
[ValidateSet('unity','scaleio','none')]
[string[]]$cinder = "scaleio",
[Parameter(ParameterSetName = "openstack",Mandatory=$False)] 
[switch]$swift,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[switch]$docker=$false,
#[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$false)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[ValidateSet('cinnamon','cinnamon-desktop-environment','xfce4','lxde','none')]
[string]$Desktop = "none",
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$False)]
[ValidateRange(1,9)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$False)]
[int32]$Startnode = 1,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$False)]
[switch]$forcedownload,
[Parameter(ParameterSetName = "scaleio", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$False)]
[switch]$forceupdate,
[Parameter(ParameterSetName = "kubernetes",Mandatory=$false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $true)]
[Switch]$scaleio,
[Parameter(ParameterSetName = "openstack",Mandatory=$false)]
[Parameter(ParameterSetName = "kubernetes",Mandatory=$false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "scaleio", Mandatory = $true)]
[Switch]$singlemdm,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Switch]$Openstack_Controller,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
[Switch]$Openstack_Baseconfig = $true,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$Custom_unity_ip,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$custom_unity_vpool_name,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
$Custom_Unity_Target_ip,
[Parameter(ParameterSetName = "openstack",Mandatory=$False)]
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
###### commo parameters
#### generic labbuildr7
	[Parameter(Mandatory = $false)]
	[ValidateRange(1,3)]
	[int32]$Disks = 1,
	[Parameter(Mandatory = $false)]
	[ValidateSet('17_10','16_4','15_10','14_4' #-#
	)]
	[string]$ubuntu_ver = "16_4",
	[Parameter(Mandatory=$false)]
	$Scriptdir = (join-path (Get-Location) "labbuildr-scripts"),
	[Parameter(Mandatory=$false)]
	$Sourcedir = $Global:labdefaults.Sourcedir,
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
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
	$vmnet = $Global:labdefaults.vmnet,
	[int]$ip_startrange = 200,
	[switch]$use_aptcache = $true,
	[ipaddress]$non_lab_apt_ip,
	[switch]$do_not_use_lab_aptcache,
	[switch]$upgrade,
	[switch]$Defaults,
	[string[]]$additional_packages
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
	$builtinParameters = @("ErrorAction","WarningAction","Verbose","ErrorVariable","WarningVariable","OutVariable","OutBuffer","Debug")
	$totalParameterCount = $($MyInvocation.MyCommand.Parameters.count)
	$parameterCount = 0 
	($MyInvocation.MyCommand.Parameters ).Keys | ForEach-Object {
		if ( $builtinParameters -notcontains $_ ) 
			{
			$parameterCount++
			}
		}
		$boundParameters = @()
		Write-Host -ForegroundColor Yellow "$parameterCount parameters defined param statement"
		Write-Host -ForegroundColor Yellow "$($MyInvocation.BoundParameters.count) parameters are provided on the cmdline:"
		$MyInvocation.BoundParameters.keys | ForEach-Object {
		Write-Host "'$($_)' = '$($PSBoundParameters.Item($_))'"
		$boundParameters+=$_
	}
	Write-Host -ForegroundColor Yellow "These parameters have been configured with default values:"
	$parametersToIgnore = $builtinParameters + $boundParameters

	($MyInvocation.MyCommand.Parameters ).Keys | ForEach-Object {
	if ( $boundParameters -notcontains $_ ) 
		{
		$val = (Get-Variable -Name $_ -EA SilentlyContinue).Value
		if( $val.length -gt 0 ) 
			{
			"'$($_)' = '$($val)'"
			}
		}
	}
 	Write-Host -ForegroundColor Yellow "Parameters with no Value:"
	($MyInvocation.MyCommand.Parameters ).Keys | ForEach-Object {
		if ( $parametersToIgnore -notcontains $_ ) {
		$val = (Get-Variable -Name $_ -EA SilentlyContinue).Value
		if( $val.length -eq 0 )
			{
			"'$($_)'"
			}
		}
	}
   	pause
}
$Scenarioname = "ubuntu"
$SIO_Username = "admin"
$SIO_Password = "Password123!"
[int]$lab_apt_cache_ip = $ip_startrange
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
if (!$DNS2)
    {
    $DNS2 = $DNS1
    }
if (!$Masterpath) {$Masterpath = $Builddir}
$additional_packages += ('git')
$ip_startrange = $ip_startrange+$Startnode
$logfile = "/tmp/labbuildr.log"

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
###
	$Devicename = "$Location"+"_Disk_$Driveletter"
	$VolumeName = "Volume_$Location"
	$ProtectionDomainName = "PD_$Builddomain"
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
			if ($swift.IsPresent)
				{
				$Disks = 3
				$openstack_release = 'ocata'
				}
			$additional_packages += ('software-properties-common', 'python-software-properties','vim','curl')
			$Scenarioname = 'Openstack'
			if ($openstack_release -in ('newton','ocata'))
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
			"Kubernetes"
			{
			$Scenarioname = 'Kubernetes'
			$ubuntu_ver = '16_4'
			$additional_packages += ('software-properties-common', 'python-software-properties','vim','curl','xfsprogs')
			If ($Nodes -lt 2 -and !$scaleio.IsPresent)
				{
				Write-Host -ForegroundColor White "--> incrementing Nodecount to 2 for Kubernetes"
				$Nodes = 2
				}
			}
		
		}
###
if ($scaleio.IsPresent -or $kubernetes.IsPresent)
{
	if ($ubuntu_ver -gt "16_4")
		{
			write-host "NO Support of $ubuntu_ver in Scenario, setting to 16_4 "
			$ubuntu_ver = "16_4"
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
		$mdm_ipb = $mdm_ipa
        }
    else
        {
        $mdm_ip="$mdm_ipa,$mdm_ipb"
        }
	Write-Host -ForegroundColor Gray " ==>using MDM IP´s $mdm_ip"
	Set-LABSIOConfig -mdm_ipa $mdm_ipa -mdm_ipb $mdm_ipb -gateway_ip $tb_ip -system_name $SystemName -pool_name $StoragePoolName -pd_name $ProtectionDomainName

	$ubuntu_sio_ver = $ubuntu_ver -replace "_",".0"
	$Ubuntu = Get-ChildItem *$ubuntu_sio_ver* -Path $scaleio_dir -Include "*UBUNTU_$ubuntu_sio_ver*" -Recurse -Directory -ErrorAction SilentlyContinue
if (!$ubuntu -or $forcedownload.IsPresent)
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
	$SIO_Ubuntu_Dir = $Ubuntu | Sort-Object -Descending | Select-Object -First 1
	Write-Host -ForegroundColor Gray " ==>Using Ubuntu Dir $SIO_Ubuntu_Dir"
	If ($SIO_Ubuntu_Dir -match 2.0.1.)
		{
		Write-Host -ForegroundColor Magenta " ==>looks like we detected ScaleIO 2.0.1"
		$SIOMajor = "2.0.1"
		$SIO_FILE_VER = "2.0-1"
		}
	else
		{
		$SIO_FILE_VER = "-2.0"
		}
	if ((Get-ChildItem -Path $SIO_Ubuntu_Dir -Filter "*.deb" -Recurse -Include *Ubuntu*).count -ge 9)
		{
		Write-Host -ForegroundColor Gray " ==>found deb files, no siob_extraxt required"
		$debfiles = $true
		}
	else
		{
		Write-Host -ForegroundColor Gray " ==>need to get deb´s from SIOB files in $SIO_Ubuntu_Dir"
		$siobfiles = Get-ChildItem -Path $SIO_Ubuntu_Dir -Filter "*.siob" -Recurse -Include *Ubuntu* -Exclude "*.sig"
		if ($siobfiles.count -ge 9)
			{
			Write-Host -ForegroundColor Gray " ==>found $($siobfiles.count) siob files  in $SIO_Ubuntu_Dir"
			#$siobfiles.count
			}
		else
			{
			Write-Host " ==> Not or not all Siob FIles found. Fun. Somebody Thinks it its cool to zip and tar and siob pack for whatever reason :-( "	
			$sio_tar_files = Get-ChildItem -Path $SIO_Ubuntu_Dir -Filter "*.tar" -Recurse -Include *Ubuntu* -Exclude "*.sig"
			Write-Host " ==> got $($sio_tar_files.count) Tar Files"
			foreach ($sio_tar_file in $sio_tar_files)
				{
				Expand-LABpackage -Archive $sio_tar_file -Destination $SIO_Ubuntu_Dir -force
				}
				if ($siobfiles = Get-ChildItem -Path $SIO_Ubuntu_Dir -Filter "*.siob" -Recurse -Include *Ubuntu* -Exclude "*.sig")
					{
					Write-Host -ForegroundColor Gray " ==>found $($siobfiles.count) siob files  in $SIO_Ubuntu_Dir"
					#$siobfiles.count
					}
				else
					{
					Write-Host	"unfortunately no siob files found, exiting now"
					break
					}
			}
		}
	Write-Host -ForegroundColor Gray " ==>evaluationg base path for Gateway in $scaleio_dir for emc-scaleio-gateway_$SIO_FILE_VER*.deb"
    $SIOGatewayrpm = Get-ChildItem -Path $scaleio_dir -Recurse -Filter "emc-scaleio-gateway_$SIO_FILE_VER*.deb"  -Exclude ".*" -ErrorAction SilentlyContinue

    try
        {
        $SIOGatewayrpm = $SIOGatewayrpm[-1].FullName
        }
    Catch
        {
        Write-Warning "ScaleIO Gateway DEB File not found in $scaleio_dir
        if using 2.x, the Zip files are Packed recursively
        manual action required: expand ScaleIO Gateway ZipFile"
        return
        }
    $Sourcedir_replace = $Sourcedir.Replace("\","/")
	$SIOGatewayrpm = $SIOGatewayrpm.Replace("\","/")
    $SIOGatewayrpm = $SIOGatewayrpm -replace  $Sourcedir_replace,"/mnt/hgfs/Sources/"
	$SIOGatewayrpm = $SIOGatewayrpm -replace "//","/"
	$Ubuntu_guestdir = $SIO_Ubuntu_Dir.Fullname.Replace("\","/")
	# = $SIO_Ubuntu_Dir.fullname.Replace("\","\\")
	$Ubuntu_guestdir = $Ubuntu_guestdir -replace  $Sourcedir_replace,"/mnt/hgfs/Sources/"
	$Ubuntu_guestdir = $Ubuntu_guestdir -replace "//","/"
    Write-Host $Ubuntu_guestdir
    Write-Host $SIOGatewayrpm
	$Percentage = [math]::Round(100/$nodes)+1
	if ($Percentage -lt 10)
		{
		$Percentage = 10
		}
	if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
		Write-Verbose "got Ubuntu_sio_ver  $ubuntu_sio_ver"
		Write-Verbose "ubuntu_ver $ubuntu_ver"
		Write-Verbose "SIO_Ubuntu_Dir $SIO_Ubuntu_Dir"
		Pause
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

	
$scsi = 0
$Nodeprefix = "Ubuntu"
$Nodeprefix = $Nodeprefix.ToLower()
$OS = "Ubuntu"
$Required_Master = "$OS$ubuntu_ver"
if ($use_aptcache.IsPresent)
	{
	if (!$do_not_use_lab_aptcache.IsPresent)
		{
		$apt_ip = "$subnet.$lab_apt_cache_ip"
		if (!($aptvmx = get-vmx aptcache -WarningAction SilentlyContinue))
			{
			Set-LABUi -title " ==>installing apt cache"
			.\install-aptcache.ps1 -ip_startrange $lab_apt_cache_ip -Size M -upgrade:$($upgrade.IsPresent)
			Set-LABUi
			}
		else
			{
			$apt_ip = $Global:labdefaults.APT_Cache_IP
			if ($aptvmx.state -ne "running")
				{
				$aptvmx | start-vmx
				$aptvmx | Set-VMXSharedFolderState -enabled
				}
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
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
####Build Machines#
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    #write-output $PSCmdlet.MyInvocation.BoundParameters
	pause
    }
$nodenum = 1
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    $MY_Size = $Size
    if ($nodenum -eq 3 -and $openstack.IsPresent)
		{
		$MY_Size = $Size
		}
	else
		{
		$MY_Size =  $Compute_Size
		}	
	If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        try
            {
			$Nodeclone = New-LabVMX -Masterpath $Masterpath -Ubuntu -Ubuntu_ver $ubuntu_ver -VMXname $Nodeprefix$Node -SCSI_DISK_COUNT $Disks -SCSI_Controller 0 -SCSI_Controller_Type lsisas1068 -SCSI_DISK_SIZE 100GB -vmnet $vmnet -Size $MY_Size -ConnectionType custom -AdapterType vmxnet3 -Scenario 7 -Scenarioname $Scenarioname -activationpreference 1 -Displayname "$Nodeprefix$Node@$DNS_DOMAIN_NAME" -vtbit
            }
        catch
            {
            Write-Warning "Error creating VM"
            break
            }
        If ($Node -eq 1)
			{
			$Primary = $NodeClone
			}
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
        }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists
Please select an available Startnode with -Startnode Parameter"
		exit
        }
    $nodenum++
	}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-output $PSCmdlet.MyInvocation.BoundParameters
	pause
    }

Set-LABUi -title "Starting Node Configuration"
$ip_startrange_count = $ip_startrange
$installmessage = @()
$iplist = @()
$openstack_cfg = @()
foreach ($Node in $machinesBuilt)
    {
        $swift_disks = @('/dev/sdc';'/dev/sdd')
		$node_type = 'compute'
		$ip="$subnet.$ip_startrange_count"
		if ($node -eq $machinesBuilt[-1])
			{
			$swift_disks = $null
			$controller_ip = $ip
			$node_type = 'controller'
			}
		$openstack_cfg += @{'NODE_TYPE' = $node_type; 'NODE_NAME' = $node;'NODE_IP' = $ip; 'swiftdisks' = $swift_disks}

		$iplist += $ip
		
        $NodeClone = get-vmx $Node
		########
		#Default Node Installer
		Set-LABUi -title "Set-LabUbuntuVMX -Ubuntu_ver $ubuntu_ver -additional_packages $additional_packages" -short
		$Nodeclone | Set-LabUbuntuVMX -Ubuntu_ver $ubuntu_ver -forceupdate:$($upgrade.IsPresent) -additional_packages $additional_packages -Scriptdir $Scriptdir -Sourcedir $Sourcedir -DefaultGateway $DefaultGateway  -guestpassword $Guestpassword -Default_Guestuser $Default_Guestuser -Rootuser $rootuser -Hostkey $Hostkey -ip $ip -DNS1 $DNS1 -DNS2 $DNS2 -subnet $subnet -Host_Name $($Nodeclone.VMXname) -DNS_DOMAIN_NAME $DNS_DOMAIN_NAME
		Set-LABUi
		########
		#### end replace labbuildr7 Scema

		if ($cinder -contains "unity")
			{
			Write-Host -ForegroundColor Gray " ==>configuring iscsi $($NodeClone.VMXName)"
			$ISCSI_IQN = "iqn.2016-10.org.linux:$($NodeClone.VMXname).$DNS_DOMAIN_NAME.c0"
			$Scriptblocks = (
			"echo 'InitiatorName=$ISCSI_IQN' > /etc/iscsi/initiatorname.iscsi",
			"apt-get install -y open-iscsi",
			#"/etc/init.d/open-iscsi stop",
			"iscsiadm -m discovery -t sendtargets -p $Unity_Target_IP",
			"iscsiadm -m node --login"
			#"/etc/init.d/open-iscsi restart"
			)
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
			$scriptblock = "apt-get update;apt-get install -y libaio1 libnuma1 openssl dos2unix"
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

					$Scriptblock = "GATEWAY_ADMIN_PASSWORD='$SIO_Password' /usr/bin/dpkg -i $SIOGatewayrpm"
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
					#Workaround Compression
					$Scriptblock = "sed -i 's/force/off/g' /opt/emc/scaleio/gateway/conf/server.xml"
					#$MY_CIPHERS="'ciphers='`"'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256,TLS_DHE_DSS_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384'`"''"
					#$Scriptblock = "MYCIPHERS=$MY_CIPHERS;sed -i '/ciphers=/s/.*/'`$MYCIPHERS'/' /opt/emc/scaleio/gateway/conf/server.xml"
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
	$mdmconnect = "scli --login --username $SIO_Username --password $MDMPassword --mdm_ip $mdm_ip"
	if ($Primary)
		{
		Write-Host -ForegroundColor Magenta "We are now creating the ScaleIO Cluster"
		Write-Host -ForegroundColor Gray " ==>adding Primary MDM $mdm_ipa"
		$sclicmd =  "scli --create_mdm_cluster --master_mdm_ip $mdm_ipa  --master_mdm_management_ip $mdm_ipa --master_mdm_name $mdm_name_a --approve_certificate --accept_license;sleep 3"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
		Write-Host -ForegroundColor Gray " ==>Setting password"
		$sclicmd =  "scli --login --username $SIO_Username --password $SIO_Username --mdm_ip $mdm_ipa;scli --set_password --old_password $SIO_Username --new_password $MDMPassword --mdm_ip $mdm_ipa"
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
				$sclicmd = "$mdmconnect; scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --mdm_ip $mdm_ipa"
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
	write-host "Connect with ScaleIO UI to $mdm_ipa admin/$SIO_Password"
	## gw tasks start
	Write-Host -ForegroundColor Gray " ==> approving mdm Certificates for gateway"
$scriptblock = "export TOKEN=`$(curl --silent --insecure --user 'admin:$($Guestpassword)' 'https://localhost/api/gatewayLogin' | sed 's:^.\(.*\).`$:\1:') \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipa)' > '/tmp/mdm_a.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_a.cer' 'https://localhost/api/trustHostCertificate/Mdm' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipb)' > '/tmp/mdm_b.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_b.cer' 'https://localhost/api/trustHostCertificate/Mdm' "
	$GatewayNode | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
	if ($kubernetes.IsPresent)
	{
	$Volumename = "k8sGateKeeper"
	$sclicmd = "scli --add_volume --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --size_gb 8 --thin_provisioned --volume_name $VolumeName --mdm_ip $mdm_ip"
	Write-Verbose $sclicmd
	$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

	foreach ($sdc_ip in $iplist)
        {
        Write-Host -ForegroundColor Magenta "Mapping $VolumeName to node $sdc_ip"
        $sclicmd  ="scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $sdc_ip --allow_multi_map --mdm_ip $mdm_iP"
		Write-Verbose $sclicmd
		$Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        }
	}#>
	$MDM_QUERY = @()
	foreach ($Node in $machinesBuilt)
			{
			$NodeClone = get-vmx $Node
			$Scriptblock = 'vmtoolsd --cmd="info-set guestinfo.MDM $(/opt/emc/scaleio/sdc/bin/drv_cfg --query_mdms)"'
			$Nodeclone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
			$MDM_QUERY += $nodeclone | Get-VMXVariable -GuestVariable MDM
			}
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
		if ($swift.IsPresent)
			{	
			$openstack_json = $openstack_cfg | ConvertTo-Json -Compress
			#$openstack_json = $openstack_json -replace "`"","'"			
			$swift_parm = " -sl '$openstack_json'"
			# $cinder_parm = " -cb "+($cinder -join ",")
			}
		$ip_startrange_count = $ip_startrange
		Write-Host -ForegroundColor Gray " ==>starting OpenStack controller setup on $($machinesBuilt[-1])"
		$Scriptblock = "cd /mnt/hgfs/Scripts/openstack/$openstack_release/Controller; bash ./install_base.sh $cinder_parm $swift_parm --domain $BuildDomain --suffix $custom_domainsuffix -c $($Openstack_Baseconfig.ispresent.ToString().tolower())"
		Set-LABUi -short -title "==>running ./install_base.sh $cinder_parm $swift_parm --domain $BuildDomain --suffix $custom_domainsuffix -c $($Openstack_Baseconfig.ispresent.ToString().tolower())"
		$controller_node | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
		Set-Labui
		$installmessage += "OpenStack Horizon can be reached via http://$($controller_node.vmxname):88/horizon with admin:$($Guestpassword)`n"
		foreach ($Node in $machinesBuilt)
			{
			if ($Node -ne $controller_node.vmxname)
				{
				$NodeClone = Get-VMX $Node
				Set-LABUi -title " ==>starting nova-compute setup on $($NodeClone.vmxname)"
				$Scriptblock = "cd /mnt/hgfs/Scripts/openstack/$openstack_release/Compute; bash ./install_base.sh $swift_parm -cip $controller_ip --docker $($docker.IsPresent.ToString().tolower()) -cname $($controller_node.vmxname.tolower())"
				Write-Verbose $Scriptblock
				$NodeClone| Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				Set-LabUI
				$installmessage += "OpenStack Nova-Compute is running on $($NodeClone.vmxname)`n"
				$ip_startrange_count++
				}
			}
		}

	if ($docker)
        {
        Write-Host -ForegroundColor Gray " ==>installing latest docker engine"
        $Scriptblock="apt-get install apt-transport-https ca-certificates;sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
            
		switch ($ubuntu_ver)
			{
			'14_4'
				{
				$deb = "deb http://apt.dockerproject.org/repo ubuntu-trusty main"
				}
			'15_4'
				{
				$deb = "deb http://apt.dockerproject.org/repo ubuntu-jessie main"
				}
			'15_10'
				{
				$deb = "deb http://apt.dockerproject.org/repo ubuntu-wily main"
				}
			'16_4'
				{
				$deb = "deb http://apt.dockerproject.org/repo ubuntu-xenial main"
				}
			'17_10'
				{
				$deb = "deb http://apt.dockerproject.org/repo ubuntu-zesty main"
				}
			}
			
		$Scriptblock = "echo '$deb' >> /etc/apt/sources.list.d/docker.list;apt-get update;apt-get purge lxc-docker;apt-cache policy docker-engine"
		Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

		$Scriptblock = "apt-get install curl linux-image-extra-`$(uname -r) -y"
		Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
		$Scriptblock = "apt-get install docker-engine -y;service docker start;service docker status"
		Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

		$Scriptblock = "curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-``uname -s``-``uname -m`` > /usr/local/bin/docker-compose;chmod +x /usr/local/bin/docker-compose"
		Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
		$Scriptblock = "groupadd docker;usermod -aG docker $Default_Guestuser"

        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
		if ("shipyard" -in $container)
			{
			$Scriptblock = "curl -s https://shipyard-project.com/deploy | bash -s"
			Write-Verbose $Scriptblock
			$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			$installmessage += " ==>you can use shipyard with http://$($ip):8080 with user admin/shipyard`n"

			}
		if ("uifd" -in $container)
			{
			$Scriptblock = "docker run -d -p 9000:9000 --privileged -v /var/run/docker.sock:/var/run/docker.sock uifd/ui-for-docker"
			Write-Verbose $Scriptblock
			$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			$installmessage += " ==>you can use container uifd with http://$($ip):9000`n"
			}

		}
		## docker end
		###
		## scaleio end
		###
if ($kubernetes.IsPresent)
    {
	$k8s_Master = $machinesBuilt[0]
	foreach ($Node in $machinesBuilt)
		{
		$NodeClone = get-vmx $Node
		$Scriptlets = (  "apt-get update && apt-get install -y apt-transport-https",
				"curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
				"cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main`
",
				"apt-get update",
				"sed -i '/ swap / s/^/#/' /etc/fstab",
				"swapoff -a",
				"apt-get install -y docker.io",
				"apt-get install -y kubelet kubeadm kubectl kubernetes-cni")
		foreach ($Scriptblock in $Scriptlets)
			{
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
			}
		if ($Node -eq $k8s_Master)
			{
			$Scriptlets = (   'kubeadm init --pod-network-cidr 10.244.0.0/16',
								'cp /etc/kubernetes/admin.conf $HOME',
								'vmtoolsd --cmd="info-set guestinfo.JOINTOKEN $(kubeadm token list)"',
								'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml --kubeconfig /etc/kubernetes/admin.conf' ,
#								'kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-legacy.yml --kubeconfig /etc/kubernetes/admin.conf',
								'cp /etc/kubernetes/admin.conf /root/.kube/config'
								)
		    foreach ($Scriptblock in $Scriptlets)
				{
				Write-Verbose $Scriptblock
				$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
				}
			$Jointoken = $nodeclone | Get-VMXVariable -GuestVariable JOINTOKEN
			$Jointoken = ($Jointoken.JOINTOKEN[1] -split " ")[0]
			}
		else
			{
			$Scriptblock = "kubeadm join --token=$Jointoken $Subnet.$($ip_startrange):6443"
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
			}
		}
	$Nodeclone = Get-VMX $k8s_Master
	$Scriptlets = ("cat > /root/kube-dashboard-rbac.yml <<EOF
kind: ClusterRoleBinding`
apiVersion: rbac.authorization.k8s.io/v1beta1`
metadata:`
  name: kubernetes-dashboard`
  labels:`
    k8s-app: kubernetes-dashboard`
roleRef:`
  apiGroup: rbac.authorization.k8s.io`
  kind: ClusterRole`
  name: cluster-admin`
subjects:`
- kind: ServiceAccount`
  name: kubernetes-dashboard`
  namespace: kube-system`
",
				"kubectl apply -f /root/kube-dashboard-rbac.yml --kubeconfig /etc/kubernetes/admin.conf",
				"kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml --kubeconfig /etc/kubernetes/admin.conf",
				"kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml  --kubeconfig /etc/kubernetes/admin.conf",
				"kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/standalone/heapster-controller.yaml --kubeconfig /etc/kubernetes/admin.conf"
				)
#				"kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/standalone/heapster-service.yaml --kubeconfig /etc/kubernetes/admin.conf"

	foreach ($Scriptblock in $Scriptlets)
		{
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
		}
	$Scriptblock = "echo 'source <(kubectl completion bash)' >> /root/.bashrc;echo 'source <(kubectl completion bash)' >> /home/labbuildr/.bashrc"
	Write-Verbose $Scriptblock
	$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
	if ($scaleio.IsPresent)
		{
		$byte_SIO_Password  = [System.Text.Encoding]::UTF8.GetBytes($SIO_Password)
		$Base64_Password = [System.Convert]::ToBase64String($byte_SIO_Password)

		$byte_SIO_Username = [System.Text.Encoding]::UTF8.GetBytes($SIO_Username)
		$Base64_Username = [System.Convert]::ToBase64String($byte_SIO_Username)

		$Scriptlets = ("cat > /root/sio-secret.yml <<EOF
apiVersion: v1`
kind: Secret`
metadata:`
  name: sio-secret`
type: kubernetes.io/scaleio`
data:`
  username: $Base64_Username`
  password: $Base64_Password`
",
						"cat > /root/sio-pvc.yml <<EOF
kind: PersistentVolumeClaim`
apiVersion: v1`
metadata:`
  name: pvc-sio-small`
  annotations:`
      volume.beta.kubernetes.io/storage-class: sio-small`
spec:`
  accessModes:`
    - ReadWriteOnce`
  resources:`
    requests:`
      storage: 16Gi`
",

				"cat > /root/sio-sc.yml <<EOF
kind: StorageClass`
apiVersion: storage.k8s.io/v1`
metadata:`
  name: sio-small`
provisioner: kubernetes.io/scaleio`
parameters:`
  gateway: https://$($tb_ip):443/api`
  system: ScaleIO@$BuildDomain`
  protectionDomain: PD_$BuildDomain`
  storagePool: SP_$BuildDomain`
  storageMode: ThinProvisioned`
  secretRef: sio-secret`
  fsType: xfs`
",
			"cat > /root/sio-pod.yml <<EOF
kind: Pod`
apiVersion: v1`
metadata:`
  name: pod-sio-small`
spec:`
  containers:`
    - name: pod-sio-small-container`
      image: gcr.io/google_containers/test-webserver`
      volumeMounts:`
      - mountPath: /test`
        name: test-data`
  volumes:`
    - name: test-data`
      persistentVolumeClaim:`
        claimName: pvc-sio-small`
",
		"kubectl create -f /root/sio-secret.yml --kubeconfig /etc/kubernetes/admin.conf",
		"kubectl create -f /root/sio-sc.yml --kubeconfig /etc/kubernetes/admin.conf",
		"kubectl create -f /root/sio-pvc.yml --kubeconfig /etc/kubernetes/admin.conf",
		"kubectl create -f /root/sio-pod.yml --kubeconfig /etc/kubernetes/admin.conf"
)
		foreach ($Scriptblock in $Scriptlets)
			{
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
			}
		}
	$Scriptblock = 'vmtoolsd --cmd="info-set guestinfo.K8SSTATE=$(kubectl get pods --all-namespaces --kubeconfig /etc/kubernetes/admin.conf)"'
	$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
	Write-Host -ForegroundColor White "K8S State"
	write-host (($nodeclone | Get-VMXVariable -GuestVariable K8SSTATE).k8sstate -join "`n")  -ForegroundColor Green
	Write-Host "you may start your kubectl proxy on your localhost ( see  http://labbuildr.readthedocs.io/en/master/Solutionpacks///ubuntu-bakery.ps1#k8s )"

	}
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White $installmessage
Set-LabUI