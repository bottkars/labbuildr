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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-ubuntu.ps1
.EXAMPLE
.\install-Ubuntu.ps1
This will install 3 Ubuntu Nodes Ubuntu1 -Ubuntu3 from the Default Ubuntu Master

#>
[CmdletBinding(DefaultParametersetName = "defaults",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
####
####
	[ValidateSet('cinnamon','cinnamon-desktop-environment','xfce4','lxde','none')]
	[string]$Desktop = "none",
	[Switch]$docker,
	[ValidateSet('uifd','shipyard')]
	[string]$Container,
	[ValidateRange(1,9)]
	[int32]$Nodes=1,
	[int32]$Startnode = 1,
	[switch]$forcedownload,
#### generic labbuildr7
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
	$Masterpath = $Global:labdefaults.Masterpath,
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
	$Host_Name,
	[Parameter(Mandatory=$false)]
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
	#vmx param
	[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]
	$vmnet = $Global:labdefaults.vmnet,
	[int]$ip_startrange = 200,
	[switch]$use_aptcache = $true,
	[ipaddress]$non_lab_apt_ip,
	[switch]$do_not_use_lab_aptcache,
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
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
[int]$lab_apt_cache_ip = $ip_startrange
if ($use_aptcache.IsPresent)
	{
	if (!$do_not_use_lab_aptcache.IsPresent)
		{
		$apt_ip = "$subnet.$lab_apt_cache_ip"
		if (!($aptvmx = get-vmx aptcache -WarningAction SilentlyContinue))
			{
			Write-Host -ForegroundColor Magenta " ==>installing apt cache"
			.\install-aptcache.ps1 -ip_startrange $lab_apt_cache_ip -Size M -upgrade:$($upgrade.IsPresent)
			}
		}
	else
		{
		if (!$apt_ip)
			{
			Write-Warning "A apt ip address must be specified if uning do_not_use_labaptcache"
			}
		}
	Set-LABAPT_Cache_IP -APT_Cache_IP $apt_ip
	#rite-Host -ForegroundColor White " ==>Using cacher at $apt_ip"
	}
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot

if (!$DNS2)
    {
    $DNS2 = $DNS1
    }
$ip_startrange = $ip_startrange+$Startnode
$logfile = "/tmp/labbuildr.log"
switch ($ubuntu_ver)
    {
    "16_4"
        {
        $netdev = "ens160"
        }
    "15_10"
        {
        $netdev= "eno16777984"
        }
    default
        {
        $netdev= "eth0"
        }
    }
$Nodeprefix = "Ubuntu"
$Required_Master = "Ubuntu$ubuntu_ver"
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
####Build Machines#
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
        try
            {
			$Nodeclone = New-LabVMX -Masterpath $Masterpath -Ubuntu -Ubuntu_ver $ubuntu_ver -VMXname $Nodeprefix$Node -SCSI_DISK_COUNT $Disks -SCSI_Controller 0 -SCSI_Controller_Type lsisas1068 -SCSI_DISK_SIZE 100GB -vmnet $vmnet -Size $Size -ConnectionType custom -AdapterType vmxnet3 -Scenario 8 -Scenarioname "ubuntu" -activationpreference 1 -Displayname "$Nodeprefix$Node@$DNS_DOMAIN_NAME" 
            } 
        catch
            {
            Write-Warning "Error creating VM"
            return
            }
        If ($Node -eq 1){$Primary = $NodeClone}
        
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Ubuntu -Scenario 7
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName).tolower()
        }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }
    }
Write-Host -ForegroundColor White "Starting Node Configuration"
$installmessage = @()    
foreach ($Node in $machinesBuilt)
    {
        $ip="$subnet.$ip_startrange"
        $NodeClone = get-vmx $Node
		$Nodeclone | Set-LabUbuntuVMX -Ubuntu_ver $ubuntu_ver -Scriptdir $Scriptdir -Sourcedir $Sourcedir -DefaultGateway $DefaultGateway  -guestpassword $Guestpassword -Default_Guestuser $Default_Guestuser -Rootuser $rootuser -Hostkey $Hostkey -ip $ip -DNS1 $DNS1 -DNS2 $DNS2 -subnet $subnet -Host_Name $($Nodeclone.VMXname) -DNS_DOMAIN_NAME $DNS_DOMAIN_NAME
 
 ## docker       
		if ($docker)
            {
            Write-Host -ForegroundColor Gray " ==>installing latest docker engine"
            $Scriptblock="apt-get install apt-transport-https ca-certificates;sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D"
            Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
            
			switch ($ubuntu_ver)
				{
				'14_4'
					{
					$deb = "deb http://apt.dockerproject.org/repo ubuntu-trusty main"
					}
				'15_4'
					{
					$deb = "deb http://apt.dockerproject.org/repo ubuntu-jessie main"
					}
				'15_10'
					{
					$deb = "deb http://apt.dockerproject.org/repo ubuntu-wily main"
					}
				'16_4'
					{
					$deb = "deb http://apt.dockerproject.org/repo ubuntu-xenial main"
					}
				}
			
			$Scriptblock = "echo '$deb' >> /etc/apt/sources.list.d/docker.list;apt-get update;apt-get purge lxc-docker;apt-cache policy docker-engine"
			Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

			$Scriptblock = "apt-get install curl linux-image-extra-`$(uname -r) -y"
			Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
			$Scriptblock = "apt-get install docker-engine -y;service docker start;service docker status"
			Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile

			$Scriptblock = "curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-``uname -s``-``uname -m`` > /usr/local/bin/docker-compose;chmod +x /usr/local/bin/docker-compose"
		    Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
			$Scriptblock = "groupadd docker;usermod -aG docker $Default_Guestuser"
		    Write-Verbose $Scriptblock
            $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
			
			if ("shipyard" -in $container)
				{
				$Scriptblock = "curl -s https://shipyard-project.com/deploy | bash -s"
				Write-Verbose $Scriptblock
				$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
				$installmessage += " ==>you can use shipyard with http://$($ip):8080 with user admin/shipyard`n"

				}
			if ("uifd" -in $container)
				{
				$Scriptblock = "docker run -d -p 9000:9000 --privileged -v /var/run/docker.sock:/var/run/docker.sock uifd/ui-for-docker"
				Write-Verbose $Scriptblock
				$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
				$installmessage += " ==>you can use container uifd with http://$($ip):9000`n"
				}

			}
		## docker end
		###
        switch ($Desktop)
            {
                default
                {
				$Desktop = $Desktop.ToLower()
                Write-Host -ForegroundColor Gray " ==>downloading and configuring $Desktop as Desktop, this may take a while"
                $Scriptblock = "apt-get update;apt-get install -y $Desktop firefox lightdm xinit"
				Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile| Out-Null
				if ($Desktop -eq 'xfce4')
					{
					$Scriptblock = "apt-get install xubuntu-default-settings -y"
					#$Scriptblock = "/usr/lib/lightdm/lightdm-set-defaults --session xfce4-session"
					Write-Verbose $Scriptblock
					$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
					}
                Write-Host -ForegroundColor Gray " ==>enabling login manager"
                #$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                $Scriptblock = "systemctl enable lightdm"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $logfile | Out-Null
                }
            'none'
                {
                }
            }

        ####
		if ($Desktop -ne 'none')
			{
			Write-Host -ForegroundColor Gray " ==>reconfiguring vmwaretools, system will be ready after login manager restart"
			$Scriptblock = "/usr/bin/vmware-config-tools.pl -d;systemctl restart lightdm"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait| Out-Null
			}
        $ip_startrange++
    }
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White $installmessage
    






