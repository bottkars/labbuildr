<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
[CmdletBinding()]
param(
[ValidateSet('nw85','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81', 'nwunknown')]$NW_ver = "nw85"

)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$Logfile = New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$Password = "Password123!"
$dbusername = "postgres"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
Write-Verbose "Setting Up SNMP"
Add-WindowsFeature snmp-service  -IncludeAllSubFeature -IncludeManagementTools
Set-Service SNMPTRAP -StartupType Automatic
Start-Service SNMPTRAP
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters -Name "EnableAuthenticationTraps" -Value 0
Remove-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers -Name "1" -Force
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Force
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration\networker -Force
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent -Force
New-ItemProperty  -Path  HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent -Name "sysServices" -PropertyType "dword" -Value 76 -Force
New-ItemProperty  -Path  HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent -Name "sysLocation" -PropertyType "string" -Value 'labbuildr' -Force
New-ItemProperty  -Path  HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent -Name "sysContact" -PropertyType "string" -Value '@Hyperv_guy' -Force
New-ItemProperty  -Path  HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name "networker" -PropertyType "dword" -Value 8 -Force


.$Builddir\test-sharedfolders.ps1
$Setuppath = "\\vmware-host\Shared Folders\Sources\$NW_ver\win_x64\networkr"
.$Builddir\test-setup -setup NWServer -setuppath $Setuppath

if ($NW_ver -lt 'nw85')
    {
    Start-Process -Wait -FilePath "$Setuppath\setup.exe" -ArgumentList ' /S /v" /passive /l*v c:\scripts\nwserversetup2.log INSTALLLEVEL=300 CONFIGFIREWALL=1 setuptype=Install"'
    Start-Process -Wait -FilePath "$Setuppath\setup.exe" -ArgumentList '/S /v" /passive /l*v c:\scripts\nwserversetup2.log INSTALLLEVEL=300 CONFIGFIREWALL=1 NW_FIREWALL_CONFIG=1 setuptype=Install"'
    
    $Setuppath = "\\vmware-host\Shared Folders\Sources\$NW_ver\win_x64\networkr\nmc\setup.exe"
    .$Builddir\test-setup -setup NWConsole -setuppath $Setuppath
    Start-Process -Wait -FilePath "$Setuppath" -ArgumentList '/S /v" /passive /l*v c:\scripts\nmcsetup2.log CONFIGFIREWALL=1 NW_FIREWALL_CONFIG=1 setuptype=Install"'

    Write-Verbose "Setting up NMC"
    # Start-Process -Wait -FilePath "javaws.exe" -ArgumentList "-import -silent -system -shortcut -association http://localhost:9000/gconsole.jnlp"
    # start-process http://localhost:9000/gconsole.jnlp

    
    }
else
    {
    Write-Warning "Installing Networker 8.5v Beta"
    Write-Warning "evaluating setup version"
    if ($setup = Get-ChildItem "\\vmware-host\shared folders\Sources\$NW_ver\win_x64\networkr\networker-*")
        {
        write-warning "creating postgres user"
        $cn = [ADSI]"WinNT://$env:COMPUTERNAME"
        $user = $cn.Create("User",$dbusername)
        $user.SetPassword($Password)
        $user.setinfo()
        $user.description = "postgres networker user"
        $user.SetInfo()
        Write-Warning "Starting Install"
        Start-Process -Wait -FilePath "$($Setup.fullname)" -ArgumentList "/s /v InstallLevel=300 ConfigureFirewall=1 StartServices=1 OptionGetNMC=1 DbUsername=$dbusername DbPassword=$Password AdminPassword=$Password KSFPassword=$Password TSFPassword=$Password"
        # Start-Process -Wait -FilePath "$($Setup.fullname)" -ArgumentList "/s /v /q /l InstallLevel=300 ConfigureFirewall=1 OptionGetNMC=1 DbPassword=$Password AdminPassword=$Password KSFPassword=$Password TSFPassword=$Password"
        }
    else
        {
        Write-Error "Networker Setup File fould not be elvaluated"
        }
    }


if (!(Test-Path "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"))
    {
    Write-Verbose "Creating Java exception.sites for User"
    New-Item -ItemType File "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" | Out-Null
    }
$javaSites = @()
$javaSites += "http://$($env:computername):9000"
$javaSites += "http://$($env:computername).$($env:USERDNSDOMAIN):9000"
$javaSites += "http://localhost:9000"
foreach ($javaSite in $Javasites)
    {    
        Write-Verbose "adding Java Exeption for $javaSite"
        $CurrentContent = Get-Content "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
        If  ((!$CurrentContent) -or ($CurrentContent -notmatch $javaSite))
            {
            Write-Verbose "adding $javaSite Java exception to $env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
            add-Content -Value $javaSite -Path "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" 
            }
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

