[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$SCALEIOMasterPath,
[Parameter(Mandatory=$true)][int32]$Nodes,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][int32]$Disks = 3,
[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet
)



$MasterVMX = get-vmx -path $SCALEIOMasterPath


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

foreach ($Node in 1..$Nodes)
    {
    write-verbose " Creating Scaleionode$node"
    $ScaleioClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName ScaleioNode$Node 
    $Config = Get-VMXConfig -config $ScaleioClone.config
    $Config = $config | ForEach-Object { $_ -replace "lsilogic" , "pvscsi" }
    Write-Verbose "Creating Disks"

  
    foreach ( $Disk in 1..$Disks)
        {
        $Diskpath = "$($ScaleioClone.Path)\0_"+$Disk+"_100GB.vmdk"
        Write-Verbose "Creating Disk # $Disk"
        & $VMWAREpath\vmware-vdiskmanager.exe -c -s 100GB -a lsilogic -t 0 $Diskpath 2>&1 | Out-Null
        $AddDrives  = @('scsi0:'+$Disk+'.present = "TRUE"')
        $AddDrives += @('scsi0:'+$Disk+'.deviceType = "disk"')
        $AddDrives += @('scsi0:'+$Disk+'.fileName = "0_'+$Disk+'_100GB.vmdk"')
        $AddDrives += @('scsi0:'+$Disk+'.mode = "persistent"')
        $AddDrives += @('scsi0:'+$Disk+'.writeThrough = "false"')
        $Config += $AddDrives
        }
    
    $Config | set-Content -Path $ScaleioClone.Config
    write-verbose "Setting NIC0 to HostOnly"
    Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $ScaleioClone.Config
    if ($vmnet)
        {
         Write-Verbose "Configuring NIC 2 and 3 for $vmnet"
         Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType vmxnet3 -config $ScaleioClone.Config 
         Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType vmxnet3 -config $ScaleioClone.Config 
         Set-VMXVnet -Adapter 1 -vnet $vmnet -config $ScaleioClone.Config 
         Set-VMXVnet -Adapter 2 -vnet $vmnet -config $ScaleioClone.Config

        }
    $Scenario = Set-VMXscenario -config $ScaleioClone.Config -Scenarioname Scaleio -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $ScaleioClone.Config -activationpreference $Node 
    Write-Verbose "Starting ScalioNode$Node"
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    start-vmx -Path $ScaleioClone.Path -VMXName $ScaleioClone.CloneName
    }






