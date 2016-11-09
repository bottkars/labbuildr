<#
.Synopsis
   .\install-scaleio.ps1 
.DESCRIPTION
  install-centos7_4scaleio is  the a vmxtoolkit solutionpack for configuring and deploying centos VM´s for ScaleIO Implementation
      
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
   https://github.com/bottkars/labbuildr/wiki/install-mesos.ps1-%5Bwith-rexray%5D
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)]
[switch]$Defaults,
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('7_1_1511','7')]
[string]$centos_ver = "7_1_1511",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('1024','2048','3072','4096','8192','12288','16384','20480','30720','51200','65536')]$Memory = "3072",
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateRange(2,3)][int32]$Nodes=3,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[int32]$Startnode = 1,
[switch]$rexray,

<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile="./defaults.xml"
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "22"
$Start = "1"
$IPOffset = 5
$Szenarioname = "Mesos"
$Nodeprefix = "$($Szenarioname)Node"
$Rexray_script = "curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -"
$DVDCLI_script = "curl -sSL https://dl.bintray.com/emccode/dvdcli/install | sh -"
$Isolator =  "https://github.com/emccode/mesos-module-dvdi/releases/download/v0.4.0/libmesos_dvdi_isolator-0.26.0.so"
$Isolator_file = Split-Path -Leaf $Isolator
$Isolator_script = "wget $Isolator -O /usr/lib/$Isolator_file"
$Scriptdir = $PSScriptRoot
$SIO = Get-LABSIOConfig
$Logfile = "/tmp/labbuildr.log"


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
    $DefaultGateway = $labdefaults.DefaultGateway
    $Gateway = $labdefaults.Gateway
    $DNS1 = $labdefaults.DNS1
    $Hostkey = $labdefaults.HostKey
    }
if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}

If (!$DNS1)
    {
    Write-Warning "DNS Server not Set, exiting now"
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

$OS = "Centos$centos_ver"
switch ($centos_ver)
    {
    "7"
        {
        $netdev = "eno16777984"
        $Required_Master = "$OS Master"
        }
    default
        {
        $netdev= "eno16777984"
        $Required_Master = $OS
        }
    }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

if ($Sourcedir[-1] -eq "\")
	{
	$Sourcedir = $Sourcedir -replace ".$"
	Set-LABSources -Sourcedir $Sourcedir
	}
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Rootpassword  = "Password123!"

$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword  = "Password123!"
###### checking master Present
try
    {
    $MasterVMX = test-labmaster -Masterpath $MasterPath -Master $Required_Master -Confirm:$Confirm -erroraction stop
    }
catch
    {
    Write-Warning "Required Master $Required_Master not found
    please download and extraxt $Required_Master to ./$Required_Master
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
##


try
    {
    $yumcachedir = join-path -Path $Sourcedir "$OS/cache/yum" -ErrorAction stop
    }
catch [System.Management.Automation.DriveNotFoundException]
    {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
    }


[uint64]$Disksize = 100GB
$Node_requires = "git numactl libaio"

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
####Build Machines#


if ($rexray.IsPresent)
    {
    Write-Host -ForegroundColor Gray " ==>Searching for ScaleIO SDC Binaries in"(join-path  $Sourcedir Scaleio)", this may take a while"
    if (!($sdc_rpm = Get-ChildItem -Path $Sourcedir -Filter "EMC-ScaleIO-sdc-*el7.x86_64.rpm" -Recurse | Sort-Object -Descending))
		{
		Receive-LABScaleIO -Destination $Sourcedir -arch linux -unzip  | Out-Null
		$sdc_rpm = Get-ChildItem -Path $Sourcedir -Filter "EMC-ScaleIO-sdc-*el7.x86_64.rpm" -Recurse | Sort-Object -Descending
		}

    If ($sdc_rpm)
        {
        $autoinstall_sdc = $true
        $sdc_rpm = $sdc_rpm[0].FullName
        Write-Host -ForegroundColor Gray "Found sdc rpm $sdc_rpm"
        
        $sdc_rpm = $sdc_rpm -replace "\\","/"
        $linux_source = $Sourcedir -replace "\\","/"
        $sdc_rpm = $sdc_rpm -replace $linux_source
        $sdc_rpm = "/mnt/hgfs/Sources/$sdc_rpm"
		Write-Host "using $sdc_rpm as install path"
        }
    else
        {
        Write-Warning "sdc Binaries not found for $OS, skipping autoinstall of RexRay for ScaleIO"
        }
    }
####Build Machines#
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        write-Host -ForegroundColor Magenta " ==>Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Verbose "Tweaking Config"
        write-verbose "Setting NIC0 to HostOnly"
        Write-Verbose "Configuring NIC 0 for $vmnet"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue| Out-Null
        Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $NodeClone | Set-VMXprocessor -Processorcount 2 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB $Memory | Out-Null
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname CentOS -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        Write-Verbose "Starting $($NodeClone.vmxname)"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
    }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }
    }
    if (!$machinesBuilt)
        {
        Write-Host -ForegroundColor Yellow "no machines have been built. script only runs on new installs of mesos scenrario"
        break
        }
        
        
    $ClassC = 1+$IPOffset
    $Masterip="$subnet.$Range$ClassC"
    foreach ($Node in $machinesBuilt)
        {
        [int]$node_num = $Node -replace "$Nodeprefix"
        $ClassC = $node_num+$IPOffset
        $ip="$subnet.$Range$ClassC"
        $Hostname = $Node.ToLower()
        $NodeClone = get-vmx $Node
		Write-Host -ForegroundColor Magenta " ==>Waiting for $Node to become ready"
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        if ($centos_ver -eq '7')
			{
			$Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
			}
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        
        If ($DefaultGateway)
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.$Custom_DomainSuffix" -Hostname $Hostname  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        else
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $ip -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.$Custom_DomainSuffix" -Hostname $Hostname  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }

		$Scriptblock = "rm /etc/resolv.conf;systemctl restart network"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
		write-verbose "Setting Hostname"
		$Scriptblock = "nmcli general hostname $Hostname.$BuildDomain.$custom_domainsuffix;systemctl restart systemd-hostnamed"
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null
        Write-Host -ForegroundColor Cyan " ==>Testing default Route, make sure that Gateway is reachable ( install and start OpenWRT )
        if failures occur, open a 2nd labbuildr windows and run start-vmx OpenWRT "

        $Scriptblock = "DEFAULT_ROUTE=`$(ip route show default | awk '/default/ {print `$3}');ping -c 1 `$DEFAULT_ROUTE"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

<#

    $Scriptblock =  "systemctl start NetworkManager"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock =  "/etc/init.d/network restart"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null 

    $Scriptblock =  "systemctl stop NetworkManager"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null 
#>
	write-verbose "disabling kenel oops"
	$Scriptblock =  "echo 'kernel.panic_on_oops=0' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null


    write-verbose "Disabling IPv6"
    $Scriptblock = "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

    $Scriptblock =  "echo '$ip $($Hostname) $($Hostname).$BuildDomain.$Custom_DomainSuffix'  >> /etc/hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null #-logfile $Logfile


    write-verbose "Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile -Confirm:$false -nowait | Out-Null

	if ($centos_ver -eq "7")
		{
		$Scriptblock = "systemctl disable iptables.service"
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    
		$Scriptblock = "systemctl stop iptables.service"
		Write-Verbose $Scriptblock
		$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }


            
        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
    
        if ($Hostkey)
            {
            $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
            }
			
        $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
	write-verbose "Setting Hostname"
    $Scriptblock = "nmcli general hostname $Hostname.$BuildDomain.$custom_domainsuffix;systemctl restart systemd-hostnamed"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null
	

    $file = "/etc/yum.conf"
    $Property = "cachedir"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\^$Property=/var*.\$Property=/mnt/hgfs/Sources/$OS/\' $file || echo '$Property=/mnt/hgfs/Sources/$OS/yum/`$basearch/`$releasever/' >> $file"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $file = "/etc/yum.conf"
    $Property = "keepcache"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\$Property=0\$Property=1\' $file || echo '$Property=1' >> $file"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock="yum makecache"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

    $Scriptblock="yum install yum-plugin-versionlock -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
    
    $Scriptblock="yum versionlock open-vm-tools"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

    $requires = "$Node_requires"
    $Scriptblock = "yum install $requires -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null



    #### end ssh
    if ($update.IsPresent)
        {
        Write-Host -ForegroundColor Magenta "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null
        }
    
    $Scriptblock = "curl -sSL https://get.docker.com/ | sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null


    $Scriptblock =  "rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock =  "yum -y install mesos marathon mesosphere-zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

    $Scriptblock = "yum -y install mesosphere-zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock = "echo '$node_num' > /var/lib/zookeeper/myid"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
    if ($rexray.IsPresent)
        {
        if ($autoinstall_sdc)
            {
            Write-Verbose "trying rexray and ScaleIO SDC Install"
            if ($SIO)
                {
                Write-Host -ForegroundColor Magenta "Found ScaleIO Config, using Values to autoconfigure RexRay and SDC"
                $Scriptblock = "export MDM_IP=$($SIO.mdm_ipa),$($SIO.mdm_ipb);yum install $sdc_rpm -y"
                }
            else
                {
                Write-Host -ForegroundColor Magenta "No ScaleIO Config found, installing SDC without mdm connection"
                $Scriptblock = "yum install $sdc_rpm -y"
                Write-Verbose $Scriptblock
                }
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait | Out-Null

            }
        else
            {
            Write-Warning "SDC Binaries not found, plese install manually"
            }
        }
    
    
    $ZK = "zk://"
    foreach ($mesos_Node in $machinesBuilt)
        {
        [int]$Mesos_Node_num = $mesos_Node -replace "$Nodeprefix"
        $ClassC = $Mesos_Node_num+$IPOffset
        $ip="$subnet.$Range$ClassC"

        $Scriptblock = "echo 'server.$Mesos_Node_num=$($IP):2888:3888' >> /etc/zookeeper/conf/zoo.cfg"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
        $zk = "$Zk$($IP):2181,"
        }
    $ZK = "$($ZK.Substring(0,$ZK.Length-1))/mesos"
    $Scriptblock = "systemctl enable docker"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock = "systemctl start docker"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock = "systemctl enable zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock = "systemctl start zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  | Out-Null

    $Scriptblock = "echo '$ZK' > /etc/mesos/zk"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    ### should be calced soon node/2+1
    $Scriptblock = "echo 2 > /etc/mesos-master/quorum"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

	if ($Update.IsPresent)
		{
        $Scriptblock = "shutdown -r now"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -nowait | Out-Null
		}
    }
if ($rexray.IsPresent)
    {
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        Write-Host -ForegroundColor Magenta " ==>trying rexray Install on $Node"
        $Scriptblock = "$Rexray_script" #;$DVDCLI_script;$Isolator_script"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        <#
        $Scriptblock = "echo 'com_emccode_mesos_DockerVolumeDriverIsolator' > /etc/mesos-slave/isolation;echo 'file:///usr/lib/dvdi-mod.json' > /etc/mesos-slave/modules"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
        
       
        $Scriptname = "dvdi-mod.json" 
        $dvdi_mod_json="{
   `"libraries`": [
     {
       `"file`": `"/usr/lib/$Isolator_file`",
       `"modules`": [
         {
           `"name`": `"com_emccode_mesos_DockerVolumeDriverIsolator`"
         }
       ]
     }
   ]
 }
"
            $dvdi_mod_json | Set-Content -Path "$Scriptdir\$Scriptname" 
            convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
            $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/usr/lib/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword


volume:
 mount:
  preempt: true
 unmount:
  ignoreUsedCount: true
 #>

        if ($SIO = Get-LABSIOConfig)
            {
            $scriptname = "config.yml"
            $yml = "rexray:
 loglevel: error
 storageDrivers:
  - ScaleIO
ScaleIO:
  endpoint: https://$($SIO.gateway_ip):443/api
  insecure: true
  userName: admin
  password: Password123!
  systemName: $($SIO.system_name)
  protectionDomainName: $($SIO.pd_name)
  storagePoolName: $($SIO.pool_name)
libstorage:
  integration:
    volume:
      operations:
        mount:
          preempt: true
        unmount:
          ignoreUsedCount: true

"       
			$yml_config_file = Join-Path $Scriptdir $Scriptname
            $yml | Set-Content -Path $yml_config_file
            convert-VMXdos2unix -Sourcefile $yml_config_file -Verbose
            Write-Host -ForegroundColor Magenta " ==>Injecting RexRay Config from config.yml"
            $NodeClone | copy-VMXfile2guest -Sourcefile $yml_config_file -targetfile "/etc/rexray/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            $Scriptblock = "rexray service start;systemctl enable rexray"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }
    }
}

    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "systemctl restart mesos-master"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "systemctl restart marathon"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "echo 'docker,mesos' > /etc/mesos-slave/containerizers;echo '5mins' > /etc/mesos-slave/executor_registration_timeout;systemctl restart mesos-slave"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }




$scriptname = "labbuildr-demo.json"
$json = '{
  "id": "labbuildr-demo",
  "cmd": "python3 -m http.server 8080",
  "cpus": 0.5,
  "mem": 32.0,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "python:3",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 8080, "hostPort": 0 }
      ]
    }
  }
}
'       
        $Script_file = Join-Path $Scriptdir $scriptname
		$json | Set-Content -Path $Script_file
        convert-VMXdos2unix -Sourcefile $Script_file -Verbose
        $NodeClone | copy-VMXfile2guest -Sourcefile $Script_file -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        $Scriptblock = "sh /root/$Scriptname &> $Logfile"
        $Scriptblock = "curl -X POST http://$($Masterip):8080/v2/apps -d @/root/$scriptname -H 'Content-type: application/json'"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait | Out-Null

#>

if ($rexray.IsPresent -and $SIO)
    {
    Write-Host -ForegroundColor Magenta "We are now trying to start a Postgres Container with Rex-Ray/ScaleIO  an Marathon" 
    $scriptname = "postgres-demo.json"
$json = '
{
    "id": "postgres-demo",
    "container": {
        "docker": {
            "image": "postgres",
            "network": "BRIDGE",
            "portMappings": [{
                "containerPort": 5432,
                "hostPort": 0,
                "protocol": "tcp"
            }],
            "parameters": [
                {"key": "volume-driver","value": "rexray" },
                {"key": "volume","value": "pg-data:/var/lib/postgresql/data" },
                {"key": "env","value": "PGDATA:/var/lib/postgresql/data/pg-data" },
                {"key": "env","value": "POSTGRES_PASSWORD=Password123!" }]
        }
    },
    "args": ["postgres"],
    "cpus": 0.8,
    "mem": 32.0,
    "instances": 1
}
'       
        $Script_file = Join-Path $Scriptdir $scriptname
		$json | Set-Content -Path $Script_file
        convert-VMXdos2unix -Sourcefile $Script_file -Verbose
        $NodeClone | copy-VMXfile2guest -Sourcefile $Script_file -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        $Scriptblock = "sh /root/$Scriptname &> $Logfile"
        $Scriptblock = "curl -X POST http://$($Masterip):8080/v2/apps -d @/root/$scriptname -H 'Content-type: application/json'"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait| Out-Null
}
$StopWatch.Stop()
Write-host -ForegroundColor White "Mesos Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor Magenta "Login to the VM´s with root/Password123! or with Pagent Auth
go to http://$($Masterip):5050 for mesos admin
go to http://$($Masterip):8080 for marathon admin"
    




#>