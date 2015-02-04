[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][int32]$Nodes =1,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][ValidateRange(3,6)][int32]$Disks = 5,
[Parameter(Mandatory=$False)][ValidateSet('36GB','72GB','146GB')][string]$Disksize = "36GB",
[Parameter(Mandatory=$False)]$Subnet = "10.10.0",
[Parameter(Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\ISImaster',
[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2"
)
#requires -version 3.0
#requires -module vmxtoolkit 

$Nodeprefix = "ISINode"

If (!($MasterVMX = get-vmx -path $MasterPath))
    {
    Write-Error "No Valid Master Found"
    break
    }

Write-Verbose "Tweaking VMX File"
$Config = Get-VMXConfig -config $MasterVMX.Config
$Config = $Config -notmatch "SCSI0:"
$Config = $Config -notmatch "ide0:0.fileName"
$Config += 'ide0:0.fileName = "boot0.vmdk"'
$Config += 'scsi0:0.redo = ""'
$Config += 'scsi0:0.present = "TRUE"'
$Config += 'scsi0:0.fileName = "isi-nvram.vmdk"'
$Config | set-Content -Path $MasterVMX.Config

$tweakname = Get-ChildItem $MasterVMX.config
$tweakdir = Split-Path -Leaf $tweakname.Directory
If ($tweakname.BaseName -notmatch  $tweakdir)
    {
    Rename-Item $tweakname -NewName "$tweakdir.vmx"
    }

write-verbose "re-reading Master"
$MasterVMX = get-vmx -path $MasterPath

if (!$MasterVMX.Template) 
    {
    write-verbose "Templating Master VMX"
    $template = $MasterVMX | Set-VMXTemplate
    }
$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"

if (!$Basesnap) 
    {
    Write-verbose "Base snap does not exist, creating now"
    $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
    }

####Build Machines#

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Verbose "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node))
    {
    write-verbose "Creating clone $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
    Write-Verbose "Creating Disks"
    $SCSI = 0
    foreach ($LUN in (1..$Disks))
            {
            $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
            Write-Verbose "Building new Disk $Diskname"
            $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
            Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
            $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
            }
    write-verbose "Setting ext-1"
    Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config
    Set-VMXVnet -Adapter 1 -vnet $vmnet -config $NodeClone.Config 
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    write-verbose "Setting Display Name $($NodeClone.CloneName)@$Builddomain"
    Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain" 
    Write-Verbose "Starting $Nodeprefix$node"
    start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName
    } # end check vm
    else
    {
    Write-Verbose "VM $Nodeprefix$node already exists"
    }
    }


