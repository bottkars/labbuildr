<#
.Synopsis
   .\install-vcsa.ps1 -ovf C:\Sourcesvmware-vcsa.ova
   .\install-vcsa.ps1 -Masterpath c:\SharedMaster -Mastername vmware-vcsa
.Description
  install-VCSA only applies to Testers of the Virtual VCSA
  install-VCSA is a 2 Step Process.
  Once VCSA is downloaded via vmware, run 
   .\install-VCSA.ps1 -defaults
   This creates a VCSA Master in your labbuildr directory.
   This installs a VCSA using the defaults file and the just extracted VCSA Master
    
      
      Copyright 2016 Karsten Bott

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
   https://github.com/bottkars/labbuildr/wiki/install-VCSA.ps1
.EXAMPLE
    Importing the ovf template
	.\install-vcsa.ps1 -ovf C:\Sourcesvmware-vcsa.ova
 .EXAMPLE
    Install a VCSANode with defaults from defaults.xml
   .\install-vcsa.ps1 -Masterpath c:\SharedMaster -Mastername vmware-vcsa

#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ova -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$Mastername,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "import",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]$MasterPath,
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,63)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,63}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[int]$Disks = 3

)
#requires -version 3.0
#requires -module vmxtoolkit
$Builddir = $PSScriptRoot
$Password = "Password123!"
$SSO_Domain = "vmware.local"
switch ($PsCmdlet.ParameterSetName)
{

    "import"
    {
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = (get-labdefaults).Masterpath
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
        if (!($mastername)) 
            {
            $OVFfile = Get-Item $ovf
            $mastername = $OVFfile.BaseName
            }
        $Template = Import-VMXOVATemplate -OVA $ovf -acceptAllEulas -AllowExtraConfig -destination $MasterPath
        #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Magenta  "Use .\install-VCSA.ps1 -Defaults -Mastername $($Template.VMname) to try defaults"
        }

default
    {
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

    $Startnode = 1
    $Nodes = 1

    [System.Version]$subnet = $Subnet.ToString()
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

    $Builddir = $PSScriptRoot
    $Nodeprefix = "VCSANode"
    if (!$Mastername)
        {
        $MasterVMX = get-vmx -path $Masterpath -VMXName vmware-vcsa
        iF ($MasterVMX)
            {
            $MasterVMX = $MasterVMX | Sort-Object -Descending
            $MasterVMX = $MasterVMX[-1]
            }
        }
    else
        {
        if ($MasterPath)        
            {
            $MasterVMX = get-vmx -path $MasterPath -VMXName $Mastername
            }
        }

    if (!$MasterVMX)
        {
        write-Host -ForegroundColor Magenta "Could not find existing VCSAMaster"
        return
        }
    Write-Host -ForegroundColor Magenta " ==>Checking Base VM Snapshot"
    if (!$MasterVMX.Template) 
        {
        Write-Host -ForegroundColor Magenta " ==>Templating Master VMX"
        $template = $MasterVMX | Set-VMXTemplate
        }
    $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base" 

    if (!$Basesnap) 
        {
        Write-Host -ForegroundColor Magenta " ==>Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
        }

    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        $ipoffset = 79+$Node
        Write-Host -ForegroundColor Magenta " ==>Checking VM $Nodeprefix$node already Exists"
        If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
            {
            write-Host -ForegroundColor Magenta " ==>Creating clone $Nodeprefix$node"
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
            Write-Host -ForegroundColor Magenta " ==>Configuring NICs"
            foreach ($nic in 0..0)
                {
                Write-Host -ForegroundColor Gray "  ==>Configuring NIC$nic"
                $Netadater0 = $NodeClone | Set-VMXVnet -Adapter $nic -vnet $VMnet -WarningAction SilentlyContinue
                }
			[string]$ip="$($subnet.ToString()).$($ipoffset.ToString())"
			$config = Get-VMXConfig -config $NodeClone.config
			$config += "guestinfo.cis.deployment.node.type = `"embedded`""
			$config += "guestinfo.cis.vmdir.domain-name = `"$BuildDomain.$SSO_Domain`""
			$config += "guestinfo.cis.vmdir.site-name = `"$BuildDomain`""
			$config += "guestinfo.cis.vmdir.password = `"$Password`""
			$config += "guestinfo.cis.appliance.net.addr.family = `"ipv4`""
			$config += "guestinfo.cis.appliance.net.addr = `"$ip`""
			$config += "guestinfo.cis.appliance.net.pnid = `"$ip`""
			$config += "guestinfo.cis.appliance.net.prefix = `"24`""
			$config += "guestinfo.cis.appliance.net.mode = `"static`""
			$config += "guestinfo.cis.appliance.net.dns.servers = `"$DNS1`""
			$config += "guestinfo.cis.appliance.net.gateway = `"$DefaultGateway`""
			$config += "guestinfo.cis.appliance.root.passwd = `"$Password`""
			$config += "guestinfo.cis.appliance.ssh.enabled = `"true`""
			$config | Set-Content -Path $NodeClone.config
            $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
            $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
            $Annotation = $Nodeclone | Set-VMXAnnotation -Line1 "Login Credentials" -Line2 "Administrator@$BuildDomain.$SSO_Domain" -Line3 "Password" -Line4 "$Password"
            Write-Host -ForegroundColor Magenta " ==>Starting VM $($NodeClone.Clonename)"
            $NodeClone | start-vmx | Out-Null
            }
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
            }
    }
Write-host
Write-host -ForegroundColor White "****** VCSA Deployed successful******
allow up to 10 minutes to configure and install.
once you see the appliance login console,
browse to
https://$ip and login with Administrator@$BuildDomain.$SSO_Domain / $Password
"

    }# end default
}

