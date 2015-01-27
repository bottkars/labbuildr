<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
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
$BackupAdmin = "HyperVBackupUser"
$PlainPassword = "Password123!"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
New-ADUser -Name $BackupAdmin -AccountPassword $SecurePassword -PasswordNeverExpires $True -Enabled $True -EmailAddress "$BackupAdmin$maildom" -samaccountname $BackupAdmin -userprincipalname "$BackupAdmin$Maildom" 
foreach ($ADgroup in ("Backup Operators", "Hyper-V Administrator", "Remote Desktop Users", "Windows Authorization Access Group", "Add Group Policy User Control")){
Add-ADGroupMember -Identity $ADgroup -Members $BackupAdmin
}

Grant-ClusterAccess -User $ADDomain\$BackupAdmin -Full
$Nodes = get-cluster . | Get-ClusterNode
foreach ($Node in $Nodes)
    {
    Add-DomainUserToLocalGroup -computer $Node.Name -group Administrators -domain $ADDomain -user $BackupAdmin
    }