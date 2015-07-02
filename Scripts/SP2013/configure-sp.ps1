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
[Validateset('AAG')]$DBtype
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Domain = $env:USERDOMAIN
$SQLUsername = "$env:USERDOMAIN\SVC_SQLADM"
$SQLPassword = "Password123!"
$FarmPassphrase = $SQLPassword
$ConfigDB = "$($Domain)_SP_ConfigDB"
$AdminDB = "$($Domain)_SP_AdminDB"
$AdminPort = "9999"
$webport = '8080'
$WebsiteName = "$DOMAIN Website"                              
$WebsiteDesc = "Powered by labbuildr"  
$PrimaryLogin = "$Domain\Administrator"                              
$PrimaryDisplay = "Admin"                              
$PrimaryEmail = "Administrator@$Domain.local" 
$SecondaryLogin = "$Domain\svc_sqladm"                              
$SecondaryDisplay = "SQL Admin"                              
$SecondaryEmail = "svc_sqladm@$Domain.local"  
$MembersGroup = "$WebsiteName Members"                              
$ViewersGroup = "Viewers"
$url = "http://$env:COMPUTERNAME.$env:USERDNSDOMAIN"
$site = "$url/sites/labbuildr"
$dbname = "labbuildr_Content"
switch ($DBtype)
    {
    'AAG'
        {
        $SQLServer = $env:USERDOMAIN+"AAGlstn"
        }
    default
        {
        Write-Verbose "Setting Sharepoint VSS Writer"
        Start-Process "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\BIN\STSADM.EXE" -ArgumentList "-o registerwsswriter" -Wait
        exit
    }

    }
$credential = New-Object System.Management.Automation.PSCredential($SQLUsername,(ConvertTo-SecureString -asPlainText -Force $SQLPassword))
Write-Warning  "Creating $ConfigDB and $AdminDB, this might take a while..."
$FarmCredentials = New-Object System.Management.Automation.PSCredential $SQLUsername, (ConvertTo-SecureString $SQLPassword -AsPlainText -Force)
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
New-SPConfigurationDatabase -DatabaseServer "$SQLServer\mssqllabbuildr" -DatabaseName $ConfigDB -AdministrationContentDatabaseName $AdminDB -Passphrase (ConvertTo-SecureString $FarmPassphrase -AsPlainText -Force) -FarmCredentials $FarmCredentials -Verbose
Write-Warning "Installing Helpcollection"
Install-SPHelpCollection -All
Initialize-SPResourceSecurity
Write-Warning "Installing SPService"
Install-SPService
Write-Warning "Installing SPFeatures"  
Install-SPFeature -AllExistingFeatures
restart-service sptimerv4
Write-Warning "Creating Central Admin Admin Site"
New-SPCentralAdministration -Port $AdminPort -WindowsAuthProvider NTLM 
Install-SPApplicationContent
#########################################################################
$Template = Get-SPWebTemplate STS#0
$ap = New-SPAuthenticationProvider
Write-Warning "Creating WebApp $url"
$WebApp = New-SPWebApplication -Name "$Domain"  -HostHeader "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -URL $url -ApplicationPool "$($env.userdomain)AppPool" -ApplicationPoolAccount (Get-SPManagedAccount "$env:USERDOMAIN\svc_sqladm") -AuthenticationProvider $ap -DatabaseName "$($Domain)_content" -AllowAnonymousAccess:$true
#
# $WebApp = New-SPWebApplication -Name "$env:USERDOMAIN" -Port $webport -HostHeader "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -URL $url  -ApplicationPool "$($env.userdomain)AppPool" -ApplicationPoolAccount (Get-SPManagedAccount "$env:USERDOMAIN\svc_sqladm") -AuthenticationProvider $ap -DatabaseName "$($env:USERDOMAIN)_content"
# Write-Warning "Creating Content DB $dbname"
# New-SPContentDatabase -Name $dbname -DatabaseServer $SQLServer -WebApplication $webapp -DatabaseCredentials $credential -WebApplication $WebApp
Write-Warning "Creating Site $url"
New-SPSite -URL $url -OwnerAlias $PrimaryLogin -SecondaryOwnerAlias $SecondaryLogin -Name "$env:USERDOMAIN" -Template $Template
# New-SPManagedPath -RelativeURL "sites/Teams1" -WebApplication $SPwebApp 
# $Template = Get-SPWebTemplate STS#0
# New-SPSite "$($url):$webPort/sites/Teams1" -OwnerAlias "$env:USERDOMAIN\Administrator" -Name "$env:USERDOMAIN" -Template $Template 
$web = Get-SPWeb $webApp.url                             
$web.CreateDefaultAssociatedGroups($PrimaryLogin,$SecondaryLogin,"") 
ADD-SPShellAdmin -UserName "$Domain\$env:COMPUTERNAME$"
Remove-PSSnapin Microsoft.SharePoint.PowerShell
Write-Verbose "Setting Sharepoint VSS Writer"
Start-Process "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\BIN\STSADM.EXE" -ArgumentList "-o registerwsswriter" -Wait
