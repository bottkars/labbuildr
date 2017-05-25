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
   http://labbuildr.readthedocs.io/en/master/Solutionpacks///install-cloudarray.ps1
.EXAMPLE
.\install-cloudarray.ps1 -ovf C:\Users\bottk\Downloads\CloudArray_ESXi5_7.0.6.0.8713\CloudArray_ESXi5_7.0.
6.0.8713.ovf
This will convert Cloudarray ESX Template
.EXAMPLE
.\install-cloudarray.ps1 -Defaults -MasterPath [you masterpath]\CloudArray_ESXi5_7.0.6.0.8713\ -Cachevols 3 -Cachevolsize 146GB
This will Install default Cloud Array
#>
[CmdletBinding()]
Param(
### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -Filter *.ov* -PathType Leaf})]$ovf,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername,
### install param
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateRange(1,3)][int32]$Cachevols = 1,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet(36GB,72GB,146GB)][uint64]$Cachevolsize = 146GB,

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath = ".\CloudArraymaster",

[Parameter(ParameterSetName = "defaults", Mandatory = $true)][switch]$Defaults,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes=1,

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,

[Parameter(ParameterSetName = "defaults", Mandatory = $false)]
[Parameter(ParameterSetName = "install",Mandatory=$false)][switch]$dedupe,

[Parameter(ParameterSetName = "install", Mandatory = $true)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet = "vmnet2"

)
#requires -version 3.0
#requires -module vmxtoolkit
$Builddir = $PSScriptRoot
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
			Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying $Builddir"
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
			### if already exist !?!?!?
            Write-Host -ForegroundColor Gray " ==>Extraxting from OVA Package $Importfile"
            $Expand = Expand-LABpackage -Archive $Importfile.FullName -destination $OVA_Destination -Force
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
            Write-Host -ForegroundColor Gray " ==>Importing Base VM"
            if ((import-VMXOVATemplate -OVA $Importfile.FullName -Name $mastername -destination $MasterPath  -acceptAllEulas).success -eq $true)
                {
                Write-Host -ForegroundColor Gray " ==>preparation of template done, please run " -NoNewline
				write-host -ForegroundColor White ".\$($MyInvocation.MyCommand) -MasterPath $MasterPath\$mastername -Defaults"
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
            $vmnet = $labdefaults.vmnet
            $subnet = $labdefaults.MySubnet
            $BuildDomain = $labdefaults.BuildDomain
            $Sourcedir = $labdefaults.Sourcedir
            $Gateway = $labdefaults.Gateway
            $DefaultGateway = $labdefaults.Defaultgateway
            $DNS1 = $labdefaults.DNS1
            $configure = $true
            }
    $Nodeprefix = "Cloudarray"
    If (!($MasterVMX = get-vmx -path $MasterPath -WarningAction SilentlyContinue))
      {
       Write-Error "No Valid Master Found"
      break
     }

    $Basesnap = $MasterVMX | Get-VMXSnapshot -WarningAction SilentlyContinue| where Snapshot -Match "Base"
    if (!$Basesnap)
        {
        Write-Host -ForegroundColor Gray " ==>Tweaking VMX File"
        $Config = Get-VMXConfig -config $MasterVMX.Config
        $Config = $Config -notmatch 'snapshot.maxSnapshots'
        $Config | set-Content -Path $MasterVMX.Config

        Write-Host -ForegroundColor Gray " ==>Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        if (!$MasterVMX.Template)
            {
            Write-Host -ForegroundColor Gray " ==>Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }
        } #end basesnap
####Build Machines#

    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        Write-Host -ForegroundColor Gray " ==>Checking VM $Nodeprefix$node already Exists"
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
            {
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node -Clonepath $Builddir
            Write-Host -ForegroundColor Gray " ==>Creating Disks"
            $SCSI = 0
            foreach ($LUN in (2..(1+$Cachevols)))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Cachevolsize.vmdk"
                $Newdisk = New-VMXScsiDisk -NewDiskSize $Cachevolsize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config -WarningAction SilentlyContinue | Out-Null
            $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6  | Out-Null
            $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node  | Out-Null
            Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain"  | Out-Null
            if ($dedupe)
                {
                Write-Host -ForegroundColor Gray " ==>Aligning Memory and cache for DeDupe"
                $NodeClone | Set-VMXmemory -MemoryMB 9216 | Out-Null
                $NodeClone | Set-VMXprocessor -Processorcount 4 | Out-Null
                }
            start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName  | Out-Null
            } # end check vm
        else
            {
            Write-Warning "VM $Nodeprefix$node already exists"
            }
        }#end foreach
    Write-Host -ForegroundColor White " ==>Login to Cloudarray with admin / password"
    } # end default
}# end switch