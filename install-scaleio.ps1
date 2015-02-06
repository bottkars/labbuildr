<#
.Synopsis
   .\install-scaleio.ps1 
.DESCRIPTION
  install-scaleio is  the a vmxtoolkit solutionpack for configuring and deploying scaleio svm´s
      
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
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -AVESize 4TB
    installs a 4TB AVE
.EXAMPLE
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -configure
    Installs the AVE Default 0.5TB and configures Network with defaults and start the AVInstaller
#>
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$SCALEIOMasterPath,
[Parameter(Mandatory=$true)][int32]$Nodes,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][int32]$Disks = 3,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",

[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(Mandatory=$False)][switch]$sds,
[Parameter(Mandatory=$False)][switch]$sdc
)
#requires -version 3.0
#requires -module vmxtoolkit
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$Guestuser = "root"
$Guestpassword = "admin"
$Disksize = "100GB"
$scsi = 0
$Nodeprefix = "ScaleIONode"
$MasterVMX = get-vmx -path $SCALEIOMasterPath


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
    write-verbose " Creating $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
    $Config = Get-VMXConfig -config $NodeClone.config
    Write-Verbose "Tweaking Config"


    $Config = $config | ForEach-Object { $_ -replace "lsilogic" , "pvscsi" }
    $Config | set-Content -Path $NodeClone.Config
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
    Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
    if ($vmnet)
        {
         Write-Verbose "Configuring NIC 0 for $vmnet"
         Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config 
         Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config 
         Write-Verbose "Disconnecting Nic1 and Nic2"
         Disconnect-VMXNetworkAdapter -Adapter 1 -config $NodeClone.Config
         Disconnect-VMXNetworkAdapter -Adapter 2 -config $NodeClone.Config

        }
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"

    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname Scaleio -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    Write-Verbose "Starting ScalioNode$Node"
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName
    $ip="$subnet.19$Node"
     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")


    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $Scriptblock = "echo 'default "+$subnet+".103 - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose  | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+".local\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $Scriptblock = "echo '"+$Nodeprefix+$Node+"."+$BuildDomain+".local'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
    if ($sds.IsPresent)
        {
        Write-Verbose "trying SDS Install"
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-sds*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
        }

    if ($sdc.IsPresent)
        {
        Write-Verbose "trying SDC Install"
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-sdc*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
        }




    }




