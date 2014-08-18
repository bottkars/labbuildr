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

Param
($source="sources",
[Parameter(Mandatory=$true)]$Sourcevhd,
$Driveletter="c")
$Builddir = $PSScriptRoot
# $vhdtype = ".vhd"
$Host.UI.RawUI.WindowTitle = "Networker2GO Mounter V2"

mountvol /N
mountvol /R

$Drive = $Driveletter.ToUpper()+":"
### testing Mountdrive is of supported type
$StorageVolume = Get-CimInstance CIM_StorageVolume | where DriveLetter -eq $Drive
if ($StorageVolume.DriveType -eq 3)
{
$Mountroot = $StorageVolume.Caption
$MountDiskNumber = $StorageVolume.Number


#foreach ($Source in $Sources)
#{
$AccessPath = "$Drive\$Source\"
#### test if already mounted 
if ($StorageVolume = Get-CimInstance CIM_StorageVolume | where Caption  -eq $AccessPath)
{
write-host "$Source Already Mounted in $AccessPath, nothing to do here !"
}

else{
## Check for Directory Exists
if (!(test-path $AccessPath)){
New-Item -Path $AccessPath -ItemType Directory }
$vhd = Get-Diskimage "$Sourcevhd"
if (!$vhd.Attached) #only Mount if not already Attached
{
Mount-DiskImage -ImagePath $vhd.imagepath -NoDriveLetter
}
Get-Disk
$Diskimage = Get-DiskImage -ImagePath $vhd.imagepath
$Diskimage.Number
Add-PartitionAccessPath -DiskNumber $Diskimage.Number -PartitionNumber 2  -AccessPath $Mountroot\$source -WarningAction SilentlyContinue -ErrorAction SilentlyContinue # we add the desired Mountpath, even if it is mounted elsewhere
}
}
#}
else
{
write-host  "$Driveletter not on Supported Drive Type"
write-host  "Only fixed Drives are Supported as Mountdrives, USB Drives are excluded"
return $return
break
}