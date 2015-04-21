[CmdletBinding()]
Param(
### import parameters
[Parameter(ParameterSetName = "import",Mandatory=$true)][String]
[ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$ovapaPath,
[Parameter(ParameterSetName = "import",Mandatory=$false)][String]$mastername = "CloudArraymaster",
### install param
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Nodes =1,
[Parameter(ParameterSetName = "install",Mandatory=$false)][int32]$Startnode = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateRange(1,3)][int32]$Cachevols = 1,
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('36GB','72GB','146GB')][string]$Cachevolsize = "146GB",
[Parameter(ParameterSetName = "install",Mandatory=$false)]$Subnet = "192.168.2",
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateLength(3,10)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain = "labbuildr",
[Parameter(ParameterSetName = "install",Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$MasterPath,
[Parameter(ParameterSetName = "install",Mandatory=$false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2"
)
#requires -version 3.0
#requires -module vmxtoolkit 
switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        & $global:vmwarepath\OVFTool\ovftool.exe --lax --skipManifestCheck  --name=$mastername $ovapaPath $PSScriptRoot #
        $Content = Get-Content $PSScriptRoot\$mastername\$mastername.vmx
        $Content = $Content-notmatch 'snapshot.maxSnapshots'
        $Content | Set-Content $PSScriptRoot\$mastername\$mastername.vmx 
        }
default
    {
    $Nodeprefix = "Cloudarray"
    If (!($MasterVMX = get-vmx -path $MasterPath))
      {
       Write-Error "No Valid Master Found"
      break
     }
    $Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
    if (!$Basesnap) 
        {

        Write-Verbose "Tweaking VMX File"
        $Config = Get-VMXConfig -config $MasterVMX.Config
        $Config = $Config -notmatch 'snapshot.maxSnapshots'
        $Config | set-Content -Path $MasterVMX.Config


        Write-verbose "Base snap does not exist, creating now"
        $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
        if (!$MasterVMX.Template) 
            {
            write-verbose "Templating Master VMX"
            $template = $MasterVMX | Set-VMXTemplate
            }

        } #end basesnap
####Build Machines#

    foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
        {
        Write-Verbose "Checking VM $Nodeprefix$node already Exists"
        If (!(get-vmx $Nodeprefix$node))
            {
            write-verbose "Creating clone $Nodeprefix$node"
            $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
            Write-Verbose "Creating Disks"
            $SCSI = 0
            foreach ($LUN in (1..$Cachevols))
                {
                $Diskname =  "SCSI$SCSI"+"_LUN$LUN"+"_$Cachevolsize.vmdk"
                Write-Verbose "Building new Disk $Diskname"
                $Newdisk = New-VMXScsiDisk -NewDiskSize $Cachevolsize -NewDiskname $Diskname -Verbose -VMXName $NodeClone.VMXname -Path $NodeClone.Path 
                Write-Verbose "Adding Disk $Diskname to $($NodeClone.VMXname)"
                $AddDisk = $NodeClone | Add-VMXScsiDisk -Diskname $Newdisk.Diskname -LUN $LUN -Controller $SCSI
                }
            Write-Verbose "Setting ext-0"
            Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config
            Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config 
            $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname $Nodeprefix -Scenario 6
            $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
            # Set-VMXVnet -Adapter 0 -vnet vmnet2
            write-verbose "Setting Display Name $($NodeClone.CloneName)@$Builddomain"
            Set-VMXDisplayName -config $NodeClone.Config -Displayname "$($NodeClone.CloneName)@$Builddomain" 
            Write-Verbose "Starting $Nodeprefix$node"
            start-vmx -Path $NodeClone.config -VMXName $NodeClone.CloneName
            } # end check vm
        else
            {
            Write-Verbose "VM $Nodeprefix$node already exists"
            }
        }#end foreach
    } # end default
}# end switch


write-Warning "Login to Cloudarray with admin / password"

