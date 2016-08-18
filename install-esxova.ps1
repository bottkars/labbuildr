<#
.Synopsis
   .\install-esxova.ps1 -ovf C:\Sources\OVA\Nested_ESXi6.x_Appliance_Template_v5.ova
   .\install-esxova.ps1 -Masterpath c:\SharedMaster -Mastername Nested_ESXi6.x_Appliance_Template_v5
.Description
  install-esxova only applies to Testers of the Virtual esxova
  install-esxova is a 2 Step Process.
  Once esxova is downloaded via vmware, run 
   .\install-esxova.ps1 -defaults
   This creates a esxova Master in your labbuildr directory.
   This installs a esxova using the defaults file and the just extracted esxova Master
    
      
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
   https://github.com/bottkars/labbuildr/wiki/install-esxova.ps1
.EXAMPLE
    Importing the ovf template
	.\install-esxova.ps1 -ovf C:\Sources\vmware-esxova.ova
 .EXAMPLE
    Install a esxovaNode with defaults from defaults.xml
   .\install-esxova.ps1 -Masterpath c:\SharedMaster -Mastername vmware-esxova

#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]
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
[int]$Disks = 3,
[Parameter(ParameterSetName = "Import", Mandatory = $true)]
[ValidateSet(
'Nested_ESXi6','Nested_ESXi5'
)]
[string]$nestedesx_ver = "Nested_ESXi6"

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
        if (!($ovf)) 
            {
            #download template
			Write-Host -ForegroundColor Gray " ==>No OVA Template specified, checking for latest $nestedesx_ver"
			$OVF = Receive-LABnestedesxtemplate -Destination C:\sources\OVA -nestedesx_ver Nested_ESXi6
			$OVFfile = Get-Item $ovf
            $mastername = $OVFfile.BaseName
            }
        $OVA = Import-VMXOVATemplate -OVA $ovf -acceptAllEulas -AllowExtraConfig -quiet -destination $MasterPath 
        #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Magenta  "Use .\install-esxova.ps1 -Defaults -Mastername $($OVA.vmname) to try defaults"
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

	Write-Verbose $MasterPath
    $Startnode = 1
    $Nodes = 1

    [System.Version]$subnet = $Subnet.ToString()
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

    $Builddir = $PSScriptRoot
    $Nodeprefix = "NestedESX"
    if (!$MasterVMX)
        {
        $MasterVMX = get-vmx -path $Masterpath -VMXName $Mastername -verbose
		$Mastervmx
		Pause
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
            $MasterVMX = get-vmx -path $MasterPath -VMXName $MasterVMX
            }
        }

    if (!$MasterVMX)
        {
        write-Host -ForegroundColor Magenta "Could not find existing esxovaMaster"
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
        $ipoffset = 80+$Node
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
			$config += "guestinfo.hostname = `"$($NodeClone.CloneName).$BuildDomain.$custom_domainsuffix`""
			$config += "guestinfo.ipaddress = `"$ip`""
			$config += "guestinfo.netmask = `"255.255.255.0`""
			$config += "guestinfo.gateway = `"$Gateway`""
			$config += "guestinfo.dns = `"$DNS1`""
			$config += "guestinfo.domain = `"$Nodeprefix$Node.$BuildDomain.$custom_domainsuffix`""
			$config += "guestinfo.ntp = `"$DNS1`""
			$config += "guestinfo.ssh = `"true`""
			$config += "guestinfo.syslog = `"$ip`""
			$config += "guestinfo.password = `"$Password`""
			$config += "guestinfo.createvmfs = `"false`""
			$config | Set-Content -Path $NodeClone.config
			$Displayname = $NodeClone | Set-VMXGuestOS -GuestOS vmkernel6
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
Write-host -ForegroundColor White "****** esxova Deployed successful******
login with root/$Password
"

    }# end default
}

