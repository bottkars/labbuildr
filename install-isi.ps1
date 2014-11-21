[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][int32]$Nodes =1,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][int32]$Disks = 5,
[Parameter(Mandatory=$False)][ValidateSet('36GB','72GB','146GB')][string]$Disksize = 36,
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

    Write-Verbose "Creating Disks"

  
    foreach ( $Disk in 1..$Disks)
        {
        $Diskname = "0_"+$Disk+"_"+$Disksize+".vmdk"
        $Diskpath = "$($NodeClone.Path)\$Diskname"
        Write-Verbose "Creating Disk #$Disk with $Diskname and a size of $Disksize"
        & $VMWAREpath\vmware-vdiskmanager.exe -c -s $Disksize -a lsilogic -t 0 $Diskpath 2>&1 | Out-Null
        $AddDrives  = @('scsi0:'+$Disk+'.present = "TRUE"')
        $AddDrives += @('scsi0:'+$Disk+'.deviceType = "disk"')
        $AddDrives += @('scsi0:'+$Disk+'.fileName = "'+$Diskname+'"')
        $AddDrives += @('scsi0:'+$Disk+'.mode = "persistent"')
        $AddDrives += @('scsi0:'+$Disk+'.writeThrough = "false"')
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
    start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName
    } # end check vm
    else
    {
    Write-Verbose "VM $Nodeprefix$node already exists"
    }
    }


