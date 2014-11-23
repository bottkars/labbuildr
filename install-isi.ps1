[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][int32]$Nodes =1,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][ValidateRange(3,6)][int32]$Disks = 5,
[Parameter(Mandatory=$False)][ValidateSet('36GB','72GB','146GB')][string]$Disksize = "36GB",
[Parameter(Mandatory=$False)]$Subnet = "10.10.0",
[Parameter(Mandatory=$False)][ValidatePATTERN("[a-zA-Z]")][string]$Builddomain = "labbuildr",
[Parameter(Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\ISImaster',
[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2"
)
#requires -version 3.0
#requires -module vmxtoolkit 

$Nodeprefix = "ISINode"

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
    $Config = Get-VMXConfig -config $NodeClone.config
###### next will be replaced by add-vmxscsicontroller
    if ($Disks -ge 15)
        {
        Write-Verbose "Configuring SCSI Controller SCSI1"
        $Config = $Config |where {$_ -NotMatch "scsi1.present"}
        $Config += 'scsi1.present = "TRUE"'
        $Config = $Config |where {$_ -NotMatch "scsi1.VirtualDev"}
        $Config += 'scsi1.virtualDev = "lsilogic"'
        }
    if ($Disks -ge 30)
        {
        Write-Verbose "Configuring SCSI Controller SCSI2"
        $Config = $Config |where {$_ -NotMatch "scsi2.present"}
        $Config += 'scsi2.present = "TRUE"'
        $Config = $Config |where {$_ -NotMatch "scsi2.VirtualDev"}
        $Config += 'scsi2.virtualDev = "lsilogic"'
        }
    if ($Disks -ge 45)
        {
        Write-Verbose "Configuring SCSI Controller SCSI3"
        $Config = $Config |where {$_ -NotMatch "scsi3.present"}
        $Config += 'scsi3.present = "TRUE"'
        $Config = $Config |where {$_ -NotMatch "scsi3.VirtualDev"}
        $Config += 'scsi3.virtualDev = "lsilogic"'
        }
######




    Write-Verbose "Creating Disks"

  
    foreach ($Disk in 1..$Disks)
        {
     if ($Disk -le 6)
        {
        $SCSI = 0
        $Lun = $Disk
        }
     if (($Disk -gt 6) -and ($Disk -le 14))
        {
        $SCSI = 0
        $Lun = $Disk+1
        }
     if (($Disk -gt 14) -and ($Disk -le 21))
        {
        $SCSI = 1
        $Lun = $Disk-15
        }
     if (($Disk -gt 21) -and ($Disk -le 29))
        {
        $SCSI = 1
        $Lun = $Disk-14
        }
     if (($Disk -gt 29) -and ($Disk -le 36))
        {
        $SCSI = 2
        $Lun = $Disk-30
        }
     if (($Disk -gt 36) -and ($Disk -le 44))
        {
        $SCSI = 2
        $Lun = $Disk-29
        }
     if (($Disk -gt 44) -and ($Disk -le 51))
        {
        $SCSI = 3
        $Lun = $Disk-45
        }
     if (($Disk -gt 51) -and ($Disk -le 59))
        {
        $SCSI = 3
        $Lun = $Disk-44
        }

        Write-Verbose "SCSI$($Scsi):$lun"
        $Diskname = "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
        $Diskpath = "$($NodeClone.Path)\$Diskname"
        Write-Verbose "Creating Disk #$Disk with $Diskname and a size of $Disksize"
        & $VMWAREpath\vmware-vdiskmanager.exe -c -s $Disksize -a lsilogic -t 0 $Diskpath 2>> error.txt
        
        $AddDrives  = @('scsi'+$scsi+':'+$LUN+'.present = "TRUE"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.deviceType = "disk"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.fileName = "'+$Diskname+'"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.mode = "persistent"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.writeThrough = "false"')
        $Config += $AddDrives
        }
    
    $Config | set-Content -Path $NodeClone.Config
    write-verbose "Setting ext-a"
    Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config
    Set-VMXVnet -Adapter 1 -vnet $vmnet -config $NodeClone.Config 
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    Write-Verbose "Starting $Nodeprefix$node"
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    Set-VMXDisplayName -config $NodeClone.Config -Value "$($NodeClone.CloneName)@$Builddomain"
    start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName
    } # end check vm
    else
    {
    Write-Verbose "VM $Nodeprefix$node already exists"
    }
    }


