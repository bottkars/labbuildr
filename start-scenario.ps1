[CmdletBinding(DefaultParametersetName = "1")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA','hyper-V','ScaleIO','ESXi','labbuildr')]$Scenario
	
	)
begin
	{
    if ((get-vmx .\DCNODE).state -ne "running")
        {get-vmx .\DCNODE | start-vmx}
	}
process
	{
	get-vmx | where scenario -match $Scenario | sort-object ActivationPreference | start-vmx
	}
end { }
