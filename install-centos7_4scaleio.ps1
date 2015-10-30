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
.\install-centos4scaleio.ps1
This will install 3 Centos Nodes CentOSNode1 -CentOSNode3 from the Default CentOS Master , in the Default 192.168.2.0 network, IP .221 - .223

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
[ValidateRange(1,9)][int32]$Nodes=3,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[int32]$Startnode = 1,

<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$forcedownload,
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$SIOGateway
)
#requires -version 3.0
#requires -module vmxtoolkit
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
    $DefaultGateway = $labdefaults.DefaultGateway
    $DNS1 = $labdefaults.DNS1
    $Hostkey = $labdefaults.HostKey
    }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
[uint64]$Disksize = 100GB
$scsi = 0
$Nodeprefix = "CentOS7Node"
$ScaleIO_OS = "Linux"
$ScaleIO_Path = "ScaleIO_$($ScaleIO_OS)_SW_Download"
$Node_requires = "numactl libaio"
$MDM_Requires = "mutt bash-completion python"
$Gateway_Requires = "jre"

##### cecking for linux binaries
write-warning "Checking for Downloaded RPM Packages"
if (!($rpmpath  = Get-ChildItem -Path "$Sourcedir\ScaleIO\$ScaleIO_Path" -Recurse -Filter "*.el7.x86_64.rpm" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
    {
    write-warning "Checking for Downloaded Package"
    $Uri = "http://www.emc.com/products-solutions/trial-software-download/scaleio.htm"
    $request = Invoke-WebRequest -Uri $Uri -UseBasicParsing
    $DownloadLinks = $request.Links | where href -match $ScaleIO_OS
    foreach ($Link in $DownloadLinks)
        {
        $Url = $link.href
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$FileName) -or $forcedownload.IsPresent)
            {
                        $ok = Get-labyesnoabort -title "Could not find $Filename, we need to dowload from www.emc.com" -message "Should we Download $FileName from www.emc.com ?" 
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
        Else
            {
            Write-Warning "Found $Sourcedir\$FileName, using this one unless -forcedownload is specified ! "
            }
        }
    if (Test-Path "$Sourcedir\$FileName")
        {
            Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\ScaleIO\$ScaleIO_Path"
        }
}
$SIOGatewayrpm = Get-ChildItem -Path "$Sourcedir\ScaleIO\" -Recurse -Filter "EMC-ScaleIO-gateway-*noarch.rpm"  -Exclude ".*" -ErrorAction SilentlyContinue
$SIOGatewayrpm = $SIOGatewayrpm[-1].FullName
$Sourcedir = $Sourcedir.Replace("\","\\")
Write-Verbose $SIOGatewayrpm
Write-Verbose $Sourcedir

$SIOGatewayrpm = $SIOGatewayrpm -replace  $Sourcedir,"/mnt/hgfs/Sources"
$SIOGatewayrpm = $SIOGatewayrpm.Replace("\","/")
Write-Verbose $SIOGatewayrpm
if (!($MasterVMX = get-vmx -path $MasterPath))
    {
    Write-Warning "no centos Master found
    please download Centos7 Master to $Sourcedir\Centos7"
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
        write-verbose " Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq 1){$Primary = $NodeClone}
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
        $Netadapter = Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
        if ($vmnet)
            {
            Write-Verbose "Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config  | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config   | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
            $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname CentOS -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        Write-Verbose "Starting CentosNode$Node"
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
        $Node_num = $node -replace $Nodeprefix
        $ip="$subnet.22$($Node[-1])"
        $NodeClone = get-vmx $Node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $Scriptblock = "systemctl disable iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    
        $Scriptblock = "systemctl stop iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


        If ($DefaultGateway)
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        else
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $ip -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        Write-Verbose "Nodenumber : $Node_num"
        Switch ($Node_num)
            {
            {$_ -in (1,2)}
                {
                $requires = "$Node_requires $MDM_Requires"
                }
            "3"
                {
                $requires = "$Node_requires $Gateway_Requires"
                }
            default
                {
                $requires = "$Node_requires"
                }
            }
        $Scriptblock = "yum install $requires -y"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/yum-requires.log
    
        if ($node[-1] -eq "3" -and $SIOGateway.ispresent)
            {
            $Scriptblock = "export GATEWAY_ADMIN_PASSWORD='Password123!';rpm -Uhv --nodeps $SIOGatewayrpm"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile /tmp/SIOGateway.log
            } 

    
    
    }
    write-Warning "Login to the VM´s with root/Password123!"
    






