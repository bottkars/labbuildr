<#
.Synopsis
   .\install-Unity-Falcon.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
  install-Unity only applies to Testers of the Virtual Unity
  install-Unity is a 1 Step Process.
  Once Unity is downloaded via feedbckcentral, run
   .\install-Unity-Falcon.ps1 -defaults
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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-unity-falcon.ps1
.EXAMPLE
    Importing the ovf template
 .\install-Unity-Falcon.ps1 -ovf E:\EMC_VAs\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.ovf
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
    Install a UnityNode with defaults from defaults.json
   .\install-Unity-Falcon.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
    WARNING: VM Path does currently not exist
    WARNING: Get-VMX : VM does currently not exist

    VMXname   Status  Starttime
    -------   ------  ---------
    UnityNode1 Started 07.21.2015 12:27:11
#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ova -PathType Leaf -ErrorAction SilentlyContinue })]
$ovf,
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$true)]
#[switch]
#$generate_uuid_and_exit,
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]
$Defaults,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateRange(3,14)]
[int]
$Disks = 3,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[switch]
$configure,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('all','E2016','DCNODE','SQL','AlwaysOn','AppSync','HyperV')]
[string[]]
$iscsi_hosts,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ })]$lic_dir,
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('iscsi','cifs','nfs')]
[string[]]
$Protocols,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]
$Mastername,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "import",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
$MasterPath,
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateRange(1,2)]
[int]
$Nodes = 1,
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]
$Defaultsfile=".\defaults.json",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]
$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,63)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,63}[a-zA-Z0-9]+$")][string]
$BuildDomain = "labbuildr",
#[Parameter(ParameterSetName = "generateuuid",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateRange(1,2)]
[int]$Startnode = 1,
$ipoffset = 170
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
			
		    if ($vmwareversion.Major -eq 14)
			{
				Write-Warning " running $($vmwareversion.ToString()),we try to avoid a OVF import Bug, trying a manual import"
				Expand-LABpackage -Archive $OVF -filepattern *.vmdk -destination "$Masterpath/$mastername" -Verbose -force
				Copy-Item "./template/UnityVSA.template" -Destination "$Masterpath/$mastername/$Mastername.vmx"
				$Template_VMX = get-vmx -Path "$Masterpath/$mastername"
				$Disk1_item = Get-Item "$Masterpath/$mastername/*disk1.vmdk"
				$Disk1 = $Template_VMX | Add-VMXScsiDisk -Diskname $Disk1_item.Name -LUN 0 -Controller 0
				$Disk2_item = Get-Item "$Masterpath/$mastername/*disk2.vmdk"
				$Disk2 = $Template_VMX | Add-VMXScsiDisk -Diskname $Disk2_item.Name -LUN 1 -Controller 0
				$Disk3_item = Get-Item "$Masterpath/$mastername/*disk3.vmdk"
				$Disk3 = $Template_VMX | Add-VMXScsiDisk -Diskname $Disk3_item.Name -LUN 2 -Controller 0
				
			} 
		else {
			Import-VMXOVATemplate -OVA $ovf -acceptAllEulas -AllowExtraConfig -destination $MasterPath
		}
        #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Gray  "Use 
.\$($MyInvocation.MyCommand) -Masterpath $Masterpath -Mastername $Mastername -defaults -configure
to deploy unity. for other options, see get-help .\$($MyInvocation.MyCommand) -online
"
        }

    default
    {
	If ($lic_dir -or $Protocols -or $iscsi_hosts)
		{
		$configure = $True
		}
	IF ($iscsi_hosts -and $Protocols -notcontains 'iscsi')
		{
		$Protocols+= 'iscsi'
		}
    If ($Defaults.IsPresent)
        {
        $labdefaults = Get-labDefaults
        if (!($labdefaults))
            {
            try
                {
                    New-LabDefaults    
                    $labdefaults = Get-labDefaults                }
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
		if ($LabDefaults.custom_domainsuffix)
			{
			$custom_domainsuffix = $LabDefaults.custom_domainsuffix
			}
		else
			{
			$custom_domainsuffix = "local"
			}
    }
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
            $MasterVMX = get-vmx -path $MasterPath -VMXName $Mastername
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
        $Vitualdev0 = "lsilogic"
        If ($MasterVMX.VMXName -match "UnityVSA-4.1")
            {
            write-host "Got Falcon Release, currently not supported on Workstation ... stay tuned"
            #return
            #$Vitualdev0 = "lsilogic"
            }

       
		Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
        }

    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
		{
		$NodeStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
		$ipoffset = $ipoffset+$Node
		If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
			{
			$NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir"
			$Vitualdev0 = 'pvscsi'
			$Controller = $NodeClone | Set-VMXScsiController -SCSIController 0 -Type pvscsi  
			if ($generate_uuid_and_exit )
				{
				$NodeClone | start-vmx | Out-Null
				$License_UUID = $NodeClone | Get-VMXUUID -unityformat
				$NodeClone | Remove-vmx -Confirm:$False | Out-Null
				Write-Host -ForegroundColor Gray  -NoNewline " ==use UUID"
				Write-Host -ForegroundColor White -NoNewline " $($License_UUID.UUID) "
				Write-Host -ForegroundColor Gray "to activate your license at https://www.emc.com/auth/elmeval.htm
You can redeploy you Unity Node with the licensefile retrieved
Example:
.\$($MyInvocation.MyCommand) -Defaults -Masterpath $($MasterVMX.path) -Lic_dir [lic_dir_path] -configure -Disks 6 -protocols [iSCSI,NFS,CIFS] -configure_iscsi_hosts [E2016,DCNODE]"
				}
			else
				{
				foreach ($nic in 0..5)
					{
					$Netadater0 = $NodeClone | Set-VMXVnet -Adapter $nic -vnet $VMnet -WarningAction SilentlyContinue
					}
				[string]$ip="$($subnet.ToString()).$($ipoffset.ToString())"
				if (!$DefaultGateway)
					{
					$DefaultGateway = $ip
					}
				[string]$ip_if0="$($subnet.ToString())."+($ipoffset+1+$Node)
				[string]$ip_if1="$($subnet.ToString())."+($ipoffset+3+$Node)
				[string]$ip_if2="$($subnet.ToString())."+($ipoffset+5+$Node)
				[string]$ip_if3="$($subnet.ToString())."+($ipoffset+7+$Node)
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
				$STart1 = $NodeClone | start-vmx | Out-Null
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
					$Network = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/sudo -n /EMC/Platform/bin/svc_initial_config -4 '$ip 255.255.255.0 $DefaultGateway'" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 60 -Confirm:$False -WarningAction SilentlyContinue
					$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/uemcli -u admin -p $oldpasswd /sys/eula set -agree yes" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 5 -Confirm:$False -WarningAction SilentlyContinue
					$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/uemcli -u admin -p $oldpasswd /user/account -id user_admin set -passwd $Password -oldpasswd $oldpasswd" -Guestuser $guestuser -Guestpassword $guestpassword
					$uemcli = "/usr/bin/uemcli -u admin -p $Password"
					$uemcli_service = "/usr/bin/uemcli -u service -p service"
					$Scriptblock = 'vmtoolsd --cmd="info-set guestinfo.SYSUUID $('+$uemcli+' /sys/general show | grep UUID)"'
					$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword
					$SYSUUID = $nodeclone | Get-VMXVariable -GuestVariable SYSUUID | Select-Object SYSUUID
					$License_UUID = ($SYSUUID.SYSUUID -split " = ")[-1]
					Write-Host -ForegroundColor White "
*************************************************************************************					
Please use UUID 
$License_UUID 
to register Unity at https://www.emc.com/auth/elmeval.htm" 
					$stop = $nodeclone | Stop-VMX -Mode Hard
					sleep 5
					$SCSI = 3
					$NewController = $NodeClone | Set-VMXScsiController -SCSIController $SCSI -Type pvscsi  
					[uint64]$Disksize = 100GB
					if ($Disks -ne 0)
						{
						foreach ($LUN in (0..($Disks-1)))
							{
							if ($LUN -ge 7)
								{
								$LUN = $LUN+1
								}
							$Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
							$Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path
							$AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI -VirtualSSD
							}
						}
					sleep 2
					$Start2 = $NodeClone | start-vmx
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
					$StopWatch.Stop()
					Write-host -ForegroundColor White "Secondboot took $($StopWatch.Elapsed.ToString())"
					$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli /env/sp show -detail" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 5 -Confirm:$False -WarningAction SilentlyContinue
					$Vdisks =  @()
					foreach ($Disk in 1..$Disks)
						{
						$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli /env/disk -id vdisk_$Disk set -tier extreme" -Guestuser $guestuser -Guestpassword $guestpassword
						$vdisks += "vdisk_$Disk"
						}
					$Vdisks = $Vdisks -join ","
					if ($lic_dir)
						{
						Write-Host -ForegroundColor Yellow "
		Please license the UnityVSA at https://www.emc.com/auth/elmeval.htm with $License_UUID
		Place the Licensefile in $lic_dir
						"
						Write-Host -ForegroundColor White "****Waiting for License*****"
						while (!($lic_file = Get-ChildItem -path $lic_dir -filter $License_UUID*.lic))
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
						$NAS_SERVER = "$($BuildDomain)_NAS_"+($ipoffset+3+$Node)
						Write-Host -ForegroundColor Gray " ==>Trying to license with provided licfile"
						$Target_lic = Split-Path -Leaf $Lic_file.Name
						$Target_lic = "/home/service/$Target_lic"
						$FileCopy = $NodeClone | Copy-VMXFile2Guest -Sourcefile $Lic_file.FullName -targetfile $Target_lic -Guestuser $guestuser -Guestpassword $guestpassword
						$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli -upload -f $Target_lic license" -Guestuser $guestuser -Guestpassword $guestpassword
						$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/if/mgmt set -ipv4 static -addr $ip -netmask 255.255.255.0 -gateway $DefaultGateway" -Guestuser $guestuser -Guestpassword $guestpassword
						$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli_service /service/ssh set -enabled yes" -Guestuser $guestuser -Guestpassword $guestpassword
						$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/config/pool create -name vPool -descr '$BuildDomain pool' -disk $Vdisks" -Guestuser $guestuser -Guestpassword $guestpassword
						If ($Protocols -contains 'iscsi')
							{
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/if create -type iscsi -port spa_eth0 -addr $ip_if0 -netmask 255.255.255.0 -gateway $DefaultGateway" -Guestuser $guestuser -Guestpassword $guestpassword
							if ($iscsi_hosts)
								{
								$hostcount = 1
								$luncount = 1
								$Possible_Error_Fix = "Error in Host / lun Creation, you may skip this"
								If ($iscsi_hosts -contains 'DCNODE' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_host = "$($BuildDomain)DC"
									$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host).$BuildDomain.$custom_domainsuffix"
									$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr 'Windows DC $iscsi_host' -type host -addr $subnet.10 -osType win2012srv",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
									foreach ($Scriptblock in $Scriptblocks)
										{
										$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix |Out-Null
										}
									$hostcount++
									}
								#create appsync host	
								If ($iscsi_hosts -contains 'AppSync' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_host = "AppSync"
									$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host).$BuildDomain.$custom_domainsuffix"
									$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr 'Windows DC $iscsi_host' -type host -addr $subnet.14 -osType win2012srv",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
									foreach ($Scriptblock in $Scriptblocks)
										{
										$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix |Out-Null
										}
									$hostcount++
									}
								#create exchange 2016 hosts
								if ($iscsi_hosts -contains 'E2016' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_hosts_tag = 'E2016N'
									foreach ($node in (1..2))
										{
										$iscsi_host = "$iscsi_hosts_tag$Node.$BuildDomain.$custom_domainsuffix"
										$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host)"
										$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr 'Exchange Node $iscsi_host' -type host -addr $subnet.12$Node -osType win2012srv ",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
										foreach ($Scriptblock in $Scriptblocks)
											{
											$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
											}
										foreach ($LUN in (0..2))
											{
											$Scriptblocks = (
											"$uemcli /stor/prov/luns/lun create -name '$iscsi_hosts_tag$($node)_LUN$($LUN)' -descr 'Exchange LUN_$LUN' -pool vPool -size 500G -thin yes",
											"$uemcli /stor/prov/luns/lun -id sv_$luncount set -lunHosts Host_$hostcount"
											)
											foreach ($Scriptblock in $Scriptblocks)
												{
												$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
												}
											$luncount++
											}
										$hostcount++
										}
									}
								if ($iscsi_hosts -contains 'AlwaysOn' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_hosts_tag = 'AAGNODE'
									foreach ($node in (1..4))
										{
										$iscsi_host = "$iscsi_hosts_tag$Node.$BuildDomain.$custom_domainsuffix"
										$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host)"
										$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr 'SQL Node $iscsi_host' -type host -addr $subnet.16$Node -osType win2012srv ",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
										foreach ($Scriptblock in $Scriptblocks)
											{
											$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
											}
										foreach ($LUN in (0..3))
											{
											if ((0,2) -contains $LUN)
												{
												$CLI_DISK_SIZE = "200G"
												}
											else
												{
												$CLI_DISK_SIZE = "50G"
												}
											$Scriptblocks = (
											"$uemcli /stor/prov/luns/lun create -name '$iscsi_hosts_tag$($node)_LUN$($LUN)' -descr 'Always On LUN_$LUN' -pool vPool -size $CLI_DISK_SIZE -thin yes",
											"$uemcli /stor/prov/luns/lun -id sv_$luncount set -lunHosts Host_$hostcount"
											)
											foreach ($Scriptblock in $Scriptblocks)
												{
												$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
												}
											$luncount++
											}
										$hostcount++
										}
									}
								if ($iscsi_hosts -contains 'SQL' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_hosts_tag = 'SQLNODE'
									foreach ($node in (1..4))
										{
										$iscsi_host = "$iscsi_hosts_tag$Node.$BuildDomain.$custom_domainsuffix"
										$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host)"
										$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr 'SQL Node $iscsi_host' -type host -addr $subnet.13$Node -osType win2012srv ",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
										foreach ($Scriptblock in $Scriptblocks)
											{
											$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
											}
										foreach ($LUN in (0..3))
											{
											if ((0,2) -contains $LUN)
												{
												$CLI_DISK_SIZE = "100G"
												}
											else
												{
												$CLI_DISK_SIZE = "50G"
												}
											$Scriptblocks = (
											"$uemcli /stor/prov/luns/lun create -name '$iscsi_hosts_tag$($node)_LUN$($LUN)' -descr 'SQL LUN_$LUN' -pool vPool -size $CLI_Disk_Size -thin yes",
											"$uemcli /stor/prov/luns/lun -id sv_$luncount set -lunHosts Host_$hostcount"
											)
											foreach ($Scriptblock in $Scriptblocks)
												{
												$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
												}
											$luncount++
											}
										$hostcount++
										}
									}
								if ($iscsi_hosts -contains 'HyperV' -or $iscsi_hosts -contains 'all')
									{
									$iscsi_hosts_tag = 'HV1Node'
									$descr = "Hyper-V"
									$HyperV_Hosts = @()
									foreach ($node in (1..4))
										{
										$iscsi_host = "$iscsi_hosts_tag$Node.$BuildDomain.$custom_domainsuffix"
										$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host)"
										$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr '$descr Node $iscsi_host' -type host -addr $subnet.15$Node -osType win2012srv ",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
										foreach ($Scriptblock in $Scriptblocks)
											{
											$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
											}
										$HyperV_Hosts+= "Host_$hostcount"
										$hostcount++
										}
										$HyperV_Hosts = $HyperV_Hosts -join ","
										foreach ($LUN in (0..1))
											{
											$CLI_DISK_SIZE = "1000G"
											$Scriptblocks = (
											"$uemcli /stor/prov/luns/lun create -name '$iscsi_hosts_tag$($node)_LUN$($LUN)' -descr '$descr LUN_$LUN' -pool vPool -size $CLI_Disk_Size -thin yes",
											"$uemcli /stor/prov/luns/lun -id sv_$luncount set -lunHosts $HyperV_Hosts"
											)
											foreach ($Scriptblock in $Scriptblocks)
												{
												$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix  $Possible_Error_Fix | Out-Null
												}
											$luncount++
											}
									$iscsi_hosts_tag = 'HV2Node'
									$descr = "Hyper-V"
									$HyperV_Hosts = @()
									foreach ($node in (1..4))
										{
										$iscsi_host = "$iscsi_hosts_tag$Node.$BuildDomain.$custom_domainsuffix"
										$ISCSI_IQN = "iqn.1991-05.com.microsoft:$($iscsi_host)"
										$Scriptblocks = (
										"$uemcli /remote/host create -name $iscsi_host -descr '$descr Node $iscsi_host' -type host -addr $subnet.15$($Node+5) -osType win2012srv ",
										"$uemcli /remote/initiator create -host Host_$hostcount -uid '$ISCSI_IQN' -type iscsi"
										)
										foreach ($Scriptblock in $Scriptblocks)
											{
											$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
											}
										$HyperV_Hosts+= "Host_$hostcount"
										$hostcount++
										}
										$HyperV_Hosts = $HyperV_Hosts -join ","
										foreach ($LUN in (0..1))
											{
											$CLI_DISK_SIZE = "1000G"
											$Scriptblocks = (
											"$uemcli /stor/prov/luns/lun create -name '$iscsi_hosts_tag$($node)_LUN$($LUN)' -descr '$descr LUN_$LUN' -pool vPool -size $CLI_Disk_Size -thin yes",
											"$uemcli /stor/prov/luns/lun -id sv_$luncount set -lunHosts $HyperV_Hosts"
											)
											foreach ($Scriptblock in $Scriptblocks)
												{
												$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix $Possible_Error_Fix | Out-Null
												}
											$luncount++
											}

									}


								}
							}
						$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/dns/config set -nameServer $DNS1" -Guestuser $guestuser -Guestpassword $guestpassword
						If ($Protocols -match "fs")
							{
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/nas/server create -name $NAS_SERVER -sp spa -pool pool_1" -Guestuser $guestuser -Guestpassword $guestpassword
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/nas/if create -server nas_1 -port spa_eth0 -addr $ip_if1 -netmask 255.255.255.0 -gateway $DefaultGateway" -Guestuser $guestuser -Guestpassword $guestpassword
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/nas/dns -server nas_1 set -name $($BuildDomain).$($custom_domainsuffix) -nameServer 192.168.2.10” -Guestuser $guestuser -Guestpassword $guestpassword
							}
						if ($Protocols -contains 'cifs')
							{
							Write-Host -ForegroundColor Gray " ==>Setting NTP, unity will reboot automatically"
							$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli /net/ntp/server create -server 192.168.2.10 -force allowDU" -Guestuser $guestuser -Guestpassword $guestpassword
							sleep 120
							$cmdline = $Nodeclone | Invoke-VMXBash -Scriptblock "$uemcli /net/ntp/server show -detail" -Guestuser $guestuser -Guestpassword $guestpassword -SleepSec 5 -Confirm:$False -WarningAction SilentlyContinue
							$CIFS_FS1 = "FileSystem01"
							$CIFS_SERVER_NAME = "CIFSserver"+($ipoffset+3+$Node)
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/nas/cifs create -server nas_1 -name $CIFS_SERVER_NAME -description 'Default CIFS Server for $BuildDomain' -domain $($BuildDomain).$($custom_domainsuffix) -username Administrator -passwd $Password"  -Guestuser $guestuser -Guestpassword $guestpassword -Possible_Error_Fix " error durring cifs join may indicate that `n 1.) no domain controller is up and running `n 2.)Computeraccount already exists in Domain"
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/prov/fs create -name $CIFS_FS1 -descr 'CIFS shares' -server nas_1 -pool pool_1 -size 100G -type cifs" -Guestuser $guestuser -Guestpassword $guestpassword
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/prov/fs/cifs create -name CIFSroot -descr 'CIFS root' -fs res_1 -path '/' -enableContinuousAvailability yes"  -Guestuser $guestuser -Guestpassword $guestpassword
							}
						if ($Protocols -contains 'nfs')
							{
							$NFS_FS1 = "FileSystem02"
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /net/nas/nfs -id nfs_1 set -v4 yes" -Guestuser $guestuser -Guestpassword $guestpassword
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/prov/fs create -name $NFS_FS1 -descr 'NFS shares' -server nas_1 -pool pool_1 -size 100G -type nfs" -Guestuser $guestuser -Guestpassword $guestpassword
							$cmdline = $NodeClone | Invoke-VMXBash -Scriptblock "$uemcli /stor/prov/fs/nfs create -name NFSshare1 -descr 'NFSroot' -fs res_2 -path '/'"  -Guestuser $guestuser -Guestpassword $guestpassword
							}
						}
					}
				If (!$configure.IsPresent)
					{
					Write-host -ForegroundColor White "****** To Configure  Unity ******
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
			$NodeStopWatch.Stop()
			Write-host -ForegroundColor White "Unity Deployment took $($NodeStopWatch.Elapsed.ToString())"

			}
		else
			{
			Write-Warning "Node $Nodeprefix$node already exists"
			}
		
		}#end nodes
	}
}