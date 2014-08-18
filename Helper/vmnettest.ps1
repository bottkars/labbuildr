
Param(
[Parameter(Mandatory=$false,HelpMessage="Enter a valid VMware network Number vmnet between 1 and 19 ")]
[ValidateRange(2,19)]$VMnet = 2)
write-host $VMnet

