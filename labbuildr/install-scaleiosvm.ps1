<#
.Synopsis
   .\install-scaleiosvm.ps1
.DESCRIPTION
  install-scaleiosvm is  the a vmxtoolkit solutionpack for configuring and deploying scaleio 2.0 svm´s

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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-scaleiosvm.ps1
.EXAMPLE
.\install-scaleiosvm.ps1 -Sourcedir d:\sources
.EXAMPLE
.\install-scaleiosvm.ps1 -configure -Defaults
This will Install and Configure a 3-Node ScaleIO with default Configuration
.EXAMPLE
.\install-scaleiosvm.ps1 -Defaults -configure -singlemdm
This will Configure a SIO Cluster with 3 Nodes and Single MDM
.EXAMPLE
.\install-scaleiosvm.ps1 -Disks 3  -sds
This will install a Single Node SDS
#>
[CmdletBinding(DefaultParametersetName = "import")]
Param(
### import parameters
<# for the Import, we specify the Path to the Sources.
Sources are the Root of the Extracted ScaleIO_VMware_SW_Download.zip
If not available, it will be downloaded from http://www.emc.com/scaleio
The extracte OVA will be dehydrated to a VMware Workstation Master #>
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Sourcedir,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$forcedownload,
[Parameter(ParameterSetName = "import",Mandatory=$false)][switch]$noextract,
[Parameter(ParameterSetName = "import",Mandatory=$true)][switch]$import,
#### install parameters#
<# The ScaleIO Master created from -sourcedir  #>
[Parameter(ParameterSetName = "defaults",Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[String]$ScaleIOMaster = ".\ScaleIOVM_2*",
<# Number of Nodes, default to 3 #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][int32]$Nodes=3,
<# Starting Node #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][int32]$Startnode = 1,
<# Number of disks to add, default is 3#>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateRange(1,3)][int32]$Disks = 3,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet,
<# Name of the domain, .$Custom_DomainSuffix added#>
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
<# VMnet to use#>
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$vmnet = "vmnet2",
<# SDS only#>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$true)][switch]$sds,
<# SDC only3#>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "sdsonly",Mandatory=$false)][switch]$sdc,
<# Configure automatically configures the ScaleIO Cluster and will always install 3 Nodes !  #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$configure = $true,
<# we use SingleMDM parameter with Configure for test and dev to Showcase ScaleIO und LowMem Machines #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][switch]$singlemdm,
<# Use labbuildr defaults.json #>
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
<# Path to a defaults.json #>
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.json"
)
#requires -version 3.0
#requires -module vmxtoolkit
#requires -module labtools
$ScaleIO_tag = "ScaleIOVM_2*"
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
		$Labdefaults = Get-LABDefaults
   		try
			{
			$Masterpath = $LabDefaults.Masterpath
			}
		catch
			{
			$Masterpath = $Builddir
			}
        Try
            {
            test-Path $Sourcedir
            }
        Catch
            {
            Write-Verbose $_
            if (!($Sourcedir = $LabDefaults.Sourcedir))
                {
                exit
                }
			else
				{
				Write-Host -ForegroundColor Gray " ==>we will use $($labdefaults.Sourcedir)"
				}
            }
        if (!($OVAPath = Get-ChildItem -Path "$Sourcedir\ScaleIO\$ScaleIO_Path" -recurse -Include "$ScaleIO_tag.ova" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
            {
            Write-Host  -ForegroundColor Gray " ==>No ScaleIO OVA found, Checking for Downloaded Package"
            $Downloadok = Receive-LABScaleIO -Destination $Sourcedir -arch VMware -unzip
			}
        $OVAPath = Get-ChildItem -Path "$Sourcedir\ScaleIO\$ScaleIO_Path" -Recurse -include "$ScaleIO_tag.ova"  -Exclude ".*" | Sort-Object -Descending
        $OVAPath = $OVApath[0]
        $mastername = $($ovaPath.Basename)
        
        if ($vmwareversion.Major -eq 14)
        {
            Write-Warning " running $($vmwareversion.ToString()),we try to avoid a OVF import Bug, trying a manual import"
            Expand-LABpackage -Archive $ovaPath.FullName -filepattern *.vmdk -destination "$Masterpath/$mastername" -Verbose -force
            Copy-Item "./template/ScaleIOVM_2nics.template" -Destination "$Masterpath/$mastername/$Mastername.vmx"
            $Template_VMX = get-vmx -Path "$Masterpath/$mastername"
            $Disk1_item = Get-Item "$Masterpath/$mastername/*disk1.vmdk"
            $Disk1 = $Template_VMX | Add-VMXScsiDisk -Diskname $Disk1_item.Name -LUN 0 -Controller 0          
        } 
    else {
		$Template = Import-VMXOVATemplate -OVA $ovaPath.FullName -destination $Masterpath -acceptAllEulas -Quiet -AllowExtraConfig
    }
        $MasterVMX = get-vmx -path "$Masterpath\$mastername"
        if (!$MasterVMX.Template)
            {
            write-verbose "Templating Master VMX"
            $Temolate = $MasterVMX | Set-VMXTemplate
            }
      Write-Host -ForegroundColor Gray "[Preparation of Template done"
	  write-host -ForegroundColor White ".\$($MyInvocation.MyCommand) -ScaleioMaster $MasterPath\$mastername -Defaults -configure"

        }
     default
        {
		If ($singlemdm.IsPresent)
			{
			[switch]$configure = $true
			}
		if ($configure.IsPresent)
			{
			[switch]$sds = $true
			[switch]$sdc = $true
			}
		If ($Defaults.IsPresent)
			{
			 $labdefaults = Get-labDefaults
			 $vmnet = $labdefaults.vmnet
			 $subnet = $labdefaults.MySubnet
			 $BuildDomain = $labdefaults.BuildDomain
			 $Sourcedir = $labdefaults.Sourcedir
			 $DefaultGateway = $labdefaults.DefaultGateway
			 $Sourcedir = $labdefaults.Sourcedir
			 }
		if ($LabDefaults.custom_domainsuffix)
			{
			$custom_domainsuffix = $LabDefaults.custom_domainsuffix
			}
		else
			{
			$custom_domainsuffix = "local"
			}

		[System.Version]$subnet = $Subnet.ToString()
		$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
		$rootuser = "root"
		$old_rootpassword = "admin"
		$MDMPassword = "Password123!"
		$Guestpassword = $MDMPassword
		[uint64]$Disksize = 100GB
		$scsi = 0
		$ScaleIO_OS = "VMware"
		$ScaleIO_Path = "ScaleIO_$($ScaleIO_OS)_SW_Download"
		$Devicename = "$Location"+"_Disk_$Driveletter"
		$VolumeName = "Volume_$Location"
		$ProtectionDomainName = "PD_$BuildDomain"
		$StoragePoolName = "SP_$BuildDomain"
		$SystemName = "ScaleIO@$BuildDomain"
		$FaultSetName = "Rack_"
		$mdm_ipa  = "$subnet.191"
		$mdm_ipb  = "$subnet.192"
		$tb_ip = "$subnet.193"
		$mdm_name_a = "Manager_A"
		$mdm_name_b = "Manager_B"
		$tb_name = "TB"
        if (!(Test-Path $SCALEIOMaster))
            {
            Write-Warning "!!!!! No ScaleIO Master found
            please run .\install-scaleiosvm.ps1 -import to download / create Master
            "
            exit
            }
        if ($SCALEIOMaster -notmatch $ScaleIO_tag)
            {
            Write-Warning "Master must match $ScaleIO_tag"
            exit
            }
        $Mastervmxlist = get-vmx -Path $SCALEIOMaster | Sort-Object -Descending
        if (!($Mastervmxlist))
            {
            Write-Warning "!!!!! No ScaleIO Master found for $ScaleIO_tag
            please run .\install-scaleiosvm.ps1 -import to download / create Master
            "
            exit
            }
        $MasterVMX = $Mastervmxlist[0]
        $Nodeprefix = "ScaleIONode"
        If ($configure.IsPresent -and $Nodes -lt 3)
            {
            Write-Warning "Configure Present, setting nodes to 3"
            $Nodes = 3
            }
		if ($MasterVMX.VMXname -match '2.0.1')
			{
			$SIO_Major = '2.0.1'
			Write-Host -ForegroundColor Magenta " ==> installing ScaleIO Branch 2.0.1 "
			}
        If ($singlemdm.IsPresent)
            {
            Write-Warning "Single MDM installations with MemoryTweaking  are only for Test Deployments and Memory Contraints/Manager Laptops :-)"
            $mdm_ip="$mdm_ipa"
            }
        else
            {
            $mdm_ip="$mdm_ipa,$mdm_ipb"
            }
        if (!$MasterVMX.Template)
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot  -WarningAction SilentlyContinue | where Snapshot -Match "Base"

        if (!$Basesnap)
        {
         Write-verbose "Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        }
####Build Machines#
    Write-Host -ForegroundColor Magenta "Starting Avalanche install For Scaleio Nodes..."
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        Write-Host -ForegroundColor Gray " ==>Checking presence of $Nodeprefix$node"
        if (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue ))
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXLinkedClone -CloneName $Nodeprefix$Node
            If ($Node -eq 1){$Primary = $NodeClone}
            $Config = Get-VMXConfig -config $NodeClone.config
            Write-Verbose "Tweaking Config"
            $Config = $config | ForEach-Object { $_ -replace "lsilogic" , "pvscsi" }
            $Config | set-Content -Path $NodeClone.Config
            foreach ($LUN in (1..$Disks))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -VMXName $NodeClone.VMXname -Path $NodeClone.Path
                $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI | Out-Null
                }
            $NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 | out-null
            if ($vmnet)
                {
                $NodeClone | Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -WarningAction SilentlyContinue | out-null
                $NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet -WarningAction SilentlyContinue | out-null
                $NodeClone | Disconnect-VMXNetworkAdapter -Adapter 1 | out-null
                $NodeClone | Disconnect-VMXNetworkAdapter -Adapter 2 | Out-Null
                }
			$Displayname = $NodeClone | Set-VMXDisplayName -DisplayName "$($NodeClone.CloneName)@$BuildDomain"
			$MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
			$Annotation = $NodeClone | Set-VMXAnnotation -Line1 "rootuser:$rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "mdmuser:admin" -Line4 "mdmpassword:$MDMPassword" -Line5 "labbuildr by @sddc_guy" -builddate
			$Scenario = $NodeClone |Set-VMXscenario -config $NodeClone.Config -Scenarioname Scaleio -Scenario 6
			$ActivationPrefrence = $NodeClone |Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node
            if ($singlemdm.IsPresent -and $Node -notin (1,3))
                {
                $memorytweak = $NodeClone | Set-VMXmemory -MemoryMB 1536
                }
            # Set-VMXVnet -Adapter 0 -vnet vmnet2
            start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName | out-null
            # $NodeClone | Set-VMXSharedFolderState -enabled
            }
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
                if ($configure.IsPresent)
                    {
                    Write-Warning "Please Delete VM´s First, use
                    'get-vmx $Nodeprefix$Node | remove-vmx'
to remove the Machine or
                    'get-vmx $Nodeprefix | remove-vmx'
to remove all Nodes"
                    exit
                    }
            }
}
$Logfile = "/tmp/install_sio.log"
Write-Host -ForegroundColor Magenta " ==>Starting configuration of Nodes, logging to $Logfile"
$Percentage = [math]::Round(100/$nodes)+1
if ($Percentage -lt 10)
    {
    $Percentage = 10
    }
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        Write-Host -ForegroundColor Gray " ==>waiting for Node $Nodeprefix$node"
        $ip="$subnet.19$Node"
        $NodeClone = get-vmx $Nodeprefix$node
        do {
            $ToolState = Get-VMXToolsState -config $NodeClone.config
            Write-Verbose "VMware tools are in $($ToolState.State) state"
            sleep 5
            }
        until ($ToolState.state -match "running")
        If (!$DefaultGateway) {$DefaultGateway = $Ip}
        $Scriptblock = "echo -e '$Guestpassword\n$Guestpassword' | (passwd --stdin root)"
        $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $old_rootpassword -logfile $Logfile | Out-Null
        
        $Scriptblock = "/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword -logfile $Logfile
        
        if ($labdefaults.Hostkey)
            {
            $Scriptblock = "echo '$($Labdefaults.Hostkey)' >> /root/.ssh/authorized_keys"
            $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
            }
        $NodeClone | Set-VMXLinuxNetwork -ipaddress $ip -network "$subnet.0" -netmask "255.255.255.0" -gateway $DefaultGateway -device eth0 -Peerdns -DNS1 "$subnet.10" -DNSDOMAIN "$BuildDomain.$Custom_DomainSuffix" -Hostname "$Nodeprefix$Node" -suse -rootuser $rootuser -rootpassword $Guestpassword | Out-Null
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm --import /root/install/RPM-GPG-KEY-ScaleIO" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-openssl*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
     
        if (!($PsCmdlet.ParameterSetName -eq "sdsonly"))
            {
            if (($Node -in 1..2 -and (!$singlemdm)) -or ($Node -eq 1))
                {
                Write-Host -ForegroundColor Gray " ==>trying MDM Install as manager"
                $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_ROLE_IS_MANAGER=1;rpm -Uhv /root/install/EMC-ScaleIO-mdm*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
                }

            if ($Node -eq 3)
                {
				$GatewayNode = $NodeClone
                Write-Host -ForegroundColor Gray " ==>trying Gateway Install"
                $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/jre-*-linux-x64.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
                $NodeClone | Invoke-VMXBash -Scriptblock "export SIO_GW_KEYTOOL=/usr/java/default/bin/;export GATEWAY_ADMIN_PASSWORD='Password123!';rpm -Uhv --nodeps  /root/install/EMC-ScaleIO-gateway*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
                if (!$singlemdm)
                    {
                    Write-Host -ForegroundColor Gray " ==>trying MDM Install as tiebreaker"
                    $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_ROLE_IS_MANAGER=0;rpm -Uhv /root/install/EMC-ScaleIO-mdm*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
                    Write-Host -ForegroundColor Gray " ==>adding MDM to Gateway Server Config File"
                    $sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$mdm_ipa;$mdm_ipb\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties"
                    }
                else
                    {
                    Write-Host -ForegroundColor Gray " ==>adding MDM's to Gateway Server Config File"
                    $sed = "sed -i 's\mdm.ip.addresses=.*\mdm.ip.addresses=$mdm_ipa;$mdm_ipa\' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties"
                    }
                Write-Verbose $sed
                $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				$MY_CIPHERS="'ciphers='`"'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256,TLS_DHE_DSS_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384'`"''"
				$Scriptblock = "MYCIPHERS=$MY_CIPHERS;sed -i '/ciphers=/s/.*/'`$MYCIPHERS'/' /opt/emc/scaleio/gateway/conf/server.xml"	
				$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
				$NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/scaleio-gateway restart" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
                }
            Write-Host -ForegroundColor Gray " ==>trying LIA Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-lia*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
            }
        if ($sds.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>trying SDS Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "rpm -Uhv /root/install/EMC-ScaleIO-sds-*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
            }
        if ($sdc.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>trying SDC Install"
            $NodeClone | Invoke-VMXBash -Scriptblock "export MDM_IP=$mdm_ip;rpm -Uhv /root/install/EMC-ScaleIO-sdc*.rpm" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
			$Scriptlets = ("cat > /bin/emc/scaleio/scini_sync/driver_sync.conf <<EOF
repo_address        = ftp://ftp.emc.com`
repo_user           = QNzgdxXix`
repo_password       = Aw3wFAwAq3`
local_dir           = /bin/emc/scaleio/scini_sync/driver_cache/`
module_sigcheck     = 0`
emc_public_gpg_key  = /bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO`
repo_public_rsa_key = /bin/emc/scaleio/scini_sync/scini_repo_key.pub`
",
"/usr/bin/dos2unix /bin/emc/scaleio/scini_sync/driver_sync.conf;/etc/init.d/scini restart")
			foreach ($Scriptblock in $Scriptlets)
						{
						Write-Verbose $Scriptblock
						$NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
						}
				           
            }
    }
if ($configure.IsPresent)
    {
    Write-Host -ForegroundColor Magenta " ==> Now configuring ScaleIO"
    $Logfile = "/tmp/configure_sio.log"
    $mdmconnect = "scli --login --username admin --password $MDMPassword --mdm_ip $mdm_ip"
    if ($Primary)
        {
        Write-Host -ForegroundColor Magenta "We are now creating the ScaleIO Cluster"
        Write-Host -ForegroundColor Gray " ==>adding Primary MDM $mdm_ipa"
        $sclicmd =  "scli  --create_mdm_cluster --master_mdm_ip $mdm_ipa  --master_mdm_management_ip $mdm_ipa --master_mdm_name $mdm_name_a --approve_certificate --accept_license;sleep 3"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        Write-Host -ForegroundColor Gray " ==>Setting password"
        $sclicmd =  "scli --login --username admin --password admin --mdm_ip $mdm_ipa;scli --set_password --old_password admin --new_password $MDMPassword --mdm_ip $mdm_ipa"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        if (!$singlemdm.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>adding standby MDM $mdm_ipb"
            $sclicmd = "$mdmconnect;scli --add_standby_mdm --mdm_role manager --new_mdm_ip $mdm_ipb --new_mdm_management_ip $mdm_ipb --new_mdm_name $mdm_name_b --mdm_ip $mdm_ipa"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
            Write-Host -ForegroundColor Gray " ==>adding tiebreaker $tb_ip"
			if ($SIO_Major -eq '2.0.1')
				{
	            $sclicmd = "$mdmconnect; scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --mdm_ip $mdm_ipa"
				}
			else
				{
				$sclicmd = "$mdmconnect; scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --tb_name $tb_name --mdm_ip $mdm_ipa"
				}

            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

            Write-Host -ForegroundColor Gray " ==>switching to cluster mode"
            $sclicmd = "$mdmconnect;scli --switch_cluster_mode --cluster_mode 3_node --add_slave_mdm_ip $mdm_ipb --add_tb_ip $tb_ip  --mdm_ip $mdm_ipa"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock $sclicmd -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
            }
        else
            {
            $mdm_ipb = $mdm_ipa
            }
        Write-Host -ForegroundColor Magenta "Storing SIO Confiuration locally"
        Set-LABSIOConfig -mdm_ipa $mdm_ipa -mdm_ipb $mdm_ipb -gateway_ip $tb_ip -system_name $SystemName -pool_name $StoragePoolName -pd_name $ProtectionDomainName

        Write-Host -ForegroundColor Gray " ==>adding protection domain $ProtectionDomainName"
        $sclicmd = "scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null

        Write-Host -ForegroundColor Gray " ==>adding storagepool $StoragePoolName"
        $sclicmd = "scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
        Write-Host -ForegroundColor Gray " ==>adding renaming system to $SystemName"
        $sclicmd = "scli --rename_system --new_name $SystemName --mdm_ip $mdm_ip"
        Write-Verbose $sclicmd
        $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
		Write-Host -ForegroundColor Gray " ==> approving mdm Certificates for gateway"
		}#end Primary
    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            Write-Host -ForegroundColor Gray " ==>adding sds $subnet.19$Node with /dev/sdb"
            $sclicmd = "scli --add_sds --sds_ip $subnet.19$Node --device_path /dev/sdb --device_name /dev/sdb  --sds_name ScaleIONode$Node --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_ip"
            Write-Verbose $sclicmd
            $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
            }
    Write-Host -ForegroundColor Gray " ==>adjusting spare policy"
    $sclicmd = "scli --modify_spare_policy --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --spare_percentage $Percentage --i_am_sure --mdm_ip $mdm_ip"
    Write-Verbose $sclicmd
    $Primary | Invoke-VMXBash -Scriptblock "$mdmconnect;$sclicmd" -Guestuser $rootuser -Guestpassword $Guestpassword -logfile $Logfile | Out-Null
	$scriptblock = "export TOKEN=`$(curl --silent --insecure --user 'admin:$($Guestpassword)' 'https://localhost/api/gatewayLogin' | sed 's:^.\(.*\).`$:\1:') \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipa)' > '/tmp/mdm_a.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_a.cer' 'https://localhost/api/trustHostCertificate/Mdm' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X GET 'https://localhost/api/getHostCertificate/Mdm?host=$($mdm_ipb)' > '/tmp/mdm_b.cer' \n`
curl --silent --show-error --insecure --user :`$TOKEN -X POST -H 'Content-Type: multipart/form-data' -F 'file=@/tmp/mdm_b.cer' 'https://localhost/api/trustHostCertificate/Mdm' "
	$GatewayNode | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $Guestpassword| Out-Null
	write-host "Connect with ScaleIO UI to $mdm_ipa admin/Password123!"
    }
write-host "Login to the VM´s with root/admin"
$StopWatch.Stop()
Write-host -ForegroundColor White "ScaleIO Deployment took $($StopWatch.Elapsed.ToString())"
} #end default
}#end switch 