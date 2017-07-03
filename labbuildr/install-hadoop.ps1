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
[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('Centos7_3_1611','Centos7_1_1511','Centos7_1_1503')]
	[string]$centos_ver = 'Centos7_3_1611',


[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$SCSI_DISK_COUNT = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = $labdefaults.sourcedir,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = $labdefaults.Masterpath,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = $labdefaults.mysubnet,
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = $labdefaults.BuildDomain,
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = $labdefaults.vmnet,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet('hadoop-2.7.0','hadoop-2.7.1','hadoop-2.7.2','hadoop-2.7.3','hadoop-2.8.0')]$release="hadoop-2.8.0",
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update,
     $Hostkey = $labdefaults.HostKey,
     $Gateway = $labdefaults.Gateway,
     $DefaultGateway = $labdefaults.Defaultgateway,
     $DNS1 = $labdefaults.DNS1,
     $DNS2 = $labdefaults.DNS2,
<#
    Size
    'XS'  = 1vCPU, 512MB
    'S'   = 1vCPU, 768MB
    'M'   = 1vCPU, 1024MB
    'L'   = 2vCPU, 2048MB
    'XL'  = 2vCPU, 4096MB 
    'TXL' = 4vCPU, 6144MB
    'XXL' = 4vCPU, 8192MB
  #>
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
$ip_startrange = 230

)
#requires -version 3.0
#requires -module vmxtoolkit
$Scenarioname = "Hadoop"
$Guestuser = $Scenarioname.ToLower()
$Nodeprefix = "$($Scenarioname)Node"

###
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "Scripts"
If ($Defaults.IsPresent)
    { deny-labdefaults
}

if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}


[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
[uint64]$Disksize = 100GB

###

$Node_requires = "tar wget java-1.7.0-openjdk git vim"
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"


[uint64]$Disksize = 100GB
$scsi = 0


###### checking master Present
try
    {
    $MasterVMX = test-labmaster -Masterpath $MasterPath -Master $centos_ver -Confirm:$Confirm -erroraction stop
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

if (!(Test-path "$Sourcedir\$Scenarioname"))
    {
	New-Item -ItemType Directory "$Sourcedir\$Scenarioname" -Force | Out-Null
	}

if (!(Test-Path "$Sourcedir\$Scenarioname\$release.tar.gz"))
    { 
    write-verbose "Downloading $release"
    try
		{
		$receive = Receive-LABBitsFile -DownLoadUrl "http://apache.claz.org/hadoop/common/$release/$release.tar.gz" -destination "$Sourcedir\$Scenarioname\$release.tar.gz"
		}
	catch
		{
		exit
		}
	}
####Build Machines#
$machinesBuilt = @()

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
    $Lab_VMX = ""
	$Lab_VMX = New-LabVMX -CentOS -CentOS_ver $centos_ver -Size $Size -SCSI_DISK_COUNT $SCSI_DISK_COUNT -SCSI_DISK_SIZE $Disksize -VMXname $Nodeprefix$Node -SCSI_Controller $SCSI_Controller -vtbit:$vtbit -start
	if ($Lab_VMX)
		{
		$temp_object = New-Object System.Object
		$temp_object | Add-Member -type NoteProperty -name Name -Value $Nodeprefix$Node
		$temp_object | Add-Member -type NoteProperty -name Number -Value $Node
		$machinesBuilt += $temp_object
		}       
    else
		{
		Write-Warning "Machine $Nodeprefix$Node already exists"
		}
			
	}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-verbose "Now Pausing"
    pause
    }


foreach ($Node in $machinesBuilt)
    {
		$ip_byte = ($ip_startrange+$Node.Number)
		$ip="$subnet.$ip_byte"
        $Nodeclone = Get-VMX $Node.Name
        if ($Node.number -eq 1)
            {
            $Masterip = $ip    
            }
		Write-Verbose "Configuring Node $($Node.Number) $($Node.Name) with $IP"
        $Hostname = $Nodeclone.vmxname.ToLower()
		$Nodeclone | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Packages $Node_requires -Host_Name $Hostname -DNS1 $DNS1 -DNS2 $DNS2 -VMXName $Nodeclone.vmxname

	write-verbose "disabling kenel oops"
	$Scriptblock =  "echo 'kernel.panic_on_oops=0' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    write-verbose "Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile -Confirm:$false -nowait | Out-Null




    Write-Verbose "Creating $Guestuser"
    $Scriptblock = "useradd $Guestuser"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null


    $Packages = "tar wget java-1.7.0-openjdk"
    Write-Verbose "Checking for $Packages"
    $Scriptblock = "yum install -y $Packages"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

#### Start ssh for pwless local login
    
    $Scriptblock = "/usr/bin/tar xzfv /mnt/hgfs/Sources/$Scenarioname/$release.tar.gz -C /home/$Guestuser; ls /home/$Guestuser/$release"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile /home/$Guestuser/tar.log | Out-Null
       
    $HADOOP_HOME = "/home/hadoop/$release"
    Write-Verbose "Setting Environment" 
    $Scriptblock = "echo 'export JAVA_HOME=/usr/lib/jvm/jre`nexport HADOOP_HOME=/home/hadoop/$release`nexport HADOOP_INSTALL=`$HADOOP_HOME`nexport HADOOP_MAPRED_HOME=`$HADOOP_HOME`nexport HADOOP_COMMON_HOME=`$HADOOP_HOME`nexport HADOOP_HDFS_HOME=`$HADOOP_HOME`nexport HADOOP_YARN_HOME=`$HADOOP_HOME`nexport HADOOP_COMMON_LIB_NATIVE_DIR=`$HADOOP_HOME/lib/native`nexport PATH=`$PATH:`$HADOOP_HOME/sbin:`$HADOOP_HOME/bin`nexport JAVA_LIBRARY_PATH=`$HADOOP_HOME/lib/native:`$JAVA_LIBRARY_PATH' >> /home/$Guestuser/.bashrc"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    $XMLfile = "$HADOOP_HOME/etc/hadoop/core-site.xml"
    Write-Verbose "Configuring $XMLfile"
    $Scriptblock = "sed  '\|<configuration>|a <property>\n  <name>fs.default.name</name>\n    <value>hdfs://$($ip):9000</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null


    $XMLfile = "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
    Write-Verbose "Configuring $XMLfile"
    $Scriptblock = "sed  '\|</configuration>|i<property>\n <name>dfs.replication</name>\n <value>1</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null


    $XMLfile = "$HADOOP_HOME/etc/hadoop/yarn-site.xml"
    Write-Verbose "Editing $XMLfile"
    $Scriptblock = "sed  '\|</configuration>|i<property>\n    <name>yarn.nodemanager.aux-services</name>\n    <value>mapreduce_shuffle</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    
    $XMLfile = "$HADOOP_HOME/etc/hadoop/mapred-site.xml"
    Write-Verbose "Editing $XMLfile"
    $Scriptblock = "cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $XMLfile"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock = "sed  '\|</configuration>|i<property>\n  <name>mapreduce.framework.name</name>\n   <value>yarn</value>\n</property>' $XMLfile -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    Write-Verbose "editing $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    $Scriptblock = "echo 'export JAVA_HOME=/usr/lib/jvm/jre' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    <#
    $Scriptblock = "echo 'export HADOOP_OPTS=-Djava.net.preferIPv4Stack=true' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null
    #>

    $Scriptblock = "source /home/$Guestuser/.bashrc;hdfs namenode -format"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock = "source /home/$Guestuser/.bashrc;start-dfs.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock = "source /home/$Guestuser/.bashrc;start-yarn.sh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    Write-Host -ForegroundColor White "  ==>Hadoop Installation finished for $($NodeClone.VMXname)

    Use the Following URLS to connect: 
        ressourcemanager on http://$($ip):8088
        namenode on         http://$($ip):50070"
 }