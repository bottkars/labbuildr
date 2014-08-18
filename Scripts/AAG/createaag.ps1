<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3

Param
(
    [string] $Nodeprefix = "AAGNODE",
    [string] $AgName = "labbuildrAvailabilityGroup",
    [string] $DatabaseList = "AdventureWorks2012",
    [string] $BackupShare = "\\vmware-host\Shared Folders\Sources\AWORKS",
    $IPAddress = "192.168.2.169"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############

$NodeLIST = @()
$AAGnodes = Get-ADComputer -Filter * | where name -match $Nodeprefix
foreach ($AAGnode in $AAGnodes){
$NodeLIST += $AAGNode.Name+"\MSSQL"+$AAGNode.Name
#$NodeLIST += $AAGNode.Name+"\MSSQLAAG"
write-Host "Adding Node $AAGnode to AAG Nodelist"
}
Import-Module “sqlps” -DisableNameChecking
# Initialize some collections
$serverObjects = @()
$replicas = @()
[System.Reflection.Assembly]::loadwithPartialName("Microsoft.SQLServer.SMO")
foreach ($server in $Nodelist)
{
    # Connection to the server instance, using Windows authentication
    Write-Verbose "Creating SMO Server object for server: $server"
    $serverObject = New-Object Microsoft.SQLServer.Management.SMO.Server($server) 
    $serverObjects += $serverObject

    # Get the mirroring endpoint on the server
    $endpointObject = $serverObject.Endpoints | 
        Where-Object { $_.EndpointType -eq "DatabaseMirroring" } | 
        Select-Object -First 1

    # Create an endpoint if one doesn't exist
    if($endpointObject -eq $null)
    {
        throw "No Mirroring endpoint found on server: $server"
    }

    $fqdn = $serverObject.Information.FullyQualifiedNetName
    $port = $endpointObject.Protocol.Tcp.ListenerPort
    $endpointURL = "TCP://${fqdn}:${port}"

    # Create an availability replica for this server instance.
    # For this example all replicas use asynchronous commit, manual failover, and 
    # support reads on the secondaries
    $replicas += (New-SqlAvailabilityReplica `
            -Name $server `
            -EndpointUrl $endpointURL `
            -AvailabilityMode "AsynchronousCommit" `
            -FailoverMode "Manual" `
            -ConnectionModeInSecondaryRole "AllowAllConnections" `
            -AsTemplate `
            -Version 11) 
}



$primary, $secondaries = $serverObjects
$primary

foreach ($db in $DatabaseList)
{
    $dbdata = $db+"_Data"
    $dblog = $db+"_log"
    $bakFile = Join-Path $BackupShare "$db.bak"
    $datapath = $primary.DefaultFile
    $logpath = $primary.DefaultLog
    $datafile = $datapath + $db + '.mdf'
    $logfile = $logpath + $db + '_log.ldf'
    $BCMD = "RESTORE DATABASE [$db] FROM  DISK = N'$bakfile' WITH  FILE = 1,  MOVE N'$dbdata' TO N'$datafile',  MOVE N'$dblog' TO N'$logfile',  NOUNLOAD,  STATS = 5"
    Invoke-Sqlcmd -Query $BCMD -ServerInstance $primary.Name

}




##### secondary restores


foreach ($db in $DatabaseList)

   {$db
    $Backupfile = $db+'.bak'
    $dbdata = $db+"_Data"
    $dblog = $db+"_log"
    #    $bakFile = Join-Path $BackupShare "$db.bak"
    $bakFile = Join-Path $BackupShare $Backupfile
    foreach($secondary in $secondaries)
    {
    $datapath = $secondary.DefaultFile
    $logpath = $secondary.DefaultLog
    $datafile = $datapath + $db + '.mdf'
    $logfile = $logpath + $db + '_log.ldf'
    $BCMD = "RESTORE DATABASE [$db] FROM  DISK = N'$bakfile' WITH  FILE = 1,  MOVE N'$dbdata' TO N'$datafile',  MOVE N'$dblog' TO N'$logfile',  NORECOVERY,  NOUNLOAD,  STATS = 5"
    Invoke-Sqlcmd -Query $BCMD -ServerInstance $secondary.Name

    }# end secondary
}


# Create the availability group
New-SqlAvailabilityGroup -Name $AgName -InputObject $primary -AvailabilityReplica $Replicas -Database $DatabaseList | Out-Null

# Join the secondary replicas, and join the databases on those replicas
foreach ($secondary in $secondaries)
{
    Write-Host "Joining secondary instance $secondary to the availability group '$AgName'"
    Join-SqlAvailabilityGroup -InputObject $secondary -Name $AgName
    $ag = $secondary.AvailabilityGroups[$AgName]
    Write-Host "Joining secondary databases on $secondary to the availability group '$AgName'"
    Add-SqlAvailabilityDatabase -InputObject $ag -Database $DatabaseList 

}

## Creating the Listener
$BCMD = "
USE [master]
GO
ALTER AVAILABILITY GROUP [$AgName]
ADD LISTENER N'NWAAG' (
WITH IP
((N'$IPAddress', N'255.255.255.0')
)
, PORT=55555)"

Invoke-Sqlcmd -Query $BCMD -ServerInstance $primary.Name


$NWNAMEres = Get-ClusterResource | where Resourcetype -eq "Network Name"
foreach ($res in $NWNAMEres){
Set-ClusterParameter -Name PublishPTRRecords -Value 1 -InputObject $res
Stop-ClusterResource -Name $res
Start-ClusterResource -Name $res
}

