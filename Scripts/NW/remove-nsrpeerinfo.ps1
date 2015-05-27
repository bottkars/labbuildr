<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
param(
    [string]$client = "hvnode1"
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Domain = $Env:USERDNSDOMAIN.tolower()
$Content = "delete type:NSR peer information;name:$client.$($Domain)"
Set-Content -Path .\delpeer.nsr -Value $Content
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -p nsrexec -i .\delpeer.nsr
