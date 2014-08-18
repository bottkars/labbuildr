<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
[CmdletBinding(DefaultParametersetName="mount")] 
Param
(
[Parameter(ParameterSetName="Mount")][switch]$mount,
[Parameter(ParameterSetName="UnMount")][switch]$unmount,

[Parameter(ParameterSetName="Mount",Mandatory=$false)]
[Parameter(ParameterSetName="UnMount",Mandatory=$false)]
[ValidateScript({Test-Path -Path $_ -PathType Leaf -Include "sources.vhd"})]
$Sourcevhd= ".\sources.vhd",

[Parameter(ParameterSetName="Mount",Mandatory=$false)]
[Parameter(ParameterSetName="UnMount",Mandatory=$false)]
$Mountdir="sources",

[Parameter(ParameterSetName="Mount",Mandatory=$false)]
[Parameter(ParameterSetName="UnMount",Mandatory=$false)]
$Driveletter="c")


if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{ Write-Host -ForegroundColor Yellow "Sorry we need to run this as Admin !!!"
break}

######### getting full name of $sourcevhd
$Sourcevhd = (Get-Item $Sourcevhd).FullName

$Builddir = $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "Networker2GO Mounter V2 - win 7 Edition"

$diskpart = @()
$diskpartfile = New-Item -ItemType file "$Builddir\diskpart.txt" -Force
$diskpart += "SELECT VDISK FILE=$sourcevhd"
$diskpart += "DETACH VDISK"
$diskpart | Set-Content $diskpartfile
$DiskpartDone = DiskPart /s $Builddir\diskpart.txt



switch ($PsCmdlet.ParameterSetName){
"mount" {
$location = $Driveletter+":\"
Push-Location
Set-Location $location
mountvol /N
mountvol /R
New-Item -ItemType Directory (Join-Path $location $Mountdir) -Force
$Volbefore = mountvol
$diskpart = @()
$diskpartfile = New-Item -ItemType file "$Builddir\diskpart.txt" -Force
$diskpart += "SELECT VDISK FILE=$sourcevhd"
$diskpart += "ATTACH VDISK"
$diskpart | Set-Content $diskpartfile
DiskPart /s $Builddir\diskpart.txt
$volafter = mountvol
$diffdisks = Compare-Object $Volbefore $volafter
$diffdisk = $diffdisks | where inputobject -match "\\Volume"
$diffdisk = $diffdisk.InputObject.Trim()
$diffdisk = $diffdisk.TrimEnd()
$diffdisk
mountvol $Mountdir $diffdisk
Pop-Location
}

"unmount"
{$DiskpartDone}
}