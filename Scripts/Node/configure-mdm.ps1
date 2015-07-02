<#
.Synopsis
   This script builds the scaleio mdm, sds and sdc for a hyper-v cluster
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
[CmdletBinding()]
param (
[parameter(mandatory = $false)][ValidateRange(1,10)]$CSVnum = 3,
[parameter(mandatory = $false)]$password = "Password123!",
[parameter(mandatory = $false)][switch]$singlemdm
)

#requires -version 3
#requires -module FailoverClusters
# 1. ######################################################################################################
# Initilization. you may want to adjust the Parameters for your needs
if (!(Get-Cluster . -ErrorAction SilentlyContinue) )
    {
    Write-Warning " This Deploymentmethod requires Windows Failover Cluster Configured"
    break
    }

$Location = $env:USERDOMAIN
$nodes = Get-ClusterNode
$Percentage = [math]::Round(100/$nodes.count)+1
write-verbose "fetching remote IP Addresses..."
$NodeIP = foreach ($node in $nodes){
Invoke-Command -ComputerName $node.name -ScriptBlock {param( $Location )
    (Get-NetIPAddress -AddressState Preferred -InterfaceAlias $Location -SkipAsSource $false -AddressFamily IPv4 ).IPAddress
    } -ArgumentList $Location
}
$PrimaryIP = $NodeIP[0]
$SecondaryIP = $NodeIP[1]
$TiebreakerIP = $NodeIP[2]
Write-Verbose $PrimaryIP
Write-Verbose $SecondaryIP
Write-Verbose $TiebreakerIP
if ($singlemdm.IsPresent)
    {
    $mdm_ip ="$PrimaryIP"
    }
    else
    {
    $mdm_ip ="$PrimaryIP,$SecondaryIP"
    }
write-verbose " mdm will be at :$mdm_ip"
$Devicename = "$Location"+"_Disk_$Driveletter"
$VolumeName = "Volume_$Location"
$ProtectionDomainName = "PD_$Location"
$StoragePoolName = "SP_$Location"

# 2. ######################################################################################################
####### create MDM
## Manually run and accept license terms !!!
######################################################################################################
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now creating the Primary M[eta] D[ata] M[anager]"
    Pause
    }
do {
Scli --add_primary_mdm --primary_mdm_ip $PrimaryIP --mdm_management_ip $PrimaryIP --accept_license
Write-Output $LASTEXITCODE
}
until ($LASTEXITCODE -in ('0','7'))
 

# 3. ######################################################################################################
# add mdm, tb and switch cluster
Write-Verbose "changing MDM Password to $password"
do 
    {
    scli --login --username admin --password admin --mdm_ip $PrimaryIP
    }
until ($LASTEXITCODE -in ('0','7'))
do
    {
    scli --set_password --old_password admin --new_password $Password --mdm_ip $mdm_ip
}
until ($LASTEXITCODE -in ('0','7'))


if (!$singlemdm.IsPresent)
    {
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
    Write-Verbose "We are now adding the secondary M[eta] D[ata] M[anager] and T[ie [Breaker] abd form the Management Cluster"
    Write-Verbose "Open your ScalIO management UI and Connect to $PrimaryIP with admin / $Password and then to Monitor the Progress"
    Pause
    }

do 
        {
    scli --user --login --username admin --password $Password --mdm_ip $mdm_ip
    }
    until ($LASTEXITCODE -in ('0','7'))
    do 
        {
    scli --add_secondary_mdm --mdm_ip $PrimaryIP --secondary_mdm_ip $SecondaryIP --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
    until ($LASTEXITCODE -in ('0','7'))
    do {
    scli --add_tb --tb_ip $TiebreakerIP --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
    until ($LASTEXITCODE -in ('0','7'))
    do {
    scli --switch_to_cluster_mode --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0','7'))
    }

else
    {
    Write-Warning "Running SqleIO ind SingleMDM Mode"
    }

# 4. ######################################################################################################
##### configure protection Domain and Storage Pool
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now configuring the Protection Domain and Storage Pool"
    Pause
    }

scli --user --login --username admin --password $Password --mdm_ip $mdm_ip
do {
    scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0','7'))

do {
    scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0','7'))

do {
    scli --modify_spare_policy --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --spare_percentage $Percentage --i_am_sure --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0','7'))
do {
scli --rename_system --new_name "ScaleIO@$Location" --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0','7'))


# 5. ######################################################################################################
#### Create SDS 

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding the S[torage] D[ata] S[ervice] Nodes"
    Pause
    }
<# $Driveletters = (get-volume | where {$_.DriveType -match "fixed" -and $_.Size -le 0 -and  $_.DriveLetter -ne ""}).Driveletter
# Write-verbose "Configuring SDS´s with $Driveletters[0] as SDS Device"
$Devicename = "$Location"+"_Disk_$($Driveletters[0])"
scli --add_sds --sds_ip $PrimaryIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode1 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds --sds_ip $SecondaryIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode2 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds --sds_ip $TiebreakerIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode3 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
#>
$Disks = @()
$Disks += (Get-ChildItem -Path C:\scaleio_devices\ -Recurse -Filter *.bin ).FullName

$Devicename = "PhysicalDisk1"
scli --add_sds --sds_ip $PrimaryIP --device_path $Disks[0] --device_name $Devicename  --sds_name hvnode1 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds --sds_ip $SecondaryIP --device_path $Disks[0] --device_name $Devicename  --sds_name hvnode2 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds --sds_ip $TiebreakerIP --device_path $Disks[0] --device_name $Devicename  --sds_name hvnode3 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip


# 6. ######################################################################################################
##### Add Disks to SDS Nodes # im am looking for Unformatted Fixed Drive with Driveletter
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding Additional Drives to the Storage Data Service Nodes"
    Pause
    }
scli --user --login --username admin --password $Password --mdm_ip $mdm_ip

<#
foreach ($Driveletter in $Driveletters | where {$_ -NotMatch $Driveletters[0]})
{
Write-verbose "Configuring $Driveletter as SDS Device"
$Devicename = "$Location"+"_Disk_$Driveletter"
scli --add_sds_device --sds_ip $PrimaryIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds_device --sds_ip $SecondaryIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
scli --add_sds_device --sds_ip $TiebreakerIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
}
#>

If ($Disks.Count -gt 1)
{
    foreach ($Disk in 2..($Disks.Count)) 
    {
    $Devicename = "PhysicalDisk$Disk"
    $Devicepath = $Disks[$Disk-1]
    Write-Verbose $Devicename
    Write-Verbose $Devicepath
    scli --add_sds_device --sds_ip $PrimaryIP --device_path $Devicepath --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
    scli --add_sds_device --sds_ip $SecondaryIP --device_path $Devicepath --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
    scli --add_sds_device --sds_ip $TiebreakerIP --device_path $Devicepath --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip
    }
}
# 7. ###################################################################################################### 
### connect sdc's
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding the S[torage] D[ata] C[lients]"
    Pause
    }
$nodes = get-clusternode
foreach ($node in $nodes)

{
Write-verbose  "Adding $($Node.Name) to the ScaleIO grid"


Invoke-Command -ComputerName $node.name -ScriptBlock {param( $mdm_ip )

."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --add_mdm --ip $mdm_ip
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --query_mdms

} -ArgumentList $mdm_ip
}

scli --mdm_ip $mdm_ip --query_all_sdc
    
do {
    scli --query_sdc --sdc_ip $PrimaryIP --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0'))
do {
    scli --query_sdc --sdc_ip $SecondaryIP --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0'))
do {
    scli --query_sdc --sdc_ip $TiebreakerIP --mdm_ip $mdm_ip
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in ('0'))
# 8. ######################################################################################################
### Create and map Volumes
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "Now Volume Creation and Mapping will start. Volumes will be added to the Cluster"
    Pause
    }
scli --user --login --username admin --password $Password --mdm_ip $mdm_ip
foreach ($Volumenumber in 1..$CSVnum)
{


$VolumeName = "Vol_$Volumenumber"
scli --mdm_ip $mdm_ip --query_all_volumes


do 
    {
    $newvol = scli --add_volume --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --size_gb 20 --thin_provisioned --volume_name $VolumeName --mdm_ip $mdm_ip
    Write-Warning $LASTEXITCODE
    Write-Output $newvol    
    }
until ($LASTEXITCODE -in ('0'))
#until ($LASTEXITCODE -in ('0','7') -and $newvol -notmatch "Error: MDM failed command.  Status: System capacity is unbalanced")

do 
    {
    scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $PrimaryIP --allow_multi_map --mdm_ip $mdm_ip
    }
until ($LASTEXITCODE -in ('0'))
do 
    {
    scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $SecondaryIP --allow_multi_map --mdm_ip $mdm_ip
    }
until ($LASTEXITCODE -in ('0'))
do 
    {
    scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $TiebreakerIP --allow_multi_map --mdm_ip $mdm_ip
    }
until ($LASTEXITCODE -in ('0'))

# join array to string, split at id remove spaces and select last
$serial = (($newvol -join '').Split('ID')).Replace(' ','')[-1]


# 9. ######################################################################################################
# initialize and import Cluster Disks
######## Disk
Write-Output "Waiting for Disk to Appear"
do
    {
    $Disk = Get-Disk  | where SerialNumber -match $serial
    if (!$disk){write-host -NoNewline "."}
    } until ($Disk) 
$Disk | Initialize-Disk -PartitionStyle GPT
$Partition = $Disk  | New-Partition -UseMaximumSize
$WinVolName =  "Scaleio_CSV_"+$VolumeName+"_"+$Serial
$WinVollabel = "Scaleio_CSV_"+$VolumeName
$Partition | Format-Volume -NewFileSystemLabel $WinVollabel -Confirm:$false
$Disk = Get-Disk  | where SerialNumber -match  $Serial 
$Clusterdisk = $Disk  | Add-ClusterDisk
$Clusterdisk.Name = $WinVolName
Get-ClusterResource -Name $Clusterdisk.Name | Add-ClusterSharedVolume
}

