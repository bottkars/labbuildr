<#
.Synopsis
   .\install-ecs.ps1
.DESCRIPTION
  install-ecs is a vmxtoolkit solutionpack for configuring and deploying emc elastic cloud staorage on centos

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
   https://github.com/bottkars/labbuildr/wiki/install-ecs.ps1
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "defaults",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
$Sourcedir = 'h:\sources',
#[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$FullClone,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet('mosaicme')]$PrepareBuckets,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('8192','12288','16384','20480','30720','51200','65536')]$Memory = "12288",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet("release-2.1","Develop",'master','latest','2.2.0.1','2.2.0.2','2.2.0.3','2.2.1.0','2.2.1.0-a','2.2.1.1','3.0.0')]$Branch = '3.0.0',
<#Adjusts some Timeouts#>
[switch]$AdjustTimeouts,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$EMC_ca,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$uiconfig,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet(150GB,500GB,520GB)][uint64]$Disksize = 150GB,
# [Parameter(ParameterSetName = "install",Mandatory=$false)]
# [Parameter(ParameterSetName = "defaults", Mandatory = $false)]
# [ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\CentOS7 Master',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 3,[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateRange(1,5)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[switch]$offline,
[switch]$pausebeforescript,
$Nodeprefix = "ECSNode",
$Custom_IP
)
#requires -version 3.0
#requires -module vmxtoolkit
$latest_ecs = "2.2.1.1"
$Range = "24"
$Start = "1"
$IPOffset = 5
$Szenarioname = "ECS"
$Builddir = $PSScriptRoot
$Masterpath = $Builddir
$scsi = 0
#$ecscli = "2.2.1"
If ($Defaults.IsPresent)
    {
    $labdefaults = Get-labDefaults
    $vmnet = $labdefaults.vmnet
    $subnet = $labdefaults.MySubnet
    $BuildDomain = $labdefaults.BuildDomain
    $Sourcedir = $labdefaults.Sourcedir
    try
        {
        Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null
        }
    catch
        [System.Management.Automation.DriveNotFoundException]
        {
        Write-Warning "Make sure to have your Source Stick connected"
        exit
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
        write-warning "no sources directory found at $Sourcedir, please create or select different Directory"
        return
        }
    try
        {
        $Masterpath = $LabDefaults.Masterpath
        }
    catch
        {
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
if (!$Masterpath) {$Masterpath = $Builddir}
If (!$DNS1 -and !$DNS2)
    {
    Write-Warning "DNS Server not Set, exiting now"
    }
If (!$DNS2 -and $DNS1)
    {
    $DNS2 = $DNS1
    }
If (!$DNS1 -and $DNS2)
    {
    $DNS1 = $DNS2
    }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Rootpassword  = "Password123!"
$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword  = "Password123!"
$OS = 'CentOS'
$OS_Version = '7_1_1511'
$Master = "$OS$OS_Version"
switch ($centos_ver)
    {
    "7"
        {
        $netdev = "eno16777984"
        $Required_Master = "$OS Master"
		$Guestuser = "stack"
        }
    default
        {
        $netdev= "eno16777984"
        $Required_Master = $OS
		$Guestuser = "labbuildr"
        }
    }
# $OS = ($Master.Split(" "))[0]
###### checking master Present
Write-Verbose  $Masterpath
$mastervmx = test-labmaster -Master $Master -MasterPath $MasterPath
$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
$repo  = "https://github.com/EMCECS/ECS-CommunityEdition.git"
switch ($Branch)
    {
    "release-2.1"
        {
        $Docker_imagename = "emccorp/ecs-software-2.1"
        $Docker_image = "ecs-software-2.1"
        $Docker_imagetag = "latest"
        $Git_Branch = $Branch
        }
    "master"
        {
        $Docker_image = "ecs-software-2.2.1"
        $Docker_imagename = "emccorp/ecs-software-2.2.1"
        $Docker_imagetag = $latest_ecs
        $Git_Branch = $Branch
        }
    "develop"
        {
        $Docker_image = "ecs-software-3.0.0"
        $Docker_imagename = "emccorp/ecs-software-3.0.0"
        $Docker_imagetag = "latest"
        $Git_Branch = $Branch
        }
    "2.2.1.0"
        {
        $Docker_image = "ecs-software-2.2.1"
        $Docker_imagename = "emccorp/ecs-software-2.2.1"
        $Docker_imagetag = $Branch
        $Git_Branch = "master"
            #$repo = "https://github.com/bottkars/ECS-CommunityEdition.git"
        }
    "2.2.1.0-a"
        {
        $Docker_image = "ecs-software-2.2.1"
        $Docker_imagename = "emccorp/ecs-software-2.2.1"
        $Docker_imagetag = $Branch
        $Git_Branch = "master"
        }
    "3.0.0"
        {
        $Docker_image = "ecs-software-3.0.0"
        $Docker_imagename = "emccorp/ecs-software-3.0.0"
        $Docker_imagetag = "latest"
        $Git_Branch = "master"
        }
    default
        {
        $Docker_image = "ecs-software-3.0.0"
        $Docker_imagename = "emccorp/ecs-software-3.0.0"
        $Docker_imagetag = "latest"
        $Git_Branch = "master"
        }
    }
if ($offline.IsPresent)
    {
    if (!(Test-Path "$Sourcedir\docker\$Docker_image_$Docker_imagetag.tgz"))
        {
        Write-Warning "No offline image "$Sourcedir\docker\$($Docker_image)_$Docker_imagetag.tgz" is present, exit now"
        exit
        }
    }
try
    {
    $yumcachedir = join-path -Path $Sourcedir "$OS\cache\yum" -ErrorAction stop
    }
catch [System.Management.Automation.DriveNotFoundException]
    {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
    }
####Build Machines#
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        $hostname = "$Nodeprefix$Node".ToLower()
        If ($FullClone.IsPresent)
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$Node -Clonepath $Builddir
            }
        else
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node -Clonepath $Builddir
            }
        If ($Node -eq $Start)
            {$Primary = $NodeClone
            }
        if (!($DefaultGateway))
            {
            $DefaultGateway = "$subnet.$Range$Node"
            }
        $Config = Get-VMXConfig -config $NodeClone.config
        $devices = @()
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            $Devices += "sd$([convert]::ToChar(97+$LUN))"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        $NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 | Out-Null
        if ($vmnet)
            {
            $NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue | Out-Null
            $NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Rootpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
        $Scenario = $NodeClone | Set-VMXscenario -Scenarioname $Szenarioname -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB $Memory | Out-Null
        $NodeClone | Set-VMXMainMemory -usefile:$false | Out-Null
        $NodeClone | Set-VMXTemplate -unprotect | Out-Null
        $NodeClone |Connect-VMXcdromImage -connect:$false -Contoller IDE -Port 1:0 | out-null
        Write-Verbose "Starting $Nodeprefix$Node"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
    }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        exit
        }
    }
foreach ($Node in $machinesBuilt)
	{
    [int]$NodeNum = $Node -replace "$Nodeprefix"
    $ClassC = $NodeNum+$IPOffset
	if (!$Custom_IP)
		{
			$ip="$subnet.$Range$ClassC"
		}
	else
		{
		$IP=$Custom_IP
		}
    $NodeClone = get-vmx $Node
    Write-Host -ForegroundColor Magenta " ==>Waiting for VM to boot GuestOS $OS"
    do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 5
        }
    until ($ToolState.state -match "running")
    $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
    if ($centos_ver -eq '7')
		{
		$Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
		}
    $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
	if ($centos_ver -eq "7")
		{
		$Scriptblock = "systemctl disable iptables.service"
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

		$Scriptblock = "systemctl stop iptables.service"
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

	    Write-Verbose "Creating $Guestuser"
		$Scriptblock = "useradd $Guestuser"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
		}
	$NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $netdev -Peerdns -DNS1 $DNS1 -DNS2 $DNS2 -DNSDOMAIN "$BuildDomain.$($custom_domainsuffix)" -Hostname $hostname  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
    $Logfile = "/tmp/labbuildr.log"
    $Scriptblock =  "systemctl start NetworkManager"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
	$Scriptblock =  "chmod 777 $Logfile"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
	write-verbose "Setting Hostname"
	$Scriptblock = "nmcli general hostname $Hostname.$BuildDomain.$custom_domainsuffix;systemctl restart systemd-hostnamed"
	Write-Verbose $Scriptblock
	$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null
    $Scriptblock =  "/etc/init.d/network restart"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $Logfile
    $Scriptblock =  "systemctl stop NetworkManager"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $Logfile
    Write-Host -ForegroundColor Gray " ==>you can now use ssh into $ip with root:Password123! and Monitor $Logfile"
    ##### Prepare

    write-verbose "Disabling IPv&"
    $Scriptblock = "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    $Scriptblock =  "echo '$ip $($hostname) $($hostname).$BuildDomain.$($Custom_DomainSuffix)'  >> /etc/hosts"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    $Scriptblock = "echo 'kernel.pid_max=655360' >> /etc/sysctl.conf;sysctl -w kernel.pid_max=655360"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    if ($EMC_ca.IsPresent)
        {
        $files = Get-ChildItem -Path "$Sourcedir\EMC_ca"
        foreach ($File in $files)
            {
            $NodeClone | copy-VMXfile2guest -Sourcefile $File.FullName -targetfile "/etc/pki/ca-trust/source/anchors/$($File.Name)" -Guestuser $Rootuser -Guestpassword $Guestpassword
            }
        $Scriptblock = "update-ca-trust"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }

	Write-Verbose "setting sudoers"
    $Scriptblock = "echo '$Guestuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #  -logfile $Logfile

    $Scriptblock = "sed -i 's/^.*\bDefaults    requiretty\b.*$/Defaults    !requiretty/' /etc/sudoers"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

	Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

	### generate user ssh keys
    $Scriptblock ="/usr/bin/ssh-keygen -t rsa -N '' -f /home/$Guestuser/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $Scriptblock = "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
    #### Start ssh for pwless  root local login
    $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    $Scriptblock = "cat /home/$Guestuser/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #  -logfile $Logfile

    if ($Hostkey)
            {
            $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
            }
    $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    $Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile
    $Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile
	#### end ssh
	### testing default route
    Write-Host -ForegroundColor Cyan " ==>Testing default Route, make sure that Gateway is reachable ( install and start OpenWRT )
    if failures occur, open a 2nd labbuildr window and run start-vmx OpenWRT "

    $Scriptblock = "DEFAULT_ROUTE=`$(ip route show default | awk '/default/ {print `$3}');ping -c 1 `$DEFAULT_ROUTE"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    ### preparing yum
    $file = "/etc/yum.conf"
    $Property = "cachedir"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\^$Property=/var*.\$Property=/mnt/hgfs/Sources/$OS/\' $file || echo '$Property=/mnt/hgfs/Sources/$OS/yum/`$basearch/`$releasever/' >> $file"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #-logfile $Logfile
    $file = "/etc/yum.conf"
    $Property = "keepcache"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\$Property=0\$Property=1\' $file || echo '$Property=1' >> $file"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #-logfile $Logfile
    $Scriptblock="yum makecache"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    $Scriptblock="yum install yum-plugin-versionlock -y"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $Scriptblock="yum versionlock open-vm-tools"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    if ($update.IsPresent)
        {
        Write-Verbose "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }
    $Scriptblock = "yum install bind-utils -y"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    foreach ($remotehost in ('emccodevmstore001.blob.core.windows.net','registry-1.docker.io','index.docker.io'))
        {
        $Scriptblock = "nslookup $remotehost"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }
    $Scriptblock = "curl https://get.docker.com/ | sh -;systemctl enable docker"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    $Packages = "git tar wget python-setuptools ntp"
    Write-Verbose "Checking for $Packages"
    $Scriptblock = "yum install $Packages -y"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $Scriptblock = "yum install $Packages -y"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
	
	$Scriptblock = "systemctl enable ntpd;systemctl start ntpd"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    Write-Verbose "Checking for offline container on $Sourcedir"
    Write-Verbose "Clonig $Scenario"
    $Scriptblock = "systemctl start docker.service"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    $Scriptblock = "/usr/bin/easy_install ecscli"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
if (!(Test-Path "$Sourcedir\docker\$($Docker_image)_$Docker_imagetag.tgz") -and !($offline.IsPresent))
    {
    New-Item -ItemType Directory "$Sourcedir\docker" -ErrorAction SilentlyContinue | Out-Null
    $Scriptblock = "docker pull $($Docker_imagename):$Docker_imagetag"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    $Scriptblock = "docker save $($Docker_imagename):$Docker_imagetag | gzip -c >  /mnt/hgfs/Sources/docker/$($Docker_image)_$Docker_imagetag.tgz"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    }
else
    {
    if (!(Test-Path "$Sourcedir\docker\$($Docker_image)_$Docker_imagetag.tgz"))
        {
        Write-Warning "no docker Image available, exiting now ..."
        exit
        }
    [switch]$offline_available = $true
    }
    $Scriptblock = "git clone -b $Git_Branch --single-branch $repo"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    Write-Host -ForegroundColor Magenta " ==>Installing ECS Singlenode, this may take a while ..."
    if ($pausebeforescript.ispresent)
        {
        pause
        }
    if ($Branch -ge "2.2.0.1")
        {
        Write-Host -ForegroundColor white " ==>install ecs with loading docker image"
        $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks $($devices -join " ") --ethadapter eno16777984 --hostname $hostname --imagename $Docker_imagename --imagetag $Docker_imagetag --load-image /mnt/hgfs/Sources/docker/$($Docker_image)_$Docker_imagetag.tgz"# &> /tmp/ecsinst_step1.log"
        }
    else
        {
        $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks $($devices -join " ") --ethadapter eno16777984 --hostname $hostname"#  &> /tmp/ecsinst_step1.log"
        }
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile
    Write-Host -ForegroundColor Magenta " ==>Setting automatic startup of docker and ecs container"
    $Scriptlets = (
    "systemctl enable docker.service",
    #"echo 'docker start ecsstandalone' `>>/etc/rc.local",
	"cat > /etc/systemd/system/docker-ecsstandalone.service <<EOF
[Unit]`
Description=EMC ECS Standalone Container`
Requires=docker.service`
After=docker.service`
[Service]`
Restart=always`
ExecStart=/usr/bin/docker start -a ecsstandalone`
ExecStop=/usr/bin/docker stop -t 2 ecsstandalone`
[Install]`
WantedBy=default.target`
",
"systemctl daemon-reload",
"systemctl enable docker-ecsstandalone",
"systemctl start docker-ecsstandalone"
)
    #'chmod +x /etc/rc.d/rc.local')
    #>
    foreach ($Scriptblock in $Scriptlets)
        {
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
        }
}
if ($uiconfig.ispresent)
    {
    Write-Warning "Please wait up to 5 Minutes and Connect to https://$($ip):443
Use root:ChangeMe for Login
"
    }
else
	{
Write-Host -ForegroundColor White "Starting ECS Install Step 2 for creation of Datacenters and Containers.
This might take up to 45 Minutes
Approx. 2000 Objects are to be created
you may chek the opject count with your bowser at http://$($IP):9101"
# $Logfile =  "/tmp/ecsinst_Step2.log"
#$Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$($BuildDomain)ns1 --ObjectVArray=$($BuildDomain)OVA1 --ObjectVPool=$($BuildDomain)OVP1 --UserName=$Guestuser --DataStoreName=$($BuildDomain)ds1 --VDCName=vdc1 --MethodName= &> /tmp/ecsinst_step2.log"
# curl --insecure https://192.168.2.211:443

Write-Host -ForegroundColor White "waiting for Webserver to accept logins"
$Scriptblock = "curl -i -k https://$($ip):4443/login -u root:ChangeMe"
Write-verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 60
if ($AdjustTimeouts.isPresent)
    {
    Write-Host -ForegroundColor Gray " ==>Adjusting Timeouts"
    $Scriptblock = "/usr/bin/sudo -s sed -i -e 's\30, 60, InsertVDC\300, 300, InsertVDC\g' /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py"
    Write-verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile   # -Confirm:$false -SleepSec 60
    }
<#
if ($Branch -eq "feature-ecs-2.2")
    {
    $Methods = ('UploadLicense','CreateObjectVarray','InsertVDC','CreateObjectVpool','CreateNamespace')
    }
else
    {
    #>
$Methods = ('UploadLicense','CreateObjectVarray','CreateDataStore','InsertVDC','CreateObjectVpool','CreateNamespace')
$Namespace_Name = "ns1"
$Pool_Name = "Pool_$Node"
$Replicaton_Group_Name = "RG_1"
$Datastore_Name  = "DS1"
$VDC_NAME = "VDC_$Node"
foreach ( $Method in $Methods )
    {
    Write-Host -ForegroundColor Gray " ==>running Method $Method, monitor tail -f /var/log/vipr/emcvipr-object/ssm.log"
    $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method"
    Write-verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile
    }
$Method = 'CreateUser'
Write-Host -ForegroundColor Gray " ==>running Method $Method"
$Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method;exit 0"
Write-verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile
if ("mosaicme" -in $PrepareBuckets)
	{
	$Method = 'CreateUser'
	Write-Host -ForegroundColor Gray " ==>running Method $Method"
	$Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=mosaicme --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method;exit 0"
	Write-verbose $Scriptblock
	$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile
	}
$Method = 'CreateSecretKey'
Write-Host -ForegroundColor Gray " ==>running Method $Method"
$Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method"
Write-verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile $Logfile
}
$StopWatch.Stop()
Write-host -ForegroundColor White "ECS Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White "Success !? Browse to https://$($IP):443 and login with root/ChangeMe"