<#
.Synopsis
   .\install-ave.ps1 -MasterPath F:\labbuildr\ave
.DESCRIPTION
  install-ave is the a vmxtoolkit solutionpack for configuring and deploying avamar virtual editions
      
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
   https://community.emc.com/blogs/bottk/2015/01/27/labbuildrnew-solution-pack-install-ave-to-autodeploy-avamar-nodes
.EXAMPLE
    .\install-ave73.ps1 -ovf  D:\EMC_VAs\AVE-7.3.0.233.ova 
    This extracts the AVE OVF into a template Ready Source
.EXAMPLE
    .\install-ave73.ps1 -MasterPath c:\SharedMaster\AVE-7.3.0.233
    installs a AVE with labbuildrdefaults

#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(

<### import parameters##>
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername,

[Parameter(ParameterSetName = "configure", Mandatory = $false)]
[Parameter(ParameterSetName = "default", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
<# specify your desireed AVE Size 
Valid Parameters: 0.5TB,1TB,2TB,4TB
This will result in the following
Machine Configurations:
=================================
Size   | Memory  | CPU | Disk
_______|_________|_____|_________
0.5TB  |  6GB    |  2  |  3*250GB
  1TB   |  8GB    |  2  |  6*250GB
  2TB   |  16GB   |  2  | 3*1000GB
  4TB   |  36GB   |  4  | 6*1000GB
#>
[Parameter(ParameterSetName = "configure", Mandatory = $false)]
[Parameter(ParameterSetName = "default", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateSet('0.5TB','1TB','2TB','4TB')][string]$AVESize = "0.5TB",

[Parameter(ParameterSetName = "default", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "default", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",


[Parameter(ParameterSetName = "configure", Mandatory = $false)]
[Parameter(ParameterSetName = "default", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,

[Parameter(ParameterSetName = "configure", Mandatory = $false)]
[Parameter(ParameterSetName = "default", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "configure",Mandatory=$true)][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "configure",Mandatory=$true)]
[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",

[Parameter(ParameterSetName = "configure", Mandatory = $true)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",

[Parameter(ParameterSetName = "default",Mandatory = $false)]
[Parameter(ParameterSetName = "configure", Mandatory = $true)][switch]$configure
)
#requires -version 3.0
#requires -module vmxtoolkit
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$sleep = 5
$Builddir = $PSScriptRoot
$Nodeprefix = "AVENode"
$rootuser = "root"
$rootpassword = "changeme"


switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
		$labdefaults = Get-LABDefaults
		try
			{
			$Sourcedir = $labdefaults.Sourcedir
			}
		catch [System.Management.Automation.ValidationMetadataException]
			{
			Write-Warning "Could not test Sourcedir Found from Defaults, USB stick connected ?"
			Break
			}
		catch [System.Management.Automation.ParameterBindingException]
			{
			Write-Warning "No valid Sourcedir Found from Defaults, USB stick connected ?"
			Break
			}
		try
			{
			$Masterpath = $LabDefaults.Masterpath
			}
		catch
			{
			Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
			$Masterpath = $Builddir
			}

        Write-Host -ForegroundColor Gray " ==>Validating OVF"
        try
            {
            $Importfile = Get-ChildItem $ovf -ErrorAction SilentlyContinue
            }
        catch
            {
            Write-Warning "$ovf is no valid ovf / ova location"
            exit
            }

        if ($Importfile.extension -eq ".ova")
            {
            $OVA_Destination = join-path $Importfile.DirectoryName $Importfile.BaseName
			### if already exíst !?!?!?
            Write-Host -ForegroundColor Gray " ==>Extraxting from OVA Package $Importfile"
            $Expand = Expand-LABPackage -Archive $Importfile.FullName -destination $OVA_Destination -Force
            $Importfile = Get-ChildItem -Path $OVA_Destination -Filter "*.ovf" 
            }
        try
            {
            Write-Host -ForegroundColor Gray " ==>Validating OVF from OVA Package"
            $Importfile = Get-ChildItem -Filter "*.ovf" -Path $Importfile.DirectoryName -ErrorAction SilentlyContinue
            }
        catch
            {
            Write-Warning "we could not find a ovf file at $($Importfile.Directoryname)"
            exit
            }
        if (!($mastername)) 
            {
            $mastername = $Importfile.BaseName
            }
        ## tweak ovf
        Write-Host -ForegroundColor Gray " ==>Adjusting OVF file for VMwARE Workstation"
        $content = Get-Content -Path $Importfile.FullName
        $Out_Line = $true
        $OutContent = @()
        ForEach ($Line In $content)
            {
            If ($Line -match '<ProductSection')
                {
                $Out_Line = $false
                }
            If ($Out_Line -eq $True)
                {
                $OutContent += $Line
                }
            If ($Line -match '</ProductSection')
                {
                $Out_Line = $True
                }
            }
        $OutContent | Set-Content -Path $Importfile.FullName
        Write-Host -ForegroundColor Gray " ==>Checkin for VM $mastername"

        if (Get-VMX -path $MasterPath\$mastername -WarningAction SilentlyContinue)
            {
            Write-Warning "Base VM $mastername already exists, please delete first"
            exit
            }
        else
            {
            Write-Host -ForegroundColor Magenta " ==>Importing Base VM"
            if ((import-VMXOVATemplate -OVA $Importfile.FullName -Name $mastername -destination $MasterPath  -acceptAllEulas).success -eq $true)
                {
                Write-Host -ForegroundColor Gray "[Preparation of Template done, please run .\$($MyInvocation.MyCommand) -MasterPath $MasterPath\$mastername]"
                }
            else
                {
                Write-Host "Error importing Base VM. Already Exists ?"
                exit
                }
            }
        }

     default
        {
        If ($Defaults.IsPresent)
            {
            $labdefaults = Get-labDefaults
            $Hostkey = $labdefaults.HostKey
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
            $DNS2 = $labdefaults.DNS2
            $configure = $true
			#$MasterPath = $labdefaults.Masterpath
            }
		if ($LabDefaults.custom_domainsuffix)
			{
			$custom_domainsuffix = $LabDefaults.custom_domainsuffix
			}
		else
			{
			$custom_domainsuffix = "local"
			}

       if ($MasterPath)        
                {
                $MasterVMX = get-vmx -path $MasterPath
                }
        else
            {
			$MasterPath = (Get-LABDefaults).Masterpath
            if (!($MasterVMX=get-vmx -Path "$Masterpath\AVEmaster"))
                {
                $MasterVMX = get-vmx -Path  "$MasterPath\AVE-7*"
                iF ($MasterVMX)
                    {
                    $MasterVMX = $MasterVMX | Sort-Object -Descending
                    $MasterVMX = $MasterVMX[-1]
                    }
                }

            }

        if (!$MasterVMX)
            {
            write-warning "Could not find AVEMaster"
            Write-Warning "Please import with -ovf [path to ova or ovf file]"
            exit
            }
            
            #}


        if (!$MasterVMX.Template) 
          {
          Write-Host -ForegroundColor Gray " ==>Templating Master VMX"
          $template = $MasterVMX | Set-VMXTemplate
          }

        $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue | where Snapshot -Match "Base"
        if (!$Basesnap) 
            {
            Write-Host -ForegroundColor Gray " ==>Tweaking baseconfig"
            $content = Get-Content $MasterVMX.config
            $content = $content -notmatch "independent_persistent"
            $content | Set-Content $MasterVMX.config
            $MasterVMX | Get-VMXScsiDisk | where lun -ne 0 | Remove-VMXScsiDisk | Out-Null
            Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
            $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
            }

        If (!($Basesnap))
            {
            Write-Error "Error creating/finding Basesnap"
            exit
            }
        ####Build Machines#

        foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
         {
          Write-Host -ForegroundColor Gray " ==>Checking VM $Nodeprefix$node already Exists"
          If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
                {
                Write-Host -ForegroundColor Magenta " ==>Creating Machine $Nodeprefix$node"
               $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir"
              # Write-Output $NodeClone
               $SCSI= 0
               switch ($AVESize)
                   {
                      "0.5TB"
                           {
                         Write-Host -ForegroundColor Gray " ==>SMALL AVE Selected"
                         $NumDisks = 3
                         [uint64]$Disksize = 250GB
                         $memsize = 6144
                               $Numcpu = 2
                            }
                        "1TB"
                            {
                            Write-Host -ForegroundColor Gray " ==>Medium AVE Selected"
                            $NumDisks = 6
                            [uint64]$Disksize = 250GB
                          $memsize = 8192
                          $Numcpu = 2
                           }
                       "2TB"
                           {
                           Write-Host -ForegroundColor Gray " ==>Large AVE Selected"
                           $NumDisks = 3
                           [uint64]$Disksize = 1000GB
                            $memsize = 16384
                            $Numcpu = 2
                           }
                       "4TB"
                           {
                           Write-Host -ForegroundColor Gray " ==>XtraLarge AVE Selected"
                          $NumDisks = 6
                          [uint64]$Disksize = 1000GB
                          $memsize = 36864
                    $Numcpu = 4
                          }
        
                 }
            
                 foreach ($LUN in (1..$NumDisks))
                    {
                    $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                    Write-Host -ForegroundColor Gray " ==>Building new Disk $Diskname"
                    $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                    Write-Host -ForegroundColor Gray " ==>Adding Disk $Diskname to $($NodeClone.clonename)"
                    $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                   }
        
    Write-Host -ForegroundColor Gray " ==>Configuring NIC"
    $Netadater = $NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet
    Write-Host -ForegroundColor Gray " ==>Disabling IDE0"
    $NodeClone | Set-VMXDisconnectIDE | Out-Null
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
    $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
    if ($mastervmx.VMXName -ge "AVE-7.2")
        {
        $Annotation = $NodeClone | Set-VMXAnnotation -builddate -Line1 "connect to https://$subnet.3$($Node):7543/avi/avigui.html to complete the Installation" -Line2 "root:$rootuser" -Line3 "password:$rootpassword" -Line4 "SupportUser = Supp0rtHarV1"
        }
    elseif ($mastervmx.VMXName -match "AVE-7.1")
        {
        $Annotation = $NodeClone | Set-VMXAnnotation -builddate -Line1 "connect to https://$subnet.3$($Node):8543/avi/avigui.html to complete the Installation" -Line2 "root:$rootuser" -Line3 "password:$rootpassword" -Line4 "SupportUser = Supp0rtInd1"
        }

    Write-Host -ForegroundColor Gray " ==>Configuring Memory to $memsize"
    $Memory = $NodeClone | Set-VMXmemory -MemoryMB $memsize
    Write-Host -ForegroundColor Gray " ==>Configuring $Numcpu CPUs"
    $Processor = $nodeclone | Set-VMXprocessor -Processorcount $Numcpu
    Write-Host -ForegroundColor Magenta " ==>Starting VM $($NodeClone.Clonename)"
    $Started = $NodeClone | start-vmx
    if ($configure.IsPresent)
    {
    $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
    $ip="$subnet.3$Node"
    Write-Host -ForegroundColor Gray  -NoNewline " [==]Waiting for VMware Tools"
     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep $sleep
        }
    until ($ToolState.state -match "running")
	Write-Host " [running]"
    # if ($mastervmx.VMXName -ge "AVE-7.2")
    # {
    Write-Host -ForegroundColor Gray -NoNewline " [==]Waiting for Avamar to come up"
    do {
        $Process = Get-VMXProcessesInGuest -config $NodeClone.config -Guestuser $rootuser -Guestpassword $rootpassword
        sleep $sleep
        }
    until ($process -match "mingetty")
	Write-Host " [running]"
    if ($DNS2)
        {
        $nameserver = "nameserverver1=$DNS1 nameserver2=$DNS2"
        }
    else
        {
        $nameserver = "nameserverver1=$DNS1"
        }
    $Hostname = $NodeClone.CloneName.ToLower()
    Write-Host -ForegroundColor White "do NOT log in to Appliance until network configured"
    $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/perl /usr/local/avamar/bin/ave-part.pl" -Guestuser $rootuser -Guestpassword changeme | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $Hostname" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $Scriptblock = "echo 'default "+$DefaultGateway+" - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+"."+$custom_domainsuffix+"\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $Scriptblock = "echo '$ip $Hostname $Hostname.$($BuildDomain).$custom_domainsuffix'  >> /etc/hosts"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $Scriptblock = "echo '$Hostname.$BuildDomain.$custom_domainsuffix'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config 
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep $sleep
        }
    until ($ToolState.state -match "running")
    if ($Hostkey)
        {
        $Scriptblock = "echo '$Hostkey' >> /root/.ssh/authorized_keys2"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $rootpassword
        $Scriptblock = "echo '$Hostkey' >> /home/admin/.ssh/authorized_keys2"
        Write-Verbose $Scriptblock
        $Bashresult = $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $rootpassword
        }
    
    Write-Host "connect to https://$subnet.3$($Node):7543/avi/avigui.html to complete the installation, you may wait a few minutes"
    } # end configure
    
    }
    else
        {
        Write-Warning "Node $Nodeprefix$node already exists"
        }

	}

}
}
