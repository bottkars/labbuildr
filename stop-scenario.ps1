[CmdletBinding(DefaultParametersetName = "1")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA','hyper-V','ScaleIO','ESXi','labbuildr')]$Scenario,
    [switch]$dc
	)
begin
	{
	}
process
	{
	get-vmx | where {$_.scenario -match $Scenario -and $_.vmxname -ne "dcnode"} | sort-object ActivationPreference -Descending | stop-vmx
    if ($dc.IsPresent)
        {
        get-vmx .\dcnode | stop-vmx
        }
	}
end {}
