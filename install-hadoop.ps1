<#
.Synopsis
   .\install-rdostack.ps1 
.DESCRIPTION
  install-rdostack is  the a vmxtoolkit solutionpack for configuring and deploying centos openstack vm´s
      
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
   https://community.emc.com/blogs/bottk/2015/07/28/labbuildrgoes-hadoop
.EXAMPLE

#>
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\CentOS7 Master',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(1,15)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet('hadoop-2.7.0','hadoop-2.7.1')]$release="hadoop-2.7.1",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "23"
$Start = "1"
$Scenarioname = "Hadoop"
$Guestuser = $Scenarioname.ToLower()
$Nodeprefix = "$($Scenarioname)Node"
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

$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"


$Disksize = "100GB"
$scsi = 0


$MasterVMX = get-vmx -path $MasterPath
if (!$MasterVMX)
    {
    Write-Warning "No Centos Master found.... exiting now"
    exit
    }
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
if (!(Test-path "$Sourcedir\$Scenarioname"))
    {New-Item -ItemType Directory "$Sourcedir\$Scenarioname"}

if (!(Test-Path "$Sourcedir\$Scenarioname\$release.tar.gz"))
    { 
    write-verbose "Downloading $release"
    get-LABHttpFile -SourceURL "http://apache.claz.org/hadoop/common/$release/$release.tar.gz" -TargetFile "$Sourcedir\$Scenarioname\$release.tar.gz"
    }
####Build Machines#
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node))
        {
        write-verbose " Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq $Start)
            {$Primary = $NodeClone
   <#
            If ($IsGateway.IsPresent)
                {
                $DefaultGateway = "$subnet.$Range$Start"
                $DNS1 = $DefaultGateway
                Write-Verbose "Setting $DefaultGateway as Lab Defaultgateway"
                Set-labDefaultGateway -DefaultGateway $DefaultGateway
                Set-labDNS1 -DNS1 $DefaultGateway
                $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType nat -AdapterType vmxnet3          
                }
     #>
            }
        if (!($DefaultGateway))
            {
            $DefaultGateway = "$subnet.$Range$Node"
            }
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Verbose "Tweaking Config"
        Write-Verbose "Creating Disks"
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        write-verbose "Setting NIC0 to HostOnly"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
        if ($vmnet)
            {
            Write-Verbose "Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Scenarioname -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 4096 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        Write-Verbose "Starting $Nodeprefix$Node"
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
        $ip="$subnet.$Range$($Node[-1])"
        $NodeClone = get-vmx $Node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        Write-verbose "Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
<#
        if ($IsGateway.IsPresent -and $NodeClone.vmxname -eq $Primary.clonename )
            {
            $Natdevice = "eno33557248"
            $NodeClone | Set-VMXLinuxNetwork -dhcp -device $Natdevice -rootuser $Rootuser -rootpassword $Guestpassword
            write-verbose "Installing NAT"
            $Scriptblock = "yum -y install dnsmasq"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword

            $Scriptblock = "chkconfig dnsmasq on && systemctl restart dnsmasq.service"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
        
            $Scriptblock = "/sbin/iptables --table nat -A POSTROUTING -o $Natdevice -j MASQUERADE"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
        
            $Scriptblock = "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/98-forward.conf"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
            }
#>

    write-verbose "Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword



    write-verbose "Disabling IPv&"
    $Scriptblock = "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


    write-verbose "Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $($NodeClone.vmxname)"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    
    $Scriptblock =  "echo '$ip $($NodeClone.vmxname) $($NodeClone.vmxname).$BuildDomain.local'  >> /etc/hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "systemctl disable iptables.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    
    $Scriptblock = "systemctl stop iptables.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


    Write-Verbose "Creating $Guestuser"
    $Scriptblock = "useradd $Guestuser"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    if ($update.IsPresent)
        {
        Write-Verbose "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
        }

    $Packages = "tar wget java-1.7.0-openjdk"
    Write-Verbose "Checking for $Packages"
    $Scriptblock = "yum install -y $Packages"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

#### Start ssh for pwless local login
    
        
    $Scriptblock ="/usr/bin/ssh-keygen -t dsa -N '' -f /home/$Guestuser/.ssh/id_dsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    
    $Scriptblock = "cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_ecdsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
    
    $Scriptblock = "{ echo -n '0.0.0.0 '; cat /etc/ssh/ssh_host_ecdsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword


    $Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_ecdsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
#### end ssh

<### aquiring software


    $Scriptblock = "/usr/bin/wget http://apache.claz.org/hadoop/common/$release/$release.tar.gz -P ~"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
### end software#>
    $Scriptblock = "tar xzfv /mnt/hgfs/Sources/$Scenarioname/$release.tar.gz -C /home/$Guestuser/"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword



    $HADOOP_HOME = "/home/hadoop/$release"
    Write-Verbose "Setting Environment"
    $Scriptblock = "echo 'export JAVA_HOME=/usr/lib/jvm/jre`nexport HADOOP_HOME=/home/hadoop/$release`nexport HADOOP_INSTALL=`$HADOOP_HOME`nexport HADOOP_MAPRED_HOME=`$HADOOP_HOME`nexport HADOOP_COMMON_HOME=`$HADOOP_HOME`nexport HADOOP_HDFS_HOME=`$HADOOP_HOME`nexport HADOOP_YARN_HOME=`$HADOOP_HOME`nexport HADOOP_COMMON_LIB_NATIVE_DIR=`$HADOOP_HOME/lib/native`nexport PATH=`$PATH:`$HADOOP_HOME/sbin:`$HADOOP_HOME/bin`nexport JAVA_LIBRARY_PATH=`$HADOOP_HOME/lib/native:`$JAVA_LIBRARY_PATH' >> /home/$Guestuser/.bashrc"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $XMLfile = "$HADOOP_HOME/etc/hadoop/core-site.xml"
    Write-Verbose "Configuring $XMLfile"
    $Scriptblock = "sed  '\|<configuration>|a <property>\n  <name>fs.default.name</name>\n    <value>hdfs://$($ip):9000</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword


    $XMLfile = "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
    Write-Verbose "Configuring $XMLfile"
    $Scriptblock = "sed  '\|</configuration>|i<property>\n <name>dfs.replication</name>\n <value>1</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword


    $XMLfile = "$HADOOP_HOME/etc/hadoop/yarn-site.xml"
    Write-Verbose "Editing $XMLfile"
    $Scriptblock = "sed  '\|</configuration>|i<property>\n    <name>yarn.nodemanager.aux-services</name>\n    <value>mapreduce_shuffle</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    
    $XMLfile = "$HADOOP_HOME/etc/hadoop/mapred-site.xml"
    Write-Verbose "Editing $XMLfile"
    $Scriptblock = "cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $XMLfile"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $Scriptblock = "sed  '\|</configuration>|i<property>\n  <name>mapreduce.framework.name</name>\n   <value>yarn</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    Write-Verbose "editing $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    $Scriptblock = "echo 'export JAVA_HOME=/usr/lib/jvm/jre' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    <#
    $Scriptblock = "echo 'export HADOOP_OPTS=-Djava.net.preferIPv4Stack=true' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
    #>

    $Scriptblock = "source /home/$Guestuser/.bashrc;hdfs namenode -format"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $Scriptblock = "source /home/$Guestuser/.bashrc;start-dfs.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    $Scriptblock = "source /home/$Guestuser/.bashrc;start-yarn.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    Write-Warning "Hadoop Installation finished for $($NodeClone.VMXname)

    Use the Following URLS to connect: 
        ressourcemanager on http://$($ip):8088
        namenode on         http://$($ip):50070"
 }