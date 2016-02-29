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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-openstack
.EXAMPLE

#>
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateRange(1,5)][int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateSet('juno','kilo','liberty')]$release="liberty",
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateRange(1,5)][int32]$Startnode = 1,
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
$Szenarioname = "Openstack"
$Nodeprefix = "$($Szenarioname)Node"
$release = $release.tolower()
$username = "stack"
$private_device = "eno33557248"
$public_device = "eno16777984"

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
     $Gateway = $labdefaults.Gateway
     $DefaultGateway = $labdefaults.Defaultgateway
     $Hostkey = $labdefaults.HostKey
     $DNS1 = $labdefaults.DNS1
     }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = "stack"
$Guestpassword  = "Password123!"

[uint64]$Disksize = 100GB
$scsi = 0

$Node_requires = "numactl libaio"
$Required_Master = "CentOS7 Master"

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
if (!(Test-path "$Sourcedir\Openstack"))
    {New-Item -ItemType Directory "$Sourcedir\Openstack"}


####Build Machines#
    $machinesBuilt = @()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        If (!(get-vmx $Nodeprefix$node))
        {
        write-Host -ForegroundColor Magenta "Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq $Start)
            {
            $Primary = $NodeClone
            }
        write-Host -ForegroundColor Magenta "      ==> Adding Private NIC"        
        $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType vmxnet3 | Out-Null 
        $NodeClone | Set-VMXVnet -Adapter 1 -Vnet vmnet3 | Out-Null           
        $Config = Get-VMXConfig -config $NodeClone.config
        write-Host -ForegroundColor Magenta "      ==> Tweaking Config"
        write-Host -ForegroundColor Magenta "      ==> Creating Disks"
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            write-Host -ForegroundColor Magenta "      ==> Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            write-Host -ForegroundColor Magenta "      ==> Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI | Out-Null
            }
        write-Host -ForegroundColor Magenta "      ==> Setting NIC0 to HostOnly"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
        if ($vmnet)
            {
            write-Host -ForegroundColor Magenta "      ==> Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Szenarioname -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 4096 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        write-Host -ForegroundColor Magenta "      ==> Starting $Nodeprefix$Node"
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
        write-Host -ForegroundColor Magenta "Configuring $Nodeprefix$node"
        $ip="$subnet.$Range$($Node[-1])"
        $private_ip="10.0.0.$Range$($Node[-1])"
        $Install_Hosts = "$Install_Hosts,$IP"
        $NodeClone = get-vmx $Node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        write-Host -ForegroundColor Magenta "      ==> Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        write-Host -ForegroundColor Magenta "      ==> Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
        write-Host -ForegroundColor Magenta "      ==> Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $public_device -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        # Configure Private Network
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $private_ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $private_device -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        write-Host -ForegroundColor Magenta "      ==> Installing Private Interface"

    write-Host -ForegroundColor Magenta "      ==> Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    write-Host -ForegroundColor Magenta "      ==> Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $($NodeClone.vmxname)"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null



### generate user ssh keys
    write-Host -ForegroundColor Magenta "      ==> Generating ssh keys for $Guestuser"
    $Scriptblock ="/usr/bin/ssh-keygen -t rsa -N '' -f /home/$Guestuser/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    write-Host -ForegroundColor Magenta "      ==> Adding ssh keys for $Guestuser"
    $Scriptblock = "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null
<####
    $Scriptblock = "[ ! -d /root/.ssh ] && mkdir /root/.ssh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
#>   
    write-Host -ForegroundColor Magenta "      ==> Generating ssh keys for $Rootuser"
    $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null 

    if ($Hostkey)
        {
        write-Host -ForegroundColor Magenta "      ==> Adding public ssh keys for Host"
        $Scriptblock = "echo 'ssh-rsa $Hostkey' >> /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo 'ssh-rsa $Hostkey' >> /home/$Guestuser/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null
        }
    
    if ($Node -eq $machinesBuilt[0])
        {
        write-Host -ForegroundColor Magenta "      ==> Copying public ssh keys to host"

        $Nodeclone | copy-VMXFile2Host -Sourcefile "/root/.ssh/id_rsa.pub" -targetfile "./pub.key.$($machinesBuilt[0]).root" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        $Nodeclone | copy-VMXFile2Host -Sourcefile "/home/$Guestuser/.ssh/id_rsa.pub" -targetfile "./pub.key.$($machinesBuilt[0]).stack" -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

        }
    else
        {
        write-Host -ForegroundColor Magenta "      ==> Copying public ssh keys to $Node "

        $content = get-content -Path "./pub.key.$($machinesBuilt[0]).root"
        $Scriptblock = "echo '$content' >> /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        $content = get-content -Path "./pub.key.$($machinesBuilt[0]).stack"
        $Scriptblock = "echo '$content' >> /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        }


    $Scriptblock = "cat /home/stack/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    
    $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    $Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
 #### end ssh
    $Scriptblock = "yum install -y $Node_requires"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
}
$NodeClone = get-vmx $machinesBuilt[0]  
write-host -ForegroundColor Magenta "Installing OpenStack $release on $($machinesBuilt[0])"
write-host -ForegroundColor Magenta "fetching OpenStack Repo for $release"
$myrepo="/mnt/hgfs/Sources/Openstack/openstack-$release/"
write-Host -ForegroundColor Magenta "      ==> installing openstack repo location"
$Scriptblock = "yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-$release/rdo-release-$release-1.noarch.rpm"
$NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
write-Host -ForegroundColor Magenta "      ==> downloading openstack files"
$Scriptblock = "reposync -l --repoid=openstack-$release --download_path=/mnt/hgfs/Sources/Openstack --downloadcomps --download-metadata -n"
$NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
write-Host -ForegroundColor Magenta "      ==> creating openstack repository"
$Scriptblock = "createrepo $myrepo"
$NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
write-Host -ForegroundColor Magenta "      ==> creating local Repository"
$baseurl="file://$myrepo"
$File = "/etc/yum.repos.d/rdo-release.repo"
$Property = "baseurl"
$Scriptblock = "sed -i '/.*$Property.*/ c\$Property=$baseurl' $file"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
$Property = "gpgcheck"
$Scriptblock = "sed -i '/.*$Property.*/ c\$Property=0' $file"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
write-Host -ForegroundColor Magenta "installing RDO OpenStack $release"

$Scriptblock = "yum install -y openstack-packstack"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
  
$Install_Hosts=$Install_Hosts.TrimStart(",")
Write-Host -ForegroundColor Magenta "Installing Openstack.... this will take a While !!!
you might open putty to $($subnet).241 and tail -f /tmp/inst_openstack.log"

$Scriptblock = "/usr/bin/packstack --install-hosts=$Install_Hosts --os-swift-install=y --os-compute-hosts=$Install_Hosts --novanetwork-pubif=$public_device --novacompute-privif=$private_device --novanetwork-privif=$private_device --default-password=$Guestpassword --os-swift-install=y --nagios-install=y --provision-demo=n" #--ssh-public-key=/home/$Guestuser/public.key  --novacompute-hosts=$Install_Hosts
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -logfile /tmp/inst_openstack.log | Out-Null

Write-Host -ForegroundColor Cyan "You can now login to Horizon dashboard at $($subnet).241 using admin/$Guestpassword"

