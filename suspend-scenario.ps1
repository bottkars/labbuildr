[CmdletBinding(DefaultParametersetName = "1")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA','hyper-V','ScaleIO','ESXi','labbuildr','isinode')]$Scenario,
    [switch]$dc
	)
begin
	{
	}
process
	{
	get-vmx | where {$_.scenario -match $Scenario -and $_.vmxname -ne "dcnode"} | sort-object ActivationPreference -Descending | suspend-vmx
    if ($dc.IsPresent)
        {
        get-vmx .\dcnode | suspend-vmx
        }
	}
end {}
