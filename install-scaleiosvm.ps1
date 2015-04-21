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
#>
[CmdletBinding(DefaultParametersetName = "action")]
Param(
### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$ovapaPath,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername = "SIOMaster",
#### install parameters#
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$true)]
[String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$SCALEIOMasterPath,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "sdsonly",Mandatory=$true)][switch]$sds,
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][switch]$sdc,
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$configure,
[Parameter(ParameterSetName = "install",Mandatory=$False)][switch]$singlemdm
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($configure.IsPresent)
    {
    [switch]$sds = $true
    [switch]$sdc = $true
    }
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$mastername $ovapaPath $PSScriptRoot #
        }
     default
        {
        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
        $Guestuser = "root"
        $Guestpassword = "admin"
        $MDMPassword = "Password123!"
        $Disksize = "100GB"
        $scsi = 0
        $Nodeprefix = "ScaleIONode"
        If ($singlemdm.IsPresent)
            {
            Write-Warning "Single MDM installations with MemoryTweaking  are only for Test Deployments and Memory Contraints/Manager Laptops :-)"
            $mdm_ip="$subnet.191"
            }
        else
            {
            $mdm_ip="$subnet.191,$subnet.192"
            }
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
        If ($Node -eq 1){$Primary = $NodeClone}
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
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Scaleio -Scenario 6
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        if ($singlemdm.IsPresent -and $Node -ne 1)
            {
            Write-Warning "Tweaking memory for $Nodeprefix$Node"
            $memorytweak = $NodeClone | Set-VMXmemory -MemoryMB 1536
            } 
        Write-Verbose "Starting ScalioNode$Node"
        # Set-VMXVnet -Adapter 0 -vnet vmnet2
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName
        # $NodeClone | Set-VMXSharedFolderState -enabled
        $ip="$subnet.19$Node"
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
  <#      do
            {
            $Plist = $NodeClone | Get-VMXProcessesInGuest -gu $Guestuser -gp $Guestpassword 
            sleep 5
            }
        until
            ($Plist-match "sshd")
#>
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway "$subnet.103" -device eth0 -Peerdns -DNS1 "$subnet.10" -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node" -suse -rootuser $Guestuser -rootpassword $Guestpassword
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm --import /root/install/RPM-GPG-KEY-ScaleIO" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
        if (!($PsCmdlet.ParameterSetName -eq "sdsonly"))
            {
            if (($Node -in 1..2 -and (!$singlemdm)) -or ($Node -eq 1))
                {
                Write-Verbose "trying MDM Install"
                $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-mdm*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
                }
            
            if ($Node -eq 3)
                {
                if (!$singlemdm)
                    {
                 Write-Verbose "trying TB Install"
                    $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-tb*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
                    }
                Write-Verbose "trying Gateway Install"
                $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/jre-*-linux-x64.rpm"-Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
                $NodeClone | Invoke-VMXBash -Scriptblock "export GATEWAY_ADMIN_PASSWORD='Password123!';rpm -Uhv --nodeps  /root/install/EMC-ScaleIO-gateway*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null 
                Write-Verbose "Adding MDM to Gateway Server Config File"
                $sed = "sed -i -- 's/mdm.ip.addresses=\`"\`"/mdm.ip.addresses=$subnet.191,$Subnet.192\`"/g' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classesmore/gatewayUser.properties" 
                Write-Verbose $sed
                $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
                $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/scaleio-gateway restart" -Guestuser $Guestpassword -Guestpassword $Guestpassword -Verbose | Out-Null
                }
            Write-Verbose "trying LIA Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-lia*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
            }
        if ($sds.IsPresent)
            {
            Write-Verbose "trying SDS Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-sds*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
            }
        if ($sdc.IsPresent)
            {
            Write-Verbose "trying SDC Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_IP=$mdm_ip;rpm -Uhv /root/install/EMC-ScaleIO-sdc*.rpm" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose | Out-Null
            }
    }
if ($configure.IsPresent)
    {
    $mdmconnect = "scli --login --username admin --password $MDMPassword --mdm_ip $mdm_ip"
    $StoragePoolName = "Pool$BuildDomain"
    $SystemName = "ScaleIO@$BuildDomain"
    $ProtectionDomainName = "PD_$BuildDomain"
    if ($Primary)
        {
        Write-Verbose "We are now creating the ScaleIO Grid"
        $Primary | Invoke-VMXBash -Scriptblock "scli --add_primary_mdm --primary_mdm_ip $subnet.191 --mdm_management_ip $subnet.191 --accept_license" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose 
        $Primary | Invoke-VMXBash -Scriptblock "scli --login --username admin --password admin --mdm_ip $subnet.191;scli --set_password --old_password admin --new_password $MDMPassword  --mdm_ip $subnet.191" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose 
        if (!$singlemdm.IsPresent)
            {
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;scli --add_secondary_mdm --mdm_ip $subnet.191 --secondary_mdm_ip $subnet.192 --mdm_ip $subnet.191" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose 
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;scli --add_tb --tb_ip $subnet.193 --mdm_ip $subnet.191" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose 
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;scli --switch_to_cluster_mode --mdm_ip $subnet.191" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose
            }
        $sclicmd = "scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose
        $sclicmd = "scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose
        $sclicmd = "scli --rename_system --new_name $SystemName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose
        }#end Primary
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            $sclicmd = "scli --add_sds --sds_ip $subnet.19$Node --device_path /dev/sdb --device_name /dev/sdb  --sds_name ScaleIONode$Node --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $Guestuser -Guestpassword $Guestpassword -Verbose
            }
    }

write-Warning "Login to the VM´s with root/admin"
}#end install

}#end switch 



