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
    Get-ChildItem .\defaults.xml -ErrorAction Stop | Out-Null
    }
catch
    [System.Management.Automation.ItemNotFoundException]
    {
    Write-Host -ForegroundColor Yellow "no defaults.xml found, using labbuildr default settings"
    Copy-Item .\defaults.xml.example .\defaults.xml
	Set-LABMasterpath "$HOME/Master.develop"
	Set-LABSources "$Home/Sources.develop"
    }
if ((Get-LABDefaults).SQLVER -notmatch 'ISO')
	{
	Set-LABSQLver -SQLVER SQL2014SP2_ISO
	}
$buildlab = (join-path $self "build-lab.ps1")
.$buildlab
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
Get-VMX
