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
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
<#Specify desired branch#>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[ValidateSet('release-2.4-coprhd','master','INTEGRATION-YODA-FOUNDATION','INTEGRATION-2.4.1-FOUNDATION','integration-2.4.1')]$branch = "master",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>

[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
$Node = 1
)
#requires -version 3.0
#requires -module vmxtoolkit
$Range = "24"
$Builddir = $PSScriptRoot

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
     $MasterPath = $labdefaults.MasterPath
     }

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$OS = "OpenSuse"
$Scenarioname = "Coprhd"
$MasterPath = Join-Path $MasterPath $OS
$Nodeprefix = "$($Scenarioname)Node"
# $release = $release.tolower()
$Guestpassword = "Password123!"
$Rootuser = "root"
$Guestuser = $Scenarioname.ToLower()
$Scriptdir = "$Sourcedir\$($Scenarioname.ToLower())"
if ($branch -eq 'release-2.4-coprhd')
    {
    $IP = "$subnet.14"
    $Nodename = "CoprHD_Release"
    } 
else
    {
    $ip = "$subnet.245"
    $Nodename = "CoprHD_Develop"
    }

[uint64]$Disksize = 100GB
$scsi = 0
if (!(Test-Path $MasterPath))
    {
    Write-Warning "no OpenSuse Master found. Please download from
    https://github.com/bottkars/labbuildr/wiki/Master"
    exit
    }
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



        If (!(get-vmx $Nodename))
        {
        write-verbose " Creating $Nodename"
        $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodename -clonepath $Builddir
        If ($Node -eq 1){$Primary = $NodeClone}
        $Config = Get-VMXConfig -config $NodeClone.config
        Write-Verbose "Tweaking Config"
        write-verbose "Setting NIC0 to HostOnly"
        Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
        if ($vmnet)
            {
            Write-Verbose "Configuring NIC 0 for $vmnet"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        $Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @hyperv_guy" -builddate
        $Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
        # $ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
        $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
        $NodeClone | Set-VMXmemory -MemoryMB 6144 | Out-Null
        $Config = $Nodeclone | Get-VMXConfig
        $Config = $Config -notmatch "ide1:0.fileName"
        $Config | Set-Content -Path $NodeClone.config 
        Write-Host -ForegroundColor Magenta "***Starting $($NodeClone.CloneName)***"
        start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | Out-Null
        $machinesBuilt += $($NodeClone.cloneName)

        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        Write-Verbose "Setting Shared Folders"
        $NodeClone | Set-VMXSharedFolderState -enabled |Out-Null
        Write-verbose "Cleaning Shared Folders"
        $Nodeclone | Set-VMXSharedFolder -remove -Sharename Sources | out-null 
        Write-Verbose "Adding Shared Folders"        
        $NodeClone | Set-VMXSharedFolder -add -Sharename Sources -Folder $Sourcedir |Out-Null
        Write-Host -ForegroundColor Magenta "[Configuring Network, please be patient]"
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -suse -device eno16777984 -Peerdns -DNS1 "$subnet.10" -DNSDOMAIN "$BuildDomain.local" -Hostname "$Nodename"  -rootuser $Rootuser -rootpassword $Guestpassword | Out-Null
        Write-Host -ForegroundColor Magenta "[Restarting Network, please be patient]"
        $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/rcnetwork restart" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
        
        Write-Host -ForegroundColor Magenta "[Starting zypper Tasks, this may take a while]"
        $Scriptblock = "sed '\|# cachedir = /var/cache/zypp|icachedir = /mnt/hgfs/Sources/$OS/zypp/\n' /etc/zypp/zypp.conf -i"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null



        $Scriptblock = "sudo zypper modifyrepo -k --all"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null


        $Scriptblock = "zypper --non-interactive install --no-recommends git make; echo $?"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/zypper.log" | Out-Null

           
        Write-Host -ForegroundColor Magenta "[Cloning into CoprHD]"
        $Scriptblock = "git clone https://review.coprhd.org/scm/ch/coprhd-controller.git"
        Write-Verbose $Scriptblock
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/git_clone.log" | Out-Null

        Write-Host -ForegroundColor Magenta "[Running Installation Tasks]"
        $Components = ('installRepositories','installPackages','installNginx','installJava 8','installStorageOS')
        Foreach ($component in $Components)
            {
            Write-Host -ForegroundColor Magenta " ==> Running Task $component"
            $Scriptblock = "/coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh $component"
            Write-Verbose $Scriptblock
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile "/tmp/$component.log"  | Out-Null       
            }
 
}
        else
        {
        Write-Warning "Machine $Nodename already exists"
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
    $NodeClone | copy-VMXfile2guest -Sourcefile $Scriptdir\$Scriptname -targetfile "/etc/$Scriptname" -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
    Write-Host -ForegroundColor Magenta " ==> Building CoprHD RPM"

    $Scriptblock = "cd /coprhd-controller;make clobber BUILD_TYPE=oss rpm &> /tmp/build_coprhd.log"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword | Out-Null
    Write-Host -ForegroundColor Magenta " ==> Installing CoprHD RPM"
    $Scriptblock = "/bin/rpm -Uhv /coprhd-controller/build/RPMS/x86_64/storageos*.x86_64.rpm" #;/sbin/shutdown -r now"
    Write-Verbose $Scriptblock
    $NodeClone | Invoke-VMXBash -Scriptblock $scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword   | Out-Null



    Write-Host -ForegroundColor Blue "Installed CoprHD RPM
    StorageOS may take 5 Minutes to boot
    please Visit https://$ip for Configuration
    Login with root:ChangeMe
    For Console login use labbuildr:$($Guestpassword) and su
    A reboot may be required
    "
