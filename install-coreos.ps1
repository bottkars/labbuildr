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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-coreos
.EXAMPLE
.\install-coreos.ps1 -defaults
this will install a Puppetmaster on CentOS7 using default Values derived from defaults.xml

#>
#
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir,
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile="./defaults.xml",
[Parameter(ParameterSetName = "download", Mandatory = $true)][switch]$download,
[Parameter(ParameterSetName = "import",Mandatory=$true)][switch]$Import,
[Parameter(ParameterSetName = "import",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults",Mandatory=$false)]
[Parameter(ParameterSetName = "download", Mandatory = $false)][ValidateSet('stable', 'alpha','beta')]$version = 'Stable',
$Nodes = 3
)
#requires -version 3.0
#requires -module vmxtoolkit

$ovf = "coreos_$version.ova"
$Master = "$PSScriptRoot/Coreos_$Version" 
switch ($PsCmdlet.ParameterSetName)
{

    "download"
        {
            $CoreOSURL = "http://$version.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova"
            

            Try 
                {
                test-Path $Sourcedir
                } 
            Catch 
                { 
                Write-Verbose $_ 
                Write-Warning "We need a Valid Sourcedir, trying Defaults"
                if (!($Sourcedir = (Get-labDefaults).Sourcedir))
                {
                Write-Warning "no sourcedir Specified"
                exit
                }
            }
            $Target = join-path $Sourcedir $ovf 
            Write-Host "Trying Download of $ovf"
            Receive-LABBitsFile -DownLoadUrl $CoreOSURL -destination $Target
            Write-Host "Now run install-coreos.ps1 -import -version $version"
            

      }
    "import"
        {
		if (!$Masterpath)
			{
			try
				{
				$Masterpath = (get-labdefaults).Masterpath
				}
			catch
				{
				Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
				$Masterpath = $Builddir
				}
			}           
		Try 
            {
            test-Path $Sourcedir
            } 
        Catch 
            { 
            Write-Verbose $_ 
            Write-Warning "We need a Valid Sourcedir, trying Defaults"
            if (!($Sourcedir = (Get-labDefaults).Sourcedir))
            {
            Write-Warning "no sourcedir Specified"
            exit
            }
        $Target = join-path $Sourcedir $ovf

        if (!(($Mymaster = Get-Item $Target -ErrorAction SilentlyContinue).Extension -match "ovf" -or "ova"))
            {
            Write-Warning "No valid ov[fa] found, Please try -download [-version]"
            Exit
            }
        else
            {
            $Mastername = $Mymaster.Basename
            }  
            
        Write-Warning "Importing $OVF, this may take a While"        
        # if (!($mastername)) {$mastername = (Split-Path -Leaf $ovf).Replace(".ovf","")}
        # $Mymaster = Get-Item $ovf

        import-VMXOVATemplate -OVA $Target -destination $Masterpath
        # & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$mastername $ovf $PSScriptRoot #
        $Mastervmx = get-vmx -path $Masterpath/$Mastername
#       $Mastervmx | Set-VMXHWversion -HWversion 7
        write-Warning "Now run .\install-coreos.ps1 -defaults -version $Version" 
        }


}


    default
    {
    $Nodeprefix = "CoreOSNode"
    $Startnode = 1
    New-Item -ItemType Directory ./Scripts/CoreOS/config-drive/openstack/latest -Force | Out-Null
    If ($Defaults.IsPresent)
        {
        $labdefaults = Get-labDefaults
        $vmnet = $labdefaults.vmnet
        $subnet = $labdefaults.MySubnet
        $BuildDomain = $labdefaults.BuildDomain
        $DefaultGateway = $labdefaults.DefaultGateway
        $Hostkey = $labdefaults.HostKey
        $DNS1 = $labdefaults.DNS1
        $DefaultGateway = $labdefaults.Defaultgateway
        }

    [System.Version]$subnet = $Subnet.ToString()
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build


    If (!($MasterVMX = get-vmx -path $Master))
     {
      Write-Error "No Valid Master Found"
      break
     }
    

    $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
    if (!$Basesnap) 
        {
        Write-verbose "Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        }
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        if (!(get-vmx $Nodeprefix$node))
            {   
            write-verbose "Creating $Nodeprefix$node"
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
            $IP = "$subnet.4$Node"

    $User_data= "#cloud-config
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

    $User_data | Set-Content -Path "$PSScriptRoot/Scripts/CoreOS/config-drive/openstack/latest/user_data"
    convert-VMXdos2unix -Sourcefile "$PSScriptRoot/Scripts/CoreOS/config-drive/openstack/latest/user_data"
    Write-Host "Creating config-2 CD"
    .$global:mkisofs -r -V config-2 -o "$($NodeClone.path)/config.iso"  "$PSScriptRoot/Scripts/CoreOS/config-drive" #  | Out-Null

    $NodeClone | Connect-VMXcdromImage -ISOfile "$($NodeClone.path)/config.iso" -Contoller ide -Port 1:0
    $NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3
    $NodeClone | Set-VMXVnet -Adapter 0 -Vnet $vmnet
    $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.Clonename)@$BuildDomain"
    $Content = $Nodeclone | Get-VMXConfig
    $Content = $Content -replace 'preset','soft'
    $Content | Set-Content -Path $NodeClone.config
    Write-Host "Startding $($NodeClone.clonename)"
    $NodeClone | start-vmx
}#end machine

else 
    {
    Write-Warning "Machine already exists"
    }


}#end foreach

}#end default
}


