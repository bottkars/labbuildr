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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-ecs
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
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('8192','12288','16384','20480','30720','51200','65536')]$Memory = "12288",

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet("release-2.1","Develop",'master')]$Branch = 'master',
<#fixes the Docker -i issue from GiT#>
#[switch]$bugfix,
<#Adjusts some Timeouts#>
[switch]$AdjustTimeouts,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$EMC_ca,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$uiconfig,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet(150GB,500GB,520GB)][uint64]$Disksize = 520GB,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateRange(1,5)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"

)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "24"
$Start = "1"
$IPOffset = 5
$Szenarioname = "ECS"
$Nodeprefix = "$($Szenarioname)Node"
$scsi = 0
If ($Defaults.IsPresent)
    {
     $labdefaults = Get-labDefaults
     $vmnet = $labdefaults.vmnet
     $subnet = $labdefaults.MySubnet
     $BuildDomain = $labdefaults.BuildDomain
     $Sourcedir = $labdefaults.Sourcedir
     try
        {
        test-path -Path $Sourcedir | out-null
        }
    catch
        [System.Management.Automation.DriveNotFoundException] 
        {
        Write-Warning "Make sure to have your Source Stick connected"
        exit
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
        write-warning "no sources directory found at $Sourcedir"
        exit
        }

     $Hostkey = $labdefaults.HostKey
     $Gateway = $labdefaults.Gateway
     $DefaultGateway = $labdefaults.Defaultgateway
     $DNS1 = $labdefaults.DNS1
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

try
    {
    $yumcachedir = join-path -Path $Sourcedir "$OS\yum" -ErrorAction stop
    }
catch [System.Management.Automation.DriveNotFoundException]
    {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
    }

### checking for license file ###
# "checkin for yum cache basdir"
try
    {
    Test-Path $yumcachedir | Out-Null
    }
catch [System.Management.Automation.ItemNotFoundException]
    {
    write-warning "yum cache not found in sources, creating now"
    New-Item  -ItemType Directory -Path $yumcachedir
    }

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
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node))
        {
        write-verbose "Creating $Nodeprefix$node"
        If ($FullClone.IsPresent)
            {
            Write-Host -ForegroundColor Magenta "Creating full Clone of $($MasterVMX.vmxname), doing full sync now"
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$Node
            }
        else
            { 
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node
            } 
        If ($Node -eq $Start)
            {$Primary = $NodeClone
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
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
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
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Rootpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @hyperv_guy" -builddate
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Szenarioname -Scenario 7
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
        Write-verbose "Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
    
    ##### Prepare
    $Logfile = "/tmp/1_prepare.log"

    $Scriptblock =  "systemctl start NetworkManager"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  #-logfile $Logfile

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

    Write-Host -ForegroundColor Magenta "Setting Kernel Parameters"
    $Scriptblock = "echo 'kernel.pid_max=655360' >> /etc/sysctl.conf;sysctl -w kernel.pid_max=655360"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile 

    if ($EMC_ca.IsPresent)
        {
        Write-Host -ForegroundColor Magenta "Copying EMC CA Certs"
        $files = Get-ChildItem -Path "$Sourcedir\EMC_ca"
        foreach ($File in $files)
            {
            $NodeClone | copy-VMXfile2guest -Sourcefile $File.FullName -targetfile "/etc/pki/ca-trust/source/anchors/$($File.Name)" -Guestuser $Rootuser -Guestpassword $Guestpassword
            }
        $Scriptblock = "update-ca-trust"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile 
        }
 
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

    Write-Verbose "Creating $Guestuser"
    $Scriptblock = "useradd $Guestuser"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $Scriptblock = "echo '$Guestuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile

    
    $Scriptblock = "sed -i 's/^.*\bDefaults    requiretty\b.*$/Defaults    !requiretty/' /etc/sudoers"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile


    Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile


    ### generate user ssh keys
    $Scriptblock ="/usr/bin/ssh-keygen -t rsa -N '' -f /home/$Guestuser/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword

    
    $Scriptblock = "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
    #### Start ssh for pwless  root local login
    $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile 

    $Scriptblock = "cat /home/$Guestuser/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    
    if ($Hostkey)
            {
            $Scriptblock = "echo 'ssh-rsa $Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
            }

    $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile

    $Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile

    $Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile


    


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


    #### end ssh
    if ($update.IsPresent)
        {
        Write-Verbose "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }

    $Scriptblock = "yum install bind-utils -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $Packages = "git tar wget docker"
    Write-Verbose "Checking for $Packages"
    $Scriptblock = "yum install $Packages -y"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        foreach ($remotehost in ('emccodevmstore001.blob.core.windows.net','registry-1.docker.io','index.docker.io'))
        {
        Write-Host -ForegroundColor Magenta "resolving $remotehost" 
        $Scriptblock = "nslookup $remotehost"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        }
    Write-Verbose "Checking for offline container on $Sourcedir"
    Write-Verbose "Clonig $Scenario" 
    switch ($Branch)
        {
            "release-2.1"
            {
            $Docker_imagename = "emccorp/ecs-software-2.1"
            $Docker_image = "ecs-software-2.1"
            $Docker_imagetag = "latest"
            }
        default
            {
            $Docker_image = "ecs-software-2.2"
            $Docker_imagename = "emccorp/ecs-software-2.2"
            $Docker_imagetag = "latest"
            }
        }
    $Scriptblock = "systemctl start docker.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile



if (!(Test-Path "$Sourcedir\docker\$Docker_image.tgz"))
    {
    New-Item -ItemType Directory "$Sourcedir\docker" -ErrorAction SilentlyContinue | Out-Null
    Write-Verbose "Creating Offline Image for ECS $Docker_imagename"
    $Scriptblock = "docker pull $Docker_imagename"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

    $Scriptblock = "docker save $($Docker_imagename):latest | gzip -c >  /mnt/hgfs/Sources/docker/$Docker_image.tgz"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
    }
else
    {
    $Scriptblock = "gunzip -c /mnt/hgfs/Sources/docker/$Docker_image.tgz | docker load"
    Write-Verbose "Creating docker fs layer from offline Image"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    }

    $Scriptblock = "git clone -b $Branch --single-branch https://github.com/EMCECS/ECS-CommunityEdition.git"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    
    # docker_image_name = "emccorp/ecs-software"

    Write-Host -ForegroundColor Magenta "Installing ECS Singlenode, this may take a while ..."
    $Logfile =  "/home/ecsuser/ecsinst_step1.log"

    # $Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks sdb --ethadapter eno16777984 --hostname $($NodeClone.vmxname)" 
    if ($Branch -match "feature-ecs-2.2")
        {
        $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks sdb --ethadapter eno16777984 --hostname $($NodeClone.vmxname) --imagename $Docker_imagename --imagetag $Docker_imagetag &> /tmp/ecsinst_step1.log"  
        }
    else
        {
        $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks sdb --ethadapter eno16777984 --hostname $($NodeClone.vmxname) &> /tmp/ecsinst_step1.log"  
        }
   # $Expect = "/usr/bin/expect -c 'spawn /usr/bin/sudo -s $Scriptblock;expect `"*password*:`" { send `"Password123!\r`" }' &> /tmp/ecsinst.log"

    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword


    Write-Host -ForegroundColor Magenta "Setting automatic startup of docker and ecs container"

    $Scriptlets = ("echo '/dev/sdb1 /ecs/uuid-1 xfs defaults 0 0' `>> /etc/fstab",
    "systemctl enable docker.service",
    "echo 'docker start ecsstandalone' `>>/etc/rc.local",
    'chmod +x /etc/rc.d/rc.local')

    foreach ($Scriptblock in $Scriptlets)
        {
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
        }


<#
    if ($bugfix.IsPresent)
        {
        Write-Host -ForegroundColor Magenta "Now adjusting some settings......"

        $DockerScripblock = ("/usr/bin/sudo -s docker exec -t  ecsstandalone cp /opt/storageos/conf/cm.object.properties /opt/storageos/conf/cm.object.properties.old",
        "docker exec -t ecsstandalone cp /opt/storageos/ecsportal/conf/application.conf /opt/storageos/ecsportal/conf/application.conf.old",
        "docker exec -t ecsstandalone cp /opt/storageos/conf/cm.object.properties /host/cm.object.properties",
        "docker exec -t ecsstandalone cp /opt/storageos/ecsportal/conf/application.conf /host/application.conf",
        "sed -i 's/object.MustHaveEnoughResources=true/object.MustHaveEnoughResources=false/' /host/cm.object.properties",
        "echo ecs.minimum.node.requirement=1 `>> /host/application.conf",
        "docker exec -t ecsstandalone cp /host/cm.object.properties /opt/storageos/conf/cm.object.properties",
        "docker exec -t ecsstandalone cp /host/application.conf /opt/storageos/ecsportal/conf/application.conf",
        "docker stop ecsstandalone",
        "docker start ecsstandalone",
        "rm -rf /host/cm.object.properties*",
        "rm -rf /host/application.conf"
        )


        foreach ($Scriptblock in $DockerScripblock)
            {    
            Write-Output $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Rootpassword -Verbose
            }

        }
#>
}
if ($uiconfig.ispresent)
    {

    Write-Host -ForegroundColor Magenta "Please wait up to 5 Minutes and Connect to https://$($ip):443
Use root:ChangeMe for Login
"
    }
else
	{
Write-Host -ForegroundColor Magenta "Starting ECS Install Step 2 for creation of Datacenters and Containers.
This might take up to 45 Minutes
Approx. 2000 Objects are to be created
you may chek the opject count with your bowser at http://$($IP):9101/stats/dt/DTInitStat"
# $Logfile =  "/tmp/ecsinst_Step2.log"
#$Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$($BuildDomain)ns1 --ObjectVArray=$($BuildDomain)OVA1 --ObjectVPool=$($BuildDomain)OVP1 --UserName=$Guestuser --DataStoreName=$($BuildDomain)ds1 --VDCName=vdc1 --MethodName= &> /tmp/ecsinst_step2.log" 
# curl --insecure https://192.168.2.211:443
    
Write-Host -ForegroundColor Magenta "waiting for Webserver to accept logins"

$Scriptblock = "curl -i -k https://$($ip):4443/login -u root:ChangeMe"
Write-verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile "/tmp/curl.log" -Confirm:$false -SleepSec 60
##  we need to edit the retry count for lowmem / ws machines !!!!!
<#

"sed -i -e 's/retry(30, 60, InsertVDC, [ECSNode, objectVpoolName])/retry(300, 60, InsertVDC, [ECSNode, objectVpoolName])/g' /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py"

def CreateObjectVarrayWithRetry(ECSNode, objectVArrayName):
     retry(30, 60, CreateObjectVArray, [ECSNode, objectVArrayName])
    retry(200, 60, CreateObjectVArray, [ECSNode, objectVArrayName])
in /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py

#>
if ($AdjustTimeouts.isPresent)
    {
    Write-Host -ForegroundColor Magenta "Adjusting Timeouts"
    $Scriptblock = "/usr/bin/sudo -s sed -i -e 's\30, 60, InsertVDC\300, 300, InsertVDC\g' /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py"
    Write-verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile "/tmp/SED.log" # -Confirm:$false -SleepSec 60
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
    Write-Host -ForegroundColor Magenta "running Method $Method, monitor tail -f /var/log/vipr/emcvipr-object/ssm.log"
    $Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method" 
    Write-verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile "/tmp/$Method.log"
    }
$Method = 'CreateUser'
Write-Host -ForegroundColor Magenta "running Method $Method"
$Scriptblock = "cd /ECS-CommunityEdition/ecs-single-node;/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method;exit 0" 
Write-verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile "/tmp/$Method.log"

$Method = 'CreateSecretKey'
Write-Host -ForegroundColor Magenta "running Method $Method"
$Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$Namespace_Name --ObjectVArray=$Pool_Name --ObjectVPool=$Replicaton_Group_Name --UserName=$Guestuser --DataStoreName=$Datastore_Name --VDCName=$VDC_NAME --MethodName=$Method" 
Write-verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile "/tmp/$Method.log"
}
Write-Host -ForegroundColor Magenta "Success !?"

