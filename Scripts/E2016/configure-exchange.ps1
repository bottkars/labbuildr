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
param(
$ex_version= "E2016",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Prereq ="Prereq" 
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$ADDomain = (get-addomain).forest
$maildom= "@"+$ADDomain
$BackupAdmin = "NMMBackupUser"
$PlainPassword = "Password123!"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$ContentSubmitters = "ContentSubmitters"
$Domain = $env:USERDOMAIN
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


Try
    {
    Write-verbose "Testing AD Group"
    get-ADgroup $ContentSubmitters
    }
Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
    Write-Warning "Group Not Found, now creating"
    New-ADGroup -DisplayName $ContentSubmitters -GroupCategory Security -GroupScope Universal -Name $ContentSubmitters -SamAccountName $ContentSubmitters -Path "OU=Microsoft Exchange Security Groups,DC=$Domain,DC=local" -Description "Indexing permissions group (KB2807668)"
    }
Finally
    {
    }

Try
    {
    Write-verbose "Testing AD User"
    get-ADUser $BackupAdmin
    }
Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
    Write-Warning "User $BackupAdmin not found, now Creating"
    New-ADUser -Name $BackupAdmin -AccountPassword $SecurePassword -PasswordNeverExpires $True -Enabled $True -EmailAddress "$BackupAdmin$maildom" -samaccountname $BackupAdmin -userprincipalname "$BackupAdmin$Maildom" 
    foreach ($ADgroup in ("Backup Operators", "Exchange Servers", "Remote Desktop Users", "Organization Management", "Server Management","Administrators"))
        {
        Add-ADGroupMember -Identity $ADgroup -Members $BackupAdmin
        }
    }
Finally
    {
    }

foreach ($localgroup in ( "Administrators", "Backup Operators","Remote Desktop Users"))
    {
    Write-Verbose "Adding $BackupAdmin to $localgroup"
    Add-DomainUserToLocalGroup -computer $env:COMPUTERNAME -group $localgroup -domain $ADDomain -user $BackupAdmin
    }

##### setting managed availablty diskspace counter
New-ItemProperty "HKLM:Software\Microsoft\ExchangeServer\v15\ActiveMonitoring\Parameters\" -Name "SpaceMonitorLowSpaceThresholdInMB" -Value 10 -PropertyType "DWord" 
####### Installing CDO
$Setupcmd = "ExchangeMapiCdo.msi"
$Setuppath = "$SourcePath\$ex_version$Prereq\ExchangeMapiCdo\$Setupcmd"
.$Builddir\test-setup -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/quiet /passive" -Wait
######################
cd c:\windows\system32\inetsrv
c:\windows\system32\inetsrv\appcmd.exe set config "Default Web Site/Powershell" -section:system.webServer/security/authentication/windowsAuthentication /useKernelMode:"False"  /commit:apphost

write-output "setting exchange powershell to full language"
$ExchangePath = ‘HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup’
$webconfig = Join-Path (Get-ItemProperty $ExchangePath).MsiInstallPath ClientAccess\PowerShell-Proxy\web.config
(get-content $webconfig) | foreach-object {$_ -replace '<add key="PSLanguageMode" value="RestrictedLanguage"/>','<add key="PSLanguageMode" value="FullLanguage"/>'} | set-content $webconfig
Restart-WebAppPool -name MSExchangePowerShellAppPool
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
