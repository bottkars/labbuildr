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
function Get-labyesnoabort
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
Param
    (
    $title = "Delete Files",
    $message = "Do you want to delete the remaining files in the folder?",
    $Yestext = "Yes",
    $Notext = "No",
    $AbortText = "Abort"
    )
$yes = New-Object System.Management.Automation.Host.ChoiceDescription ("&Yes","$Yestext")
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","$Notext"
$abort = New-Object System.Management.Automation.Host.ChoiceDescription "&Abort","$Aborttext"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $Abort )
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
return ($result)
}

function Set-labDefaultGateway
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$DefaultGateway
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.DefaultGateway = $DefaultGateway
    Write-Verbose "Setting Default Gateway $DefaultGateway"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}


function Set-labDNS1
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$DNS1
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.DNS1 = $DNS1
    Write-Verbose "Setting DNS1 $DNS1"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labVMNET
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.vmnet = $VMnet
    Write-Verbose "Setting LABVMnet $VMnet"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labGateway
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][switch]$Gateway
    )
if (!(Test-Path $Defaultsfile))
    {
    Write-Warning "Creating new defaultsfile"
    new-labdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.Gateway = $Gateway.IsPresent
    Write-Verbose "Setting $Gateway"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labNMM
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 2)][switch]$NMM
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.NMM = $NMM.IsPresent
    Write-Verbose "Setting NMM to $($NMM.IsPresent)"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labsubnet
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$subnet
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.Mysubnet = $subnet
    Write-Verbose "Setting subnet $subnet"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-labBuilddomain
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [ValidateLength(1,15)]
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)]
    [ValidatePattern("^[a-zA-Z\s]+$")][string]$builddomain
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.builddomain = $builddomain
    Write-Verbose "Setting builddomain $builddomain"
    save-labdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}


function Set-labSources
{
	[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [ValidateLength(3,10)]
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Sourcedir
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating new defaultsfile"
        new-labdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = get-labdefaults -Defaultsfile $Defaultsfile
    $Defaults.sourcedir = $Sourcedir
    Write-Verbose "Setting builddomain $Sourcedir"
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
process 
{
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Defaults does not exist. please create with new-labdefaults or set any parameter with set-labxxx"
    }
    else
        {

        Write-Verbose "Loading defaults from $Defaultsfile"
        [xml]$Default = Get-Content -Path $Defaultsfile
        $object = New-Object psobject
	    $object | Add-Member -MemberType NoteProperty -Name Master -Value $Default.config.master
        $object | Add-Member -MemberType NoteProperty -Name ScaleIOVer -Value $Default.config.scaleiover
        $object | Add-Member -MemberType NoteProperty -Name BuildDomain -Value $Default.config.Builddomain
        $object | Add-Member -MemberType NoteProperty -Name MySubnet -Value $Default.config.MySubnet
        $object | Add-Member -MemberType NoteProperty -Name vmnet -Value $Default.config.vmnet
        $object | Add-Member -MemberType NoteProperty -Name DefaultGateway -Value $Default.config.DefaultGateway
        $object | Add-Member -MemberType NoteProperty -Name DNS1 -Value $Default.config.DNS1
        $object | Add-Member -MemberType NoteProperty -Name Gateway -Value $Default.config.Gateway
        $object | Add-Member -MemberType NoteProperty -Name AddressFamily -Value $Default.config.AddressFamily
        $object | Add-Member -MemberType NoteProperty -Name IPV6Prefix -Value $Default.Config.IPV6Prefix
        $object | Add-Member -MemberType NoteProperty -Name IPv6PrefixLength -Value $Default.Config.IPV6PrefixLength
        $object | Add-Member -MemberType NoteProperty -Name Sourcedir -Value $Default.Config.Sourcedir
        $object | Add-Member -MemberType NoteProperty -Name SQLVer -Value $Default.config.sqlver
        $object | Add-Member -MemberType NoteProperty -Name ex_cu -Value $Default.config.ex_cu
        $object | Add-Member -MemberType NoteProperty -Name NMM_Ver -Value $Default.config.nmm_ver
        $object | Add-Member -MemberType NoteProperty -Name NW_Ver -Value $Default.config.nw_ver
        $object | Add-Member -MemberType NoteProperty -Name NMM -Value $Default.config.nmm
        $object | Add-Member -MemberType NoteProperty -Name Masterpath -Value $Default.config.Masterpath

        Write-Output $object
        }
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
        $xmlcontent += ("<nmm>$($Defaults.nmm)</nmm>")
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
        $xmlcontent += ("<DNS1>$($Defaults.DNS1)</DNS1>")
        $xmlcontent += ("<Sourcedir>$($Defaults.Sourcedir)</Sourcedir>")
        $xmlcontent += ("<ScaleIOVer>$($Defaults.ScaleIOVer)</ScaleIOVer>")
        $xmlcontent += ("<Masterpath>$($Masterpath)</Masterpath>")
        $xmlcontent += ("</config>")
        $xmlcontent | Set-Content $defaultsfile
        }
end {}
}


function Expand-LABZip
{
	param ([string]$zipfilename, [string] $destination)
	$copyFlag = 16 # overwrite = yes
	$Origin = $MyInvocation.MyCommand
	if (test-path($zipfilename))
	{		
        Write-Verbose "extracting $zipfilename"
        if (!(test-path  $destination))
            {
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            }
        $shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(), $copyFlag)
	}
}

function Get-LABFTPFile
{ 
[CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
Param(
    [Parameter(ParameterSetName = "1", Mandatory = $true)]$Source,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$Target,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$UserName = "Anonymous",
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$Password = "Admin@labbuildr.local",
    [Parameter(ParameterSetName = "1", Mandatory = $false)][switch]$Defaultcredentials
) 
if (!$Target)
    {
    $Target = Split-Path -Leaf $Source 
    }
# Create a FTPWebRequest object to handle the connection to the ftp server 
$ftprequest = [System.Net.FtpWebRequest]::create($Source) 
 
# set the request's network credentials for an authenticated connection 
if ($Defaultcredentials.Ispresent)
    {
    $ftprequest.UseDefaultCredentials 
    }
else
    {
    $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)
    }     

$ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
$ftprequest.UseBinary = $true 
$ftprequest.KeepAlive = $false 
 
# send the ftp request to the server 
$ftpresponse = $ftprequest.GetResponse() 
Write-Verbose $ftpresponse.WelcomeMessage
Write-Verbose "Filesize: $($ftpresponse.ContentLength)"
 
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
return $true
}

function enable-labfolders
    {
    get-vmx | where state -match running  | Set-VMXSharedFolderState -enabled
    }

function get-labscenario
    {
    Get-VMX | get-vmxscenario | Sort-Object Scenarioname | ft -AutoSize
    }


function new-labdefaults   
{
    [CmdletBinding(HelpUri = "http://labbuildr.bottnet.de/modules/")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)]$Defaultsfile=".\defaults.xml"
    )
        Write-Verbose "Saving defaults to $Defaultsfile"
        $xmlcontent =@()
        $xmlcontent += ("<config>")
        $xmlcontent += ("<nmm_ver></nmm_ver>")
        $xmlcontent += ("<nmm></nmm>")
        $xmlcontent += ("<nw_ver></nw_ver>")
        $xmlcontent += ("<master></master>")
        $xmlcontent += ("<sqlver></sqlver>")
        $xmlcontent += ("<ex_cu></ex_cu>")
        $xmlcontent += ("<vmnet></vmnet>")
        $xmlcontent += ("<BuildDomain></BuildDomain>")
        $xmlcontent += ("<MySubnet></MySubnet>")
        $xmlcontent += ("<AddressFamily></AddressFamily>")
        $xmlcontent += ("<IPV6Prefix></IPV6Prefix>")
        $xmlcontent += ("<IPv6PrefixLength></IPv6PrefixLength>")
        $xmlcontent += ("<Gateway></Gateway>")
        $xmlcontent += ("<DefaultGateway></DefaultGateway>")
        $xmlcontent += ("<DNS1></DNS1>")
        $xmlcontent += ("<Sourcedir></Sourcedir>")
        $xmlcontent += ("<ScaleIOVer></ScaleIOVer>")
        $xmlcontent += ("<Masterpath></Masterpath>")
        $xmlcontent += ("</config>")
        $xmlcontent | Set-Content $defaultsfile
     }

