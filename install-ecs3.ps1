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
   http://labbuildr.readthedocs.io/en/latest/Solutionpacks//install-ecs.ps1
.EXAMPLE
#>


[CmdletBinding(DefaultParametersetName = "install")]
Param (
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [ValidateSet('Centos7_3_1611')]
    [string]$centos_ver = 'Centos7_3_1611',
    [Parameter(ParameterSetName = "defaults", Mandatory = $false)]
    [Parameter(ParameterSetName = "install", Mandatory = $false)][switch]$Update,
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [ValidateRange(1, 1)][int32]$Nodes = 1,
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [switch]$rexray,
    [ValidateRange(0, 3)]
    [int]$SCSI_Controller = 0,
    [ValidateRange(3, 3)] # set hard for ECS 3 installer
    [int]$SCSI_DISK_COUNT = 3,
    <# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [int32]$Startnode = 1,
    [int]$ip_startrange = 244,
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
    [ValidateSet('XS', 'S', 'M', 'L', 'XL', 'TXL', 'XXL')]$Size = "XL",
    $Nodeprefix = "ecsnode",
    [Parameter(Mandatory = $false)]
    $Scriptdir = (join-path (Get-Location) "labbuildr-scripts"),
    [Parameter(Mandatory = $false)]
    $Sourcedir = $Global:labdefaults.Sourcedir,
    [Parameter(Mandatory = $false)]
    $DefaultGateway = $Global:labdefaults.DefaultGateway,
    [Parameter(Mandatory = $false)]
    $guestpassword = "Password123!",
    $Rootuser = 'root',
    $Hostkey = $Global:labdefaults.HostKey,
    $Default_Guestuser = 'labbuildr',
    [Parameter(Mandatory = $false)]
    $Subnet = $Global:labdefaults.MySubnet,
    [Parameter(Mandatory = $false)]
    $DNS1 = $Global:labdefaults.DNS1,
    [Parameter(Mandatory = $false)]
    $DNS2 = $Global:labdefaults.DNS2,
    [switch]$Defaults,
    [switch]$vtbit,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][switch]$FullClone,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('8192', '12288', '16384', '20480', '30720', '51200', '65536')]$Memory = "16384",
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [ValidateSet('3.0.0.1')]$Branch = '3.0.0.1',
    [Parameter(ParameterSetName = "install", Mandatory = $false)][switch]$EMC_ca,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][switch]$ui_config,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet(150GB, 500GB, 520GB)][uint64]$Disksize = 150GB,
    [Parameter(ParameterSetName = "install", Mandatory = $False)]
    [ValidateLength(1, 15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
    [Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('vmnet2', 'vmnet3', 'vmnet4', 'vmnet5', 'vmnet6', 'vmnet7', 'vmnet9', 'vmnet10', 'vmnet11', 'vmnet12', 'vmnet13', 'vmnet14', 'vmnet15', 'vmnet16', 'vmnet17', 'vmnet18', 'vmnet19')]$VMnet = $labdefaults.vmnet,
    [switch]$offline,
    $Custom_IP
) 
#requires -version 3.0
#requires -module vmxtoolkit
$latest_ecs = "3.0.0.1"
$Logfile = "/tmp/labbuildr.log"
$Szenarioname = "ECS"
$Builddir = $PSScriptRoot
$Masterpath = $Builddir
If ($Defaults.IsPresent) {
    deny-labdefaults
}
try {
    Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null
}
catch
[System.Management.Automation.DriveNotFoundException] {
    Write-Warning "Make sure to have your Source Stick connected"
    exit
}
catch [System.Management.Automation.ItemNotFoundException] {
    write-warning "no sources directory found at $Sourcedir, please create or select different Directory"
    return
}
try {
    $Masterpath = $LabDefaults.Masterpath
}
catch {
    $Masterpath = $Builddir
}
$Hostkey = $labdefaults.HostKey

if ($LabDefaults.custom_domainsuffix) {
    $custom_domainsuffix = $LabDefaults.custom_domainsuffix
}
else {
    $custom_domainsuffix = "local"
}
if (!$Masterpath) {$Masterpath = $Builddir}
If (!$DNS1 -and !$DNS2) {
    Write-Warning "DNS Server not Set, exiting now"
}
If (!$DNS2 -and $DNS1) {
    $DNS2 = $DNS1
}
If (!$DNS1 -and $DNS2) {
    $DNS1 = $DNS2
}
$DNS_Domain = "$BuildDomain.$custom_domainsuffix"
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Rootpassword = "Password123!"
$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword = "Password123!"
$Node_requires = @()
$Node_requires = ('git','numactl','libaio','vim','docker-engine')

$repo = "https://github.com/EMCECS/ECS-CommunityEdition.git"
switch ($Branch) {
    "3.0.0.1" {
        $Docker_image = "ecs-software-3.0.0"
        $Docker_imagename = "emccorp/ecs-software-3.0.0"
        $Docker_imagetag = "3.0.0.1"
        $Git_Branch = "master"
    }
    default {
        $Docker_image = "ecs-software-3.0.0"
        $Docker_imagename = "emccorp/ecs-software-3.0.0"
        $Docker_imagetag = "latest"
        $Git_Branch = "master"
    }
}
$Docker_basepath = Join-Path $Sourcedir "docker"
$Docker_Image_file = Join-Path $Docker_basepath "$($Docker_image)_$Docker_imagetag.tgz"
Write-Verbose "Docker Imagefile $Docker_Image_file"
if (!(test-path $Docker_basepath)) {
    New-Item -ItemType Directory $Docker_basepath -Force -Confirm:$false | Out-Null
}
if ($offline.IsPresent) {
    if (!(Test-Path $Docker_Image_file)) {
        Write-Warning "No offline image $Docker_Image_file present, exit now"
        exit
    }
}
try {
    $OS_Sourcedir = Join-Path $Sourcedir $OS
    $OS_CahcheDir = Join-Path $OS_Sourcedir "cache"
    $yumcachedir = Join-path -Path $OS_CahcheDir "yum"  -ErrorAction stop
}
catch [System.Management.Automation.DriveNotFoundException] {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
}
Write-Verbose "yumcachedir $yumcachedir"
####Build Machines#
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($Node in $Startnode..(($Startnode - 1) + $Nodes)) {
    Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
    $Lab_VMX = ""
    $Lab_VMX = New-LabVMX -CentOS -CentOS_ver $centos_ver -Size $Size -SCSI_DISK_COUNT $SCSI_DISK_COUNT -SCSI_DISK_SIZE $Disksize -VMXname $Nodeprefix$Node -SCSI_Controller $SCSI_Controller -vtbit:$vtbit -memory $Memory -start
    if ($Lab_VMX) {
        $temp_object = New-Object System.Object
        $temp_object | Add-Member -type NoteProperty -name Name -Value $Nodeprefix$Node
        $temp_object | Add-Member -type NoteProperty -name Number -Value $Node
        $machinesBuilt += $temp_object
    }       
    else {
        Write-Warning "Machine $Nodeprefix$Node already exists"
    }
			
}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent) {
    Write-verbose "Now Pausing"
    pause
}

Write-Host -ForegroundColor White "Starting Node Configuration"

if (!$machinesBuilt) {
    Write-Host -ForegroundColor Yellow "no machines have been built. script only runs on new installs of mesos scenrario"
    break
}

# $Node_requires = $Node_requires -join ","
foreach ($Node in $machinesBuilt) {
    if (!$Custom_IP) {
        $ip_byte = ($ip_startrange + $Node.Number) 
        $ip = "$subnet.$ip_byte"
    }
    else {
        $IP = $Custom_IP
    }
    $ip_byte = ($ip_startrange + $Node.Number)
		
    $Nodeclone = Get-VMX $Node.Name

    Write-Verbose "Configuring Node $($Node.Number) $($Node.Name) with $IP"
    $Hostname = $Nodeclone.vmxname.ToLower()
    $Nodeclone | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Epel_Packages docker -Additional_Packages $Node_requires -Host_Name $Hostname -DNS1 $DNS1 -DNS2 $DNS2 -DNS_DOMAIN_NAME $DNS_Domain  -VMXName $Nodeclone.vmxname
#    $Nodeclone | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Packages $Node_requires -Additional_Epel_Packages $Epel_Packages -Host_Name $Hostname -DNS1 $DNS1 -DNS2 $DNS2 -VMXName $Nodeclone.vmxname
    ##### Prepare
    if ($EMC_ca.IsPresent) {
        $files = Get-ChildItem -Path "$Sourcedir\EMC_ca"
        foreach ($File in $files) {
            $NodeClone | copy-VMXfile2guest -Sourcefile $File.FullName -targetfile "/etc/pki/ca-trust/source/anchors/$($File.Name)" -Guestuser $Rootuser -Guestpassword $Guestpassword
        }
        $Scriptblock = "update-ca-trust"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    }

    $Scriptblock = 'rm -f /etc/localtime;ln -s /usr/share/zoneinfo/UTC /etc/localtime'
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile


 #   $Scriptblock = "/usr/bin/easy_install ecscli"
 #   Write-Verbose $Scriptblock
 #   $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
####### docker path´s
    $Docker_basepath = Join-Path $Sourcedir docker
    $Docker_Image_file = Join-Path $Docker_basepath "$($Docker_image)_$Docker_imagetag.tgz"
#### docker workaround save unitil further notice
    if (Test-Path $Docker_Image_file)
        {
        $Scriptblock = "gunzip -c /mnt/hgfs/Sources/docker/$($Docker_image)_$Docker_imagetag.tgz| docker load;docker tag $($Docker_imagename):$Docker_imagetag $($Docker_imagename):latest"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }
    else {
        if (!(Test-Path $Docker_Image_file) -and !($offline.IsPresent)) {
            New-Item -ItemType Directory $Docker_basepath -ErrorAction SilentlyContinue | Out-Null
            $Scriptblock = "docker pull $($Docker_imagename):$Docker_imagetag"
            Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
            $Scriptblock = "docker save $($Docker_imagename):$Docker_imagetag | gzip -c >  /mnt/hgfs/Sources/docker/$($Docker_image)_$Docker_imagetag.tgz;docker tag $($Docker_imagename):$Docker_imagetag $($Docker_imagename):latest"
            Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
        }
        else {
            if (!(Test-Path $Docker_Image_file)) {
                Write-Warning "no docker Image available, exiting now ..."
                exit
                }
            [switch]$offline_available = $true
            }
        
        }
    

### enc docker save workaround
$Git_Branch = 'develop'
$Scriptblock = "git clone -b $Git_Branch --single-branch $repo"
Write-Verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

$my_yaml = "# deploy.yml for labbuildr

licensing:
  license_accepted: true
facts:
  install_node: $ip
  management_clients:
    - 0.0.0.0/0
  ssh_defaults:
    ssh_username: $Default_Guestuser
    ssh_password: $guestpassword
  node_defaults:
    dns_domain: $dns_domain  
    dns_servers:
      - $DNS1
    ntp_servers:
      - 0.de.pool.ntp.org
    entropy_source: /dev/urandom
    autonaming: moons
    ecs_root_user: root
    ecs_root_pass: ChangeMe
  storage_pool_defaults:
    is_cold_storage_enabled: false
    is_protected: false
    description: Default storage pool description
    ecs_block_devices:
      - /dev/sdb
      - /dev/sdc
      - /dev/sdd
  storage_pools:
    - name: sp1
      members:
        - $IP
      options:
        is_protected: false
        is_cold_storage_enabled: false
        description: My First SP
        ecs_block_devices:
          - /dev/sdb
          - /dev/sdc
          - /dev/sdd
  virtual_data_center_defaults:
    description: $Builddomain virtual data center 
  virtual_data_centers:
    - name: vdc1
      members:
        - sp1
      options:
        description: My First VDC
  replication_group_defaults:
    description: Default replication group description
    enable_rebalancing: true
    allow_all_namespaces: true
    is_full_rep: false
  replication_groups:
    - name: rg1
      members:
        - vdc1
      options:
        description: My First RG
        enable_rebalancing: true
        allow_all_namespaces: true
        is_full_rep: false
  namespace_defaults:
    is_stale_allowed: false
    is_compliance_enabled: false
  namespaces:
    - name: ns1
      replication_group: rg1
      administrators:
        - root
      options:
        is_stale_allowed: false
        is_compliance_enabled: false
"

$File = "$Sourcedir\deploy.yml"
$my_yaml | Set-Content $file
convert-VMXdos2unix -Sourcefile $file -Verbose
$File = Get-ChildItem $File
$NodeClone | copy-VMXfile2guest -Sourcefile $File.FullName -targetfile "/root/$($File.Name)" -Guestuser $Rootuser -Guestpassword $Guestpassword |Out-Null

Write-Host -ForegroundColor White "Starting ECS Preparation, this may take a while"
Write-Host -ForegroundColor White "you may follow the process with 'tail -f /ECS-CommunityEdition/install.log'"

$Scriptblock = 'cd /ECS-CommunityEdition; ./bootstrap.sh -c /root/deploy.yml'
Write-Verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

Write-Host -ForegroundColor Gray " ==>Adjusting docker run for non tty ( pull request made )"
$Scriptblock = "/usr/bin/sudo -s sed -i -e 's\-it\-i\g' /ECS-CommunityEdition/ui/run.sh"
Write-verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile   # -Confirm:$false -SleepSec 60


$Scriptblock = 'shutdown -r now'
Write-Verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -nowait -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
start-sleep 30
do {
		$ToolState = $Nodeclone | Get-VMXToolsState 
		Set-LABUi -short -title "VMware tools are in $($ToolState.State) state"
		Start-Sleep -Seconds 5
    }
    until ($ToolState.state -match "running")

Write-Host -ForegroundColor Gray " ==>Waiting for Docker Daemon"
$Scriptblock = 'until [[ "$(systemctl is-active docker)" == "active" ]]; do sleep 5; done'
Write-Verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword #-logfile $Logfile

Write-Host -ForegroundColor White "Starting ECS Configuration Step1, this may take a while"
Write-Host -ForegroundColor White "you may follow the process with 'tail -f /tmp/systemd-private-*-vmtoolsd.service-*/tmp/labbuildr.log'"
$Scriptblock = 'cd /ECS-CommunityEdition; /root/bin/step1'
Write-Verbose $Scriptblock
$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
Set-LABUi -short -title $Scriptblock   
if (!$ui_config.IsPresent)
    {
    Write-Host -ForegroundColor White "Starting ECS Customization Step2, this may take a while"
    Write-Host -ForegroundColor White "you may follow the process with 'tail -f ls /tmp/systemd-private-*-vmtoolsd.service-*/tmp/labbuildr.log'"
    $Scriptblock = 'cd /ECS-CommunityEdition; /root/bin/step2'
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    Set-LABUi -short -title $Scriptblock   
    }
}
$StopWatch.Stop()
Write-host -ForegroundColor White "ECS Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White "Success !? Browse to https://$($IP):443 and login with root/ChangeMe"
Set-LABUi 
