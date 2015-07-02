<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
.EXAMPLES
remove-nsrpeerinfo.ps1 -client hvnode1
this removes the client hvnode1 from networker peer info ( domain appended automatically )
#>
#requires -version 3
param(
[Parameter(mandatory=$true)][string]$client
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Domain = $Env:USERDNSDOMAIN.tolower()
$Content = "delete type:NSR peer information;name:$client.$($Domain)"
Set-Content -Path .\delpeer.nsr -Value $Content
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -p nsrexec -i .\delpeer.nsr
