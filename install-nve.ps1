<#
.Synopsis

.DESCRIPTION
   import-viprva

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
   https://community.emc.com/blogs/bottk/2015/05/04/labbuildrannouncement-unattended-vipr-controller-deployment-for-vmware-workstation
.EXAMPLE
 Download and Install ViPR 2.3:
 .\install-vipr.ps1 -Defaults -viprmaster vipr-2.3.0.0.828
#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "import", Mandatory = $true)]$OVA,

[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]$NVEMaster,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"

)

$targetname = "nvenode1"
$rootuser = "root"
$rootpassword = "changeme"

switch ($PsCmdlet.ParameterSetName)
{
    "import"

    {
        $Disks = ('disk1','disk2')
        $masterpath = Get-ChildItem -path $OVA
        $mastername = $masterpath.BaseName
        $Missing = @()
        foreach ($Disk in $Disks)
        {
            if (!(Test-Path "$global:vmwarepath\7za.exe"))
                    {
                    Write-Warning " 7zip not found
                    7za is part of VMware Workstation 11 or the 7zip Distribution
                    please get and copy 7za to & $global:vmwarepath\7za.exe"
                    exit
                    }
            Write-warning "$Disk not found, deflating NVE $Disk from OVA"
            & $global:vmwarepath\7za.exe x "-o$mastername" -y $masterpath.FullName "*$Disk*.vmdk"
            $Mydisk = Get-ChildItem  -Path $mastername -filter *$Disk* 
            # $Mydisk | Move-Item -Destination "$mastername\$Disk.vmdk"
            write-warning "converting $TargetDisk"
            & $VMwarepath\vmware-vdiskmanager.exe -r $Mydisk.FullName -t 0 ".\$mastername\$Disk.vmdk" # 2>&1 | Out-Null
            remove-item $Mydisk.FullName
         }

        $Mastercontent = Get-Content .\Scripts\NVE\NVEMAster.vmx
        $Mastercontent = $Mastercontent -replace "NVEMaster","$mastername"
        $Mastercontent | Set-Content -Path ".\$mastername\$mastername.vmx"
        $Mastervmx = get-vmx -path ".\$mastername\$mastername.vmx"
        $Mastervmx | New-VMXSnapshot -SnapshotName Base
        $Mastervmx | Set-VMXTemplate
    
    }

"defaults"

 {

If ($Defaults.IsPresent)
    {
     $labdefaults = Get-labDefaults
     $vmnet = $labdefaults.vmnet
     $subnet = $labdefaults.MySubnet
     $BuildDomain = $labdefaults.BuildDomain
     $Sourcedir = $labdefaults.Sourcedir
     $Gateway = $labdefaults.Gateway
     $DefaultGateway = $labdefaults.Defaultgateway
     $DNS1 = $labdefaults.DNS1
     }
else
    {
    $subnet = "192.168.2.0"
    }

if (!(test-path $Sourcedir))
    {
    Write-Warning " $Sourcedir not found. we need a Valid Directory for sources specified with set-labsources"
    exit
    }



[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
if (!$Defaultgateway)
    {
    $Defaultgateway = "$subnet.12"
    }
if (get-vmx $targetname)
    {
    Write-Warning " the Virtual Machine already exists"
    Break
    }
$ip="$subnet.12"
$master = get-vmx $NVEMaster
$Base = $master  | Get-VMXSnapshot
$NodeClone = $Base | New-VMXLinkedClone -CloneName $targetname
$NodeClone | Set-VMXNetworkAdapter -Adapter 0 -AdapterType e1000 -ConnectionType custom
$NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet
$NodeClone | Set-VMXDisplayName -DisplayName $targetname
$Annotation = $NodeClone | Set-VMXAnnotation -Line1 "https://$subnet.9" -Line2 "user:$rootuser" -Line3 "password:$rootpassword" -Line4 "add license from $masterpath" -Line5 "labbuildr by @hyperv_guy" -builddate
$NodeClone | Start-VMX


     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }

    until ($ToolState.state -match "running")
        do {
        Write-Warning "Waiting for $targetname to come up"
        $Process = Get-VMXProcessesInGuest -config $NodeClone.config -Guestuser $rootuser -Guestpassword $rootpassword
        sleep 10
        }
    until ($process -match "mingetty")
    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $rootuser -Guestpassword $rootpassword 
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $rootuser -Guestpassword $rootpassword 
    $Scriptblock = "echo 'default "+$Gateway+" - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword 
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+".local\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword 
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword 
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $rootuser -Guestpassword $rootpassword 
    $Scriptblock = "echo '"+$Nodeprefix+$Node+"."+$BuildDomain+".local'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $rootuser -Guestpassword $rootpassword



Write-Host -ForegroundColor Yellow "
Successfully Deployed $targetname
wait a view minutes for storageos to be up and running
point your browser to https://$($ip):7543/avi/avigui.html
Login with $rootuser/$rootpassword and follow the wizard steps
"
}
}
