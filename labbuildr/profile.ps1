<#$Userinterface = (Get-Host).UI.RawUI
$Userinterface.BackgroundColor = "Black"
$Userinterface.ForegroundColor = "Green"
$size = $Userinterface.BufferSize
$size.width=130
$size.height=5000
$Userinterface.BufferSize = $size
$size = $Userinterface.WindowSize
$size.width=120
$size.height=36
$Userinterface.WindowSize = $size
#>
param(
    $defaultsfile = "./defaults.json",
    [switch]$noopenwrt
)
if ($vmxtoolkit_type -eq "win_x86_64")
	{
	$labbuildr_home = $env:USERPROFILE
	}
else
	{
	$labbuildr_home = $HOME
	}
clear-host
$self  = Get-Location
import-module (Join-Path $self "vmxtoolkit") -Force -ArgumentList $self
import-module (Join-Path $self "labtools") -Force
try
    {
    Get-ChildItem labbuildr-scripts -ErrorAction Stop | Out-Null
    }
catch
    [System.Management.Automation.ItemNotFoundException]
    {
    Write-Warning -InformationAction Stop "labbuildr-scripts not found, need to move scripts folder"
	try
        {
		Write-Host -ForegroundColor Gray " ==> moving Scripts to labbuildr-scripts"
        Move-Item -Path Scripts -Destination labbuildr-scripts -ErrorAction Stop
        }
    catch
        {
        Write-Warning "could not move old scripts folder, incomlete installation ?"
        exit
        }
    }

try
    {
    Get-ChildItem $defaultsfile -ErrorAction Stop | Out-Null
    }
catch
    [System.Management.Automation.ItemNotFoundException]
    {
    Write-Host -ForegroundColor Yellow "no defaults.json found, using labbuildr default settings"
    New-LABdefaults -Defaultsfile $defaultsfile
    $Master_path = Join-Path $labbuildr_home "Master.labbuildr"
    $Source_path = Join-Path $labbuildr_home "Sources.labbuildr"
    Set-LABMasterpath -Masterpath $Master_path.tostring() #| Out-Null
    Set-LABSources -Sourcedir $Source_path.tostring() #| Out-Null
    }
$global:labdefaults = Get-LABDefaults
if (!$global:labdefaults.Masterpath)
    {
    Set-LABMasterpath -Masterpath (Join-Path $labbuildr_home "Master.labbuildr").tostring() | Out-Null
    }
if (!$global:labdefaults.Sourcedir)
    {
    Set-LABSources -Sourcedir (Join-Path $labbuildr_home "Sources.labbuildr").tostring() | Out-Null
    }    
if ($global:labdefaults.SQLVER -notmatch 'ISO')
	{
	Set-LABSQLver -SQLVER SQL2014SP2_ISO | Out-Null
    }
If (!$global:labdefaults.Masterpath)
    {	
    $Master_path = Join-Path $labbuildr_home "Master.labbuildr"
    Set-LABMasterpath -Masterpath $Master_path.tostring() #| Out-null
    }
If (!$global:labdefaults.Sourcedir)
    {
    $Source_path = Join-Path $labbuildr_home "Sources.labbuildr"
    Set-LABSources -Sourcedir $Source_path.tostring() #| Out-Null
    }
If (!$global:labdefaults.NoDomainCheck)
    {	
	Set-LABNoDomainCheck -enabled:$false  | out-null
    }

<#write-host -ForegroundColor Yellow "Running VMware $vmwareversion"
if (!(Test-Connection community.emc.com -Quiet -Count 2 -ErrorAction SilentlyContinue))
    {
    Write-Warning "no Internet Connection detected or on EMC Net, Download of Sources may not work"
    }
else
    {
    Write-host "latest updates on vmxtoolkit and labbuildr"
    $Url = "https://community.emc.com/blogs/bottk/feeds/posts"
    $blog = [xml](new-object System.Net.WebClient).DownloadString($Url)
    $blog.rss.channel.item |  where {$_.title -match "vmxtoolkit" -or $_.title -Match "labbuildr"} |select Link | ft
    }#>

if ($global:labdefaults.Languagetag -match "_")
    {
    $global:labdefaults.Languagetag = $global:labdefaults.Languagetag -replace "_","-"
    save-labdefaults -defaults $global:labdefaults | Out-Null        
    }
if (!$global:labdefaults.timezone)
    {
    Set-Labtimezone  | out-null
    }
if ($noopenwrt.IsPresent)
    {
        Set-LABOpenWRT -enabled:$false
    }
if ($global:labdefaults.openwrt -eq "false")
	{
	Write-Host -ForegroundColor Yellow "==> Running labbuildr without OpenWRT, know what you do !"
	}
else
	{
	if (!($openwrt = get-vmx OpenWRT* -WarningAction SilentlyContinue) -and !($global:labdefaults.openwrt -eq "false"))
		{
		Receive-LABOpenWRT -start  | Out-Null
		}
	else
		{
		if (($openwrt.status) -notmatch "running")
			{
			$openwrt[-1] | Start-VMX -nowait | Out-Null
			}
		}
	}
$buildlab = (join-path $self "build-lab.ps1")
.$buildlab    
Set-LabUI
Get-VMX
