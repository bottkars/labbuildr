





<#	
	.SYNOPSIS
	Get-VMXProcessesInGuest
	
	.DESCRIPTION
		Displays version Information on installed VMware version
	
	.EXAMPLE
#>

function Set-labDefaultGateway
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$DefaultGateway
    )
$Defaults = get-labdefaults -Defaultsfile $Defaultsfile
$Defaults.DefaultGateway = $DefaultGateway
Write-Verbose "Setting Default Gateway $Gateway"
save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labGateway
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 2)][switch]$Gateway
    )
$Defaults = get-labdefaults -Defaultsfile $Defaultsfile
$Defaults.DefaultGateway = $Gateway.IsPresent
Write-Verbose "Setting $Gateway"
save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labsubnet
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 2)][system.net.ipaddress]$subnet
    )
$Defaults = get-labdefaults -Defaultsfile $Defaultsfile
$Defaults.Mysubnet = $subnet
Write-Verbose "Setting subnet $subnet"
save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labBuilddomain
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [ValidateLength(3,10)]
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 2)]
    [ValidatePattern("^[a-zA-Z\s]+$")][string]$builddomain
    )
$Defaults = get-labdefaults -Defaultsfile $Defaultsfile
$Defaults.builddomain = $builddomain
Write-Verbose "Setting builddomain $builddomain"
save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Get-labDefaults
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
    )
begin {
    }
process {
        Write-Verbose "Loading defaults from $Defaultsfile"
        [xml]$Default = Get-Content -Path $Defaultsfile
        $object = New-Object psobject
	    $object | Add-Member -MemberType NoteProperty -Name Master -Value $Default.config.master
        $object | Add-Member -MemberType NoteProperty -Name ScaleIOVer -Value $Default.config.scaleiover
        $object | Add-Member -MemberType NoteProperty -Name BuildDomain -Value $Default.config.Builddomain
        $object | Add-Member -MemberType NoteProperty -Name MySubnet -Value ([system.net.ipaddress]$Default.config.MySubnet)
        $object | Add-Member -MemberType NoteProperty -Name vmnet -Value $Default.config.vmnet
        $object | Add-Member -MemberType NoteProperty -Name DefaultGateway -Value $Default.config.DefaultGateway
        $object | Add-Member -MemberType NoteProperty -Name Gateway -Value $Default.config.Gateway
        $object | Add-Member -MemberType NoteProperty -Name AddressFamily -Value $Default.config.AddressFamily
        $object | Add-Member -MemberType NoteProperty -Name IPV6Prefix -Value $Default.Config.IPV6Prefix
        $object | Add-Member -MemberType NoteProperty -Name IPv6PrefixLength -Value $Default.Config.IPV6PrefixLength
        $object | Add-Member -MemberType NoteProperty -Name Sourcedir -Value $Default.Config.Sourcedir
        $object | Add-Member -MemberType NoteProperty -Name SQLVer -Value $Default.config.sqlver
        $object | Add-Member -MemberType NoteProperty -Name ex_cu -Value $Default.config.ex_cu
        $object | Add-Member -MemberType NoteProperty -Name NMM_Ver -Value $Default.config.nmm_ver
        $object | Add-Member -MemberType NoteProperty -Name NW_Ver -Value $Default.config.nw_ver
        Write-Output $object
        }

end {
    }
}


<#
function set-labdefaults
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
    )
begin {
    }
process {
        Write-Verbose "Loading defaults from $Defaultsfile"
        [xml]$Default = Get-Content -Path $Defaultsfile
        $object = New-Object psobject
#>

function save-labdefaults
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true)]$Defaults

    )
begin {
    }
process {
        Write-Verbose "Saving defaults to $Defaultsfile"
        $xmlcontent =@()
        $xmlcontent += ("<config>")
        $xmlcontent += ("<nmm_ver>$($Defaults.nmm_ver)</nmm_ver>")
        $xmlcontent += ("<nw_ver>$($Defaults.nw_ver)</nw_ver>")
        $xmlcontent += ("<master>$($Defaults.Master)</master>")
        $xmlcontent += ("<sqlver>$($Defaults.SQLVER)</sqlver>")
        $xmlcontent += ("<ex_cu>$($Defaults.ex_cu)</ex_cu>")
        $xmlcontent += ("<vmnet>$($Defaults.VMnet)</vmnet>")
        $xmlcontent += ("<BuildDomain>$($Defaults.BuildDomain)</BuildDomain>")
        $xmlcontent += ("<MySubnet>$($Defaults.MySubnet)</MySubnet>")
        $xmlcontent += ("<AddressFamily>$($Defaults.AddressFamily)</AddressFamily>")
        $xmlcontent += ("<IPV6Prefix>$($Defaults.IPV6Prefix)</IPV6Prefix>")
        $xmlcontent += ("<IPv6PrefixLength>$($Defaults.IPv6PrefixLength)</IPv6PrefixLength>")
        $xmlcontent += ("<Gateway>$($Defaults.Gateway)</Gateway>")
        $xmlcontent += ("<DefaultGateway>$($Defaults.DefaultGateway)</DefaultGateway>")
        $xmlcontent += ("<Sourcedir>$($Defaults.Sourcedir)</Sourcedir>")
        $xmlcontent += ("<ScaleIOVer>$($Defaults.ScaleIOVer)</ScaleIOVer>")
        $xmlcontent += ("</config>")
        $xmlcontent | Set-Content $defaultsfile
        }

end {}
}

function Get-LABFTPFile
{ 
[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
Param(
    [Parameter(ParameterSetName = "1", Mandatory = $true)]$Source,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$Target,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$UserName = "Anonymous",
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$Password = "Admin@labbuildr.local"
) 


if (!$Target)
    {
    $Target = Split-Path -Leaf $Source 
    }
# Create a FTPWebRequest object to handle the connection to the ftp server 
$ftprequest = [System.Net.FtpWebRequest]::create($Source) 
 
# set the request's network credentials for an authenticated connection 
$ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password) 
 
$ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
$ftprequest.UseBinary = $true 
$ftprequest.KeepAlive = $false 
 
# send the ftp request to the server 
$ftpresponse = $ftprequest.GetResponse() 
Write-Verbose $ftpresponse.WelcomeMessage
Write-Verbose "Filesize: $($ftpresponse.ContentLength/1MB) MB"
 
# get a download stream from the server response 
$responsestream = $ftpresponse.GetResponseStream() 
 
# create the target file on the local system and the download buffer 
$targetfile = New-Object IO.FileStream ($Target,[IO.FileMode]::Create) 
[byte[]]$readbuffer = New-Object byte[] 1024 
Write-Verbose "Downloading $Source via ftp" 
# loop through the download stream and send the data to the target file 
$I = 1
do{ 
    $readlength = $responsestream.Read($readbuffer,0,1024) 
    $targetfile.Write($readbuffer,0,$readlength)
    if ($I -eq 1024)
        {
        Write-Host '#' -NoNewline 
        $I = 0
        }
    $I++
} 
while ($readlength -ne 0) 
 
$targetfile.close()
Write-Host 
} 