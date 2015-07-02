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
param (
$Subnet = "10.10.0",
$ProtectionDomainName = "PD_labbuildr",
$StoragePoolName = "SP_labbuildr",
$mdm_ip = "$Subnet.151,$Subnet.152",
$Servers = 3,
$Devices = 3,
$Password = "Password123!"
)


scli --user --login --username admin --password $Password --mdm_ip $mdm_ip
foreach ($server in (1..$Servers))
    {
    $Devicepath = "/dev/sdb"
    $sds_ip = "$Subnet.9$server"
    Write-Verbose "Adding $sds_ip with $Devicepath to ScaleIO"
    do
        {
        scli --add_sds --sds_ip $sds_ip --device_path $Devicepath --device_name "$Devicepath@$SDS_IP"  --sds_name $SDS_IP --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
        }
    until ($LASTEXITCODE -in ('0','7'))
    foreach ($Devicenumber in 2..$Devices)
        {
        $Devicepath = "/dev/sd"+[char[]](97+$Devicenumber)
        Write-Verbose "Adding $Devicepath  to $sds_ip"
        do
            {
            scli --add_sds_device --sds_ip $sds_ip --device_path $Devicepath --device_name "$Devicepath@$SDS_IP" --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --mdm_ip $mdm_ip
            }
        until ($LASTEXITCODE -in ('0','7'))
       }
    }
