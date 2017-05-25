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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///SolutionPacks#install-coprhd
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
[ValidateSet(
'master',
'release-2.4.1','release-2.4',
'release-3.0','release-3.0.0.1-sc',
'release-3.5',
'VIPR-3.5-GA','VIPR-3.1-GA','VIPR-3.0-GA','VIPR-3.0.0.2-GA','feature-COP-26740-openSUSE-42.2'
)]$branch = "master",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
$Node = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet(
'http://ftp.halifax.rwth-aachen.de/opensuse/',
'http://mirror.euserv.net/linux/opensuse',
'http://suse.mobile-central.org/',
'http://suse.mirrors.tds.net/pub/opensuse/',
'http://mirror.aarnet.edu.au/pub/opensuse/opensuse/',
'http://mirror.rackspace.co.uk/openSUSE/'
)]
$Static_mirror,
[switch]$cache_repo
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
        # Write-Host -ForegroundColor Gray " ==>No Masterpath specified, trying default"
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
$logfile = "/tmp/labbuildr.log"
#$OS = "OpenSUSE"
#$Required_Master = $OS
#if ($branch -match 'feature-COP-26740-openSUSE-42.2')
 #   {
        $Required_Master = 'openSUSE42_2'
        $OPENSUSE_VER = '42.2'
  #  }
#else 
#    {
#        $OPENSUSE_VER = '13.2'
#try
#    {
#    $MasterPath = Join-Path $MasterPath $OS
#    }        
#    catch [System.Management.Automation.MetadataException]
#        {
#        write-warning "no valid Path for $OS Specified, or $OS Master not in $MasterPath"
#        exit
#        }        
#    }

$Scenarioname = "Coprhd"


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

if ($branch -ne 'master')
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
        If (!(get-vmx $Nodename -WarningAction SilentlyContinue))
        {
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodename -clonepath $Builddir
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
        if ($vmnet)
            {
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue| Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 6144 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)

        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        $NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
        if ($OPENSUSE_VER -match '13.2')
        {
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | out-null 
        }
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir |Out-Null        
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -suse -device eth0 -Peerdns -DNS1 "$DNS1" -DNSDOMAIN "$BuildDomain.$custom_domainsuffix" -Hostname "$Nodename"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null

#        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -suse -device eno16777984 -Peerdns -DNS1 "$DNS1" -DNSDOMAIN "$BuildDomain.$custom_domainsuffix" -Hostname "$Nodename"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        # $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/rcnetwork restart" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        Write-Host -ForegroundColor Magenta " ==>Starting customization, all commands will be logged in $logfile on host, use tail -f $logfile on console/ssh"
		###  ssh section
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
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword   -logfile $Logfile

		$Scriptblock = "{ echo -n '$($NodeClone.vmxname) '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword   -logfile $Logfile

		$Scriptblock = "{ echo -n 'localhost '; cat /etc/ssh/ssh_host_rsa_key.pub; } >> ~/.ssh/known_hosts"
		Write-Verbose $Scriptblock
		$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword    -logfile $Logfile
		Write-Host -ForegroundColor Gray " ==>ssh configuration finished"     
		#### end ssh  
	    if ($cache_repo.ispresent)
            {
            $Scriptblock = "sed '\|# cachedir = /var/cache/zypp|icachedir = /mnt/hgfs/Sources/$OS/zypp/\n' /etc/zypp/zypp.conf -i"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
            }
		if ($Static_mirror)
			{

			$Scriptblock = "sed 's\http://download.opensuse.org/\$($Static_mirror)\g' /etc/zypp/repos.d/*.repo -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null

<#
			$Scriptblock = "sed '\|baseurl=http://download.opensuse.org/distribution/13.2/repo/oss/|ibaseurl = $Static_mirror/distribution/13.2/repo/oss/\n' /etc/zypp/repos.d/openSUSE-13.2-0.repo -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null

			$Scriptblock = "sed '\|baseurl=http://download.opensuse.org/distribution/13.2/repo/non-oss/|ibaseurl = $Static_mirror/distribution/13.2/repo/non-oss/\n' /etc/zypp/repos.d/repo-non-oss.repo -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null

			$Scriptblock = "sed '\|baseurl=http://download.opensuse.org/update/13.2/|ibaseurl = $Static_mirror/update/13.2/\n' /etc/zypp/repos.d/repo-update.repo -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
			
			$Scriptblock = "sed '\|baseurl=http://download.opensuse.org/update/13.2-non-oss/|ibaseurl = $Static_mirror/update/13.2-non-oss/\n' /etc/zypp/repos.d/repo-update-non-oss.repo -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
#>
			}
        $Scriptblock = "sudo zypper modifyrepo -k --all"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
    
        $Scriptblock = "sudo zypper ref"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null

        $Scriptblock = "zypper --non-interactive install --no-recommends git make gcc48 gcc-c++ acl ; echo $?"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
           
        $Scriptblock = "git clone -b $branch https://review.coprhd.org/scm/ch/coprhd-controller.git"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
		
        $Leap_Dir = '/coprhd-controller/packaging/appliance-images/openSUSE/42.2/'
        $Scriptblock = "rm -rf $Leap_Dir; git clone https://github.com/bottkars/coprHD_leap $Leap_Dir"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null


		if ($Static_mirror -match "halifax")
			{
			$Scriptblock = "sed 's\http://download.opensuse.org/\http://ftp.halifax.rwth-aachen.de/opensuse/\g' /coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHD/configure.sh -i"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null

			}

		#$Scriptblock = "zypper --non-interactive --no-gpg-checks install --details --no-recommends --force-resolution java-1_8_0-openjdk java-1_8_0-openjdk-devel gcc-c++"
		#Write-Verbose $Scriptblock
		#$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null


        Write-Host -ForegroundColor Gray " ==>Running Installation Tasks"
		$Components = ('installRepositories','installPackages','installJava 8','installStorageOS')# ,'enableStorageOS')
#        $Components = ('installRepositories','installPackages','installNginx','installJava 8','installStorageOS','enableStorageOS')
        Foreach ($component in $Components)
            {
            Write-Host -ForegroundColor Gray " ==>Running Task $component"
            $Scriptblock = "/coprhd-controller/packaging/appliance-images/openSUSE/$OPENSUSE_VER/CoprHD/configure.sh $component"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null       
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
    $Scriptname_fullpath = Join-Path $Scriptdir $Scriptname
    $Content | Set-Content -Path $Scriptname_fullpath
    convert-VMXdos2unix -Sourcefile $Scriptname_fullpath -Verbose
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptname_fullpath -targetfile "/etc/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    
    Write-Host -ForegroundColor Magenta " ==>Building CoprHD RPM"
    $Scriptblock = "cd /coprhd-controller;make clobber BUILD_TYPE=oss rpm"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword  -logfile $logfile| Out-Null
    
    Write-Host -ForegroundColor Magenta " ==>Installing CoprHD RPM"
    $Scriptblock = "/bin/rpm -Uhv /coprhd-controller/build/RPMS/x86_64/storageos*.x86_64.rpm;/sbin/shutdown -r now"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword  -logfile $logfile -nowait| Out-Null
	$StopWatch.Stop()
	Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
    Write-host -ForegroundColor White "Installed CoprHD RPM
    StorageOS may take 5 Minutes to boot
    please Visit https://$ip for Configuration
    Login with root:ChangeMe
    For Console login use labbuildr:$($Guestpassword) and su
    A reboot may be required
    "
