<#
.Synopsis
   .\install-puppetmaster.ps1
.DESCRIPTION
  install-puppetmaster is  the a vmxtoolkit solutionpack for configuring and deploying a Puppet Master onj CentOS7

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
   http://labbuildr.readthedocs.io/en/latest/Solutionpacks//SolutionPacks#install-puppetmaster
.EXAMPLE
.\install-puppetmaster.ps1 -defaults
this will install a Puppetmaster on CentOS7 using default Values derived from defaults.xml

#>
#
[CmdletBinding(DefaultParametersetName = "defaults")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\CentOS7 Master',


<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('puppetlabs-release-7-11', 'PuppetEnterprise')]$PuppetMaster = "puppetlabs-release-7-11",

[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
[switch]$download
)
#requires -version 3.0
#requires -module vmxtoolkit
If  ($PuppetMaster -match "PuppetEnterprise")
    {
    $Requires_Sources = $true
    $Enterprise = $true
    }

If ($Defaults.IsPresent)
    {
     $labdefaults = Get-labDefaults
     $vmnet = $labdefaults.vmnet
     $subnet = $labdefaults.MySubnet
     $BuildDomain = $labdefaults.BuildDomain
     $PuppetMaster = $labdefaults.Puppetmaster
     $DefaultGateway = $labdefaults.DefaultGateway
     $DNS1 = $labdefaults.DNS1
       If  ($PuppetMaster -match "PuppetEnterprise")
        {
        $Requires_Sources = $true
        $Enterprise = $true
        $Sourcedir = $labdefaults.Sourcedir
        }
     }


if ($Requires_Sources)
    {
    if (!$Sourcedir)
        {
        Write-Warning "no Sourcedir specified, will exit now"
        exit
        }
    else
        {
        try
            {
            Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null 
            }
        catch
            [System.Management.Automation.DriveNotFoundException] 
            {
            Write-Warning "Drive not found, make sure to have your Source Stick connected"
            exit
            }
        catch [System.Management.Automation.ItemNotFoundException]
            {
            write-warning "no sources directory found named $Sourcedir"
            exit
            }
        $puppet_Sources = Join-Path $Sourcedir 'Puppet'
        if (!(Test-Path $puppet_Sources))
            {
            New-Item -ItemType Directory $puppet_Sources | Out-Null
            }
            
        }
    }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
If  ($PuppetMaster -match "PuppetEnterprise")
    {
    [uint64]$Disksize = 100GB
    $scsi = 0
    $Nodeprefix = "PuppetENMaster"
    $Node = 1
    $ip= "$subnet.16"
    }
else
    {
    [uint64]$Disksize = 100GB
    $scsi = 0
    $Nodeprefix = "PuppetMaster"
    $Node = 1
    $ip = "$subnet.15"
    }


if ($Requires_Sources -and $Download)
    {
    Write-Warning "we try to download Puppet Enterprise, this might take a while"
    $Outfile = Join-Path $puppet_sources "pe.tar.gz"
    Try
        {
        $Puppet_Parse = Invoke-WebRequest -Uri "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest" -UseBasicParsing -Method Head
        }
    catch [Exception] 
        {
        Write-Warning "Could not connect to puppetlabs"
        Write-Warning $_.Exception
        break
        }
    write-verbose "Trying Download"
    Invoke-WebRequest -Uri "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest" -Method Get -OutFile $Outfile
    Push-Location
    Set-Location $puppet_sources
    $Puppet_Archive = & $vmwarepath\7za.exe x $Outfile
    $Puppetfile = $Puppet_Archive | where {$_ -Match "Extracting"}
    $Puppetfile = $Puppetfile -replace "Extracting  "
    $Outfile = Join-Path $puppet_sources $Puppetfile
    & $vmwarepath\7za.exe x $Outfile
    Pop-Location

    exit

    }


##### Basic Checks for Master
if (!($MasterVMX = get-vmx -path $MasterPath))
    {
    Write-Warning "no centos Master found
    please download Centos7 Master to $Sourcedir\Centos7"
    exit
    }
if (!$MasterVMX.Template)
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
        if (!$Basesnap)
        {
         Write-verbose "Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        }

####Build Machine#

If (!(get-vmx $Nodeprefix$node))
  {
    write-verbose "Creating $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node
    $Config = Get-VMXConfig -config $NodeClone.config
    Write-Verbose "Tweaking Config"
    Write-Verbose "Creating Disks"
    write-verbose "Setting NIC0 to HostOnly"
    $Netadapter = Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
    if ($vmnet)
      {
      Write-Verbose "Configuring NIC 0 for $vmnet"
      Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config  | Out-Null
      Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config   | Out-Null
      }
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
    $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
    # $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname CentOS -Scenario 7
    $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
    Write-Verbose "Starting $NodeClone$Node"
    start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
    
do {
    $ToolState = Get-VMXToolsState -config $NodeClone.config
    Write-Verbose "VMware tools are in $($ToolState.State) state"
    sleep 5
    }
until ($ToolState.state -match "running")
$Nodeprefix = $Nodeprefix.ToLower()
$BuildDomain = $BuildDomain.ToLower()

Write-Verbose "Setting Shared Folders"
$NodeClone | Set-VMXSharedFolderState -enabled | Out-Null
If ($Requires_Sources)
    {
    $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | Out-Null
    Write-Verbose "Adding Shared Folders"
    $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir  | Out-Null
    }
$Scriptblock = "systemctl disable iptables.service"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

$Scriptblock = "systemctl stop iptables.service"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword

If ($DefaultGateway)
    {
    $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
    }
else
    {
    $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $ip -device eno16777984 -Peerdns -DNS1 $DNS1 -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
    }

$Scriptblock = "rm -rf /etc/resolv.conf"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/resolv.log

$Scriptblock = "sed -i '$ a $ip $Nodeprefix$Node $Nodeprefix$Node.$BuildDomain.local' /etc/hosts"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/hosts.log


$Scriptblock = "hostname '$Nodeprefix$Node.$BuildDomain.local'"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/hostname.log

$Scriptblock = "systemctl restart network"
Write-Verbose $Scriptblock
$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/network.log

if (!$Enterprise)
    {

    $Scriptblock = "rpm -ivh https://yum.puppetlabs.com/el/7/products/x86_64/$PuppetMaster.noarch.rpm"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/$PuppetMaster.log

    $Scriptblock = "yum install -y puppet-server"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/puppetserver.log

    $Scriptblock = "sed -i '/\[main\]/a  dns_alt_names = $Nodeprefix$Node,$Nodeprefix$Node.$BuildDomain.local' /etc/puppet/puppet.conf"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/puppetserver.log

    $Scriptblock = "systemctl start  puppetmaster.service"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/service.log
    ####
    $Scriptblock = "puppet resource service puppetmaster ensure=running enable=true"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/puppet_run.log


    ### Apache
    $Scriptblock = "yum install -y httpd httpd-devel mod_ssl ruby-devel rubygems gcc gcc-c++ curl-devel zlib-devel make automake  openssl-devel"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/Apache.log

    ### gem RACK passenger
    $Scriptblock = "gem install rack passenger"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/passenger.log

    ### passenger install

    Write-Warning "Building passanger apache2_mod, this may take a few moments ..."

    $Scriptblock = "passenger-install-apache2-module -a --languages ruby,python"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/passenger_install.log

    $Scriptblock = "mkdir -p /usr/share/puppet/rack/puppetmasterd"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/directory1.log

    $Scriptblock = "mkdir /usr/share/puppet/rack/puppetmasterd/public /usr/share/puppet/rack/puppetmasterd/tmp"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/directory2.log

    $Scriptblock = "cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/;chown puppet /usr/share/puppet/rack/puppetmasterd/config.ru"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/config_ru.log


$httpdconf = "# RHEL/CentOS:
LoadModule passenger_module  /usr/local/share/gems/gems/passenger-5.0.20/buildout/apache2/mod_passenger.so
PassengerRoot /usr/local/share/gems/gems/passenger-5.0.20/
PassengerRuby /usr/bin/ruby
# And the passenger performance tuning settings:
PassengerHighPerformance On
# PassengerUseGlobalQueue On
# Set this to about 1.5 times the number of CPU cores in your master:
PassengerMaxPoolSize 6
# Recycle master processes after they service 1000 requests
PassengerMaxRequests 1000
# Stop processes if they sit idle for 10 minutes
PassengerPoolIdleTime 600
Listen 8140
<VirtualHost *:8140>
    SSLEngine On
    # Only allow high security cryptography. Alter if needed for compatibility.
    SSLProtocol             All -SSLv2
    SSLCipherSuite          HIGH:!ADH:RC4+RSA:-MEDIUM:-LOW:-EXP
    SSLCertificateFile      /var/lib/puppet/ssl/certs/$Nodeprefix$Node.$BuildDomain.local.pem
    SSLCertificateKeyFile   /var/lib/puppet/ssl/private_keys/$Nodeprefix$Node.$BuildDomain.local.pem
    SSLCertificateChainFile /var/lib/puppet/ssl/ca/ca_crt.pem
    SSLCACertificateFile    /var/lib/puppet/ssl/ca/ca_crt.pem
    SSLCARevocationFile     /var/lib/puppet/ssl/ca/ca_crl.pem
    SSLVerifyClient         optional
    SSLVerifyDepth          1
    SSLOptions              +StdEnvVars +ExportCertData
    # These request headers are used to pass the client certificate
    # authentication information on to the puppet master process
    RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
    RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
    RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e
    #RackAutoDetect On
    DocumentRoot /usr/share/puppet/rack/puppetmasterd/public/
    <Directory /usr/share/puppet/rack/puppetmasterd/>
        Options None
        AllowOverride None
        Order Allow,Deny
        Allow from All
    </Directory>
</VirtualHost>"


    $httpdconf | Set-Content -Path .\puppetmaster.conf
    convert-VMXdos2unix -Sourcefile .\puppetmaster.conf
    $NodeClone | copy-VMXfile2guest -Sourcefile .\puppetmaster.conf -targetfile /etc/httpd/conf.d/puppetmaster.conf -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "systemctl stop puppetmaster"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/step_puppetstop.log

    $Scriptblock = "systemctl start httpd"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile /tmp/step_httpd.log
    
    Write-Warning "puppetmaster creation finished. please try connect to REST API https://$($IP):8140"


}
else
    {
    
    $Answer="q_activity_database_name='pe-activity'
q_activity_database_password='jCgyheYD5fZTjkoy0RIfCQ'
q_activity_database_user='pe-activity'
q_all_in_one_install='y'
q_classifier_database_name='pe-classifier'
q_classifier_database_password='nUqz7lggdCfmDaEdkonrcQ'
q_classifier_database_user='pe-classifier'
q_database_host='puppetenmaster.builddomain.local'
q_database_install='y'
q_database_port='5432'
q_database_root_password='920FfiSaa2hjUJvWjM_nfg'
q_database_root_user='root'
q_fail_on_unsuccessful_master_lookup='y'
q_install='y'
q_pe_check_for_updates='y'
q_pe_database='y'
q_public_hostname='puppetenmaster.builddomain.local'
q_puppet_cloud_install='y'
q_puppet_enterpriseconsole_auth_password='Password123!'
q_puppet_enterpriseconsole_httpd_port='443'
q_puppet_enterpriseconsole_install='y'
q_puppet_enterpriseconsole_master_hostname='puppetenmaster.builddomain.local'
q_puppetagent_certname='puppetenmaster.builddomain.local'
q_puppetagent_install='y'
q_puppetagent_server='puppetenmaster.builddomain.local'
q_puppetdb_database_name='pe-puppetdb'
q_puppetdb_database_password='mvLqz81WY1ckikgLwZy3HQ'
q_puppetdb_database_user='pe-puppetdb'
q_puppetdb_hostname='puppetenmaster.builddomain.local'
q_puppetdb_install='y'
q_puppetdb_plaintext_port='8080'
q_puppetdb_port='8081'
q_puppetmaster_certname='puppetenmaster.builddomain.local'
q_puppetmaster_dnsaltnames='puppetenmaster,puppetenmaster.builddomain.local'
q_puppetmaster_enterpriseconsole_hostname='puppetenmaster.builddomain.local'
q_puppetmaster_enterpriseconsole_port='443'
q_puppetmaster_install='y'
q_rbac_database_name='pe-rbac'
q_rbac_database_password='xbZH9ute10MkOMMr7_phrQ'
q_rbac_database_user='pe-rbac'
q_skip_backup='y'
q_skip_master_verification='n'
q_vendor_packages_install='y'"
    $Answer = $Answer -replace 'Builddomain',$BuildDomain
    $Answer = $Answer -replace 'puppetenmaster',"$Nodeprefix$Node"
    $Answer | Set-Content -Path $puppet_sources\puppetanswerfile.txt

    $Puppet_Instlog = "/tmp/puppet_en_inst.log"
    Write-Warning "Now trying automated install. You may sh into $IP and tail -f $Puppet_Instlog" 
    $Scriptblock = "cd /mnt/hgfs/Sources/Puppet/puppet-enterprise*;./puppet-enterprise-installer -a ../puppetanswerfile.txt"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -Confirm:$false -SleepSec 5 -logfile $Puppet_Instlog

Write-Warning "puppetmaster creation finished. please try connect to console  https://$($IP):443 with user admin / $Guestpassword"


}

}
else
  {
    write-Warning "Machine $Nodeprefix$node already Exists"
  }
