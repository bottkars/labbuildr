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
    [string[]] $Nodeprefix = "AAGNODE",
    [string] $EndpointPort = 5022,
    [string] $EndpointName = "AlwaysOn_Endpoint"
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
#$NodeLIST += $AAGNode.Name+"\MSSQLAAG"
$NodeLIST += $AAGNode.Name+"\MSSQL"+$AAGNode.Name

write-Host "Adding Node $AAGnode to AAG Nodelist"
}
## - Loading the SQL Server SMO Assembly"
Import-Module “sqlps” -DisableNameChecking
[System.Reflection.Assembly]::loadwithPartialName("Microsoft.SQLServer.SMO")
foreach ($server in $NodeList)
{
    # Connection to the server instance, using Windows authentication
    Write-Verbose "Creating SMO Server object for server: $server"
    $serverObject = New-Object Microsoft.SQLServer.Management.SMO.Server($server)

    # Enable AlwaysOn. We use the -Force option to force a server restart without confirmation.
    # This WILL result in your SQL Server instance restarting.
    Write-Verbose "Enabling AlwaysOn on server instance: $server"
    Enable-SqlAlwaysOn -InputObject $serverObject -Force

    # Check if the server already has a mirroring endpoint (note: a server can only have one)
    $endpointObject = $serverObject.Endpoints |
        Where-Object { $_.EndpointType -eq "DatabaseMirroring" } |
        Select-Object -First 1

    # Create an endpoint if one doesn't exist
    if($endpointObject -eq $null)
    {
        Write-Verbose "Creating endpoint '$EndpointName' on server instance: $server"
        $endpointObject = New-SqlHadrEndpoint -InputObject $serverObject -Name $EndpointName -Port $EndpointPort
    }
    else
    {
        Write-Verbose "An endpoint already exists on '$server', skipping endpoint creation."
    }

    # Start the endpoint
    Write-Verbose "Starting endpoint on server instance: $server"
    Set-SqlHadrEndpoint -InputObject $endpointObject -State "Started" | Out-Null
}
