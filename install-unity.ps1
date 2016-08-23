<#
.Synopsis
   .\install-Unity.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
  install-Unity only applies to Testers of the Virtual Unity
  install-Unity is a 1 Step Process.
  Once Unity is downloaded via feedbckcentral, run 
   .\install-Unity.ps1 -defaults
   This creates a Unity Master in your labbuildr directory.
   This installs a Unity using the defaults file and the just extracted Unity Master
    
      
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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-Unity
.EXAMPLE
    Importing the ovf template
 .\install-Unity.ps1 -ovf E:\EMC_VAs\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.ovf
    Opening OVF source: E:\EMC_VAs\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.ovf
    The manifest does not validate
    Opening VMX target: F:\labbuildr_beta
    Warning:
    - Hardware compatibility check is disabled.
    - Line 54: Unsupported virtual hardware device 'VirtualSCSI'.
    Writing VMX file: F:\labbuildr_beta\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.vmx
    Transfer Completed
    Warning:
    - ExtraConfig option 'tools.guestlib.enableHostInfo' is not allowed, will skip it.
    - ExtraConfig option 'sched.mem.pin' is not allowed, will skip it.
    Completed successfully
.EXAMPLE
    Install a UnityNode with defaults from defaults.xml
   .\install-Unity.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
    WARNING: VM Path does currently not exist
    WARNING: Get-VMX : VM does currently not exist

    VMXname   Status  Starttime
    -------   ------  ---------
    UnityNode1 Started 07.21.2015 12:27:11
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
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[int]$Disks = 3,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[switch]$configure,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ })]$Lic_file
)
#requires -version 3.0
#requires -module vmxtoolkit
$Builddir = $PSScriptRoot
$guestuser = "service"
$guestpassword = "service"
$oldpasswd = "Password123#"
$Password = "Password123!"
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
                Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
        if (!($mastername)) 
            {
            $OVFfile = Get-Item $ovf
            $mastername = $OVFfile.BaseName
            }
        Import-VMXOVATemplate -OVA $ovf -acceptAllEulas -AllowExtraConfig -destination $MasterPath
        #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Gray  "Use .\install-Unity.ps1 -Masterpath $Masterpath -Mastername $Mastername 
        .\install-Unity.ps1 -Defaults to try defaults"
        }

    default
    {
    If ($Defaults.IsPresent)
        {
        $labdefaults = Get-labDefaults
        if (!($labdefaults))
            {
            try
                {
                $labdefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                }
            catch
                {
                Write-Warning "no  defaults or example defaults found, exiting now"
                exit
                }
            Write-Host -ForegroundColor Gray "Using generic defaults from labbuildr"
            }
        $vmnet = $labdefaults.vmnet
        $subnet = $labdefaults.MySubnet
        $BuildDomain = $labdefaults.BuildDomain
        $Sourcedir = $labdefaults.Sourcedir
        $Gateway = $labdefaults.Gateway
        $DefaultGateway = $labdefaults.Defaultgateway
        $DNS1 = $labdefaults.DNS1
        $DNS2 = $labdefaults.DNS2
        $masterpath = $labdefaults.Masterpath
    }

    $Startnode = 1
    $Nodes = 1

    [System.Version]$subnet = $Subnet.ToString()
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

    $Builddir = $PSScriptRoot
    $Nodeprefix = "UnityNode"
	$MasterVMX = @()
    if (!$Mastername)
        {
        $MasterVMX = get-vmx -path $Masterpath -VMXName UnityVSA-4*
        iF ($MasterVMX)
            {
            $MasterVMX = $MasterVMX | Sort-Object -Descending
            $MasterVMX = $MasterVMX[0]
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
        write-Host -ForegroundColor Magenta "Could not find existing UnityMaster"
        return
        }
    Write-Host -ForegroundColor Gray " ==>Checking Base VM Snapshot"
    if (!$MasterVMX.Template) 
        {
        Write-Host -ForegroundColor Gray " ==>Templating Master VMX"
        $template = $MasterVMX | Set-VMXTemplate
        }
    $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base" 

    if (!$Basesnap) 
        {
        Write-Host -ForegroundColor Gray "Tweaking Base VMX"
        $config = Get-VMXConfig -config $MasterVMX.config
        foreach ($scsi in 0..3)
            {
            $config = $config -notmatch "scsi$scsi.virtualDev"
            $config += 'scsi'+$scsi+'.virtualDev = "pvscsi"'
            $config = $config -notmatch "scsi$scsi.present"
            $config += 'scsi'+$scsi+'.present = "true"'
            }
        Set-Content -Path $MasterVMX.config -Value $config
        Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
        }
            # $Basesnap
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        $ipoffset = 84+$Node
        If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
            foreach ($nic in 0..5)
                {
                $Netadater0 = $NodeClone | Set-VMXVnet -Adapter $nic -vnet $VMnet -WarningAction SilentlyContinue
                }
            $SCSI = 1
            [uint64]$Disksize = 100GB
            if ($Disks -ne 0)
                {
                foreach ($LUN in (1..($Disks+2)))
                    {
                    $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                    $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                    $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                    }
                }
            [string]$ip="$($subnet.ToString()).$($ipoffset.ToString())"
			[string]$ip_if0="$($subnet.ToString()).200"

            $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
            $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
			if ($configure.IsPresent) 
				{
				$Annotation = $Nodeclone | Set-VMXAnnotation -Line1 "System User" -Line2 "sysadmin:sysadmin" -Line3 "Unity User" -Line4 "admin:$Password"
				}
			else
				{
				$Annotation = $Nodeclone | Set-VMXAnnotation -Line1 "System User" -Line2 "sysadmin:sysadmin" -Line3 "Unity User" -Line4 "admin:$oldpasswd"
				}
            $NodeClone | start-vmx | Out-Null
			$sleep = 2
			if ($configure.IsPresent)
				{
				Write-Host -ForegroundColor White " ==>Waiting for $($NodeClone.Clonename) first boot finished, this may take up to 10 minutes " -NoNewline
				$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
				while (($NodeClone | Get-VMXToolsState).state -notmatch "running")
					{
					foreach ($i in (1..$sleep))
						{
						Write-Host -ForegroundColor Yellow "-`b" -NoNewline
						sleep 1
						Write-Host -ForegroundColor Yellow "\`b" -NoNewline
						sleep 1
						Write-Host -ForegroundColor Yellow "|`b" -NoNewline
						sleep 1
						Write-Host -ForegroundColor Yellow "/`b" -NoNewline
						sleep 1
						}
					}
				Write-Host
				$StopWatch.Stop()
				Write-host -ForegroundColor White "Firstboot took $($StopWatch.Elapsed.ToString())"
				Write-Host -ForegroundColor White " ==>Waiting for $($NodeClone.Clonename) to become ready, the network config may need to wait up to 5 Minutes"
				$Network = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/sudo -n /EMC/Platform/bin/svc_initial_config -4 '$ip 255.255.255.0 $Gateway'" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 60 -Confirm:$False -WarningAction SilentlyContinue
				$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/uemcli -u admin -p $oldpasswd /sys/eula set -agree yes" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 5 -Confirm:$False -WarningAction SilentlyContinue
				$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/uemcli -u admin -p $oldpasswd /user/account -id user_admin set -passwd $Password -oldpasswd $oldpasswd" -Guestuser $guestuser -Guestpassword $guestpassword 
				$uemcli = "/usr/bin/uemcli -u admin -p $Password"
				$Vdisks =  @()
					foreach ($Disk in 1..$Disks)
						{
						$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli /env/disk -id vdisk_$Disk set -tier extreme" -Guestuser $guestuser -Guestpassword $guestpassword 
						$vdisks += "vdisk_$Disk"
						}
				$Vdisks = $Vdisks -join ","
				if ($Lic_file)
					{
					Write-Host -ForegroundColor Gray " ==>Trying to license with provided licfile"
					$Target_lic = Split-Path -Leaf $Lic_file
					$Target_lic = "/home/service/$Target_lic"
					$FileCopy = $NodeClone | Copy-VMXFile2Guest -Sourcefile $Lic_file -targetfile $Target_lic -Guestuser $guestuser -Guestpassword $guestpassword
					$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli -upload -f $Target_lic license" -Guestuser $guestuser -Guestpassword $guestpassword 
					$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/config/pool create -name vPool -descr 'labbuildr pool' -disk $Vdisks" -Guestuser $guestuser -Guestpassword $guestpassword 
					$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/if create -type iscsi -port spa_eth0 -addr $ip_if0 -netmask 255.255.255.0 -gateway $Gateway" -Guestuser $guestuser -Guestpassword $guestpassword 
					}
				}
			If (!$configure.IsPresent)
				{
				Write-host -ForegroundColor White "****** To Configure  Unity 4 ******
Go to VMware Console an wait for system to boot
It might take up to 15 Minutes on First boot
Login with  
service/service 
and run  
svc_initial_config -4 `"$ip 255.255.255.0 $DefaultGateway`"
once configured
open browser to 
https://$ip and login with admin / $oldpasswd
activate your license at
https://www.emc.com/auth/elmeval.htm
Please keep your license in a save location as it might me re-used when re-deploying $Nodeprefix$Node"
				}
			else
				{
				Write-Host -ForegroundColor White "Your System is now ready. Browse to https://$ip and login with admin / $Password "
				if (!$Lic_file)
					{
					Write-Host -ForegroundColor Gray "activate your license at https://www.emc.com/auth/elmeval.htm
Please keep your license in a save location as it might me re-used when re-deploying $Nodeprefix$Node"
					}
				}
			}
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
            }
		
		}


    }# end default
}

