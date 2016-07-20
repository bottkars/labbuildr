<#
.Synopsis
   .\install-coprhd.ps1 
.DESCRIPTION
  install-coprhd is  the a labbuildr solutionpack for compiling  and deploying CoprHD Controller
      
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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-coprhd
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "defaults",
SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
#[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]$Sourcedir,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
$MasterPath,
<#Specify desired branch#>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('release-2.4-coprhd','master','INTEGRATION-YODA-FOUNDATION','INTEGRATION-2.4.1-FOUNDATION','integration-2.4.1')]$branch = "master",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
$Node = 1
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "24"
$Builddir = $PSScriptRoot
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
	if ($LabDefaults.custom_domainsuffix)
		{
		$custom_domainsuffix = $LabDefaults.custom_domainsuffix
		}
	else
		{
		$custom_domainsuffix = "local"
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
if (!$Masterpath) {$Masterpath = $Builddir}

$ip_startrange = $ip_startrange+$Startnode
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$OS = "OpenSUSE"
$Required_Master = $OS
$Scenarioname = "Coprhd"
try
    {
    $MasterPath = Join-Path $MasterPath $OS
    }        
catch [System.Management.Automation.MetadataException]
        {
        write-warning "no valid Path for $OS Specified, or $OS Master not in $MasterPath"
        exit
        }

$Nodeprefix = "$($Scenarioname)Node"
# $release = $release.tolower()
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = $Scenarioname.ToLower()
$Scriptdir = "$Sourcedir\$($Scenarioname.ToLower())"

if (!$Sourcedir)
    {
    Write-Warning "no Sourcedir specified, will exit now"
    exit
    }
else
    {
    Write-Host -ForegroundColor Gray " ==>Checking for $Sourcedir"
    try
        {
        Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null 
        }
        catch
        [System.Management.Automation.DriveNotFoundException] 
        {
        Write-Warning "Received Drive not found, make sure to have your Source Stick/Disk connected"
        exit
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
        write-host -ForegroundColor Magenta "no sources directory found named $Sourcedir, creating now"
        $newsourcedir =New-Item -ItemType Directory -Path $Sourcedir -Force 
        }
    }

if ($branch -eq 'release-2.4-coprhd')
    {
    $IP = "$subnet.14"
    $Nodename = "CoprHD_Release"
    } 
else
    {
    $ip = "$subnet.245"
    $Nodename = "CoprHD_Develop"
    }

[uint64]$Disksize = 100GB
$scsi = 0

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
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
if (!(Test-path $Scriptdir ))
    {
    $CoprHD_Dir = New-Item -ItemType Directory $Scriptdir -Force
    }

	    Write-Host -ForegroundColor Magenta "Checking for $Nodename"
        If (!(get-vmx $Nodename -WarningAction SilentlyContinue))
        {
        write-host -ForegroundColor White " ==>Creating $Nodename"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodename -clonepath $Builddir
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Host -ForegroundColor Gray " ==>Tweaking Config"
        Write-Host -ForegroundColor Gray " ==>Setting NIC0 to HostOnly"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
        if ($vmnet)
            {
            Write-Host -ForegroundColor Gray " ==>Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue| Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @hyperv_guy" -builddate
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
        # $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        Write-Host -ForegroundColor Gray " ==>Setting VM Size"
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 6144 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        
        write-host -ForegroundColor Magenta "Starting Virtual Machine $($NodeClone.CloneName)"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)

        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Host -ForegroundColor Gray " ==>Setting Shared Folders enabled"
        $NodeClone | Set-VMXSharedFolderState -enabled |Out-Null
        Write-Host -ForegroundColor Gray " ==>Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | out-null 
        Write-Host -ForegroundColor Gray " ==>Adding $Sourcedir to Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir |Out-Null
        Write-Host -ForegroundColor Gray " ==>Configuring Network with $IP for $Nodename"
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -suse -device eno16777984 -Peerdns -DNS1 "$DNS1" -DNSDOMAIN "$BuildDomain.$custom_domainsuffix" -Hostname "$Nodename"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        Write-Host -ForegroundColor Gray " ==>Restarting Network, please be patient"
        $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/rcnetwork restart" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        
		###  ssh section
		Write-Host -ForegroundColor Gray " ==>Configuring SSH Access"
		$Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile  

		if ($Hostkey)
				{
				$Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
				Write-Verbose $Scriptblock
				$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword
				}

		$Scriptblock = "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;chmod 0600 /root/.ssh/authorized_keys"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword   # -logfile $Logfile

		$Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword   # -logfile $Logfile

		$Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword   # -logfile $Logfile
		Write-Host -ForegroundColor Gray " ==>ssh configuration finished"     
		#### end ssh  
	
		Write-Host -ForegroundColor Gray " ==>Starting zypper Tasks, this may take a while"
        $Scriptblock = "sed '\|# cachedir = /var/cache/zypp|icachedir = /mnt/hgfs/Sources/$OS/zypp/\n' /etc/zypp/zypp.conf -i"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "sudo zypper modifyrepo -k --all"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

    
        $Scriptblock = "sudo zypper ref"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

        $Scriptblock = "zypper --non-interactive install --no-recommends git make; echo $?"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/zypper.log" | Out-Null

           
        Write-Host -ForegroundColor Gray " ==>Cloning into CoprHD"
        $Scriptblock = "git clone https://review.coprhd.org/scm/ch/coprhd-controller.git"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/git_clone.log" | Out-Null
		

        Write-Host -ForegroundColor Gray " ==>Running Installation Tasks"
        $Components = ('installRepositories','installPackages','installNginx','installJava 8','installStorageOS')
        Foreach ($component in $Components)
            {
            Write-Host -ForegroundColor Gray " ==> Running Task $component"
            $Scriptblock = "/coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh $component"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/$component.log"  | Out-Null       
            }
 
}
        else
        {
        Write-Warning "Machine $Nodename already exists"
        break
        }

    
    $Scriptname = "ovfenv.properties"
    $Content = "network_1_ipaddr6=::0
network_1_ipaddr=$ip
network_gateway6=::0
network_gateway=$DefaultGateway
network_netmask=255.255.255.0
network_prefix_length=64
network_vip6=::0
network_vip=$ip
node_count=1
node_id=vipr1"

    $Content | Set-Content -Path $Scriptdir\$Scriptname
    convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/etc/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    Write-Host -ForegroundColor Magenta " ==> Building CoprHD RPM"

    $Scriptblock = "cd /coprhd-controller;make clobber BUILD_TYPE=oss rpm &> /tmp/build_coprhd.log"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
    Write-Host -ForegroundColor Magenta " ==> Installing CoprHD RPM"
    $Scriptblock = "/bin/rpm -Uhv /coprhd-controller/build/RPMS/x86_64/storageos*.x86_64.rpm" #;/sbin/shutdown -r now"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword   | Out-Null
	$StopWatch.Stop()
	Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
    Write-Host -ForegroundColor Blue "Installed CoprHD RPM
    StorageOS may take 5 Minutes to boot
    please Visit https://$ip for Configuration
    Login with root:ChangeMe
    For Console login use labbuildr:$($Guestpassword) and su
    A reboot may be required
    "
