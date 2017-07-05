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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-centos.ps1
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "install",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
	[Parameter(Mandatory = $False)]
	[AllowNull()] 
    [AllowEmptyString()]
	[ValidateSet('cinnamon','none')]
	[string]$Desktop,
	[Parameter(Mandatory = $False)]
	[Switch]$docker,
	[Parameter(Mandatory = $false)]
	[ValidateSet('shipyard','uifd')][string[]]$container,
	[Parameter(Mandatory = $false)]
	[ValidateSet('influxdb','grafana')][string[]]$AdditionalPackages,
	[Parameter(ParameterSetName = "install",Mandatory=$False)]
	[ValidateRange(0,3)]
	[int]$SCSI_Controller = 0,
	[ValidateRange(0,5)]
	[int]$SCSI_DISK_COUNT = 0,
	[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('Centos7_3_1611','Centos7_1_1511','Centos7_1_1503')]
	[string]$centos_ver = 'Centos7_3_1611',
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[ValidateRange(1,4)]
	[int32]$Nodes=1,
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[int32]$Startnode = 1,
	[int]$ip_startrange = 205,
    <#
    Size
    'XS'  = 1vCPU, 512MB
    'S'   = 1vCPU, 768MB
    'M'   = 1vCPU, 1024MB
    'L'   = 2vCPU, 2048MB
    'XL'  = 2vCPU, 4096MB 
    'TXL' = 4vCPU, 6144MB
    'XXL' = 4vCPU, 8192MB
    #>
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	$Nodeprefix = "centos",
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
	[switch]$Defaults,
	[switch]$vtbit = $false
)
#requires -version 3.0
#requires -module vmxtoolkit
###standard labbuildr init###
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
$ip_startrange = $ip_startrange-1
[Uint64]$SCSI_DISK_SIZE = 100GB
$SCSI_Controller_Type = "pvscsi"
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Logfile = "/tmp/labbuildr.log"
if (!$DNS2)
    {
    $DNS2 = $DNS1
    }
$OS = "Centos"
switch ($centos_ver)
    {
    "7"
        {
        $netdev = "eno16777984"
        $Required_Master = "$OS$centos_ver Master"
		$Guestuser = "stack"
        }
    default
        {
        $netdev= "eno16777984"
        $Required_Master = "$OS$centos_ver"
		$Guestuser = "labbuildr"
        }
    }
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
[uint64]$Disksize = 100GB
####Build Machines###### cecking for linux binaries
####Build Machines#
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$Epel_Packages = @()
if ($docker.IsPresent -or $container)
	{
	$Epel_Packages += "docker" 
	}
if ($Desktop -contains 'cinnamon')
	{
	$Epel_Packages += "generic" 
	}
if ($AdditionalPackages -contains 'influxdb')
	{
	$Epel_Packages += "influxdb" 
	}
if ($AdditionalPackages -contains 'grafana')
	{
	$Epel_Packages += "grafana" 
	}

#$Epel_Packages = $Epel_Packages -join ","
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
    $Lab_VMX = ""
	$Lab_VMX = New-LabVMX -CentOS -CentOS_ver $centos_ver -Size $Size -SCSI_DISK_COUNT $SCSI_DISK_COUNT -SCSI_DISK_SIZE $Disksize -VMXname $Nodeprefix$Node -SCSI_Controller $SCSI_Controller -vtbit:$vtbit -start
	if ($Lab_VMX)
		{
		$temp_object = New-Object System.Object
		$temp_object | Add-Member -type NoteProperty -name Name -Value $Nodeprefix$Node
		$temp_object | Add-Member -type NoteProperty -name Number -Value $Node
		$machinesBuilt += $temp_object
		}       
    else
		{
		Write-Warning "Machine $Nodeprefix$Node already exists"
		}
			
	}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-verbose "Now Pausing"
    pause
    }
Write-Host -ForegroundColor White "Starting Node Configuration"

foreach ($Node in $machinesBuilt)
    {
		$ip_byte = ($ip_startrange+$Node.Number)
		$ip="$subnet.$ip_byte"
        $Nodeclone = Get-VMX $Node.Name
		Write-Verbose "Configuring Node $($Node.Number) $($Node.Name) with $IP"
        $Hostname = $Nodeclone.vmxname.ToLower()
		$Nodeclone | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Epel_Packages $Epel_Packages -Host_Name $Hostname -DNS1 $DNS1 -DNS2 $DNS2 -VMXName $Nodeclone.vmxname
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

        if ($Desktop)
            {
            Write-Host -ForegroundColor Gray " ==>Installing X-Windows environment"
            $Scriptblock = "yum groupinstall -y `'X Window system'"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }
        switch ($Desktop)
            {
            'cinnamon'
                {
                Write-Host -ForegroundColor Gray " ==>Installing Display Manager"
                $Scriptblock = "yum install -y lightdm cinnamon gnome-desktop3 firefox"
                Write-Verbose $Scriptblock
                $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
                $Scriptblock = "yum groupinstall gnome -y"
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
				$Scriptblock = "/usr/bin/vmware-config-tools.pl -d;shutdown -r now"
				Write-Verbose $Scriptblock
				$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -nowait| Out-Null
                }
            default
                {
                }
        }
	}#end machines
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
write-Host -ForegroundColor White "Login to the VM´s with root/Password123!"
Write-Host "Created $($machinesBuilt.Name -join ',') with current run"
