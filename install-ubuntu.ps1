<#
.Synopsis
   .\install-ubuntu.ps1 
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
.\install-Ubuntu.ps1
This will install 3 Ubuntu Nodes UbuntuNode1 -UbuntuNode3 from the Default Ubuntu Master , in the Default 192.168.2.0 network, IP .221 - .223

#>
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\Ubuntu15_Master',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[int32]$Nodes=3,
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
     $Sourcedir = $labdefaults.Sourcedir
     $DefaultGateway = $labdefaults.DefaultGateway
     $DNS1 = $labdefaults.DNS1
     }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
[uint]$Disksize = 100GB
$scsi = 0
$Nodeprefix = "Ubuntu15Node"
<#
##### cecking for linux binaries
$url = "ftp://ftp.emc.com/Downloads/ScaleIO/ScaleIO_RHEL6_Download.zip"
write-warning "Checking for Downloaded RPM Packages"
if (!($rpmpath  = Get-ChildItem -Path "$Sourcedir\ScaleIO\" -Recurse -Filter "*.el7.x86_64.rpm" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
    {
    write-warning "Checking for Downloaded Package"
    $Uri = "http://www.emc.com/products-solutions/trial-software-download/scaleio.htm"
    $request = Invoke-WebRequest -Uri $Uri -UseBasicParsing
    $DownloadLinks = $request.Links | where href -match "linux"
    foreach ($Link in $DownloadLinks)
        {
        $Url = $link.href
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$FileName) -or $forcedownload.IsPresent)
            {
                        $ok = Get-labyesnoabort -title "Could not find $Filename, we need to dowload from www.emc.com" -message "Should we Download $FileName from ww.emc.com ?" 
                        switch ($ok)
                            {

                            "0"
                                {
                                Write-Verbose "$FileName not found, trying Download"
                                if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -Defaultcredentials))
                                    { 
                                    write-warning "Error Downloading file $Url, Please check connectivity"
                                    Remove-Item -Path $Sourcedir\$FileName -Verbose
                                    }
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
            Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\ScaleIO\"
        }
}
$SIOGatewayrpm = Get-ChildItem -Path "$Sourcedir\ScaleIO\" -Recurse -Filter "EMC-ScaleIO-gateway-*noarch.rpm" -ErrorAction SilentlyContinue
$SIOGatewayrpm = $SIOGatewayrpm[-1].FullName
$SIOGatewayrpm = $SIOGatewayrpm.Replace($Sourcedir,"/mnt/hgfs/Sources")
$SIOGatewayrpm = $SIOGatewayrpm.Replace("\","/")
#>
if (!($MasterVMX = get-vmx -path $MasterPath))
    {
    Write-Warning "no Ubuntu Master found
    please download Ubuntu Master to $Sourcedir\Ubuntu15_Master"
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
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Ubuntu -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $CDDisconnect = $NodeClone | Connect-VMXcdromImage -Contoller SATA -connect:$False
        Write-Verbose "Starting UbuntuNode$Node"
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
        $ip="$subnet.22$($Node[-1])"
        $NodeClone = get-vmx $Node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled # | Out-Null
        # $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources # | Out-Null
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
        $Scriptblock = "systemctl disable iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
    
        ##### selectiung fastest apt mirror
        ## sudo netselect -v -s10 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep 
        
        <#
        $Scriptblock = "systemctl stop iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        #>


        $Scriptblock = "echo 'auto lo' > /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


        $Scriptblock = "echo 'iface lo inet loopback' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword


        $Scriptblock = "echo 'auto eth0' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'iface eth0 inet static' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'address $ip' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'gateway $DefaultGateway' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'netmask 255.255.255.0' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'network $subnet.0' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "echo 'broadcast $subnet.255' >> /etc/network/interfaces"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        $Scriptblock = "/etc/init.d/networking restart"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

        if ($node[-1] -eq "3" -and $SIOGateway.ispresent)
            {
            $Scriptblock = "yum install jre -y"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/yum-jre.log
            
            $Scriptblock = "export GATEWAY_ADMIN_PASSWORD='Password123!';rpm -Uhv --nodeps $SIOGatewayrpm"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile /tmp/SIOGateway.log
            } 

    
    
    }
    write-Warning "Login to the VM´s with root/Password123!"
    






