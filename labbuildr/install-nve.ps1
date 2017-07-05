<#
.Synopsis

.DESCRIPTION
   install-nve.ps1

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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-nve.ps1
.EXAMPLE
#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "import", Mandatory = $true)][switch]$import,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "defaults",Mandatory = $true)]
[Parameter(ParameterSetName = "import",Mandatory = $false)]
[ValidateSet(
    '9.0.1-72',
	'9.1.0.3','9.1.0.4',#-#
	'9.0.1.1','9.0.1.2','9.0.1.3','9.0.1.4','9.0.1.5','9.0.1.6' #-#
)]

$nve_ver = '9.1.0.4',
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[Parameter(ParameterSetName = "defaults",Mandatory = $false)]
[ValidateRange(1,2)]
[int32]$Nodes=1
)

$basename = "nvenode"
$rootuser = "root"
$rootpassword = "changeme"
$Product = "Networker"
$nve_dotver = $nve_ver -replace "-","."
$Product_tag = "nve-$nve_dotver"
$labdefaults = Get-labDefaults
$vmnet = $labdefaults.vmnet
$subnet = $labdefaults.MySubnet
$BuildDomain = $labdefaults.BuildDomain
$Builddir = $PSScriptRoot
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
    Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
    $Masterpath = $Builddir
    }
$Hostkey = $labdefaults.HostKey
$Gateway = $labdefaults.Gateway
$DefaultGateway = $labdefaults.Defaultgateway
$DNS1 = $labdefaults.DNS1
$DNS2 = $labdefaults.DNS2
if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}

switch ($nve_ver)
	{
		'9.1.0.4'
		{
		$Product_tag = 'NVE-9.1.0.166'
		}
		'9.1.0.3'
		{
		$Product_tag = 'NVE-9.1.0.132'
		}
	}

switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        Write-Verbose $Product_tag
        $Networker_dir = Join-Path $Sourcedir $Product
        Write-Verbose $Networker_dir
        $nve_dir = Join-Path $Networker_dir $Product_tag
        Write-Verbose "NVE Dir : $nve_dir"
        Write-Verbose "Masterpath : $masterpath" 
		Write-Verbose "Product Tag : $Product_tag"
        if (!($Importfile = Get-ChildItem -Path $nve_dir -Filter "$Product_tag.ovf" -ErrorAction SilentlyContinue))
            {
            Write-host -ForegroundColor Gray " ==> OVF does not exist, we need to extract from OVA" 
            Write-Host -ForegroundColor Gray " ==> Checking for $Product OVA package"
            Receive-LABNetworker -nve -nve_ver $nve_ver -Destination "$Sourcedir\$Product" -Confirm:$false
            $OVA_File = Get-ChildItem -Path "$Sourcedir\$Product" -Recurse -include "$Product_tag.ova" -Exclude ".*" | Sort-Object -Descending | Select-Object -First 1
            if (!$OVA_File)
				{
				Write-Host "Could not find ova with pattern NVE-$Product_tag.ova in $Sourcedir\$Product"
				Return
				}
			Write-Host -ForegroundColor Magenta " ==>Extraxting from OVA Package $OVA_File"
            $Expand = Expand-LABpackage -Archive $OVA_file.FullName -destination $nve_dir
            try
                {
                Write-Host -ForegroundColor Gray " ==>Validating OVF from OVA Package"
                $Importfile = Get-ChildItem -Filter "*.ovf" -Path $nve_dir -ErrorAction stop
                }
            catch
                {
                Write-Warning "we could not find a ovf file at $($OVA_Destination)"
                return
                }
            ## tweak ovf
            Write-Host -ForegroundColor Gray " ==>Adjusting OVF file for VMwARE Workstation"
            $content = Get-Content -Path $Importfile.FullName
            $Out_Line = $true
            $OutContent = @()
            ForEach ($Line In $content)
                {
                If ($Line -match '<ProductSection')
                    {
                    $Out_Line = $false
                    }
                If ($Out_Line -eq $True)
                    {
                    $OutContent += $Line
                    }
                If ($Line -match '</ProductSection')
                    {
                    $Out_Line = $True
                    }
                }
            $OutContent | Set-Content -Path $Importfile.FullName
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==> OVF already extracted, found $($Importfile.Basename)"#
            }
        if (!($mastername)) 
            {
            $mastername = $Importfile.BaseName
            }

        Write-Host -ForegroundColor Gray " ==>Checkin for VM $mastername"

        if (Get-VMX -Path $masterpath\$mastername -WarningAction SilentlyContinue)
            {
            Write-Warning "Base VM $masterpath\$mastername already exists, please delete first"
            exit
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==>Importing Base VM, this may take a while"
            if ((import-VMXOVATemplate -OVA $Importfile.FullName -Name $mastername -destination $masterpath  -acceptAllEulas).success -eq $true)
                {
                Write-Host -ForegroundColor Gray " ==> Preparation of Template done, please run $($MyInvocation.MyCommand) -Defaults -nve_ver $nve_ver"
                }
            else
                {
                Write-Host "Error importing Base VM. Already Exists ?"
                exit
                }

    }


        <#
        $Mastercontent = Get-Content .\Scripts\NVE\NVEMAster.vmx
        $Mastercontent = $Mastercontent -replace "NVEMaster","$mastername"
        $Mastercontent | Set-Content -Path ".\$mastername\$mastername.vmx"
        $Mastervmx = get-vmx -path ".\$mastername\$mastername.vmx"
        $Mastervmx | New-VMXSnapshot -SnapshotName Base
        $Mastervmx | Set-VMXTemplate
        #>
    
    }

	"defaults"

	{
	foreach ($node in 1..$Nodes)
		{
		$targetname = "$basename$node"
		[System.Version]$subnet = $Subnet.ToString()
		$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
		$ip_byte = 22 + $node
		$ip="$subnet.$ip_byte"
		
		if (!$Defaultgateway)
			{
			$Defaultgateway = "$subnet.$ip_byte"
			}
		Write-Host -ForegroundColor Gray " ==>Checking if node $targetname already exists"
		if (get-vmx $targetname -WarningAction SilentlyContinue)
			{
			Write-Warning " the Virtual Machine already exists"
			Break
			}

		if (!($MasterVMX = Get-VMX -Path $masterpath\$Product_tag))
			{
			Write-Host -ForegroundColor White "No Master exists for $Product_tag"
			return
			}

		$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
		if (!$Basesnap) 
			{
			$Content = Get-Content -Path $MasterVMX.config 
			$content = $content -replace "independent_",""
			$content | Set-Content -Path $MasterVMX.config
			Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
			$Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
			}

		If (!($Basesnap))
			{
			Write-Error "Error creating/finding Basesnap"
			exit
			}


		Write-Host -ForegroundColor Magenta " ==>Creating Machine $targetname"
		$NodeClone = $Basesnap | New-VMXLinkedClone -CloneName $targetname -Path $Builddir
		Write-Host -ForegroundColor Gray " ==>Configuring VM Network for vmnet $vmnet"
		$NodeClone | Set-VMXNetworkAdapter -Adapter 0 -AdapterType e1000 -ConnectionType custom -WarningAction SilentlyContinue | Out-Null
		$NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet -WarningAction SilentlyContinue | Out-Null
		$NodeClone | Set-VMXDisplayName -DisplayName $targetname | Out-Null
		$Annotation = $NodeClone | Set-VMXAnnotation -Line1 "https://$ip" -Line2 "user:$rootuser" -Line3 "password:$rootpassword" -Line4 "add license from $masterpath" -Line5 "labbuildr by @sddc_guy" -builddate
		$NodeClone | Start-VMX | Out-Null
			 do {
				$ToolState = Get-VMXToolsState -config $NodeClone.config
				Write-Verbose "VMware tools are in $($ToolState.State) state"
				sleep 10
				}
			until ($ToolState.state -match "running")
			 do {
				Write-Host -ForegroundColor Gray " ==> Waiting for $targetname to come up"
				$Process = Get-VMXProcessesInGuest -config $NodeClone.config -Guestuser $rootuser -Guestpassword $rootpassword
				sleep 10
				}
			until ($process -match "mingetty")
			Write-Host -ForegroundColor Gray " ==>Configuring Base OS"
			Write-Host -ForegroundColor Gray " ==> Setting Network"
			$NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$Scriptblock = "echo 'default "+$DefaultGateway+" - -' > /etc/sysconfig/network/routes"
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=`"`"/NETCONFIG_DNS_STATIC_SEARCHLIST=`""+$BuildDomain+"."+$Custom_DomainSuffix+"`"/g' /etc/sysconfig/network/config" 
			$NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=`"`"/NETCONFIG_DNS_STATIC_SERVERS=`""+$DNS1+"`"/g' /etc/sysconfig/network/config"
			$NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			$Scriptblock = "echo '"+$targetname+"."+$BuildDomain+"."+$Custom_DomainSuffix+"'  > /etc/HOSTNAME"
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword  | Out-Null
			$NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			Write-Host -ForegroundColor Gray " ==>Tweaking Configuration"
			$Scriptblock = "sed -i '/PermitRootLogin/ c\PermitRootLogin yes' /etc/ssh/sshd_config"
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
			if ($Hostkey)
				{
				$Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys"
				Write-Verbose $Scriptblock
				$Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $rootpassword
				}
			$Scriptblock = "insserv sshd;rcsshd restart"
			Write-Verbose $Scriptblock
			$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $rootpassword | Out-Null
			$Outmessage += "
		Successfully Deployed $targetname

		point your browser to https://$($ip)
		Login with $rootuser/$rootpassword and follow the wizard steps
		to monitor / install an update, browse to https://$($ip)/avi/avigui.html
		NVE updates can be downloaded with Receive-LABNetworker -nveupdate -nve_ver [nve_ver] -Destination [destination]
		"
		}#end nodes
	Write-Host -ForegroundColor Yellow $Outmessage
	}
	
}
