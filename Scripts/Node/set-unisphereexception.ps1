<#
.Synopsis
set-unisphereexception.ps1 -Domainname <Object> [<CommonParameters>]

set-unisphereexception.ps1 -IPAddress <IPAddress> [<CommonParameters>]
.DESCRIPTION
   set-unisphere exception sets java and ie11 exception lists for Domain or IP Address
   It 
      
      Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
.EXAMPLE
    set-unisphereexception.ps1 -Domainname labbuildr.local
    Disable Popup Blocker, Sets java exception and adds domain to Trusted IE Sites
.EXAMPLE
    set-unisphereexception.ps1 -IPAddress 192.168.2.81
    Disable Popup Blocker, Sets java exception and adds Host to Trusted, secure (https) IE Sites

#>
[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
param (
[Parameter(ParameterSetName = "2", Mandatory = $true, ValueFromPipelineByPropertyName = $True)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$IPAddress,
[Parameter(ParameterSetName = "1", Mandatory = $true, ValueFromPipelineByPropertyName = $True)][ValidatePattern("(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])")][string]$Hostname
)
#requires -version 3.0


begin
{

if (!(Test-Path "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"))
    {
    Write-Verbose "Creating Java exception.sites for User"
    New-Item -ItemType File "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" | Out-Null
    }
if (!(Test-path 'HKCU:\Software\Microsoft\Internet Explorer\New Windows\Allow'))
    {
    Write-Verbose "Creating Popup Blocker Registy Key"
    New-Item 'HKCU:\Software\Microsoft\Internet Explorer\New Windows' -Name Allow | Out-Null
    }

}
process{

switch ($PsCmdlet.ParameterSetName)
		{
			"1"
   			{
            $Address = "$Hostname"
            }
			"2"
			{
            $Address  = $IPAddress
            }

        }
        $Content = "https://$Address"
        Write-Verbose "adding Java Exeption for $Address"
        $CurrentContent = Get-Content "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
        If  ((!$CurrentContent) -or ($CurrentContent -notmatch $Content))
            {
            Write-Verbose "adding $Content to Java exception to $env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
            add-Content -Value $Content -Path "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" 
            }
        $Range = 0
        do  {
            $Range ++
            }
        until (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range$Range"))
        Write-Verbose " Adding new Zonemap Range for Host $Address$Range"
        New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range$Range" | Out-Null
        New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range$Range" -Name https -Value 2 -PropertyType DWORD | Out-Null
        New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range$Range" -Name :Range -Value $Address | Out-Null
        IF ((Get-ItemProperty "HKCU:Software\Microsoft\Internet Explorer\New Windows\Allow\") -notmatch $Address)
            {
            Write-verbose "Now Disabling Popup Blocker for $Address "
            New-ItemProperty 'HKCU:Software\Microsoft\Internet Explorer\New Windows\Allow' -Name $Address -Value ([byte[]](0x00,0x00))  | Out-NULL
            }
    
}
end{}