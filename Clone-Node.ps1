<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][string]$Builddir = $PSScriptRoot,
[Parameter(Mandatory=$true)][string]$MasterVMX,
[Parameter(Mandatory=$false)][string]$Domainname,
[Parameter(Mandatory=$true)][string]$Nodename,
[Parameter(Mandatory=$false)][string]$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx",
[Parameter(Mandatory=$false)][string]$vmnet ="vmnet2",
[Parameter(Mandatory=$false)][switch]$Isilon,
[Parameter(Mandatory=$false)][string]$scenarioname = "Default",
[Parameter(Mandatory=$false)][int]$Scenario = 1,
[Parameter(Mandatory=$false)][int]$ActivationPreference = 1,
[Parameter(Mandatory=$false)][switch]$AddDisks,
[Parameter(Mandatory=$false)][switch]$SharedDisk,
[Parameter(Mandatory=$false)][uint64]$Disksize = 200GB,
[Parameter(Mandatory=$false)][ValidateRange(1, 6)][int]$Disks = 1,
#[string]$Build,
[Parameter(Mandatory=$false)][ValidateSet('XS','S','M','L','XL','TXL','XXL','XXXL')]$Size = "M",
[switch]$HyperV,
[switch]$NW,
[switch]$Bridge,
[switch]$Gateway,
[switch]$sql,
$Sourcedir,
$Scripts = "labbuildr-scripts"
# $Machinetype
)
# $SharedFolder = "Sources"
$Origin = $MyInvocation.InvocationName
$Sources = "$MountDrive\sources"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$BuildDate = Get-Date -Format "MM.dd.yyyy hh:mm:ss"
###################################################
### Node Cloning and Customizing script
### Karsten Bott
### 08.10.2013 Added vmrun errorcheck on initial base snap
###################################################
$VMrunErrorCondition = @("Error: The virtual machine is not powered on","waiting for Command execution Available","Error","Unable to connect to host.","Error: The operation is not supported for the specified parameters","Unable to connect to host. Error: The operation is not supported for the specified parameters")
function write-log {
    Param ([string]$line)
    $Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
    Add-Content $Logfile -Value "$Logtime  $line"
}

function test-user {param ($whois)
$sleep = 1
$Origin = $MyInvocation.MyCommand
do {
([string]$cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword listProcessesInGuest $Clone.config )2>&1 | Out-Null
	Write-Debug $cmdresult
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
until (($cmdresult -match $whois) -and ($VMrunErrorCondition -notcontains $cmdresult))
write-log "$origin $UserLoggedOn"
}
if (!(Get-ChildItem $MasterVMX -ErrorAction SilentlyContinue)) { write-host "Panic, $MasterVMX not installed"!; Break}
# Setting Base Snapshot upon First Run
if (!($Master = get-vmx  -Path $MasterVMX))
    { Write-Error "where is our master ?! "
    break
    }
write-verbose "Checking template"
if (!($Master.Template))
    {
    write-verbose "Templating"
    $Master | Set-VMXTemplate
    }
Write-verbose "Checking Snapshot"
    if(!($Snapshot = $Master | Get-VMXSnapshot | where snapshot -eq "Base"))
    {
    Write-Verbose "Creating Base Snapshot"
    $Snapshot = $Master | New-VMXSnapshot -SnapshotName "Base"
    }

if (get-vmx $Nodename -WarningAction SilentlyContinue)
{
Write-Warning "$Nodename already exists"
return $false
}
else
{
$Displayname = "$Nodename@$Domainname"
Write-verbose "Creating linked $Nodename of $MasterVMX"

$Clone = $Snapshot | New-VMXLinkedClone -CloneName $Nodename -clonepath $Builddir
write-verbose "starting customization of $($Clone.config)"
$Content = $Clone | Get-VMXConfig
$Content = $Content | where {$_ -notmatch "memsize"}
$Content = $Content | where {$_ -notmatch "numvcpus"}
$Content = $Content | where {$_ -notmatch "sharedFolder"}
$Content = $Content | where {$_ -notmatch "svga.autodetecct"}
$Content = $Content | where {$_ -notmatch "gui.applyHostDisplayScalingToGuest"}
$Content += 'gui.applyHostDisplayScalingToGuest = "False"'
$Content += 'svga.autodetect = "TRUE" '
#$Content += 'sharedFolder0.present = "TRUE"'
#$Content += 'sharedFolder0.enabled = "TRUE"'
#$Content += 'sharedFolder0.readAccess = "TRUE"'
#$Content += 'sharedFolder0.writeAccess = "TRUE"'
#$Content += 'sharedFolder0.hostPath = "'+"$Sourcedir"+'"'
#$Content += 'sharedFolder0.guestName = "Sources"'
#$Content += 'sharedFolder0.expiration = "never"'
#$Content += 'sharedFolder.maxNum = "1"'

switch ($Size)
{
"XS"{
$content += 'memsize = "512"'
$Content += 'numvcpus = "1"'
}
"S"{
$content += 'memsize = "768"'
$Content += 'numvcpus = "1"'
}
"M"{
$content += 'memsize = "1024"'
$Content += 'numvcpus = "1"'
}
"L"{
$content += 'memsize = "2048"'
$Content += 'numvcpus = "2"'
}
"XL"{
$content += 'memsize = "4096"'
$Content += 'numvcpus = "2"'
}
"TXL"{
$content += 'memsize = "8192"'
$Content += 'numvcpus = "2"'
}
"XXL"{
$content += 'memsize = "8192"'
$Content += 'numvcpus = "4"'
}
"XXXL"{
$content += 'memsize = "16384"'
$Content += 'numvcpus = "4"'
}
}
if ($HyperV){
#$Content = $Clone | Get-VMXConfig
$Content = $Content | where {$_ -notmatch "guestOS"}
$Content += 'guestOS = "winhyperv"'
}
$Content = $Content | where {$_ -notmatch "gui.exitAtPowerOff"}
$Content += 'gui.exitAtPowerOff = "TRUE"'
$Content = $Content | where {$_ -notmatch "virtualHW.version"}
$Content += 'virtualHW.version = "'+"$($Global:vmwareversion.Major)"+'"'
Set-Content -Path $Clone.config -Value $content -Force
$Clone | Set-VMXMainMemory -usefile:$false
$Clone | Set-VMXDisplayName -DisplayName $Displayname
$Clone | Set-VMXAnnotation -builddate -Line1 "This is node $Nodename for domain $Domainname"-Line2 "Adminpasswords: Password123!" -Line3 "Userpasswords: Welcome1"
$Clone | Set-VMXAnnotation -builddate -Line1 "This is node $Nodename for domain $Domainname"-Line2 "Adminpasswords: Password123!" -Line3 "Userpasswords: Welcome1"
if ($sql.IsPresent)
    {
    $Diskname =  "DATA_LUN.vmdk"
    $Newdisk = New-VMXScsiDisk -NewDiskSize 500GB -NewDiskname $Diskname -Verbose  -VMXName $Clone.VMXname -Path $Clone.Path
    Write-Verbose "Adding Disk $Diskname to $($Clone.VMXname)"
    $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN 1 -Controller 0
    $Diskname =  "LOG_LUN.vmdk"
    $Newdisk = New-VMXScsiDisk -NewDiskSize 100GB -NewDiskname $Diskname -Verbose -VMXName $Clone.VMXname -Path $Clone.Path
    Write-Verbose "Adding Disk $Diskname to $($Clone.VMXname)"
    $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN 2 -Controller 0
    $Diskname =  "TEMPDB_LUN.vmdk"
    $Newdisk = New-VMXScsiDisk -NewDiskSize 100GB -NewDiskname $Diskname -Verbose -VMXName $Clone.VMXname -Path $Clone.Path
    Write-Verbose "Adding Disk $Diskname to $($Clone.VMXname)"
    $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN 3 -Controller 0
    $Diskname =  "TEMPLOG_LUN.vmdk"
    $Newdisk = New-VMXScsiDisk -NewDiskSize 50GB -NewDiskname $Diskname -Verbose -VMXName $Clone.VMXname -Path $Clone.Path
    Write-Verbose "Adding Disk $Diskname to $($Clone.VMXname)"
    $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN 4 -Controller 0
    }

if ($AddDisks.IsPresent)
    {
    if ($SharedDisk.IsPresent)
        {
        $SCSI = "1"
        $Clone | Set-VMXScsiController -SCSIController $SCSI -Type pvscsi 
        }
    else
        {
        $SCSI = "0"
        }
    foreach ($LUN in (1..$Disks))
        {
        $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
        Write-Verbose "Building new Disk $Diskname"
        $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -VMXName $Clone.VMXname -Path $Clone.Path
        Write-Verbose "Adding Disk $Diskname to $($Clone.VMXname)"
        if ($SharedDisk.ispresent)
            {
            $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI -Shared
            }
        else
            {
            $AddDisk = $Clone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
        }
    }

Set-VMXActivationPreference -config $Clone.config -activationpreference $ActivationPreference | Out-Null
Set-VMXscenario -config $Clone.config -Scenario $Scenario -Scenarioname $scenarioname |Out-Null
Set-VMXscenario -config $Clone.config -Scenario 9 -Scenarioname labbuildr | Out-Null
if ($bridge.IsPresent)
    {
    write-verbose "configuring network for bridge"
    $Clone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType bridged -AdapterType vmxnet3
    $Clone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue
    $Clone | Set-VMXVnet -Adapter 0 -vnet $vmnet
    }
elseif($NW -and $gateway.IsPresent)
    {
    write-verbose "configuring network for gateway"
    $Clone | Set-VMXNetworkAdapter -Adapter 1 -ConnectionType nat -AdapterType vmxnet3
    $Clone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue
    $Clone | Set-VMXVnet -Adapter 0 -vnet $vmnet
    }
elseif(!$Isilon.IsPresent)
        {
        $Clone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue
        $Clone | Set-VMXVnet -Adapter 0 -vnet $vmnet
        }

$Clone | Set-VMXToolsReminder -enabled:$false
$Clone | Start-VMX
if (!$Isilon.IsPresent)
    {
	$Scripts_Folder = join-path $Builddir $Scripts
    $Clone | Set-VMXSharedFolderState -enabled
    $Clone | Set-VMXSharedFolder -add -Sharename Scripts -Folder $Scripts_Folder
    $Clone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir
    Write-verbose "waiting for Pass 1 (sysprep Finished)"
    Write-Host -ForegroundColor Gray " ==>waiting for Sysprep finished " -NoNewline
	test-user -whois Administrator
	Write-Host -ForegroundColor Green "[sysprep finished]"
    } #end not isilon
return,[bool]$True
}  