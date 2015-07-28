<#
.Synopsis
   .\install-ecs.ps1 
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
   https://community.emc.com/blogs/bottk/
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
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateRange(1,1)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(1,15)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$Update
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "21"
$Start = "1"
$Szenarioname = "ECS"
$Nodeprefix = "$($Szenarioname)Node"
$Memory = "20240"
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

If (!$DNS1)
    {
    Write-Warning "DNS Server not Set, exiting now"
    }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = "$($Szenarioname.ToLower())user"
$Guestpassword  = "Password123!"

$Disksize = "512GB"
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
# if (!(Test-path "$Sourcedir\Openstack"))
#    {New-Item -ItemType Directory "$Sourcedir\Openstack"}


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
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Szenarioname -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB $Memory | Out-Null
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

    write-verbose "Disabling IPv&"
    $Scriptblock = "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p"
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


    write-verbose "Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    write-verbose "Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $($NodeClone.vmxname)"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    Write-Verbose "Creating $Guestuser"
    $Scriptblock = "useradd $Guestuser"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "echo '$Guestuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    
    $Scriptblock = "sed -i 's/^.*\bDefaults    requiretty\b.*$/Defaults    !requiretty/' /etc/sudoers"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


    Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


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
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword 

    $Scriptblock = "cat /home/$Guestuser/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    #### end ssh
  if ($update.IsPresent)
        {
        Write-Verbose "Performing yum update, this may take a while"
        $Scriptblock = "yum update -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
        }

    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Packages = "git tar wget"
    Write-Verbose "Checking for $Packages"
    $Scriptblock = "yum install $Packages"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    Write-Verbose "Clonig $Scenario" 
    $Scriptblock = "git clone https://github.com/EMCECS/ECS-CommunityEdition"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    
    Write-Verbose "resolving index.docker.io" 
    $Scriptblock = "ping -c 3 index.docker.io"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    
    
    Write-Warning "Installing ECS Singlenode, this may take a while ..."

    $Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step1_ecs_singlenode_install.py --disks sdb --ethadapter eno16777984 --hostname $($NodeClone.vmxname) &> /tmp/ecsinst_step1.log"  
    $Expect = "/usr/bin/expect -c 'spawn /usr/bin/sudo -s $Scriptblock;expect `"*password*:`" { send `"Password123!\r`" }' &> /tmp/ecsinst.log"

    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword
}

Write-Warning "Please wait up to 5 Minutes and Connect to https://$($ip):443
Use root:ChangeMe for Login
make sure to add the ecs license file before continuing with Step 2:

When Done press any Key to continue with Step2"
Pause

$Scriptblock = "/usr/bin/sudo -s python /ECS-CommunityEdition/ecs-single-node/step2_object_provisioning.py --ECSNodes=$IP --Namespace=$($BuildDomain)ns1 --ObjectVArray=$($BuildDomain)OVA1 --ObjectVPool=$($BuildDomain)OVP1 --UserName=$Guestuser --DataStoreName=$($BuildDomain)ds1 --VDCName=$($BuildDomain)vdc1 --MethodName= &> /tmp/ecsinst_step2.log" 
Write-verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword



