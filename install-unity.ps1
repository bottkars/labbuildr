<#
.Synopsis
   .\install-Unity.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
  install-Unity only applies to Testers of the Virtual Unity
  install-Unity is a 1 Step Process.
  Once Unity is downloaded via feedbckcentral, run 
   .\install-Unity.ps1 -defaults
   This creates a Unity Master in your labbuildr directory.
   This installs a Unity using the defaults file and the just extracted Unity Master
    
      
      Copyright 2016 Karsten Bott

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
   https://github.com/bottkars/labbuildr/wiki/SolutionPacks#install-Unity
.EXAMPLE
    Importing the ovf template
 .\install-Unity.ps1 -ovf E:\EMC_VAs\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.ovf
    Opening OVF source: E:\EMC_VAs\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.ovf
    The manifest does not validate
    Opening VMX target: F:\labbuildr_beta
    Warning:
    - Hardware compatibility check is disabled.
    - Line 54: Unsupported virtual hardware device 'VirtualSCSI'.
    Writing VMX file: F:\labbuildr_beta\Unity-1.4.5.2-535679\Unity-1.4.5.2-535679.vmx
    Transfer Completed
    Warning:
    - ExtraConfig option 'tools.guestlib.enableHostInfo' is not allowed, will skip it.
    - ExtraConfig option 'sched.mem.pin' is not allowed, will skip it.
    Completed successfully
.EXAMPLE
    Install a UnityNode with defaults from defaults.xml
   .\install-Unity.ps1 -Masterpath .\Unity-1.4.5.2-535679 -Defaults
    WARNING: VM Path does currently not exist
    WARNING: Get-VMX : VM does currently not exist

    VMXname   Status  Starttime
    -------   ------  ---------
    UnityNode1 Started 07.21.2015 12:27:11
#>
[CmdletBinding(DefaultParametersetName = "default")]
Param(
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ova -PathType Leaf -ErrorAction SilentlyContinue })]$ovf,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$Mastername,
[Parameter(ParameterSetName = "defaults",Mandatory=$False)]
[Parameter(ParameterSetName = "import",Mandatory=$false)]
[Parameter(ParameterSetName = "install",Mandatory=$true)]$MasterPath,
[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)]
[ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)]
[ValidateLength(1,63)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,63}[a-zA-Z0-9]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install", Mandatory = $false)]
[ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",
[int]$Disks = 3

)
#requires -version 3.0
#requires -module vmxtoolkit
$Builddir = $PSScriptRoot
switch ($PsCmdlet.ParameterSetName)
{

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
        if (!($mastername)) 
            {
            $OVFfile = Get-Item $ovf
            $mastername = $OVFfile.BaseName
            }
        Import-VMXOVATemplate -OVA E:\EMC_VAs\UnityVSA-4.0.0.7329527.ova -acceptAllEulas -AllowExtraConfig -destination $MasterPath
        #   & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Magenta  "Use .\install-Unity.ps1 -Masterpath $Masterpath -Mastername $Mastername 
        .\install-Unity.ps1 -Defaults to try defaults"
        }

     default
        {
        If ($Defaults.IsPresent)
            {
            $labdefaults = Get-labDefaults
            if (!($labdefaults))
                {
                try
                    {
                    $labdefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                    }
                catch
                    {
                Write-Warning "no  defaults or example defaults found, exiting now"
                exit
                    }
            Write-Host -ForegroundColor Magenta "Using generic defaults from labbuildr"
            }
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
            $DNS2 = $labdefaults.DNS1
            $configure = $true
            $masterpath = $labdefaults.Masterpath
            }

        $Startnode = 1
        $Nodes = 1
        [System.Version]$subnet = $Subnet.ToString()
        $Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

        $Builddir = $PSScriptRoot
        $Nodeprefix = "UnityNode"
        if (!$MasterVMX)
            {
            $MasterVMX = get-vmx -path $Masterpath -VMXName UnityVSA-4*
            iF ($MasterVMX)
                {
                $MasterVMX = $MasterVMX | Sort-Object -Descending
                $MasterVMX = $MasterVMX[-1]
                }
            }
        else
            {
            if ($MasterPath)        
                {
                $MasterVMX = get-vmx -path $MasterPath -VMXName $MasterVMX
                }
            }

        if (!$MasterVMX)
            {
            write-Host -ForegroundColor Magenta "Could not find existing UnityMaster"
            <#
            if ($Defaults.IsPresent)
                {
                Write-Host -ForegroundColor Magenta "Trying Latest OVF fom $Sourcedir"
                try
                    {
                    $OVFpath =Join-Path $Sourcedir "Unity-*.ov*" -ErrorAction Stop
                    }
                catch [System.Management.Automation.DriveNotFoundException] 
                    {
                    Write-Warning "Drive not found, make sure to have your Source Stick connected"
                    exit
                    }
                
                    $OVFfile = get-item -Path $OVFpath | Sort-Object -Descending -Property Name
                    If (!$OVFfile)
                        {
                        Write-Warning "No OVF for Unity found, please conntact feedbackcentral"
                        exit
                        }
                    else 
                        {
                        Write-Host -ForegroundColor Magenta "testing OVA File"
                        $OVFfile = $OVFfile[0]
                        $mastername = $OVFfile.BaseName
                        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $OVFfile.FullName $PSScriptRoot #
                        if ($LASTEXITCODE -ne 0)
                            {
                            Write-Warning "Error Extraxting OVF"
                            exit
                            }
                        $MasterVMX = get-vmx $mastername
                        }
                }
            else
                {
                Write-Warning "Please import with -ovf or use -Defaults"
                exit
                }
            #>
            return
            }
        Write-Host -ForegroundColor Magenta " ==>Checking Base VM Snapshot"
        if (!$MasterVMX.Template) 
            {
            Write-Host -ForegroundColor Magenta " ==>Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base" 

        if (!$Basesnap) 
            {
            Write-Host -ForegroundColor Magenta "Tweaking Base VMX"
            $config = Get-VMXConfig -config $MasterVMX.config
            foreach ($scsi in 0..3)
                {
                $config = $config -notmatch "scsi$scsi.virtualDev"
                $config += 'scsi'+$scsi+'.virtualDev = "pvscsi"'
                $config = $config -notmatch "scsi$scsi.present"
                $config += 'scsi'+$scsi+'.present = "true"'
                }
            Set-Content -Path $MasterVMX.config -Value $config
            Write-Host -ForegroundColor Magenta " ==>Base snap does not exist, creating now"
            $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName Base
            }
            # $Basesnap
        foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
            {
            $ipoffset = 4+$Node
            Write-Host -ForegroundColor Magenta " ==>Checking VM $Nodeprefix$node already Exists"
            If (!(get-vmx -path $Nodeprefix$node -WarningAction SilentlyContinue))
                {
                write-Host -ForegroundColor Magenta " ==>Creating clone $Nodeprefix$node"
                $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir" 
        Write-Host -ForegroundColor Magenta " ==>Configuring NICs"
        foreach ($nic in 0..5)
            {
            Write-Host -ForegroundColor Gray "  ==>Configuring NIC$nic"
            $Netadater0 = $NodeClone | Set-VMXVnet -Adapter $nic -vnet $VMnet -WarningAction SilentlyContinue
            }
        Write-Host -ForegroundColor Magenta " ==>Creating Disks"
        $SCSI = 1
        [uint64]$Disksize = 100GB
        if ($Disks -ne 0)
            {
            foreach ($LUN in (3..($Disks+2)))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN.vmdk"
                Write-Host -ForegroundColor Gray "  ==>Building new Disk $Diskname"
                $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                Write-Host -ForegroundColor Gray "  ==>Adding Disk $Diskname to $($NodeClone.VMXname)"
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }
        }
        $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
        $MainMem = $NodeClone | Set-VMXMainMemory -usefile:$false
        Write-Host -ForegroundColor Magenta " ==>Starting VM $($NodeClone.Clonename)"
        $NodeClone | start-vmx | Out-Null
        if ($configure.IsPresent)
            {
            $ip="$subnet.$ipoffset"
            }
        }
        else
            {
            Write-Warning "Node $Nodeprefix$node already exists"
            }

        }
    Write-host
    Write-host -ForegroundColor Blue "****** To Configure  Unity 4 ******
        Go to VMware Console an wait for system to boot
        It might take up to 1Minutes on First boot
        Login with  
service/service 
        and run  
svc_initial_config -4 `"$ip 255.255.255.0 $DefaultGateway`"
        once configured, open browser to 
https://$ip and login with admin / Password123#
    activate your license at
 https://www.emc.com/auth/elmeval.htm
"

    }# end default
}

