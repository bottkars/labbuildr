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
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ipaddress]$IPAddress = "192.168.2.239",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"

)
#requires -version 3.0
#requires -module vmxtoolkit
$Szenarioname = "Docker"
$Nodeprefix = "$($Szenarioname)Host"
$username = "docker"
# $private_device = "eno33557248"
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
     $DNS2 = $labdefaults.DNS1
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

[System.Version]$IP = $IPAddress.ToString()
[string]$IP = $IP.MinorRevision
$Node = $IP
$DefaultTimezone = "Europe/Berlin"
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = "docker"
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
# if (!(Test-path "$Sourcedir\Openstack"))
#    {New-Item -ItemType Directory "$Sourcedir\Openstack"}


####Build Machines#
        If (!(get-vmx $Nodeprefix$Node))
        {
        write-Host -ForegroundColor Magenta "Creating $Nodeprefix$Node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        # write-Host -ForegroundColor Magenta "      ==> Adding Private NIC"        
        # $NodeClone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType vmxnet3 | Out-Null 
        # $NodeClone | Set-VMXVnet -Adapter 1 -Vnet vmnet3 | Out-Null           
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
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference 0
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 4096 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        write-Host -ForegroundColor Magenta "      ==> Starting $Nodeprefix$Node"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        write-Host -ForegroundColor Magenta "Configuring $Nodeprefix$node"
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

    write-Host -ForegroundColor Magenta "      ==> Setting Timezone"
    $Scriptblock = "timedatectl set-timezone $DefaultTimezone"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null


    write-Host -ForegroundColor Magenta "      ==> Configuring Network with $IPAddress"

        $NodeClone | Set-VMXLinuxNetwork -ipaddress $IPAddress -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $public_device -Peerdns -DNS1 $DNS1 -DNS2 $DNS2 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        # Configure Private Network
        # $NodeClone | Set-VMXLinuxNetwork -ipaddress $private_ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $private_device -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        #write-Host -ForegroundColor Magenta "      ==> Installing Private Interface"


    write-Host -ForegroundColor Magenta "      ==> Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $Nodeprefix$Node"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    
    Write-Verbose "Creating $Guestuser"
    $Scriptblock = "useradd $Guestuser"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    Write-Verbose "Changing Password for $Guestuser to $Guestpassword"
    $Scriptblock = "echo $Guestpassword | passwd $Guestuser --stdin"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    ##generate user ssh keys
    write-Host -ForegroundColor Magenta "      ==> Generating ssh keys for $Guestuser"
    $Scriptblock ="/usr/bin/ssh-keygen -t rsa -N '' -f /home/$Guestuser/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null

    write-Host -ForegroundColor Magenta "      ==> Adding ssh keys for $Guestuser"
    $Scriptblock = "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null
    
    $Scriptblock = "[ ! -d /root/.ssh ] && mkdir /root/.ssh"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    write-Host -ForegroundColor Magenta "      ==> Generating ssh keys for $Rootuser"
    $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null 

    if ($Hostkey)
        {
        write-Host -ForegroundColor Magenta "      ==> Adding public ssh keys for Host"
        $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "echo '$Hostkey' >> /home/$Guestuser/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword | Out-Null
        }
    
    $Scriptblock = "cat /home/$Guestuser/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"
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

    $Scriptblock = "curl https://get.docker.com/ | sh -;systemctl enable docker"
    Write-Verbose $Scriptblock
    $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


Write-Host -ForegroundColor Cyan "You can now login to dockerhost at $IPAddress using $Guestuser/$Guestpassword"

}
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }