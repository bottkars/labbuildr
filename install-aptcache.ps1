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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-aptcache.ps1
.EXAMPLE
.\install-Ubuntu.ps1
This will install 3 Ubuntu Nodes Ubuntu1 -Ubuntu3 from the Default Ubuntu Master

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
	[Parameter(Mandatory = $false)]
	[ValidateRange(1,1)]
	[int32]$Disks = 1,
	[Parameter(Mandatory = $false)]
	[ValidateSet('16_4','15_10','14_4')]
	[string]$ubuntu_ver = "16_4",
	[Parameter(Mandatory=$false)]
	$Scriptdir = (join-path (Get-Location) "labbuildr-scripts"),
	[Parameter(Mandatory=$false)]
	$Sourcedir = $Global:labdefaults.Sourcedir,
	[Parameter(Mandatory=$false)]
	$DefaultGateway = $Global:labdefaults.DefaultGateway,
	[Parameter(Mandatory=$false)]
	$guestpassword = "Password123!",
	$Rootuser = 'root',
	$Hostkey = $Global:labdefaults.HostKey,
	$Default_Guestuser = 'labbuildr',
	[Parameter(Mandatory=$false)]
	$Subnet = $Global:labdefaults.MySubnet,
	[Parameter(Mandatory=$false)]
	$DNS1 = $Global:labdefaults.DNS1,
	[Parameter(Mandatory=$false)]
	$DNS2 = $Global:labdefaults.DNS2,
	[Parameter(Mandatory=$false)]
	$Host_Name = $VMXName,
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
	#vmx param
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
	$vmnet = $Global:labdefaults.vmnet,
	[int]$ip_startrange = 200,
	[switch]$upgrade,
	[switch]$Defaults
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
	[int]$SCSI_Controller = 0
	[int]$SCSI_DISK_COUNT = 0
	[Uint64]$SCSI_DISK_SIZE = 100GB
	$SCSI_Controller_Type = "pvscsi"
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "labbuildr-scripts"
$Masterpath = $Global:labdefaults.Masterpath

$logfile = "/tmp/labbuildr.log"
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
[uint64]$Disksize = 100GB
$scsi = 0
$Nodeprefix = "aptcache"
$Nodeprefix = $Nodeprefix.ToLower()
$OS = "Ubuntu"
$Required_Master = "$OS$ubuntu_ver"
$Default_Guestuser = "labbuildr"
$fqdn = "$Nodeprefix.$DNS_DOMAIN_NAME"
if (!($aptcacher = Get-VMX -VMXName $Nodeprefix -WarningAction SilentlyContinue))
	{
	$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
	$apt_cachedir = Join-Path $Sourcedir "apt-cacher-ng"
	if (!(Test-Path $apt_cachedir))
		{
		New-Item -ItemType Directory -Path $apt_cachedir | Out-Null
		}
	$Nodeclone = New-LabVMX -Masterpath $Masterpath -Ubuntu -Ubuntu_ver $ubuntu_ver -VMXname $Nodeprefix -SCSI_DISK_COUNT $Disks -SCSI_Controller 0 -SCSI_Controller_Type lsisas1068 -SCSI_DISK_SIZE 100GB -vmnet $vmnet -Size $Size -ConnectionType custom -AdapterType vmxnet3 -Scenario 8 -Scenarioname "ubuntu" -activationpreference 1 -Displayname $Nodeprefix 
	$ip="$subnet.$ip_startrange"
	If (!$DefaultGateway)
		{
		$DefaultGateway = $ip
		}
#	$Nodeclone | Set-LabUbuntuVMX -Ubuntu_ver $ubuntu_ver $Hostkey -ip $ip -Host_Name $Nodeprefix -DNS_DOMAIN_NAME $DNS_DOMAIN_NAME -DNS1 $DNS1 -DNS2 $DNS2
	$Nodeclone | Set-LabUbuntuVMX -Ubuntu_ver $ubuntu_ver -Scriptdir $Scriptdir -Sourcedir $Sourcedir -DefaultGateway $DefaultGateway  -guestpassword $Guestpassword -Default_Guestuser $Default_Guestuser -Rootuser $rootuser -Hostkey $Hostkey -ip $ip -DNS1 $DNS1 -DNS2 $DNS2 -subnet $subnet -Host_Name $Nodeprefix -DNS_DOMAIN_NAME $DNS_DOMAIN_NAME -use_aptcache:$false
	$packages = "apt-cacher-ng"
	$Scriptblocks = (
	"apt-get install $packages -y",
	"cat > /etc/apt/apt.conf.d/01proxy <<EOF
Acquire::http { Proxy `"http://$($ip):3142`"; };`
Acquire::https { Proxy `"https://$($ip):3142`"; };`
",
"cat > etc/apt-cacher-ng/zzz_override.conf <<EOF
CacheDir: /mnt/hgfs/Sources/apt-cacher-ng`
StupidFs: 1`
RequestAppendix: Cookie: oraclelicense=a`
PfilePattern = .*(\.d?deb|\.rpm|\.drpm|\.dsc|\.tar(\.gz|\.bz2|\.lzma|\.xz)(\.gpg|\?AuthParam=.*)?|\.diff(\.gz|\.bz2|\.lzma|\.xz)|\.jigdo|\.template|changelog|copyright|\.udeb|\.debdelta|\.diff/.*\.gz|(Devel)?ReleaseAnnouncement(\?.*)?|[a-f0-9]+-(susedata|updateinfo|primary|deltainfo).xml.gz|fonts/(final/)?[a-z]+32.exe(\?download.*)?|/dists/.*/installer-[^/]+/[0-9][^/]+/images/.*)$`
",
"systemctl restart apt-cacher-ng"
	)
foreach ($Scriptblock in $Scriptblocks)
	{
	$nodeclone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
	}
if ($upgrade.ispresent)
	{
	$Scriptblock = "apt-get update;DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=`"--force-confdef`" -o Dpkg::Options::=`"--force-confold`" dist-upgrade"
	$nodeclone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
	}
Set-LABAPT_Cache_IP -APT_Cache_IP $ip
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
}
else
	{
	Write-Host "Apt-Cacher already deployed"
	}