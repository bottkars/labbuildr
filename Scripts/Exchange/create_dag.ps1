<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param ($DAGIP = ([System.Net.IPAddress])::None)

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$Domain = $env:USERDOMAIN
$Dagname = $Domain+"DAG"
$WitnessDirectory = "C:\FSW_"+$Dagname
$DBNAME = $Dagname+"_DB1"
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$env:COMPUTERNAME/PowerShell/ -Authentication Kerberos -Credential $Credential
Import-PSSession $Session

$WitnessServer = (Get-DomainController).name
$ADAdminGroup = Get-ADGroup -Filter * | where name -eq Administrators
$ADTrustedEXGroup = Get-ADGroup -Filter * | where name -eq "Exchange Trusted Subsystem"
Add-ADGroupMember -Identity $ADAdminGroup -Members $ADTrustedEXGroup  -Credential $Credential

Write-Host "Creating the DAG" -foregroundColor Yellow
New-DatabaseAvailabilityGroup -name $DAGName -WitnessServer $WitnessServer -WitnessDirectory $WitnessDirectory -DatabaseAvailabilityGroupIPAddress $DAGIP

Write-Host "Adding DAG Member" $Server -ForeGroundColor Yellow

$MailboxServers = Get-MailboxServer | Select -expandProperty Name
foreach($Server in $MailboxServers){
    Add-DatabaseAvailabilityGroupServer -id $DAGName -MailboxServer $Server
}
write-host "DAG $Dagname created"
if ($DAGIP -ne ([System.Net.IPAddress])::None) { 
write-host "Changing PTR Record" 
########## changing cluster to register PTR record 
$res = Get-ClusterResource "Cluster Name" 
Set-ClusterParameter -Name PublishPTRRecords -Value 1 -InputObject $res
Stop-ClusterResource -Name $res
Start-ClusterResource -Name $res
}




################# Create database

Write-Host "Creating Mailbox Database $DBName " -foregroundcolor yellow
New-MailboxDatabase -Name $DBName -EDBFilePath "O:\$DBNAME\$DBName.edb" -LogFolderPath "P:\$DBNAME\Log" -Server $env:COMPUTERNAME
Mount-Database -id $DBName
Write-Host "Setting Offline Address Book" -foregroundcolor Yellow
Set-MailboxDatabase $DBName -offlineAddressBook "Default Offline Address Book"

############### create copies
	
foreach($Server in $MailboxServers){
		if(!($Server -eq $ENV:ComputerName)){
		Write-Host "Creating database Copy $DBName" -foregroundcolor yellow
			Add-MailboxDatabaseCopy -id $DBName -MailboxServer $Server
		}
	}


Remove-PSSession $Session