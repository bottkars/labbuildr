[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$SCALEIOMasterPath,
[Parameter(Mandatory=$true)][int32]$Nodes,
[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet
)



### prepare 

# $SCALEIOMasterPath = "E:\LABBUILDR\ScaleIOVM_1.30.426.0"

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
    Write-Verbose "Creating Disk"
    & $VMWAREpath\vmware-vdiskmanager.exe -c -s 100GB -a lsilogic -t 0 "$($ScaleioClone.Path)\0_1_100GB.vmdk" 2>&1 | Out-Null
    $AddDrives = @('scsi0:1.present = "TRUE"','scsi0:1.deviceType = "disk"','scsi0:1.fileName = "0_1_100GB.vmdk"','scsi0:1.mode = "persistent"','scsi0:1.writeThrough = "false"')
    $Config += $AddDrives
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



# $vmx | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3


