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
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-LAByesnoabort
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Get-LAByesnoabort",
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

function Set-LABDefaultGateway
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABDefaultGateway")]
	param (    
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$DefaultGateway,
    [Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.DefaultGateway = $DefaultGateway
    Write-Verbose "Setting Default Gateway $DefaultGateway"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}



function Set-LABDNS1
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#SET-LABDNS1")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$DNS1
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.DNS1 = $DNS1
    Write-Verbose "Setting DNS1 $DNS1"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABvmnet
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABvmnet")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false )][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.vmnet = $VMnet
    Write-Verbose "Setting LABVMnet $VMnet"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABGateway
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABGateway")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][switch]$enabled
    )
if (!(Test-Path $Defaultsfile))
    {
    Write-Warning "Creating New defaultsfile"
    New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.Gateway = $enabled.IsPresent
    Write-Verbose "Setting $Gateway"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABNoDomainCheck
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABNoDomainCheck")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][switch]$enabled
    )
if (!(Test-Path $Defaultsfile))
    {
    Write-Warning "Creating New defaultsfile"
    New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.NoDomainCheck = $enabled.IsPresent
    Write-Verbose "Setting $NoDomainCheck"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}


function Set-LABpuppet
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABpuppet")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][switch]$enabled
    )
if (!(Test-Path $Defaultsfile))
    {
    Write-Warning "Creating New defaultsfile"
    New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.puppet = $enabled.IsPresent
    Write-Verbose "Setting $puppet"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABPuppetMaster
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABpuppetMaster")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateSet('puppetlabs-release-7-11', 'PuppetEnterprise')]$PuppetMaster = "PuppetEnterprise"
    )
if (!(Test-Path $Defaultsfile))
    {
    Write-Warning "Creating New defaultsfile"
    New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.puppetmaster = $PuppetMaster
    Write-Verbose "Setting $puppetMaster"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}



function Set-LABnmm
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABnmm")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][switch]$NMM
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }

    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.NMM = $NMM.IsPresent
    Write-Verbose "Setting NMM to $($NMM.IsPresent)"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABsubnet
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABsubnet")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][system.net.ipaddress]$subnet
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.Mysubnet = $subnet
    Write-Verbose "Setting subnet $subnet"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}


function Set-LABHostKey
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABHostKey")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 2)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)]$HostKey
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.HostKey = $HostKey
    Write-Verbose "Setting HostKey $HostKey"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Set-LABBuilddomain
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABBuilddomain")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain
    )
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.builddomain = $builddomain
    Write-Verbose "Setting builddomain $builddomain"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}


function Set-LABSources
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Set-LABSources")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml",
    [ValidateLength(3,10)]
    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateScript({ 
    try
        {
        Get-Item -Path $_ -ErrorAction Stop | Out-Null 
        }
        catch
        [System.Management.Automation.DriveNotFoundException] 
        {
        Write-Warning "Drive not found, make sure to have your Source Stick connected"
        exit
        }
        catch #[System.Management.Automation.ItemNotFoundException]
        {
        write-warning "no sources directory found"
        exit
        }
        return $True
        })]$Sourcedir
    
#Test-Path -Path $_ })]$Sourcedir
    )   
    if (!(Test-Path $Sourcedir)){exit} 

    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Creating New defaultsfile"
        New-LABdefaults -Defaultsfile $Defaultsfile
    }
    $Defaults = Get-LABdefaults -Defaultsfile $Defaultsfile
    $Defaults.sourcedir = $Sourcedir
    Write-Verbose "Setting Sourcedir $Sourcedir"
    Save-LABdefaults -Defaultsfile $Defaultsfile -Defaults $Defaults
}

function Get-LABDefaults
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Get-LABDefaults")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
    )
begin {
    }
process 
{
    if (!(Test-Path $Defaultsfile))
    {
        Write-Warning "Defaults does not exist. please create with New-LABdefaults or set any parameter with set-LABxxx"
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
        $object | Add-Member -MemberType NoteProperty -Name e16_cu -Value $Default.config.e16_cu
        $object | Add-Member -MemberType NoteProperty -Name NMM_Ver -Value $Default.config.nmm_ver
        $object | Add-Member -MemberType NoteProperty -Name NW_Ver -Value $Default.config.nw_ver
        $object | Add-Member -MemberType NoteProperty -Name NMM -Value $Default.config.nmm
        $object | Add-Member -MemberType NoteProperty -Name Masterpath -Value $Default.config.Masterpath
        $object | Add-Member -MemberType NoteProperty -Name NoDomainCheck -Value $Default.config.NoDomainCheck
        $object | Add-Member -MemberType NoteProperty -Name Puppet -Value $Default.config.Puppet
        $object | Add-Member -MemberType NoteProperty -Name PuppetMaster -Value $Default.config.PuppetMaster
        $object | Add-Member -MemberType NoteProperty -Name HostKey -Value $Default.config.Hostkey

        Write-Output $object
        }
    }
end {
    }
}


<#
function set-LABdefaults
{
	[CmdletBinding(HelpUri = "http://LABbuildr.bottnet.de/modules/")]
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

function Save-LABdefaults
{
	[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Save-LABDefaults")]
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
        $xmlcontent += ("<e16_cu>$($Defaults.e16_cu)</e16_cu>")
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
        $xmlcontent += ("<Masterpath>$($Defaults.Masterpath)</Masterpath>")
        $xmlcontent += ("<NoDomainCheck>$($Defaults.NoDomainCheck)</NoDomainCheck>")
        $xmlcontent += ("<Puppet>$($Defaults.Puppet)</Puppet>")
        $xmlcontent += ("<PuppetMaster>$($Defaults.PuppetMaster)</PuppetMaster>")
        $xmlcontent += ("<Hostkey>$($Defaults.HostKey)</Hostkey>")
        $xmlcontent += ("</config>")
        $xmlcontent | Set-Content $defaultsfile
        }
end {}
}




function Expand-LAB7Zip
{
 [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
    HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Expand-LABZip")]
	param (
        [string]$Archive,
        [string]$destination=$vmxdir
        #[String]$Folder
        )
	$Origin = $MyInvocation.MyCommand
	if (test-path($Archive))
	{
 #   If ($Folder)
 #      {
 #     $zipfilename = Join-Path $zipfilename $Folder
 #    }
    	$7za = "$vmwarepath\7za.exe"
    
        if (!(test-path $7za))
            {
            Write-Warning "7za not found in $vmwarepath"
            }	
        Write-Verbose "extracting $Archive to $destination"
        if (!(test-path  $destination))
            {
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            }
        $destination = "-o"+$destination
        .$7za x $destination $Archive
	}
}

function Expand-LABZip
{
 [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
    HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Expand-LABZip")]
	param (
        [string]$zipfilename,
        [string] $destination,
        [String]$Folder)
	$copyFlag = 16 # overwrite = yes
	$Origin = $MyInvocation.MyCommand
	if (test-path($zipfilename))
	{
    If ($Folder)
        {
        $zipfilename = Join-Path $zipfilename $Folder
        }
    		
        Write-Verbose "extracting $zipfilename to $destination"
        if (!(test-path  $destination))
            {
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            }
        $shellApplication = New-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace("$destination")
		$destinationFolder.CopyHere($zipPackage.Items(), $copyFlag)
	}
}

function Get-LABFTPFile
{ 
[CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Get-LABFTPfile")]
Param(
    [Parameter(ParameterSetName = "1", Mandatory = $true)]$Source,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$TarGet,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$UserName = "Anonymous",
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$Password = "Admin@LABbuildr.local",
    [Parameter(ParameterSetName = "1", Mandatory = $false)][switch]$Defaultcredentials
) 
if (!$TarGet)
    {
    $TarGet = Split-Path -Leaf $Source 
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
 
# Get a download stream from the server response 
$responsestream = $ftpresponse.GetResponseStream() 
 
# create the tarGet file on the local system and the download buffer 
$tarGetfile = New-Object IO.FileStream ($TarGet,[IO.FileMode]::Create) 
[byte[]]$readbuffer = New-Object byte[] 1024 
Write-Verbose "Downloading $Source via ftp" 
# loop through the download stream and send the data to the tarGet file 
$I = 1
do{ 
    $readlength = $responsestream.Read($readbuffer,0,1024) 
    $tarGetfile.Write($readbuffer,0,$readlength)
    if ($I -eq 1024)
        {
        Write-Host '#' -NoNewline 
        $I = 0
        }
    $I++
} 
while ($readlength -ne 0) 
 
$tarGetfile.close()
Write-Host
return $true
}

function Enable-LABfolders
    {
    [CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Enable-Labfolders")]
    param()
    Get-vmx | where state -match running  | Set-VMXSharedFolderState -Enabled
    }

function Get-LABscenario
    {
    [CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Get-LABScenario")]
    param()
    Get-VMX | Get-vmxscenario | Sort-Object Scenarioname | ft -AutoSize
    }


function New-LABdefaults   
{
    [CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#New-LABDefaults")]
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
        $xmlcontent += ("<NoDomainCheck></NoDomainCheck>")
        $xmlcontent += ("<Puppet></Puppet>")
        $xmlcontent += ("<PuppetMaster></PuppetMaster>")
        $xmlcontent += ("<HostKey></HostKey>")
        $xmlcontent += ("</config>")
        $xmlcontent | Set-Content $defaultsfile
     }






function Start-LABScenario
    {
    [CmdletBinding(DefaultParametersetName = "1",
    HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Start-LABscenario")]
	    param (
	    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA','hyper-V','ScaleIO','ESXi','LABbuildr')]$Scenario
	
	)
begin
	{
    if ((Get-vmx .\DCNODE).state -ne "running")
        {Get-vmx .\DCNODE | Start-vmx}
	}
process
	{
	Get-vmx | where scenario -match $Scenario | sort-object ActivationPreference | Start-vmx
	}
end { }
}

function Stop-LABScenario
    {
    [CmdletBinding(DefaultParametersetName = "1",
    HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Stop-LABSscenario")]
	    param (
	    [Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)][ValidateSet('Exchange','SQL','DPAD','EMCVSA','hyper-V','ScaleIO','ESXi','LABbuildr')]$Scenario,
        [Parameter(ParameterSetName = "1", Mandatory = $false)][switch]$dcnode
	
	)
begin
	{

	}
process
	{
	Get-vmx | where { $_.scenario -match $Scenario -and $_.vmxname -notmatch "dcnode" } | sort-object ActivationPreference  -Descending | Stop-vmx
        if ($dcnode)
            {
            Get-vmx .\DCNODE | Stop-vmx
            }
	}
end { }
}

function Start-LABPC
   {
    [cmdletbinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Start-LABPC")]
    param ([String]$MAC= $(throw 'No MAC addressed passed, please pass as xx:xx:xx:xx:xx:xx'))
    $MACAddr = $MAC.split(':') | %{ [byte]('0x' + $_) }
    if ($MACAddr.Length -ne 6)
    {
        throw 'MAC address must be format xx:xx:xx:xx:xx:xx'
    }
    $UDPclient = New-Object System.Net.Sockets.UdpClient
    $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
    $packet = [byte[]](,0xFF * 6)
    $packet += $MACAddr * 16
    [void] $UDPclient.Send($packet, $packet.Length)
    write "Wake-On-Lan magic packet sent to $MACAddrString, length $($packet.Length)"
 }


function Get-LABHttpFile
 {
    [CmdletBinding(DefaultParametersetName = "1",
    HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#GET-LABHttpFile")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 0)]$SourceURL,
    [Parameter(ParameterSetName = "1", Mandatory = $false)]$TarGetFile,
    [Parameter(ParameterSetName = "1", Mandatory = $false)][switch]$ignoresize
    )


begin
{}
process
{
if (!$TarGetFile)
    {
    $TarGetFile = Split-Path -Leaf $SourceURL
    }
try
                    {
                    $Request = Invoke-WebRequest $SourceURL -UseBasicParsing -Method Head
                    }
                catch [Exception] 
                    {
                    Write-Warning "Could not downlod $SourceURL"
                    Write-Warning $_.Exception
                    break
                    }
                
                $Length = $request.Headers.'content-length'
                try
                    {
                    # $Size = "{0:N2}" -f ($Length/1GB)
                    # Write-Warning "
                    # Trying to download $SourceURL 
                    # The File size is $($size)GB, this might take a while....
                    # Please do not interrupt the download"
                    Invoke-WebRequest $SourceURL -OutFile $TarGetFile
                    }
                catch [Exception] 
                    {
                    Write-Warning "Could not downlod $SourceURL. please download manually"
                    Write-Warning $_.Exception
                    break
                    }
                if ( (Get-ChildItem  $TarGetFile).length -ne $Length -and !$ignoresize)
                    {
                    Write-Warning "File size does not match"
                    Remove-Item $TarGetFile -Force
                    break
                    }                       


}
end
{}
}                 



 function Get-LABJava64
    {
    [CmdletBinding(HelpUri = "https://github.com/bottkars/LABbuildr/wiki/LABtools#Get-LABJava64")]
	param (
	[Parameter(ParameterSetName = "1", Mandatory = $false)]$DownloadDir=$vmxdir
    )
    Write-warning "Asking for latest Java"
    Try
        {
        $javaparse = Invoke-WebRequest https://www.java.com/en/download/manual.jsp
        }
    catch [Exception] 
        {
        Write-Warning "Could not connect to java.com"
        Write-Warning $_.Exception
        break
        }
    write-verbose "Analyzing response Stream"
    $Link = $javaparse.Links | Where-Object outerText -Match "Windows Offline \(64-Bit\)" | Select-Object href
    If ($Link)
        {
        $latest_java8uri = $link.href
        Write-Verbose "$($link.href)"
        $Headers = Invoke-WebRequest  $Link.href -UseBasicParsing -Method Head
        $File =  $Headers.BaseResponse | Select-Object responseUri
        $Length = $Headers.Headers.'Content-Length'
        $Latest_java8 = split-path -leaf $File.ResponseUri.AbsolutePath
        Write-verbose "We found $latest_java8 online"
        if (!(Test-Path "$DownloadDir\$Latest_java8"))
            {
            Write-Verbose "Downloading $Latest_java8"
            Try
                {
                Invoke-WebRequest "$latest_java8uri" -OutFile "$DownloadDir\$latest_java8" -TimeoutSec 60
                }
            catch [Exception] 
                {
                Write-Warning "Could not DOWNLOAD FROM java.com"
                Write-Warning $_.Exception
                break
                } 
            if ( (Get-ChildItem $DownloadDir\$Latest_java8).length -ne $Length )
                {
                Write-Warning "Invalid FileSize, must be $Length, Deleting Download File"
                Remove-Item $DownloadDir\$Latest_java8 -Force
                break
                }
            }
        else
            {
            Write-Warning "$Latest_java8 already exists in $DownloadDir"
            }
            $object = New-Object psobject
	        $object | Add-Member -MemberType NoteProperty -Name LatestJava8 -Value $Latest_java8
	        $object | Add-Member -MemberType NoteProperty -Name LatestJava8File -Value (Join-Path $DownloadDir $Latest_java8)
            Write-Output $object
        }
    }