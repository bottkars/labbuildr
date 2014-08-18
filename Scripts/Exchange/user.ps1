<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param(
$Subnet = "192.168.2"
)
Write-Output "Setting user credentials to perform installation and configuration"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
$Dot = "."
$Domain = (get-addomain).name
$ADDomain = (get-addomain).forest
$maildom= "@"+$ADDomain
$Space = " "
$Database = "DB1_"+$env:COMPUTERNAME
$Subject = "Welcome to $Domain"
$SenderSMTP = "Administrator"+$maildom
$Smtpserver = $env:COMPUTERNAME+$Dot+$ADDomain
$BackupAdmin = "NMMBackupUser"
$Body = "Hello and have fun ... for Questions drop an email to Karsten.Bott@emc.com "
$AttachDir =  Join-Path $Builddir Attachements 
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
function Extract-Zip
{
	
    param([string]$zipfilename, [string] $destination)
    $copyFlag = 16 # overwrite = yes 
    $Origin = $MyInvocation.MyCommand
	if(test-path($zipfilename))
	{	
		$shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(),$copyFlag)
	}
}

# $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$env:COMPUTERNAME/PowerShell/ -Authentication Kerberos -Credential $Credential
# Import-PSSession $Session -AllowClobber

Set-TransportConfig -MaxReceiveSize 50MB
Set-TransportConfig -MaxSendSize 50MB

New-Item -ItemType Directory $AttachDir
Extract-Zip c:\scripts\attachements.zip $AttachDir
$Attachement = Get-ChildItem -Path $AttachDir -file -Filter *microsoft*release-notes*
Add-RoleGroupMember "Discovery Management" –Member $BackupAdmin
Get-MailboxDatabase | Set-MailboxDatabase -CircularLoggingEnabled $false
New-Item -ItemType Directory -Path R:\rdb
New-Item -ItemType Directory -Path S:\rdb
New-MailboxDatabase -Recovery -Name rdb$env:COMPUTERNAME -server $Smtpserver -EdbFilePath R:\rdb\rdb.edb  -logFolderPath S:\rdb
Get-AddressList  | Update-AddressList
# Enable-Mailbox -Identity $Domain\Administrator
Enable-Mailbox -Identity $BackupAdmin
New-ManagementRoleAssignment -Role "Databases" -User $BackupAdmin
Send-MailMessage -From $SenderSMTP -Subject $Subject -To "$BackupAdmin$maildom"  -Body $Body -Attachments $Attachement.FullName -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
get-ExchangeServer  | add-adpermission -user $BackupAdmin -accessrights ExtendedRight -extendedrights Send-As, Receive-As, ms-Exch-Store-Admin
if (Get-DatabaseAvailabilityGroup){
$DAGDatabase = Get-MailboxDatabase | where ReplicationType -eq Remote
$Database = $DAGDatabase.Name}
Import-CSV C:\Scripts\user.csv | ForEach {
$givenname=$_.givenname
$surname=$_.surname
$Displayname = $givenname+$Space+$surname
$SamAccountName = $Givenname.Substring(0,1)+$surname
$UPN = $SamAccountName+$maildom
$emailaddress = "$givenname$Dot$surname$maildom"
$name = "$givenname $surname"
$user = @{
givenname=$givenname;
surname=$surname;
name=$name;
displayname=$Displayname;
samaccountname=$SamAccountName;
userprincipalname=$UPN;
emailaddress=$emailaddress;
homedirectory=" ";
accountpassword=(ConvertTo-SecureString "Welcome1" -AsPlainText -Force);
}
New-ADUser @user -Enabled $True
Enable-Mailbox $user.samaccountname -database $Database
Send-MailMessage -From $SenderSMTP -Subject $Subject -Attachments $Attachement.FullName -To $UPN -Body $Body -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}


#######
##Public Folder Structure
New-Mailbox -PublicFolder -Name $Domain -database $Database 
$Newfolder = New-PublicFolder -Name $Domain
Enable-MailPublicFolder $Newfolder
$PFSMTP = (Get-MailPublicFolder -Identity $Newfolder).EMAILAddresses[0].AddressString



$count = (Get-ChildItem -Path $AttachDir -file).count
$incr = 1
foreach ( $file in Get-ChildItem -Path $AttachDir -file ) {
Write-Progress -Activity "Sending File to Public Folder $Newfolder " -Status $file -PercentComplete (100/$count*$incr)
Send-MailMessage -From $PFSMTP -Subject $file.name -To $PFSMTP -Attachments $file.FullName -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$incr++
}

################# Configuring SMTP receive Connector for non Exchange Servers and setting Up Mailhost on DNS
Write-Host -ForegroundColor Yellow "Setting Up receive Connector"
Import-CSV C:\Scripts\folders.csv | ForEach {
$Folder=$_.Folder
$Path=$_.Path -replace "BRSLAB", "$Domain" 
$Path 
New-PublicFolder -Name $Folder -Path $Path
Enable-MailPublicFolder $Path\$Folder
Send-MailMessage -From $SenderSMTP -Subject "Welcome To Public Folders" -To $Folder$maildom -Body "This is Public Folder $Folder" -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}


Write-Host -ForegroundColor Yellow "Setting Up C-record for mailhost"

$MyIP = ((Get-NetIPAddress -AddressFamily IPv4 -SkipAsSource $false | where IPaddress -match $Subnet).IpAddress)
# New-ReceiveConnector -Name SMTP -Usage Custom -Bindings $MyIP":25" -RemoteIPRanges "$Subnet.1-$Subnet.99","$Subnet.120-$Subnet.255"
# Get-ReceiveConnector “SMTP” | Add-ADPermission -User “NT AUTHORITY\ANONYMOUS LOGON” -ExtendedRights “Ms-Exch-SMTP-Accept-Any-Recipient”
Get-ReceiveConnector "Default Frontend*" | Add-ADPermission -User “NT AUTHORITY\ANONYMOUS LOGON” -ExtendedRights “Ms-Exch-SMTP-Accept-Any-Recipient”
$dnsserver = (Get-DnsClientServerAddress -AddressFamily IPv4  | where ServerAddresses -match $Subnet).ServerAddresses[0]
$zone = get-dnsserverzone (Get-ADDomain).dnsroot -ComputerName $dnsserver
Add-DnsServerResourceRecordCName -HostNameAlias "$env:COMPUTERNAME.$ADDomain" -Name mailhost -ZoneName $zone.ZoneName -ComputerName $dnsserver
# Remove-PSSession $Session