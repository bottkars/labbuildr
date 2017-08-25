<#
.Synopsis
   .\install-scaleio.ps1 
.DESCRIPTION
  install-scaleio is  the a vmxtoolkit solutionpack for configuring and deploying scaleio svm´s
      
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
.EXAMPLE
.\install-geonas.ps1 -ovf D:\Sources\geonas-ESXi5-5.1.0.6695\geonas-ESXi5-5.1.0.6695.ovf 
This will convert geonas ESX Template 
.EXAMPLE
.\install-geonas.ps1 -MasterPath .\geonas-cacheESXi5-5.1.0.6695 -Defaults  
This will Install default Cloud boost
#>
[CmdletBinding()]
Param(
### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf})]$ova,
<### install param
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateRange(1,3)][int32]$Cachevols = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet(36GB,72GB,146GB)][uint64]$Cachevolsize = 146GB,
#>
#[Parameter(ParameterSetName = "defaults", Mandatory = $true)]
[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$Master,



[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.json",


[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][validateRange(1,3)][int32]$Nodes=1,

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,

[Parameter(ParameterSetName = "install", Mandatory = $true)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2",

[Parameter(Mandatory = $true)][ValidateSet('primary','sitecache')]$role = "primary"

)
#requires -version 3.0
#requires -module vmxtoolkit 

function clone-node
{
[CmdletBinding()]
Param(
$Nodename
)
    
        Write-Verbose "Checking VM $Nodename already Exists"
        If (!(get-vmx $Nodename))
            {
            Write-Host -ForegroundColor Magenta " ==>Creating clone $Nodename"
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
            Write-Host -ForegroundColor Magenta " ==>tweaking $Nodeprefix to run on Workstation"
            $NodeClone | Set-VMXmemory -MemoryMB 8192 | Out-Null
            Write-Verbose "Setting ext-0"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType e1000 -PCISlot 32 -config $NodeClone.Config | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config | Out-Null
            $SetScenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Scenario -Scenario 6
            $SetActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
            # Set-VMXVnet -Adapter 0 -vnet vmnet2
            write-verbose "Setting Display Name $($NodeClone.CloneName)@$Builddomain"
            Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain" | Out-Null
            Write-host -ForegroundColor Magenta " ==>Starting $Nodename"

            start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName | Out-Null
            } # end check vm
        else
            {
            Write-Warning "VM $Nodeprefix$node already exists"
            }
    
    
    
    
    } 

$Scenario = "geonas"
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {

        if (!(($Mymaster = Get-Item $ova).Extension -match "ovf" -or "ova"))
            {
            write-warning "no ova Template found"
            exit
            }
        
        # if (!($mastername)) {$mastername = (Split-Path -Leaf $ovf).Replace(".ovf","")}
        # $Mymaster = Get-Item $ovf
        $Mastername = "$($scenario)_$($role)_master"
        Write-Host -ForegroundColor Magenta " ==>Importing $Mastername"
        import-VMXOVATemplate -OVA $ova -Name $Mastername
        # & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$mastername $ovf $PSScriptRoot #
        Write-Host -ForegroundColor Magenta " ==>tweaking $Mastername"
        $Content = Get-Content $PSScriptRoot\$mastername\$mastername.vmx
        $Content = $Content -notmatch 'snapshot.maxSnapshots'
        $Content = $Content -notmatch 'vmci0.pciSlotNumber'
        $Content += 'vmci0.pciSlotNumber = "33"'
        $Content | Set-Content $PSScriptRoot\$mastername\$mastername.vmx
        $Mastervmx = get-vmx -path $PSScriptRoot\$mastername\$mastername.vmx
        $Mastervmx | Set-VMXHWversion -HWversion 7 | Out-Null
        write-host -ForegroundColor Magenta "Now run .\install-geonas.ps1 -role $role -Defaults" 
        }
default
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
            $configure = $true
            }



    $Nodeprefix = "$($Scenario)$role"
    If (!($Master))
        {
        $master = "$($scenario)_$($role)_master"
        }
    If (!($MasterVMX = get-vmx -path $Master))
      {
       Write-Error "No Valid Master Found"
      break
     }
    

    $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
    if (!$Basesnap) 
        {
        Write-Host -ForegroundColor Magenta " ==>tweaking $Mastername"
        $Config = Get-VMXConfig -config $MasterVMX.Config
        $Config = $Config -notmatch 'snapshot.maxSnapshots'
        $Config | set-Content -Path $MasterVMX.Config
        Write-Host -ForegroundColor Magenta " ==>Creating Basesnap"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }

        } #end basesnap
####Build Machines#
    switch ($role)
        {
        "primary"
            {
            clone-node -Nodename $Nodeprefix
            }

        "sitecache"
            {    
            foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
                {
                clone-node -Nodename $Nodeprefix$node
                }#end foreach
            }
        }
    Write-Host "Login to geonas with admin / password"
    } # end default


}# end switch