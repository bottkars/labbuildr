<#
.Synopsis
   .\install-coreos.ps1
.DESCRIPTION
  install-coreos is  the a vmxtoolkit solutionpack installing coreos to run docker containers 

      Copyright 2015 Karsten Bott

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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///SolutionPacks#install-coreos
.EXAMPLE
.\install-coreos.ps1 -defaults
this will install a Puppetmaster on CentOS7 using default Values derived from defaults.xml

#>
#
[CmdletBinding()]
Param(
    [Parameter(ParameterSetName = "install", Mandatory = $false)]
    [ValidateScript( { Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = $labdefaults.Sourcedir,
    [Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = $labdefaults.MySubnet,
    [Parameter(ParameterSetName = "install", Mandatory = $False)]
    [ValidateLength(1, 15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = $labdefaults.BuildDomain,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2', 'vmnet3')]$vmnet = $labdefaults.vmnet,
    [Parameter(ParameterSetName = "install", Mandatory = $false)][ValidateSet('photon-1.0-rev2')]$photonOS = 'photon-1.0-rev2',
    [Parameter(ParameterSetName = "install", Mandatory = $false)]$masterpath = $labdefaults.Masterpath,
    $Startnode = 1,
    $nodes = 1
)
#requires -version 3.0
#requires -module vmxtoolkit
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$Nodeprefix = "PhotonOSNode"
[System.Version]$subnet = $subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$Master_StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$masterVMX = Test-LABmaster -Masterpath $masterpath -Master $photonOS
$Master_StopWatch.stop()

foreach ($Node in $Startnode..(($Startnode - 1) + $Nodes)) {
    if (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue)) {   
        write-verbose "Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 


        <#  $User_data= "#cloud-config
hostname: $($nodeclone.clonename)
ssh_authorized_keys:
    - $($Hostkey)
write_files:
    - path: /etc/systemd/network/static.network
      permissions: 0644
      content: |
        [Match]
        Name=eno16777984

        [Network]
        Address=$IP/24
        Gateway=$DefaultGateway
        DNS=$DNS1
        DNS=8.8.8.8
    - path: /etc/iptables.rules
      permissions: 0644
      content: |
        *filter
        :INPUT DROP [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [76:7696]
        -A INPUT -p tcp -m conntrack --ctstate NEW -m multiport --dports 22 -j ACCEPT
        -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -p icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
        COMMIT
coreos:
    units:
        - name: systemd-networkd.service
          command: restart
        - name: iptables.service
          command: start
          content: |
            [Unit]
            Description=iptables
            Author=Me
            After=systemd-networkd.service

            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/iptables-restore /etc/iptables.rules
            ExecReload=/usr/sbin/iptables-restore /etc/iptables.rules
            ExecStop=/usr/sbin/iptables-restore /etc/iptables.rules

            [Install]
            WantedBy=multi-user.target"

		$User_data | Set-Content -Path "$PSScriptRoot/labbuildr-scripts/CoreOS/config-drive/openstack/latest/user_data" | Out-Null 
		convert-VMXdos2unix -Sourcefile "$PSScriptRoot/labbuildr-scripts/CoreOS/config-drive/openstack/latest/user_data" | Out-Null 
		Write-Host -ForegroundColor Gray "  ==>Creating config-2 CD"
		.$global:mkisofs -r -V config-2 -o "$($NodeClone.path)/config.iso"  "$PSScriptRoot/Scripts/CoreOS/config-drive" #  | Out-Null

		$NodeClone | Connect-VMXcdromImage -ISOfile "$($NodeClone.path)/config.iso" -Contoller ide -Port 1:0 | Out-Null 
		$NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue | Out-Null 
		$NodeClone | Set-VMXVnet -Adapter 0 -Vnet $vmnet -WarningAction SilentlyContinue | Out-Null 
		$NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.Clonename)@$BuildDomain" | Out-Null 
		$Content = $Nodeclone | Get-VMXConfig 
		$Content = $Content -replace 'preset','soft'
		$Content | Set-Content -Path $NodeClone.config #>
        $NodeClone | start-vmx | Out-Null 
    }#end machine

    else {
        Write-Warning "Machine already exists"
    }


}#end foreach

$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
Write-host -ForegroundColor White "Master Section took $($Master_StopWatch.Elapsed.ToString())"


