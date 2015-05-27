<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$Domain = $env:USERDOMAIN
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name ConsentPromptBehaviorAdmin -PropertyType DWord -Value 0 -Force
$Files = Get-ChildItem -Path $Builddir -Filter VMserver.ini
foreach ($file in $Files) {
$content = Get-Content -path $File.fullname
$content = $content | foreach {$_ -replace "BRS2GO", "$env:USERDOMAIN"}
$content | foreach {$_ -replace "VMMINSTANCE", "MSSQL$env:USERDOMAIN"} | Set-Content $file.FullName
}
