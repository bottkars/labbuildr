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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-mesos
.EXAMPLE
.\install-centos7_4scaleio.ps1 -Defaults
This will install 3 Centos Nodes CentOSNode1 -CentOSNode3 from the Default CentOS7 Master , in the Default 192.168.2.0 network, IP .221 - .223

#>
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
#[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('4096','8192','12288','16384','20480','30720','51200','65536')]$Memory = "4096",
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
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
#[Parameter(ParameterSetName = "install",Mandatory = $false)]
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$forcedownload,
#[Parameter(ParameterSetName = "install",Mandatory = $false)]
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$SIOGateway
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
If (!$DNS1)
    {
    Write-Warning "DNS Server not Set, exiting now"
    }



[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Rootpassword  = "Password123!"

$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword  = "Password123!"
$Required_Master = "CentOS7 Master"
$OS = ($Required_Master.Split(" "))[0]
###### checking master Present
if (!($MasterVMX = get-vmx $Required_Master))
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


try
    {
    $yumcachedir = join-path -Path $Sourcedir "$OS\cache\yum" -ErrorAction stop
    }
catch [System.Management.Automation.DriveNotFoundException]
    {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
    }


[uint64]$Disksize = 100GB
$Node_requires = "git"
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
    Write-Warning "Searching for ScaleIO SDC Binaries in $Sourcedir\Scaleio, this may take a while"
    $sdc_rpm = Get-ChildItem -Path $Sourcedir -Filter "EMC-ScaleIO-sdc-*el7.x86_64.rpm" -Recurse | Sort-Object -Descending
    If ($sdc_rpm)
        {
        $autoinstall_sdc = $true
        $sdc_rpm = $sdc_rpm[0].FullName
        Write-Verbose "Found sdc rpm $sdc_rpm"
        
        $sdc_rpm = $sdc_rpm -replace "\\","/"
        $linux_source = $Sourcedir -replace "\\","/"
        $sdc_rpm = $sdc_rpm -replace $linux_source
        $sdc_rpm = "/mnt/hgfs/Sources$sdc_rpm"
        }
    else
        {
        Write-Warning "sdc Binaries not found for $OS, skipping autoinstall of RexRay for ScaleIO"
        }
    }
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node))
        {
        write-verbose " Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Verbose "Tweaking Config"
        <#
        Write-Verbose "Creating Disks"
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        #>
        write-verbose "Setting NIC0 to HostOnly"
        $Netadapter = Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
        if ($vmnet)
            {
            Write-Verbose "Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config  | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config   | Out-Null
            }
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
    foreach ($Node in $machinesBuilt)
        {
        [int]$node_num = $Node -replace "$Nodeprefix"
        $ClassC = $node_num+$IPOffset
        $ip="$subnet.$Range$ClassC"
        $NodeClone = get-vmx $Node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        
        If ($DefaultGateway)
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        else
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $ip -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
    
    
            $Logfile = "/tmp/1_prepare.log"

    $Scriptblock =  "systemctl start NetworkManager"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #| ft -AutoSize vmxname,scriptblock #-logfile $Logfile

    $Scriptblock =  "/etc/init.d/network restart"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile

    $Scriptblock =  "systemctl stop NetworkManager"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile


    Write-Host -ForegroundColor Magenta "ssh into $ip with root:Password123! and Monitor $Logfile"
    write-verbose "Disabling IPv&"
    $Scriptblock = "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile 

    $Scriptblock =  "echo '$ip $($NodeClone.vmxname) $($NodeClone.vmxname).$BuildDomain.local'  >> /etc/hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile

 
    $Scriptblock = "systemctl disable iptables.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    
    $Scriptblock = "systemctl stop iptables.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    write-verbose "Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    write-verbose "Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $($NodeClone.vmxname)"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

            
        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword 
    
        if ($Hostkey)
            {
            $Scriptblock = "echo 'ssh-rsa $Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
            }

        $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        Write-Host -ForegroundColor Magenta "Nodenumber : $Node_num"
    ### preparing yum
    $file = "/etc/yum.conf"
    $Property = "cachedir"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\^$Property=/var*.\$Property=/mnt/hgfs/Sources/$OS/\' $file || echo '$Property=/mnt/hgfs/Sources/$OS/yum/`$basearch/`$releasever/' >> $file"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $file = "/etc/yum.conf"
    $Property = "keepcache"
    $Scriptblock = "grep -q '^$Property' $file && sed -i 's\$Property=0\$Property=1\' $file || echo '$Property=1' >> $file"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    Write-Host -ForegroundColor Magenta "Generating Yum Cache on $Sourcedir"
    $Scriptblock="yum makecache"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    Write-Host -ForegroundColor Magenta "INSTALLING VERSIONLOCK"
    $Scriptblock="yum install yum-plugin-versionlock -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    
    Write-Host -ForegroundColor Magenta "locking vmware tools"
    $Scriptblock="yum versionlock open-vm-tools"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $requires = "$Node_requires"
    $Scriptblock = "yum install $requires -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/yum-requires.log



    #### end ssh
    if ($update.IsPresent)
        {
        Write-Host -ForegroundColor Magenta "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }
    
    $Scriptblock = "curl -sSL https://get.docker.com/ | sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/yum-requires.log


    $Scriptblock =  "rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock =  "yum -y install mesos marathon mesosphere-zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "yum -y install mesosphere-zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "echo '$node_num' > /var/lib/zookeeper/myid"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
    if ($rexray.IsPresent)
        {
        if ($autoinstall_sdc)
            {
            Write-Verbose "trying rexray and ScaleIO SDC Install"
            if ($SIO = Get-LABSIOConfig)
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
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

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
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
        $zk = "$Zk$($IP):2181,"
        }
    $ZK = "$($ZK.Substring(0,$ZK.Length-1))/mesos"
    $Scriptblock = "systemctl enable docker"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "systemctl start docker"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "systemctl enable zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "systemctl start zookeeper"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/mesos.log

    $Scriptblock = "echo '$ZK' > /etc/mesos/zk"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
    ### should be calced soon node/2+1
    $Scriptblock = "echo 2 > /etc/mesos-master/quorum"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5


    }
if ($rexray.IsPresent)
    {
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        Write-Verbose "trying rexray Install"
        $Scriptblock = "$Rexray_script;$DVDCLI_script;$Isolator_script"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
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
"       
            $yml | Set-Content -Path $Scriptdir\$scriptname
            convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
            $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/etc/rexray/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword
            $Scriptblock = "systemctl enable rexray;systemctl start rexray"
        }
    }
}

    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "systemctl restart mesos-master"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
        }
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "systemctl restart marathon"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
        }
    foreach ($Node in $machinesBuilt)
        {
        $NodeClone = get-vmx $Node
        $Scriptblock = "echo 'docker,mesos' > /etc/mesos-slave/containerizers;echo '5mins' > /etc/mesos-slave/executor_registration_timeout;systemctl restart mesos-slave"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5
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
        $json | Set-Content -Path $Scriptdir\$scriptname
        convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
        $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword
        $Scriptblock = "sh /root/$Scriptname &> /tmp/$Scriptname.log"


        $Scriptblock = "curl -X POST http://$($ip):8080/v2/apps -d @/root/$scriptname -H 'Content-type: application/json'"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5

#>

    Write-Host -ForegroundColor Magenta "Login to the VM´s with root/Password123! or with Pagent Auth
    go to http://$($ip):5050 for mesos admin
    go to http://$($ip):8080 for marathon admin"
    



    <#
    find the sdc software ( only once )
    install rexray
    curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -

            if ($sdc.IsPresent)
            {
            Write-Verbose "trying SDC Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_IP=$mdm_ip;rpm -Uhv /root/install/EMC-ScaleIO-sdc*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }



rexray:
 storageDrivers:
  - ScaleIO
ScaleIO:
  endpoint: https://192.168.2.193:443/api
  insecure: true
  userName: admin
  password: Password123!
  systemName: ScaleIO@EMCDEBlog
  protectionDomainName: PD_EMCDEBlog
  storagePoolName: PoolEMCDEBlog
[root@mesosnode1 ~]#





#>