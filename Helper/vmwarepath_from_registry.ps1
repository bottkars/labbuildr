$vmware = "d:\Program Files (x86)\VMware\VMware Workstation\vmware.exe"
Test-Path $vmware
if (!(Test-Path $vmware)){
if (!(Test-Path "HKCR:\")) {New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT}
$VMWAREpath = Get-ItemProperty HKCR:\Applications\vmware.exe\shell\open\command
$VMWAREpath = Split-Path $VMWAREpath.'(default)' -Parent
$VMWAREpath = $VMWAREpath -replace '"',''
$VMWAREpath
$vmware = "$VMWAREpath\vmware.exe"
$vmrun = "$VMWAREpath\vmrun.exe"

}

Test-Path HKCR:\


$vmwareversion = (Get-ChildItem  $vmware).VersionInfo.Productversion