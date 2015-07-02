<#
.Synopsis
   labbuildr allows you to create Virtual Machines with VMware Workstation froim Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Logfile = New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
$dnsroot = '@' + (Get-ADDomain).DNSRoot
$accountPassword = (ConvertTo-SecureString "Password123!" -AsPlainText -force)
Import-Csv c:\scripts\adminuser.csv | foreach-object {
   
    if ($_.OU -ne "") { $OU = "OU=" + $_.OU + ',' + (Get-ADDomain).DistinguishedName }
    if (!(Get-ADOrganizationalUnit -Filter * | where name -match $_.OU -ErrorAction SilentlyContinue )){New-ADOrganizationalUnit -Name $_.OU; Write-Host $OU }

    else { $OU = (Get-ADDomain).UsersContainer }
 
    #In case of for example a service account without first and last name.
    if ($_.FirstName -eq"" -and $_.LastName -eq "") { $Name = $_.SamAccountName }
    else { $Name = ($_.FirstName + " " + $_.LastName) }

    
    if ($_.Manager -eq "") {
        $newUser = New-ADUser -Name $Name -SamAccountName $_.SamAccountName -DisplayName $Name -Description $_.Description -GivenName $_.FirstName -Surname $_.LastName `
            -EmailAddress ($_.SamAccountName + $dnsroot) -Title $_.Title `
            -UserPrincipalName ($_.SamAccountName + $dnsroot) -Path $OU -Enabled $true `
            -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
            -AccountPassword $accountPassword -PassThru
    }
    else {
        $newUser = New-ADUser -Name $Name -SamAccountName $_.SamAccountName -DisplayName $Name -Description $_.Description -GivenName $_.FirstName -Surname $_.LastName `
            -EmailAddress ($_.SamAccountName + $dnsroot) -Title $_.Title`
            -UserPrincipalName ($_.SamAccountName + $dnsroot) -Path $OU -Enabled $true `
            -ChangePasswordAtLogon $false -Manager $_.Manager -PasswordNeverExpires $true `
            -AccountPassword $accountPassword -PassThru
    }

    if ($_.SecurityGroup -ne ""){
        if (!($SecurityGroup = Get-ADGroup -filter * | where name -match $_.SecurityGroup -ErrorAction SilentlyContinue)){ 
        $SecurityGroup = New-ADGroup -Name $_.SecurityGroup -GroupScope Global -GroupCategory Security
        }
    Add-ADGroupMember -Identity $_.SecurityGroup -Members $newUser
    }
        
 

}
