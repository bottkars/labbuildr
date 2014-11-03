### Instuctions
# Copy all paragraph subsecuent to a Powershell Session and run


# 1. ######################################################################################################
# Initilization. you may want to adjust the Parameters for your needs
$Location = "Airplay"
$PrimaryIP = "10.10.0.151"
$SecondaryIP = "10.10.0.152" 
$TiebreakerIP = "10.10.0.153" 
$mdm_ip ="$PrimaryIP,$SecondaryIP"
$Devicename = "$Location"+"_Disk_$Driveletter"
$VolumeName = "Volume_$Location"
$ProtectionDomainName = "PD_EMCDemo"
$StoragePoolName = "SP_Demo"

# 2. ######################################################################################################
####### create MDM
## Manually run and accept license terms !!!
######################################################################################################
Scli --add_primary_mdm --primary_mdm_ip $PrimaryIP --mdm_management_ip $mdm_ip


# 3. ######################################################################################################
# add mdm, tb and switch cluster
scli --login --username admin --password admin --mdm_ip $mdm_ip
scli --set_password --old_password admin --new_password Password123! --mdm_ip $mdm_ip
scli --user --login --username admin --password Password123! --mdm_ip $mdm_ip
scli --add_secondary_mdm --mdm_ip $PrimaryIP --secondary_mdm_ip $SecondaryIP --mdm_ip $mdm_ip
scli --add_tb --tb_ip $TiebreakerIP --mdm_ip $PrimaryIP
scli --switch_to_cluster_mode --mdm_ip $PrimaryIP


# 4. ######################################################################################################
##### configure protection Domain and Storage Pool
scli --user --login --username admin --password Password123! --mdm_ip $mdm_ip
scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip
scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip

# 5. ######################################################################################################
#### Create SDS 
$Driveletters = (get-volume | where {$_.DriveType -match "fixed" -and $_.FileSystemType -match "Unknown" -and  $_.DriveLetter -ne ""}).Driveletter
scli --add_sds --sds_ip $PrimaryIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode1 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
scli --add_sds --sds_ip $SecondaryIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode2 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
scli --add_sds --sds_ip $TiebreakerIP --device_path $Driveletters[0] --device_name $Devicename  --sds_name hvnode3 --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip

# 6. ######################################################################################################
##### Add Disks to SDS Nodes # im am looking for Unformatted Fixed Drive with Driveletter
scli --user --login --username admin --password Password123! --mdm_ip $mdm_ip
foreach ($Driveletter in $Driveletters | where {$_ -NotMatch $Driveletters[0]})
{
Write-Output $Driveletter
$Devicename = "$Location"+"_Disk_$Driveletter"
scli --add_sds_device --sds_ip $PrimaryIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
scli --add_sds_device --sds_ip $SecondaryIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
scli --add_sds_device --sds_ip $TiebreakerIP --device_path $Driveletter --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName  --mdm_ip $mdm_ip
}

# 7. ###################################################################################################### 
### connect sdc's

$nodes = get-clusternode
foreach ($node in $nodes)
{Write-Output $Node.Name


Invoke-Command -ComputerName $node.name -ScriptBlock {param( $mdm_ip )

."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --add_mdm --ip $mdm_ip

} -ArgumentList $mdm_ip
}


# 8. ######################################################################################################
### Create and map Volumes
scli --user --login --username admin --password Password123! --mdm_ip $mdm_ip
foreach ($Volumenumber in 1..10)
{


$VolumeName = "Vol_$Volumenumber"

$newvol = scli --add_volume --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --size_gb 20 --thin_provisioned --volume_name $VolumeName --mdm_ip $mdm_ip
scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $PrimaryIP --allow_multi_map --mdm_ip $mdm_ip
scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $SecondaryIP --allow_multi_map --mdm_ip $mdm_ip
scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $TiebreakerIP --allow_multi_map --mdm_ip $mdm_ip
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

