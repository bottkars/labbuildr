<#
.Synopsis
   .\install-ave.ps1 -MasterPath F:\labbuildr\ave
.DESCRIPTION
  install-ave is the a vmxtoolkit solutionpack for configuring and deploying avamar virtual editions
      
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
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -DDVESize 2TB
    installs a 4TB AVE
.EXAMPLE
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -configure
    Installs the AVE Default 0.5TB and configures Network with defaults and start the AVInstaller
#>
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
<# specify your desireed DDVE Size 
Valid Parameters:2TB,4TB,8TB
This will result in the following
Machine Configurations:
=================================
Size    | Memory  | CPU | Disk
_____ __|_________|_____|_________
  2TB   |  4GB    |  2  |  1*500GB
  4TB   |  6GB    |  2  |  1*500GB
  8TB   |  8GB    |  2  |  1*500GB

#>
[Parameter(Mandatory=$False)][ValidateSet('2TB')][string]$DDVESize = "2TB",
[Parameter(Mandatory=$false)][int32]$Nodes=1,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",

[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2"
# [Parameter(Mandatory = $false)][switch]$configure
)
#requires -version 3.0
#requires -module vmxtoolkit
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$Builddir = $PSScriptRoot
$Nodeprefix = "DDvENode"

$MasterVMX = get-vmx -path $MasterPath

if (!$MasterVMX.Template) 
    {
    write-verbose "Templating Master VMX"
    $template = $MasterVMX | Set-VMXTemplate
    }
$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"

if (!$Basesnap) 
    {
    write-verbose "Tweaking Base VMX"
    $config = Get-VMXConfig -config $MasterVMX.config
    $config = $config -notmatch "scsi0.virtualDev"
    $config += 'scsi0.virtualDev = "pvscsi"'
    $config = $config -notmatch "virtualhw.version"
    $config += 'virtualhw.version = "9"'
    $config = $config -notmatch 'scsi0:0.mode = "independent_persistent"'
    $config += 'scsi0:0.mode = "persistent"'
    Set-Content -Path $MasterVMX.config -Value $config
    Write-verbose "Base snap does not exist, creating now"
    $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
    }
    $Basesnap
# $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
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
        switch ($DDvESize)
            {
                "2TB"
                    {
                    Write-Verbose "2TB DDvE Selected"
                    $NumDisks = 1
                    $Disksize = "500GB"
                    $memsize = 6044
                    $Numcpu = 2
                    }

            }
            
            foreach ($LUN in (2..($NumDisks+1)))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        
    Write-Verbose "Configuring NIC0"
    $Netadater0 = $NodeClone | Set-VMXVnet -Adapter 0 -vnet vmnet2
    Write-Verbose "Configuring NIC1"
    $Netadater1 = $NodeClone | Set-VMXVnet -Adapter 1 -vnet vmnet2
    $Netadater1connected = $NodeClone | Connect-VMXNetworkAdapter -Adapter 1

    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
    Write-Verbose "Configuring Memory to $memsize"
    $Memory = $NodeClone | Set-VMXmemory -MemoryMB $memsize
    Write-Verbose "Configuring $Numcpu CPUs"
    $Processor = $nodeclone | Set-VMXprocessor -Processorcount $Numcpu





    Write-Verbose "Starting VM $($NodeClone.Clonename)"
    $NodeClone | start-vmx
    if ($configure.IsPresent)
    {
    $ip="$subnet.2$Node"
    }
<#     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")

    Write-Verbose "Configuring Disks"
    $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/perl /usr/local/avamar/bin/ave-part.pl" -Guestuser root -Guestpassword changeme -Verbose | Out-Null

    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $Scriptblock = "echo 'default "+$subnet+".103 - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser root -Guestpassword changeme -Verbose  | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+".local\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $Scriptblock = "echo '"+$Nodeprefix+$Node+"."+$BuildDomain+".local'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    # $NodeClone | Invoke-VMXBash -Scriptblock "shutdown -r now" -Guestuser root -Guestpassword changeme -Verbose -nowait
    Write-Verbose "rebooting VM $($NodeClone.Clonename)"
    # we do not use shutdown since toolstate does not reset
    $NodeClone | Stop-VMX | Out-Null
    $NodeClone | start-vmx | Out-Null
    do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config 
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")

    Write-Verbose "Starting Avamar Installer, this may take a while"
    $NodeClone | Invoke-VMXBash -Scriptblock "/bin/sh /usr/local/avamar/src/avinstaller-bootstrap-7.1.1-141.sles11_64.x86_64.run" -Guestuser root -Guestpassword changeme -Verbose | Out-Null
    Write-Host "Trying to connect to https://$subnet.3$($Node):8543/avi/avigui.html to complete the Installation"
    Start-Process "https://$subnet.3$($Node):8543/avi/avigui.html"
    
    } # end configure
    $NodeClone
#>
    }
    else
        {
        Write-Warning "Node $Nodeprefix$node already exists"
        }

}


