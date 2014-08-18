$ScriptName = $MyInvocation.MyCommand.Name
New-Item -ItemType file -Path c:\scripts\$ScriptName.log
$Host.UI.RawUI.WindowTitle = "$ScriptName"


function Extract-Zip
{
	
    param([string]$zipfilename, [string] $destination)
    $copyFlag = 16 # overwrite = yes 
    $Origin = $MyInvocation.MyCommand
	if(test-path($zipfilename))
	{	
		$shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(),$copyFlag)
	}
}
New-Item -ItemType file -Path c:\scripts\$ScriptName.log
Extract-Zip c:\scripts\gpo.zip c:\scripts
Import-GPO -BackupGpoName "Default Domain Policy" -TargetName "Default Domain Policy" -Path C:\Scripts\GPO
