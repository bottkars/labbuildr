<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[cmdletBinding()] 
param (
[parameter(mandatory = $false)]$PlainPassword = "Password123!",
[parameter(mandatory = $false)]$BackupAdmin = "HyperVBackupUser"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
Function Add-DomainUserToLocalGroup 
{ 
[cmdletBinding()] 
Param( 
[Parameter(Mandatory=$True)][string]$computer, 
[Parameter(Mandatory=$True)][string]$group, 
[Parameter(Mandatory=$True)][string]$domain, 
[Parameter(Mandatory=$True)][string]$user 
) 
$de = [ADSI]"WinNT://$computer/$Group,group" 
$de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path) 
} #end function Add-DomainUserToLocalGroup
$ADDomain = (get-addomain).forest
$maildom= "@"+$ADDomain

#$PlainPassword = "Password123!"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
New-ADUser -Name $BackupAdmin -AccountPassword $SecurePassword -PasswordNeverExpires $True -Enabled $True -EmailAddress "$BackupAdmin$maildom" -samaccountname $BackupAdmin -userprincipalname "$BackupAdmin$Maildom" 
foreach ($ADgroup in ( "Remote Desktop Users"))#, "Windows Authorization Access Group"))
    {
    Write-Verbose "Adding $BackupAdmin to $ADgroup"
    Add-ADGroupMember -Identity $ADgroup -Members $BackupAdmin
    }

Grant-ClusterAccess -User $ADDomain\$BackupAdmin -Full
$Nodes = get-cluster . | Get-ClusterNode
foreach ($Node in $Nodes)
    {
    foreach ($localgroup in ( "Administrators", "Backup Operators", "Hyper-V Administrators","Remote Desktop Users"))
        {
        Write-Verbose "Adding $BackupAdmin to $localgroup"
        Add-DomainUserToLocalGroup -computer $Node.Name -group $localgroup -domain $ADDomain -user $BackupAdmin
        }
    }
