<#
.Synopsis
   .\install-vnx.ps1 -MasterPath F:\labbuildr\ave
.DESCRIPTION
  install-vnx is the a vmxtoolkit solutionpack for configuring and deploying the VNX File Virtual Edition
  per default, we will default parameter from labbuildr ( see get-help -Parameter )
      
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
    .\install-vnx.ps1 -MasterPath F:\labbuildr\vnx
    installs a Single Datamover VNX
.EXAMPLE
    .\install-vnx.ps1 -MasterPath F:\labbuildr\vnx -DualDM
    installs a Dual Datamover VNX
#>
[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
<#Specify Single (4GB) or DualDatamove (6GB) being Used
#>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults,
# [Parameter(ParameterSetName = "defaults", Mandatory=$false)][ValidateSet("vipr-2.3.0.0.828","vipr-2.2.1.0.1106")]$viprmaster = "vipr-2.3.0.0.828",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][switch]$DualDM,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",

[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$configure,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$configurevdm
)
#requires -version 3.0
#requires -module vmxtoolkit
$ZONE = "Europe/Berlin"
$rootuser = "root"
$rootpassword = "nasadmin"
$Nasuser = "nasadmin"
If ($Defaults.IsPresent)
    {
     $labdefaults = Get-labDefaults
     $vmnet = $labdefaults.vmnet
     $subnet = $labdefaults.MySubnet
     $BuildDomain = $labdefaults.BuildDomain
     $Sourcedir = $labdefaults.Sourcedir
     $Defaultgateway = $labdefaults.DefaultGateway
     $DNS1 = $labdefaults.DNS1

     }

If ($configurevdm.IsPresent)
    {
    $configure = $true
    }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$Builddir = $PSScriptRoot
$Nodeprefix = "VNXNode"
If (!($Masterpath))
    {
    $MasterPath = $Builddir
    }
$MasterVMX = get-vmx "VNX*"
if (!($MasterVMX))
    {
    Write-Warning "We need to  build a Master from a Valid OVA Template"
    try
        {
            $vnxova = Get-ChildItem "$Sourcedir"  -Filter "8*.ova" -ErrorAction Stop
        }
    
    catch [System.Management.Automation.ItemNotFoundException]
        {
        Write-Warning "no vnx ova found, please download from support.emc.com
        https://download.emc.com/downloads/DL49032_VNX_File_Simulator_(OE_8.1.0.15)_Single/Dual_Data_Mover_(OVA_package).ova"
        exit
        }
    catch [System.Management.Automation.DriveNotFoundException]
        {
        Write-Warning "Sourcedrive not found, usb stick connected ? "
        exit
        }
    $vnxova = $vnxova | Sort-Object -Descending
    $vnxova = $vnxova[0]
    $LatestOVA = $vnxova.BaseName
    <#
    if (!(Test-Path "$global:vmwarepath\7za.exe"))
                    {
                    Write-Warning " 7zip not found
                    7za is part of VMware Workstation 11 or the 7zip Distribution
                    please get and copy 7za to & $global:vmwarepath\7za.exe"
                    exit
                    }
                    #>
            Write-warning "$deflating VNX Simulator $LatestOVA"
            #& $global:vmwarepath\7za.exe x "-oVNX$LatestOVA" -y "$($vnxova.FullName)" 
            & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name="VNX$LatestOVA" $($vnxova.FullName) $PSScriptRoot
    $MasterVMX = get-vmx "VNX*"
    }
if (!($MasterVMX))
    {
    Write-Warning "we had trouble finding a Master"
    exit
    }
$MasterVMX = $MasterVMX | Sort-Object -Descending
$MasterVMX = $MasterVMX[0]
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

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Verbose "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node))
        {
        write-verbose "Creating clone $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir"
        # Write-Output $NodeClone
        $SCSI= 0
    Write-Verbose "Configuring NIC1"
    $Netadater = $NodeClone | Set-VMXVnet -Adapter 1 -vnet $vmnet
    Write-Verbose "Configuring NIC2"
    $Netadater = $NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet

    Write-Verbose "Disabling IDE0"
    $NodeClone | Set-VMXDisconnectIDE | Out-Null
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
    $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$rootuser" -Line2 "rootpasswd:$rootpassword"  -Line5 "labbuildr by @hyperv_guy" -builddate

    if ($DualDM.IsPresent)
        {
        Write-Verbose "Configuring Memory to 6GB"
        $Memory = $NodeClone | Set-VMXmemory -MemoryMB 6144
        }
    Write-Verbose "Starting VM $($NodeClone.Clonename)"
    $Started = $NodeClone | start-vmx
    if ($configure.IsPresent)
    {
    $eth0ip="$subnet.8$Node"
    $eth1ip="$subnet.9$Node"

     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 5
        }
    until ($ToolState.state -match "running")
    Write-Verbose "Setting Hostname"
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $rootuser -Guestpassword $rootpassword
    Write-Verbose "Setting Timezone"
    $NodeClone | Invoke-VMXBash -Scriptblock "echo 'ZONE=$ZONE' >> /etc/sysconfig/clock" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/bin/ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null

    Write-warning "Waiting for Daemons Startup, this may take a while"
    do {
        $Processlist = $NodeClone | Get-VMXProcessesInGuest -Guestuser $rootuser -Guestpassword $rootpassword
        sleep 10
        write-verbose "Still Waiting ! "
        }
    until ($Processlist -match 'avahi-daemon')

        $NodeClone | Set-VMXLinuxNetwork -ipaddress $eth0ip -device eth0 -network "$subnet.0" -netmask 255.255.255.0 -gateway $Defaultgateway  -Peerdns -DNS1 $DNS1 -DNS2 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$node" -rootuser $rootuser -rootpassword $rootpassword
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $eth1ip -device eth1 -network "$subnet.0" -netmask 255.255.255.0 -gateway $Defaultgateway  -Peerdns -DNS1 $DNS1 -DNS2 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$node" -rootuser $rootuser -rootpassword $rootpassword
       #  $NodeClone | Set-VMXLinuxDNS -Nameserver1 $DNS1 -Nameserver2 $DNS1 -Search1 "$BuildDomain.local" -Domain "$BuildDomain.local" -rootuser $rootuser -rootpassword $rootpassword
        $Scriptblock = "/etc/init.d/network restart"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword


    
    <#
    $Scriptblock = "echo 'default "+$subnet+".103 - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword
    $scriptblock = "sed -i -- 's/HOSTNAME=localhost.localdomain/HOSTNAME=$Nodeprefix$node.$BuildDomain.local/g' /etc/sysconfig/network"
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword
    Write-Verbose "Configuring Datamover NICS"
        $Scriptblock = "echo  'IPADDR=$eth1ip' >> /etc/sysconfig/network-scripts/ifcfg-eth0"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
        $Scriptblock = "echo  'IPADDR=$eth2ip' >> /etc/sysconfig/network-scripts/ifcfg-eth1"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword  | Out-Null
    foreach ($eth in ("eth0","eth1"))
        {
    
        Write-Verbose "Configuring $eth"
        $Scriptblock = "echo  'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-$eth"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        $Scriptblock = "echo  'GATEWAY=$subnet.103' >> /etc/sysconfig/network-scripts/ifcfg-$eth"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        $Scriptblock = "sed -i -- '/BOOTPROTO/c\BOOTPROTO=static' /etc/sysconfig/network-scripts/ifcfg-$eth"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        $scriptblock = "sed -i -- 's/PEERDNS=no/d' /etc/sysconfig/network-scripts/ifcfg-$eth"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        }

        $Scriptblock = "sed -i -- '/nameserver/c\nameserver $subnet.10' /etc/resolv.conf"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
       
        $Scriptblock = "sed -i -- '/domain/c\domain $BuildDomain.local' /etc/resolv.conf"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
 
        $Scriptblock = "sed -i -- '/search/c\search $BuildDomain.local' /etc/resolv.conf"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword

        $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/service network restart" -Guestuser $rootuser -Guestpassword $Rootpassword -Verbose | Out-Null
        #>
 # Starting NAS Config
        Write-Verbose "Configuring Datamover DNS Settings"
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_dns server_2 -protocol tcp $BuildDomain.local $subnet.10"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser nasadmin -Guestpassword $rootpassword
        Write-Verbose "Configuring Datamover Timezone Settings"
        $Scriptblock = "/usr/bin/perl /nas/http/webui/bin/timezone.pl -s $ZONE"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        Write-Verbose "Creating SSL Certificate"
        $Scriptblock = "/usr/bin/perl /nas/http/webui/bin/gen_ssl_cert.pl -qq"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser  -Guestpassword $rootpassword 
        if ($ConfigureVDM.isPresent)
        {
        Write-Verbose "Creating VDM"
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/nas_server -name VDM_$Builddomain -type vdm -create server_2 pool=clar_r5_performance"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        Write-Verbose "Creating CIFS Mountpoint"
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_mountpoint VDM_$Builddomain -create /vm"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        write-Verbose "Creating CIFS Fislesystem"
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/nas_fs -name virtualmachinesfs -create size=88G pool=clar_r5_performance -thin yes -auto_extend yes -max_size 1T"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        Write-Verbose "Mounting Filesystem with SMBCA"       
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_mount VDM_$Builddomain -o smbca virtualmachinesfs /vm"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword
        Write-Verbose "Exporting Share with Contious Access"       
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_export VDM_$BuildDomain -Protocol cifs -name VMShare -option type=CA /vm" 
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword
        Write-Verbose "Starting CIFS Service"       
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_setup server_2 -Protocol cifs -option start"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        Write-Verbose "Creating VDM network Interface"         
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_ifconfig server_2 -create -Device cge0 -name IF_VDM_1 -protocol IP $subnet.85 255.255.255.0 $subnet.255"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        write-Verbose "Creating Cifs Server VNX_$BuildDomain"
        $Scriptblock = "export NAS_DB=/nas;/nas/bin/server_cifs VDM_$Builddomain -add compname=VNX_$Builddomain,domain=$Builddomain.local,interface=IF_VDM_1 -comment 'Virtual VNX built by labbuildr'"       
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword 
        write-Verbose "Joining Cifs Server VNX_$BuildDomain to $BuildDomain"
        $Scriptblock = "export NAS_DB=/nas;/usr/bin/expect -c 'set timeout 30;spawn /nas/bin/server_cifs VDM_"+$BuildDomain+" -Join compname=VNX_"+$BuildDomain+",domain="+$BuildDomain+".local,admin=Administrator;expect `"assword:`" { send `"Password123!\r`" };interact'"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Nasuser -Guestpassword $rootpassword
        write-Verbose "Clearing LOG File"
        $Scriptblock = "echo '#version 1' > /nas/log/webui/alert_log"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword
        write-Verbose "Generationg Certificate"
        $Scriptblock = "/nas/sbin/nas_ca_certificate -generate"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword 
        }

        #| Out-Null
    } # end
    $NodeClone
    }
    else
        {
        Write-Warning "Node $Nodeprefix$node already exists"
        }

}


