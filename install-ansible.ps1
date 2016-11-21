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
#>
[CmdletBinding(DefaultParametersetName = "defaults",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
	[Parameter(ParameterSetName = "install",Mandatory=$False)]
	[ValidateRange(1,3)]
	[int32]$Disks = 1,
	[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('Centos7_1_1511','Centos7_1_1503')]
	[string]$centos_ver = "Centos7_1_1511",
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[ValidateRange(1,1)]
	[int32]$Nodes=1,
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[int32]$Startnode = 1,
	[int]$ip_startrange = 248,
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
	$Nodeprefix = "ansible",
	[switch]$Defaults
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
$Logfile = "/tmp/labbuildr.log"
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "labbuildr-scripts"
$ip_startrange = $ip_startrange+$Startnode
$OS = "Centos"
[System.Version]$subnet = $Global:labdefaults.MySubnet
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
$Guestuser = 'labbuildr'
[uint64]$Disksize = 100GB
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
####Build Machines###### cecking for linux binaries
####Build Machines#
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
		$IP = "$subnet.$ip_startrange"
		Write-Verbose "will use IP $IP"
        Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
		$Host_Name = "$Nodeprefix$node"
        Write-Host -ForegroundColor Gray "==>Creating $host_name"
		$Lab_VMX = New-LabVMX -CentOS -CentOS_ver $centos_ver -Size $Size -SCSI_DISK_COUNT $Disks -SCSI_DISK_SIZE $Disksize -VMXname $Nodeprefix$Node -SCSI_Controller 0
	    $Global:labdefaults.AnsiblePublicKey = ""
		$Annotation = $Lab_VMX | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
		$Lab_VMX | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Aditional_Epel_Packages ansible -Host_Name $Host_Name
		#### retrieving guest_rsakey
		Write-Host -ForegroundColor Gray " ==>retrieving root key for ansible"
		$Scriptblock = '/usr/sbin/vmtoolsd --cmd="info-set guestinfo.ROOT_PUBLIC_KEY $(cat /root/.ssh/id_rsa.pub)"'
		Write-Verbose $Scriptblock
		$Bashresult = $Lab_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
		$Public_Key = $Lab_VMX | Get-VMXVariable -GuestVariable ROOT_PUBLIC_KEY
		Set-LABAnsiblePublicKey -AnsiblePublicKey $Public_Key.ROOT_PUBLIC_KEY
        }
	}	
	
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
write-Host -ForegroundColor White "Login to the VM´s with root/Password123!"

			
<#		
		
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname CentOS -Scenario 7
        Write-Host -ForegroundColor Gray " ==>setting VM size to $Size"
        $mysize = $NodeClone |Set-VMXSize -config $NodeClone.Config -Size $Size
        $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        Write-Host -ForegroundColor Gray " ==>Starting CentosNode$Node"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)
    }
    else
        {
        write-Warning "Machine $Nodeprefix$node already Exists"
        }
    }
Write-Host -ForegroundColor White "Starting Node Configuration"
        if ($docker)
            {
            Write-Host -ForegroundColor Gray " ==>installing latest docker engine"
            $Scriptblock="curl -fsSL https://get.docker.com | sh;systemctl enable docker; systemctl start docker;usermod -aG docker $Guestuser"
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
        if ($Desktop -ne "none")
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
		$ip_startrange_count ++
		}#end machines
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
write-Host -ForegroundColor White "Login to the VM´s with root/Password123!"
#>