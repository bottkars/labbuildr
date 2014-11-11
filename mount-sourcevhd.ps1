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

$Driver = driverquery | where {$_ -match "vhdmp"}

if ((Get-Service vhdmp).Status -eq "Stopped")
    { Write-Host -ForegroundColor Red " The Command may fail up to 2 times since HD Drivers needs to be installed during plug and Play"
    $waitfordriverevent = $true
    
    }





######### getting full name of $sourcevhd
$Sourcevhd = (Get-Item $Sourcevhd).FullName

$Builddir = $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "labbuildr - Win 7 Edition"

$diskpart = @()
$diskpartfile = New-Item -ItemType file "$Builddir\diskpart.txt" -Force
$diskpart += "SELECT VDISK FILE=$sourcevhd"
$diskpart += "DETACH VDISK"
$diskpart | Set-Content $diskpartfile

$DiskpartDone = DiskPart /s $Builddir\diskpart.txt
$DiskpartDone
write-verbose "UnMount succeeded with $LASTEXITCODE"

if ($waitfordriverevent)
    {
     Write-Verbose "We are waiting for VHD HBA Driver to be Installed"
     do
       {
        write-host "." -NoNewline
       }
     until (Get-EventLog -LogName System -Newest 5 | where EventID -Match 20003)
write-host
}

"rescan" | diskpart



switch ($PsCmdlet.ParameterSetName){
"mount" {
$location = $Driveletter+":\"
Push-Location
Set-Location $location
mountvol /N
mountvol /R
# "rescan" | diskpart
New-Item -ItemType Directory (Join-Path $location $Mountdir) -Force
$Volbefore = mountvol
$diskpart = @()
$diskpartfile = New-Item -ItemType file "$Builddir\diskpart.txt" -Force
$diskpart += "SELECT VDISK FILE=$sourcevhd"
$diskpart += "ATTACH VDISK"
$diskpart | Set-Content $diskpartfile
write-verbose "Trying mount"
DiskPart /s $Builddir\diskpart.txt
write-verbose "Mount succeeded with $LASTEXITCODE"
if ($waitfordriverevent)
    {
     Write-Verbose "We are waiting for VHD Volume Driver to be Installed"
     do
       {
        write-host "." -NoNewline
       }
        Until ((Get-EventLog -LogName System -Newest 30 | where Message -Match "Driver Management concluded the process to install driver FileRepository\\volume.inf").count -ge 2)
     }


 
write-host
mountvol | Out-Null

$volafter = mountvol



$diffdisks = Compare-Object $Volbefore $volafter
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-host
    Write-host -ForegroundColor Magenta "mountvol difference file:"
    $diffdisks
    }

$diffdisk = $diffdisks | where inputobject -match "\\Volume"
$diffdisk = $diffdisk.InputObject.Trim()
$diffdisk = $diffdisk.TrimEnd()

Write-Verbose "we have volume $diffdisk to mount"
Write-Output "Mounting volume $diffdisk"
mountvol $Mountdir $diffdisk
Pop-Location
}

"unmount"
{
$DiskpartDone
}
}