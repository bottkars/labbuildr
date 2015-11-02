<#
.Synopsis
   .\install-coprhd.ps1 
.DESCRIPTION
  install-coprhd is  the a labbuildr solutionpack for compiling  and deploying CoprHD Controller
      
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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-coprhd
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "defaults",
SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
#[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
#[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir = 'h:\sources',
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = '.\OpenSuse',
<#Specify desired branch#>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('master','INTEGRATION-YODA-FOUNDATION','INTEGRATION-2.4.1-FOUNDATION','integration-2.4.1','VIPR-2.3-PATCH1-HF4','VIPR-2.3-PATCH1-HF3','VIPR-2.3-PATCH1-HF2','VIPR-2.3-PATCH1-HF1','bugfix-COP-17106','bugfix-COP-17153')]$branch = "master",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
$Node = 1
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "24"


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

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$Scenarioname = "Coprhd"
$Nodeprefix = "$($Scenarioname)Node"
# $release = $release.tolower()
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = $Scenarioname.ToLower()
$Scriptdir = "$Sourcedir\$($Scenarioname.ToLower())"


[uint64]$Disksize = 100GB
$scsi = 0
#$Node = "1"
if (!($MasterVMX = get-vmx -path $MasterPath))
    {
    Write-Warning "no OpenSuse Master found. Please download from
    https://github.com/bottkars/labbuildr/wiki/Master"
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
if (!(Test-path "$Sourcedir\$Scenarioname"))
    {
    New-Item -ItemType Directory "$Sourcedir\$Scenarioname"
    }



        If (!(get-vmx $Nodeprefix$node))
        {
        write-verbose " Creating $Nodeprefix$node"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node 
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Verbose "Tweaking Config"
        write-verbose "Setting NIC0 to HostOnly"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config 
        if ($vmnet)
            {
            Write-Verbose "Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @hyperv_guy" -builddate
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
        # $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4
        $NodeClone | Set-VMXmemory -MemoryMB 8192l
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        Write-Verbose "Starting $($NodeClone.CloneName)"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName
        $machinesBuilt += $($NodeClone.cloneName)

        $ip="$subnet.245"
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled
        Write-verbose "Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | out-null
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -suse -device eno16777984 -Peerdns -DNS1 "$subnet.10" -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodeprefix$Node"  -rootuser $Rootuser -rootpassword $Guestpassword
        # $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/rcnetwork restart" -Guestuser $Rootuser -Guestpassword $Guestpassword
        Write-Warning "Starting zypper Tasks, this may take a while"
        $Scriptblock = "zypper -n rm patterns-openSUSE-minimal_base-conflicts"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/zypper.log"
        

### Adding Repos        
        $Scriptname = "add_repos.sh"
        $content = "#!/bin/bash
# Contains apache-maven
cat >> /etc/zypp/repos.d/suse-13.1-cesarizu.repo <<EOF
[suse-13.1-cesarizu]
name=suse-13.1-cesarizu
enabled=1
autorefresh=0
baseurl=http://download.opensuse.org/repositories/home:/cesarizu/openSUSE_13.1
type=NONE
EOF
 
# Contains atop
cat >> /etc/zypp/repos.d/suse-13.2-monitoring.repo <<EOF
[suse-13.2-monitoring]
name=suse-13.2-monitoring
enabled=1
autorefresh=0
baseurl=http://download.opensuse.org/repositories/server:/monitoring/openSUSE_13.2
type=NONE
EOF
 
 
# Contains python-cjson
cat >> /etc/zypp/repos.d/suse-13.2-python.repo <<EOF
[suse-13.2-python]
name=suse-13.2-python
enabled=1
autorefresh=0
baseurl=http://download.opensuse.org/repositories/devel:/languages:/python/openSUSE_13.2
type=NONE
EOF
 
# Contains gradle
cat >> /etc/zypp/repos.d/suse-13.2-scalpel4k.repo <<EOF
[suse-13.2-scalpel4k]
name=suse-13.2-scalpel4k
enabled=1
autorefresh=0
baseurl=http://download.opensuse.org/repositories/home:/scalpel4k/openSUSE_13.2
type=NONE
EOF
 
# Contains sipcalc
cat >> /etc/zypp/repos.d/suse-13.2-seife.repo <<EOF
[suse-13.2-seife]
name=suse-13.2-seife
enabled=1
autorefresh=0
baseurl=http://download.opensuse.org/repositories/home:/seife:/testing/openSUSE_13.2
type=NONE
EOF
"
# cachedir = /var/cache/zypp
    $Scriptblock = "sed '\|# cachedir = /var/cache/zypp|icachedir = /mnt/hgfs/Sources/CoprHD/zypp/\n' /etc/zypp/zypp.conf -i"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword



    $Scriptblock = "sudo zypper modifyrepo -k --all"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword



        $Content | Set-Content -Path $Scriptdir\$Scriptname
        convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
        $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword
        
        $Scriptblock = "sh /root/$Scriptname &> /tmp/$Scriptname.log"
        Write-Verbose $Scriptblock
        Write-Warning "When creating local Repo Cache, this might take a while first time!"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
#### Install Prereqs
        $Scriptname = "inst_pre.sh" 
        $Content ="#!/bin/bash
zypper --gpg-auto-import-keys refresh
zypper -n install gcc make pcre-devel zlib-devel ant apache2-mod_perl createrepo expect gcc-c++ gpgme inst-source-utils java-1_7_0-openjdk java-1_7_0-openjdk-devel kernel-default-devel kernel-source kiwi-desc-isoboot kiwi-desc-oemboot kiwi-desc-vmxboot kiwi-templates libtool openssh-fips perl-Config-General perl-Tk python-libxml2 python-py python-requests setools-libs python-setools qemu regexp rpm-build sshpass sysstat unixODBC xfsprogs xml-commons-jaxp-1.3-apis zlib-devel git git-core glib2-devel libgcrypt-devel libgpg-error-devel libopenssl-devel libuuid-devel libxml2-devel pam-devel pcre-devel perl-Error python-devel readline-devel subversion xmlstarlet xz-devel libpcrecpp0 libpcreposix0 ca-certificates-cacert p7zip python-iniparse python-gpgme yum keepalived
zypper -n install -r suse-13.2-monitoring atop GeoIP-data libGeoIP1 GeoIP
zypper -n install -r suse-13.2-scalpel4k gradle
zypper -n install -r suse-13.2-seife sipcalc
zypper -n install -r suse-13.2-python python-cjson
zypper -n install -r suse-13.1-cesarizu apache-maven
"
        $Content | Set-Content -Path $Scriptdir\$Scriptname
        convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
        $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword
        $Scriptblock = "sh /root/$Scriptname &> /tmp/$Scriptname.log"
        Write-Verbose $Scriptblock
        Write-Warning "Installation of Packages form $Scriptname may take a While. you may tail -f /tmp/$Scriptname.log
        If Scriptfailure occurs, press return to retry one time or examine log"
        $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
 
## Compiling nginx 
        $Scriptname = "build_nginx.sh" 
        $Content ="#!/bin/bash
mkdir /tmp/nginx
cd /tmp/nginx
wget 'http://nginx.org/download/nginx-1.6.2.tar.gz'
wget 'http://nginx.org/download/nginx-1.6.2.tar.gz'
wget 'https://github.com/yaoweibin/nginx_upstream_check_module/archive/v0.3.0.tar.gz'
wget 'https://github.com/openresty/headers-more-nginx-module/archive/v0.25.tar.gz'
tar -xzvf nginx-1.6.2.tar.gz
tar -xzvf v0.3.0.tar.gz
tar -xzvf v0.25.tar.gz
cd nginx-1.6.2
patch -p1 < ../nginx_upstream_check_module-0.3.0/check_1.5.12+.patch
./configure --add-module=../nginx_upstream_check_module-0.3.0 --add-module=../headers-more-nginx-module-0.25 --with-http_ssl_module --prefix=/usr --conf-path=/etc/nginx/nginx.conf
make
make install
"

    $Content | Set-Content -Path $Scriptdir\$Scriptname
    convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "sh /root/$Scriptname &> /tmp/$Scriptname.log"
    Write-Verbose $Scriptblock
    Write-Warning "Compiling nginx Server from $Scriptname may take a While. you may tail -f /tmp/$Scriptname.log"
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword

        
}
        else
        {
        Write-Warning "Machine $Nodeprefix$Node already exists"
        break
        }

    
    $Scriptname = "ovfenv.properties"
    $Content = "network_1_ipaddr6=::0
network_1_ipaddr=$ip
network_gateway6=::0
network_gateway=$DefaultGateway
network_netmask=255.255.255.0
network_prefix_length=64
network_vip6=::0
network_vip=$ip
node_count=1
node_id=vipr1"

    $Content | Set-Content -Path $Scriptdir\$Scriptname
    convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/etc/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword
    
    $Scriptblock = "groupadd storageos"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword

    $Scriptblock = "useradd -u 444 -d /opt/storageos -g storageos storageos"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
    
    $Scriptblock = "/usr/sbin/update-alternatives --set java /usr/lib64/jvm/jre-1.7.0-openjdk/bin/java"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword

    $Scriptname = "build_coprhd.sh"
$content = "#!/bin/bash
git clone -b $branch https://github.com/CoprHD/coprhd-controller.git /root/coprhd-controller
cd /root/coprhd-controller   
make clobber BUILD_TYPE=oss rpm"

    $Content | Set-Content -Path $Scriptdir\$Scriptname
    convert-VMXdos2unix -Sourcefile $Scriptdir\$Scriptname -Verbose
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/root/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword

    $Scriptblock = "sh /root/$Scriptname &> /tmp/$Scriptname.log"
    Write-Verbose $Scriptblock
    Write-Warning "Comiling CoprHD from $Scriptname for $branch may take a While. you may tail -f /tmp/$Scriptname.log"
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword

    $Scriptblock = "/bin/rpm -Uhv /root/coprhd-controller/build/RPMS/x86_64/storageos*.x86_64.rpm"
    Write-Verbose $Scriptblock
    Write-Warning "Installing CoprHD RPM
    StorageOS may take 5 Minutes to boot
    please Visit https://$ip for Configuration
    Login with root:ChangeMe"
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword
#>

