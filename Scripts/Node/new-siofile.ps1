[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param( [string]$Path,[double]$Size )
$SIOfile = [System.IO.File]::Create($Path)
$SIOfile.SetLength($Size)
$SIOfile.Close()
Get-Item $file.Name