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
   https://community.emc.com/blogs/bottk/
.EXAMPLE
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -AVESize 4TB
    installs a 4TB AVE
.EXAMPLE
    .\install-ave.ps1 -MasterPath F:\labbuildr\ave -configure
    Installs the AVE Default 0.5TB and configures Network with defaults and start the AVInstaller
#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
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
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateSet('0.5TB','1TB','2TB','4TB')][string]$AVESize = "0.5TB",
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$subnet = "192.168.2.0",
[Parameter(ParameterSetName = "install",Mandatory=$False)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",

[Parameter(ParameterSetName = "install",Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(ParameterSetName = "install",Mandatory = $false)][switch]$configure,


### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]

[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf -ErrorAction SilentlyContinue })]$ovafile,
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]$mastername


)
#requires -version 3.0
#requires -module vmxtoolkit
[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build

$Builddir = $PSScriptRoot
$Nodeprefix = "AVENode"
$rootuser = "root"
$rootpassword = "changeme"




switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck --acceptAllEulas   --name=$mastername $ovafile $PSScriptRoot #
        }
     "install"

        {
        if (!($MasterVMX = get-vmx -path $MasterPath))
            {
            Write-Error "$Masterpath is not a Virtual machine"
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

        If (!($Basesnap))
            {
            Write-Error "Error creating/finding Basesnap"
            }
        ####Build Machines#

        foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
         {
          Write-Verbose "Checking VM $Nodeprefix$node already Exists"
          If (!(get-vmx $Nodeprefix$node))
                {
                write-verbose "Creating clone $Nodeprefix$node"
               $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXlinkedClone -CloneName $Nodeprefix$node -Clonepath "$Builddir"
              # Write-Output $NodeClone
               $SCSI= 0
               switch ($AVESize)
                   {
                      "0.5TB"
                           {
                         Write-Verbose "SMALL AVE Selected"
                         $NumDisks = 3
                         $Disksize = "250GB"
                         $memsize = 6144
                               $Numcpu = 2
                            }
                        "1TB"
                            {
                            Write-Verbose "Medium AVE Selected"
                            $NumDisks = 6
                            $Disksize = "250GB"
                          $memsize = 8192
                          $Numcpu = 2
                           }
                       "2TB"
                           {
                           Write-Verbose "Large AVE Selected"
                           $NumDisks = 3
                           $Disksize = "1000GB"
                            $memsize = 16384
                            $Numcpu = 2
                           }
                       "4TB"
                           {
                           Write-Verbose "XtraLarge AVE Selected"
                          $NumDisks = 6
                          $Disksize = "1000GB"
                          $memsize = 36864
                    $Numcpu = 4
                          }
        
                 }
            
                 foreach ($LUN in (1..$NumDisks))
                  {
                   $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
                   Write-Verbose "Building new Disk $Diskname"
                    $Newdisk = New-VMXScsiDisk -NewDiskSize $Disksize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                 Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
                   $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                   }
        
    Write-Verbose "Configuring NIC"
    $Netadater = $NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet
    Write-Verbose "Disabling IDE0"
    $NodeClone | Set-VMXDisconnectIDE | Out-Null
    $Displayname = $NodeClone | Set-VMXDisplayName -DisplayName $NodeClone.CloneName
    Write-Verbose "Configuring Memory to $memsize"
    $Memory = $NodeClone | Set-VMXmemory -MemoryMB $memsize
    Write-Verbose "Configuring $Numcpu CPUs"
    $Processor = $nodeclone | Set-VMXprocessor -Processorcount $Numcpu
    Write-Verbose "Starting VM $($NodeClone.Clonename)"
    $Started = $NodeClone | start-vmx
    if ($configure.IsPresent)
    {
    $ip="$subnet.3$Node"
     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")

    Write-Verbose "Configuring Disks"
    $NodeClone | Invoke-VMXBash -Scriptblock "/usr/bin/perl /usr/local/avamar/bin/ave-part.pl" -Guestuser $rootuser -Guestpassword changeme -Verbose | Out-Null

    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $Scriptblock = "echo 'default "+$subnet+".103 - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword -Verbose  | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+".local\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $Scriptblock = "echo '"+$Nodeprefix+$Node+"."+$BuildDomain+".local'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    # $NodeClone | Invoke-VMXBash -Scriptblock "shutdown -r now" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose -nowait
    Write-Verbose "rebooting VM $($NodeClone.Clonename)"
    # we do not use shutdown since toolstate does not reset
    $NodeClone | Stop-VMX | Out-Null
    $NodeClone | start-vmx | Out-Null
    do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config 
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")

    Write-Verbose "Starting Avamar Installer, this may take a while"
    $NodeClone | Invoke-VMXBash -Scriptblock "/bin/sh /usr/local/avamar/src/avinstaller-bootstrap-7.1.1-141.sles11_64.x86_64.run" -Guestuser $rootuser -Guestpassword $rootpassword -Verbose | Out-Null
    Write-Host "Trying to connect to https://$subnet.3$($Node):8543/avi/avigui.html to complete the Installation"
    Start-Process "https://$subnet.3$($Node):8543/avi/avigui.html"
    
    } # end configure
    $NodeClone
    }
    else
        {
        Write-Warning "Node $Nodeprefix$node already exists"
        }

}

}
}
