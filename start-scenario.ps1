[CmdletBinding(DefaultParametersetName = "1")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA')]$Scenario
	
	)
begin
	{
	}
process
	{
	get-vmx | where scenario -match $Scenario | sort-object ActivationPreference | start-vmx
	}
end { }
