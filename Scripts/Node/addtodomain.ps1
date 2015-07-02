<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
param (
$Domain="labbuildr",
$domainsuffix = ".local",
$subnet = "192.168.2",
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
$IPv6Subnet
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$Domain"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass3" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\3.pass`""
Start-Process C:\scripts\Autologon.exe -ArgumentList "Administrator $Domain Password123! /Accepteula"
######Newtwork Sanity Check #######
If ($AddressFamily -match "IPv6")
    {
    $subnet = "$IPv6Subnet$subnet"
    }
else 
    {
    $subnet = "$subnet"
    }

Do {
    $Ping = Test-Connection "$Subnet.10" -ErrorAction SilentlyContinue
    If (!$Ping)
        {
        Write-Warning "Can Not reach Domain Controller with $subnet.10
                        This is most Likely a VMnet Configuration Issue
                        please Fix Network Assignments ( vmnet ) and specify correct Addressfamily"
        Pause
        }
    }
Until ($Ping)    
$Mydomain = "$Domain$domainsuffix"
$password = "Password123!" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\Administrator" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Do {
    $Domain_OK = Add-Computer -DomainName $Mydomain -Credential $credential -PassThru
    If (!$Domain_OK.HasSucceeded)
        {
        Write-Warning "Can Not Join Domain $Domain, please verify and retry
                    Most likely this Computer has not been removed from Domain or Domain needs to refresh
                    Please Check Active Directory Users and Computers on the DC"
        Pause
        }
    }
Until ($Domain_OK.HasSucceeded)    
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "Computerinfo" -Value "$PSHOME\powershell.exe -file c:\scripts\set-computerinfo.ps1"
Start-Process C:\scripts\Autologon.exe -ArgumentList "Administrator $Domain Password123! /Accepteula" -Wait

Restart-Computer
