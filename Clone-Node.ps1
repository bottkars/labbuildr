<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
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
$Sourcedir
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
$VMrunErrorCondition = @("Error: The virtual machine is not powered on","Waiting for Command execution Available","Error","Unable to connect to host.","Error: The operation is not supported for the specified parameters","Unable to connect to host. Error: The operation is not supported for the specified parameters")
function write-log {
    Param ([string]$line)
    $Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
    Add-Content $Logfile -Value "$Logtime  $line"
}

function test-user {param ($whois)
$Origin = $MyInvocation.MyCommand
do {([string]$cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword listProcessesInGuest $Clone.config )2>&1 | Out-Null
Write-Debug $cmdresult
Start-Sleep 5
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

if (get-vmx $Nodename)
{
Write-Warning "$Nodename already exists"
return $false
}
else
{
$Displayname = "$Nodename@$Domainname"
Write-Host -ForegroundColor Gray "Creating Linked Clone $Nodename from $MasterVMX, VMsize is $Size"
Write-verbose "Creating linked $Nodename of $MasterVMX"
# while (!(Get-ChildItem $MasterVMX)) {
# write-Host "Try Snapshot"

$Clone = $Snapshot | New-VMXLinkedClone -CloneName $Nodename -clonepath $Builddir
write-verbose "starting customization of $($Clone.config)"
$Content = $Clone | Get-VMXConfig
$Content = $Content | where {$_ -notmatch "memsize"}
$Content = $Content | where {$_ -notmatch "numvcpus"}
$Content = $Content | where {$_ -notmatch "sharedFolder"}
$Content = $Content | where {$_ -notmatch "svga.autodetecct"}
$Content = $Content | where {$_ -notmatch "gui.applyHostDisplayScalingToGuest"}
$Content += 'gui.applyHostDisplayScalingToGuest = "FALSE"'
$Content += 'svga.autodetect = "TRUE" '
$Content += 'sharedFolder0.present = "TRUE"'
$Content += 'sharedFolder0.enabled = "TRUE"'
$Content += 'sharedFolder0.readAccess = "TRUE"'
$Content += 'sharedFolder0.writeAccess = "TRUE"'
$Content += 'sharedFolder0.hostPath = "'+"$Sourcedir"+'"'
$Content += 'sharedFolder0.guestName = "Sources"'
$Content += 'sharedFolder0.expiration = "never"'
$Content += 'sharedFolder.maxNum = "1"'

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
$content += 'memsize = "6144"'
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

Set-Content -Path $Clone.config -Value $content -Force
(get-content $Clone.config) | foreach-object {$_ -replace 'gui.exitAtPowerOff = "FALSE"','gui.exitAtPowerOff = "TRUE"'} | set-content $Clone.Config
$Clone | Set-VMXMainMemory -usefile:$false
$Clone | Set-VMXDisplayName -DisplayName $Displayname
if ($HyperV){
($Clone | Get-VMXConfig) | foreach-object {$_ -replace 'guestOS = "windows8srv-64"', 'guestOS = "winhyperv"' } | set-content $Clone.config
($Clone | Get-VMXConfig) | foreach-object {$_ -replace 'guestOS = "windows9srv-64"', 'guestOS = "winhyperv"' } | set-content $Clone.config

}
$Clone | Set-VMXAnnotation -builddate -Line1 "This is node $Nodename for domain $Domainname"-Line2 "Adminpasswords: Password123!" -Line3 "Userpasswords: Welcome1"
######### next commands will be moved in vmrunfunction soon 
# KB , 06.10.2013 ##
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

Set-VMXActivationPreference -config $Clone.config -activationpreference $ActivationPreference
Set-VMXscenario -config $Clone.config -Scenario $Scenario -Scenarioname $scenarioname
Set-VMXscenario -config $Clone.config -Scenario 9 -Scenarioname labbuildr
if ($bridge.IsPresent)
    {
    write-verbose "configuring network for bridge"
    Set-VMXNetworkAdapter -config $Clone.config -Adapter 1 -ConnectionType bridged -AdapterType vmxnet3
    Set-VMXNetworkAdapter -config $Clone.config -Adapter 0 -ConnectionType custom -AdapterType vmxnet3
    Set-VMXVnet -config $Clone.config -Adapter 0 -vnet $vmnet
    }
elseif($NW -and $gateway.IsPresent) 
    {
    write-verbose "configuring network for gateway"
    Set-VMXNetworkAdapter -config $Clone.config -Adapter 1 -ConnectionType nat -AdapterType vmxnet3
    Set-VMXNetworkAdapter -config $Clone.config -Adapter 0 -ConnectionType custom -AdapterType vmxnet3
    Set-VMXVnet -config $Clone.config -Adapter 0 -vnet $vmnet
    }
elseif(!$Isilon.IsPresent)
        {
        Set-VMXNetworkAdapter -config $Clone.config -Adapter 0 -ConnectionType custom -AdapterType vmxnet3
        Set-VMXVnet -config $Clone.config -Adapter 0 -vnet $vmnet
        }

$Clone | Set-VMXToolsReminder -enabled:$false

Write-Host -ForegroundColor DarkCyan "Booting into Machine Customization, this may take a while"
$Clone | Start-VMX
if (!$Isilon.IsPresent)
    {
    Write-Host -ForegroundColor Gray "Enabling Shared Folders"
    $Clone | Set-VMXSharedFolderState -enabled
    # $Clone | Write-Host -ForegroundColor Gray
    $Clone | Set-VMXSharedFolder -add -Sharename Scripts -Folder "$Builddir\Scripts"
    Write-verbose "Waiting for Pass 1 (sysprep Finished)"
    test-user -whois Administrator
    } #end not isilon
return,[bool]$True
}
