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
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(1,15)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "23"
$Start = "1"
$Szenarioname = "Hadoop"
$Nodeprefix = "$($Szenarioname)Node"
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
$Guestuser = "hadoop"
$Guestpassword  = "Password123!"

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
if (!(Test-path "$Sourcedir\Openstack"))
    {New-Item -ItemType Directory "$Sourcedir\Openstack"}


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
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Szenarioname -Scenario 7
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

    write-verbose "Setting Hostname"
    $Scriptblock = "hostnamectl set-hostname $($NodeClone.vmxname)"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

    Pause
    <#
    write-warning "trying to fetch RDO"
    $myrepo="/mnt/hgfs/Sources/Openstack/openstack-juno/"
    write-verbose "installing openstack repo location"
    $Scriptblock = "yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm"
    $NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    write-verbose "downloading openstack files"
    $Scriptblock = "reposync -l --repoid=openstack-juno --download_path=/mnt/hgfs/Sources/Openstack --downloadcomps --download-metadata -n"
    $NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    write-verbose "creating openstack repository"
    $Scriptblock = "createrepo $myrepo"
    $NodeClone |Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
    write-verbose "creating local Repository"
    $baseurl="file://$myrepo"
    $File = "/etc/yum.repos.d/rdo-release.repo"
    $Property = "baseurl"
    $Scriptblock = "sed -i '/.*$Property.*/ c\$Property=$baseurl' $file"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
    $Property = "gpgcheck"
    $Scriptblock = "sed -i '/.*$Property.*/ c\$Property=0' $file"
    Write-Verbose $Scriptblock

    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
    write-verbose "installing packstack"
    $Scriptblock = "yum install -y openstack-packstack"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


    Write-Warning "Installing AllInOne Openstack.... this will take a While !!!
    you might open putty to $ip and run TOP with user stack"
    #$Scriptblock = "/usr/bin/expect -c 'spawn `"/usr/bin/packstack`" `"--allinone`";expect `"*password:`" { send `"Password123!\r`" };interact'"

    $Scriptblock = "/usr/bin/expect -c 'set timeout -1;spawn `"/usr/bin/packstack`" `"--allinone`";expect `"*password:`" { send `"Password123!\r`" };interact'"
    $NodeClone |Invoke-VMXBash -Scriptblock "$Scriptblock" -Guestuser $Guestuser -Guestpassword $Guestpassword
    #>
}
write-Warning "Login to the $ip vms with stack/Password123!"
Write-Warning "Copy the following Text into BASH:
---------- snip --------------
expect << EOF
set timeout -1
spawn `"/usr/bin/packstack`" `"--allinone`"
expect `"root@192.168.2.241's password:`"
send `"Password123!\n`"
expect eof
EOF
---------- snip --------------"






