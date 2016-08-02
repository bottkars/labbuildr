<#
.Synopsis
   .\install-scaleio.ps1 
.DESCRIPTION
  install-centos7_4scaleio is  the a vmxtoolkit solutionpack for configuring and deploying centos VM´s for ScaleIO Implementation
      
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
   https://github.com/bottkars/labbuildr/wiki/install-centos.ps1
.EXAMPLE
.\install-centos7_4scaleio.ps1 -Defaults
This will install 3 Centos Nodes CentOSNode1 -CentOSNode3 from the Default CentOS7 Master , in the Default 192.168.2.0 network, IP .221 - .223

#>
[CmdletBinding(DefaultParametersetName = "defaults",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)]
[switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateRange(1,3)]
[int32]$Disks = 1,
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('7')]
[string]$centos_ver = "7",
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('cinnamon','none')]
[string]$Desktop = "none",
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateRange(1,9)]
[int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[int32]$Startnode = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })]
[ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")]
[string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[ValidateSet('vmnet1', 'vmnet2','vmnet3')]
$vmnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ })]
$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "install",Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$forcedownload,
[int]$ip_startrange = 205,
[Switch]$docker,
[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL"
)
#requires -version 3.0
#requires -module vmxtoolkit
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "Scripts"
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
    try
        {
        $Masterpath = $LabDefaults.Masterpath
        }
    catch
        {
        # Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
        $Masterpath = $Builddir
        }
     $Hostkey = $labdefaults.HostKey
     $Gateway = $labdefaults.Gateway
     $DefaultGateway = $labdefaults.Defaultgateway
     $DNS1 = $labdefaults.DNS1
     $DNS2 = $labdefaults.DNS2
    }
if (!$DNS2)
    {
    $DNS2 = $DNS1
    }

if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}

if (!$Masterpath) {$Masterpath = $Builddir}

$ip_startrange = $ip_startrange+$Startnode
$OS = "Centos$centos_ver"
switch ($centos_ver)
    {
    "7"
        {
        $netdev = "eno16777984"
        $Required_Master = "$OS Master"
        }
    default
        {
        $netdev= "eno16777984"
        $Required_Master = $OS
        }
    }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestuser = "labbuildr"
$Guestpassword = "Password123!"
[uint64]$Disksize = 100GB
$scsi = 0
$Nodeprefix = "Centos"
try
    {
    $yumcachedir = join-path -Path $Sourcedir "$OS\cache\yum" -ErrorAction stop
    }
catch [System.Management.Automation.DriveNotFoundException]
    {
    write-warning "Sourcedir not found. Stick not inserted ?"
    break
    }

#$mastervmx = test-labmaster -Master $Required_Master -MasterPath $MasterPath -Confirm:$Confirm

###### checking master Present
try
    {
    $MasterVMX = test-labmaster -Masterpath $MasterPath -Master $Required_Master -Confirm:$Confirm -erroraction stop
    }
catch
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
##
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
####Build Machines###### cecking for linux binaries
####Build Machines#
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
        Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        Write-Host -ForegroundColor Gray "==>Creating $Nodeprefix$node"
        try
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node # -clonepath $Builddir
            }
        catch
            {
            Write-Warning "Error creating VM"
            return
            }
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Host -ForegroundColor Gray " ==> Tweaking Config"
        Write-Host -ForegroundColor Gray " ==> Creating Disks"
        foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
            Write-Host -ForegroundColor Gray " ==> Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Host -ForegroundColor Gray " ==> Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        Write-Host -ForegroundColor Gray " ==> Setting NIC0 to HostOnly"
        $Netadapter = Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
        if ($vmnet)
            {
            Write-Host -ForegroundColor Gray " ==> Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }

        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        if ($node -eq 3)
            {
            Write-Host -ForegroundColor Gray " ==> Setting Gateway Memory to 3 GB"
            $NodeClone | Set-VMXmemory -MemoryMB 3072 | Out-Null
            }
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname CentOS -Scenario 7
        Write-Host -ForegroundColor Gray "setting vM size to $Size"
        $mysize = $NodeClone |Set-VMXSize -config $NodeClone.Config -Size $Size

        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        Write-Host -ForegroundColor Gray " ==> Starting CentosNode$Node"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
    }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }
    }
Write-Host -ForegroundColor White "Starting Node Configuration"
foreach ($Node in $machinesBuilt)
    {
        $ip="$subnet.$ip_startrange"
        $NodeClone = get-vmx $Node
        Write-Host -ForegroundColor Gray " ==> Waiting for $node to boot"

        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Host -ForegroundColor Gray " ==> Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
        Write-Host -ForegroundColor Gray " ==> Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null

        $Scriptblock = "systemctl disable iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    
        $Scriptblock = "systemctl stop iptables.service"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            
        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null
    
        if ($Hostkey)
            {
            $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }

        $Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        If ($DefaultGateway)
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device $netdev -Peerdns -DNS1 $DNS1 -DNS2 $DNS2 -DNSDOMAIN "$BuildDomain.$Custom_DomainSuffix" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        else
            {
            $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $ip -device $netdev -Peerdns -DNS1 $DNS1 -DNS2 $DNS2 -DNSDOMAIN "$BuildDomain.$Custom_DomainSuffix" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
            }
        $Scriptblock = "rm /etc/resolv.conf;systemctl restart network"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  | Out-Null

        Write-Host -ForegroundColor Cyan " ==>Testing default Route, make sure that Gateway is reachable ( install and start OpenWRT )
        if failures occur, open a 2nd labbuildr windows and run start-vmx OpenWRT "
   
        $Scriptblock = "DEFAULT_ROUTE=`$(ip route show default | awk '/default/ {print `$3}');ping -c 1 `$DEFAULT_ROUTE"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile     
        ### preparing yum
        $file = "/etc/yum.conf"
        $Property = "cachedir"
        $Scriptblock = "grep -q '^$Property' $file && sed -i 's\^$Property=/var*.\$Property=/mnt/hgfs/Sources/$OS/\' $file || echo '$Property=/mnt/hgfs/Sources/$OS/yum/`$basearch/`$releasever/' >> $file"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        $file = "/etc/yum.conf"
        $Property = "keepcache"
        $Scriptblock = "grep -q '^$Property' $file && sed -i 's\$Property=0\$Property=1\' $file || echo '$Property=1' >> $file"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        Write-Host -ForegroundColor Gray " ==>Generating Yum Cache on $Sourcedir"
        $Scriptblock="yum makecache"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        Write-Host -ForegroundColor Gray " ==>INSTALLING VERSIONLOCK"
        $Scriptblock="yum install yum-plugin-versionlock -y"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
    
        Write-Host -ForegroundColor Gray " ==>locking vmware tools"
        $Scriptblock="yum versionlock open-vm-tools"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

        #Write-Host -ForegroundColor Gray " ==> Installing Required RPM´s on $Nodeprefix$Node_num"
        # $Scriptblock = "yum install $requires -y"
        #Write-Verbose $Scriptblock
        #$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/yum-requires.log | Out-Null
    
    #yum groupinstall "X Window system"
        if ($docker)
            {
            Write-Host -ForegroundColor Gray " ==>installing latest docker engine"
            $Scriptblock="curl -fsSL https://get.docker.com | sh;systemctl enable docker; systemctl start docker;usermod -aG docker stack"
            Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
            }
        if ($Desktop -ne "none")
            {
            Write-Host -ForegroundColor Gray " ==> Installing X-Windows environment"
            $Scriptblock = "yum groupinstall -y `'X Window system'"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }
        switch ($Desktop)
            {
                'cinnamon'
                {
                Write-Host -ForegroundColor Gray " ==> adding EPEL Repo"
                $Scriptblock = 'rpm -i http://dl.fedoraproject.org/pub/epel/x86_64/e/epel-release-7-7.noarch.rpm'
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                
                Write-Host -ForegroundColor Gray " ==> Installing Display Manager"
                $Scriptblock = "yum install -y lightdm cinnamon gnome-desktop3 xdm firefox"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

                $Scriptblock = "yum groupinstall gnome -y"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

                $Scriptblock = "systemctl isolate graphical.target>> /tmp/lightdm.log"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                
                $Scriptblock = "systemctl set-default graphical.target"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                
                $Scriptblock = "rm '/etc/systemd/system/default.target'"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                
                
                $Scriptblock = "ln -s '/usr/lib/systemd/system/graphical.target' '/etc/systemd/system/default.target'"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

                }
            default
                {

                }
    
        }
    $Scriptblock = "/usr/bin/vmware-config-tools.pl -d;shutdown -r now"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait| Out-Null


    }#end machines

$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
write-Host -ForegroundColor White "Login to the VM´s with root/Password123!"
    
