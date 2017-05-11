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
[CmdletBinding(DefaultParametersetName = "install")]
Param (
    [Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('Centos7_3_1611','Centos7_1_1511','Centos7_1_1503')]
	[string]$centos_ver = 'Centos7_3_1611',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateRange(2,3)][int32]$Nodes=3,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[switch]$rexray,
[ValidateRange(0,3)]
	[int]$SCSI_Controller = 0,
	[ValidateRange(0,5)]
	[int]$SCSI_DISK_COUNT = 0,

<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[int32]$Startnode = 1,
	[int]$ip_startrange = 226,
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
	$Nodeprefix = "mesos",
	[Parameter(Mandatory=$false)]
	$Scriptdir = (join-path (Get-Location) "labbuildr-scripts"),
	[Parameter(Mandatory=$false)]
	$Sourcedir = $Global:labdefaults.Sourcedir,
	[Parameter(Mandatory=$false)]
	$DefaultGateway = $Global:labdefaults.DefaultGateway,
	[Parameter(Mandatory=$false)]
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
	$Host_Name = $VMXName,
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
	[switch]$Defaults,
	[switch]$vtbit = $false
)
#requires -version 3.0
#requires -module vmxtoolkit

$Nodeprefix = "$($Nodeprefix)Node"
$Rexray_script = "curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -"
$DVDCLI_script = "curl -sSL https://dl.bintray.com/emccode/dvdcli/install | sh -"
$Isolator =  "https://github.com/emccode/mesos-module-dvdi/releases/download/v0.4.0/libmesos_dvdi_isolator-0.26.0.so"
$Isolator_file = Split-Path -Leaf $Isolator
$Isolator_script = "wget $Isolator -O /usr/lib/$Isolator_file"
$Scriptdir = $PSScriptRoot
$SIO = Get-LABSIOConfig
$Logfile = "/tmp/labbuildr.log"
$Szenarioname = "Mesos"

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
###
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
$ip_startrange = $ip_startrange-1
[Uint64]$SCSI_DISK_SIZE = 100GB
$SCSI_Controller_Type = "pvscsi"
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Logfile = "/tmp/labbuildr.log"
if (!$DNS2)
    {
    $DNS2 = $DNS1
    }
$OS = "Centos"
switch ($centos_ver)
    {
    "7"
        {
        $netdev = "eno16777984"
        $Required_Master = "$OS$centos_ver Master"
		$Guestuser = "stack"
        }
    default
        {
        $netdev= "eno16777984"
        $Required_Master = "$OS$centos_ver"
		$Guestuser = "labbuildr"
        }
    }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$Epel_Packages = @()
$Epel_Packages += "docker" 



if ($Sourcedir[-1] -eq "\")
	{
	$Sourcedir = $Sourcedir -replace ".$"
	Set-LABSources -Sourcedir $Sourcedir
	}
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword  = "Password123!"


######

[uint64]$Disksize = 100GB
$Node_requires = "git numactl libaio"
If ($rexray)
	{
	$Node_requires = "$Node_requires postgresql"
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
Write-Host -ForegroundColor White "Starting Node Configuration"

    if (!$machinesBuilt)
        {
        Write-Host -ForegroundColor Yellow "no machines have been built. script only runs on new installs of mesos scenrario"
        break
        }


foreach ($Node in $machinesBuilt)
    {
		$ip_byte = ($ip_startrange+$Node.Number)
		$ip="$subnet.$ip_byte"
        $Nodeclone = Get-VMX $Node.Name
		Write-Verbose "Configuring Node $($Node.Number) $($Node.Name) with $IP"
        $Hostname = $Nodeclone.vmxname.ToLower()
		$Nodeclone | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Epel_Packages $Epel_Packages -Host_Name $Hostname -DNS1 $DNS1 -DNS2 $DNS2 -VMXName $Nodeclone.vmxname

	write-verbose "disabling kenel oops"
	$Scriptblock =  "echo 'kernel.panic_on_oops=0' >> /etc/sysctl.conf;sysctl -p"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

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
		$ip_byte = ($ip_startrange+$MesosNode.Number)
		$ip="$subnet.$ip_byte"

        $Scriptblock = "echo 'server.$(Mesos_Node.Number)=$($IP):2888:3888' >> /etc/zookeeper/conf/zoo.cfg"
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
    "mem": 256,
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