<#
.Synopsis
   .\install-scaleiosvm.ps1 
.DESCRIPTION
  install-scaleiosvm is  the a vmxtoolkit solutionpack for configuring and deploying scaleio svm´s
      
      Copyright 2016 Karsten Bott

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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-coprhddevkit 
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "import")]
Param(
### import parameters
<# for the Import, we specify the Path to the Sources. 
Sources are the Root of the Extracted ScaleIO_VMware_SW_Download.zip
If not available, it will be downloaded from http://www.emc.com/scaleio
The extracte OVA will be dehydrated to a VMware Workstation Master #>
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$forcedownload,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$noextract,
[Parameter(ParameterSetName = "import",Mandatory=$true)][switch]$import,

#### install parameters#
<# The ScaleIO Master created from -sourcedir  #>
[Parameter(ParameterSetName = "defaults",Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[String]$CoprHD_DevKit = ".\CoprHDDevKit-*",
<# Starting Node #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
<# Name of the domain, .local added#>
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",

<# VMnet to use#>
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$vmnet = "vmnet2",
<# Configure automatically configures the Scalio Cluster and will always install 3 Nodes !  #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$configure,
<# Use labbuildr Defaults.xml #>
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
<# Path to a Defaults.xml #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
)
#requires -version 3.0
#requires -module vmxtoolkit
#requires -module labtools
if ($configure.IsPresent)
    {
    }
If ($Defaults.IsPresent)
    {
     $labdefaults = Get-labDefaults
     $vmnet = $labdefaults.vmnet
     $subnet = $labdefaults.MySubnet
     $BuildDomain = $labdefaults.BuildDomain
     $Sourcedir = $labdefaults.Sourcedir
     $DefaultGateway = $labdefaults.DefaultGateway
     $Sourcedir = $labdefaults.Sourcedir
     }

switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        Try 
            {
            test-Path $Sourcedir
            } 
        Catch 
            { 
            Write-Verbose $_ 
            Write-Warning "We need a Valid Sourcedir, trying Defaults"
            if (!($Sourcedir = (Get-labDefaults).Sourcedir))
                {
                exit
                }
            }
        if (!($OVAPath = Get-ChildItem -Path "$Sourcedir\CoprHD\$CoprHD_DevKit" -recurse -Filter "*.ova" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
            {
                    write-warning "Checking for Downloaded Package"
                    $Url = "devkit/ws/CH-coprhd-controller-coprhd-devkit/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/build/*zip*/build.zip"
                    $FileName = Split-Path -Leaf -Path $Url
                        if (!(test-path  $Sourcedir\$FileName) -or $forcedownload.IsPresent)
                        {
                                    
                        $ok = Get-labyesnoabort -title "Could not find $Filename, we need to dowload from www.emc.com" -message "Should we Download $FileName from ww.emc.com ?" 
                        switch ($ok)
                            {

                            "0"
                                {
                                Write-Verbose "$FileName not found, trying Download"
                                Get-LABHttpFile -SourceURL $URL -TarGetFile $Sourcedir\$FileName -verbose
                                $Downloadok = $true
                                }
                             "1"
                                {
                                break
                                }   
                             "2"
                                {
                                Write-Verbose "User requested Abort"
                                exit
                                }
                            }
                        
                        }

                        if ((Test-Path "$Sourcedir\$FileName") -and (!($noextract.ispresent)))
                            {
                            Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\ScaleIO\$ScaleIO_Path"
                            }
                        else
                            {
                            if (!$noextract.IsPresent)
                                {
                                exit
                                }
                            }
                        }
            

        }
           
        $OVAPath = Get-ChildItem -Path "$Sourcedir\ScaleIO\$ScaleIO_Path" -Recurse -Filter "*.ova"  -Exclude ".*" | Sort-Object -Descending
        $OVAPath = $OVApath[0]
        Write-Warning "Creating ScaleIO Master for $($ovaPath.Basename), may take a while"
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --name=$($ovaPath.Basename) $ovaPath.FullName $PSScriptRoot  #
        $MasterVMX = get-vmx -path ".\$($ovaPath.Basename)"
        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $MasterVMX | Set-VMXTemplate
            }
        }
     default
        {
        if (!(Test-Path $SCALEIOMaster))
            {
            Write-Warning "please run .\install-scaleiosvm.ps1 -Sourcedir [sourcedir] to download / create Master"
            exit
            }
        $Mastervmxlist = get-vmx $SCALEIOMaster | Sort-Object -Descending
        $MasterVMX = $Mastervmxlist[0]   
        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
        $rootuser = "root"
        $rootpassword = "admin"
        $MDMPassword = "Password123!"
        [uint64]$Disksize = 100GB
        $scsi = 0
        $Nodeprefix = "ScaleIONode"
        If ($configure.IsPresent -and $Nodes -lt 3)
            {
            Write-Warning "Configure Present, setting nodes to 3"
            $Nodes = 3
            }
        If ($singlemdm.IsPresent)
            {
            Write-Warning "Single MDM installations with MemoryTweaking  are only for Test Deployments and Memory Contraints/Manager Laptops :-)"
            $mdm_ip="$subnet.191"
            }
        else
            {
            $mdm_ip="$subnet.191,$subnet.192"
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
    Write-Verbose "Starting Avalanche..."
    Measure-Command -Expression {
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        if (!(get-vmx $Nodeprefix$node))
            {   
            write-verbose "Creating $Nodeprefix$node"

            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
            If ($Node -eq 1){$Primary = $NodeClone}
            $Config = Get-VMXConfig -config $NodeClone.config
            Write-Verbose "Tweaking Config"
            $Config = $config | ForEach-Object { $_ -replace "lsilogic" , "pvscsi" }
            $Config | set-Content -Path $NodeClone.Config
            Write-Verbose "Creating Disks"
            foreach ($LUN in (1..$Disks))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                Write-Verbose "Building new Disk $Diskname"
                $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI 
                }
            write-verbose "Setting NIC0 to HostOnly"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | out-null
            if ($vmnet)
                {
                Write-Verbose "Configuring NIC 0 for $vmnet"
                Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config | out-null
                Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | out-null
                Write-Verbose "Disconnecting Nic1 and Nic2"
                Disconnect-VMXNetworkAdapter -Adapter 1 -config $NodeClone.Config | out-null
                Disconnect-VMXNetworkAdapter -Adapter 2 -config $NodeClone.Config | out-null
                }
            $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
                $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false

            $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$rootuser" -Line2 "rootpasswd:$rootpassword" -Line3 "mdmuser:admin" -Line4 "mdmpassword:$MDMPassword" -Line5 "labbuildr by @hyperv_guy" -builddate
 
            $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Scaleio -Scenario 6
            $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
            if ($singlemdm.IsPresent -and $Node -ne 1)
                {
                write-host "Tweaking memory for $Nodeprefix$Node"
                $memorytweak = $NodeClone | Set-VMXmemory -MemoryMB 1536
                } 
            Write-Verbose "Starting ScalioNode$Node"
            # Set-VMXVnet -Adapter 0 -vnet vmnet2
            start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | out-null
            # $NodeClone | Set-VMXSharedFolderState -enabled
            }
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
                if ($configure.IsPresent)
                    {
                    Write-Warning "Please Delete VM´s First, use 
                    'get-vmx $Nodeprefix$Node | remove-vmx'
to remove the Machine or
                    'get-vmx $Nodeprefix | remove-vmx' 
to remove all Nodes"
                    exit
                    }


            }

}

write-host "Installing ScaleIO Components, could take 2 Minutes"
$Logfile = "/tmp/install_sio.log"
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        write-host "Installing ScaleIO Components on $Nodeprefix$node"
        $ip="$subnet.19$Node"
        $NodeClone = get-vmx $Nodeprefix$node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        If (!$DefaultGateway) {$DefaultGateway = $Ip}
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eth0 -Peerdns -DNS1 "$subnet.10" -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node" -suse -rootuser $rootuser -rootpassword $rootpassword 
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm --import /root/install/RPM-GPG-KEY-ScaleIO" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
        if (!($PsCmdlet.ParameterSetName -eq "sdsonly"))
            {
            if (($Node -in 1..2 -and (!$singlemdm)) -or ($Node -eq 1))
                {
                Write-Verbose "trying MDM Install"
                $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-mdm*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                }
            
            if ($Node -eq 3)
                {
                Write-Verbose "trying Gateway Install"
                $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/jre-*-linux-x64.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                $NodeClone | Invoke-VMXBash -Scriptblock "export SIO_GW_KEYTOOL=/usr/java/default/bin/;export GATEWAY_ADMIN_PASSWORD='Password123!';rpm -Uhv --nodeps  /root/install/EMC-ScaleIO-gateway*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                if (!$singlemdm)
                    {
                    Write-Verbose "trying TB Install"
                    $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-tb*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                    Write-Verbose "Adding MDM to Gateway Server Config File"
                    $sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$subnet.191;$Subnet.192\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties" 
                    }
                else
                    {
                    Write-Verbose "Adding MDM to Gateway Server Config File"
                    $sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$subnet.191;$Subnet.191\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties" 
                    }
                Write-Verbose $sed
                $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/scaleio-gateway restart" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
                }
            Write-Verbose "trying LIA Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-lia*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }
        if ($sds.IsPresent)
            {
            Write-Verbose "trying SDS Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-sds*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }
        if ($sdc.IsPresent)
            {
            Write-Verbose "trying SDC Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_IP=$mdm_ip;rpm -Uhv /root/install/EMC-ScaleIO-sdc*.rpm" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }
    }
if ($configure.IsPresent)
    {
    Write-Output "Configuring ScaleIO"
    $Logfile = "/tmp/configure_sio.log"
    write-host "Configuring ScaleIO"
    $mdmconnect = "scli --login --username admin --password $MDMPassword --mdm_ip $mdm_ip"
    $StoragePoolName = "Pool$BuildDomain"
    $SystemName = "ScaleIO@$BuildDomain"
    $ProtectionDomainName = "PD_$BuildDomain"
    if ($Primary)
        {
        Write-Verbose "We are now creating the ScaleIO Grid"
        $sclicmd =  "scli --add_primary_mdm --primary_mdm_ip $subnet.191 --mdm_management_ip $subnet.191 --accept_license"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile

        $sclicmd =  "scli --login --username admin --password admin --mdm_ip $subnet.191;scli --set_password --old_password admin --new_password $MDMPassword  --mdm_ip $subnet.191"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile

        if (!$singlemdm.IsPresent)
            {
            $sclicmd = "$mdmconnect;scli --add_secondary_mdm --mdm_ip $subnet.191 --secondary_mdm_ip $subnet.192 --mdm_ip $subnet.191"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile 
            
            $sclicmd = "$mdmconnect;scli --add_tb --tb_ip $subnet.193 --mdm_ip $subnet.191"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            
            $sclicmd = "$mdmconnect;scli --switch_to_cluster_mode --mdm_ip $subnet.191"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }
        $sclicmd = "scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
        $sclicmd = "scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
        $sclicmd = "scli --rename_system --new_name $SystemName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
        }#end Primary
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            $sclicmd = "scli --add_sds --sds_ip $subnet.19$Node --device_path /dev/sdb --device_name /dev/sdb  --sds_name ScaleIONode$Node --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $rootpassword -logfile $Logfile
            }
    write-host "Connect with ScaleIO UI to $subnet.191 admin/Password123!"
    }

write-host "Login to the VM´s with root/admin"

}#end measuer
} #end default
}#end switch 



