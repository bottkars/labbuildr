if (git)
	{
	$Git_Dir = Split-Path (Get-Location)
	Write-Host -ForegroundColor Gray " ==> git installed, running update"
	$Repos = ('/labbuildr','/labbuildr/labbuildr-scripts','/labbuildr/vmxtoolkit','/labbuildr/labtools')
	foreach ($Repo in $Repos)
		{
		Write-Host -ForegroundColor Gray " ==>Checking for Update on $Repo"
		git -C $Git_Dir/$Repo pull
		}
	Import-Module $Git_Dir/labbuildr/vmxtoolkit -ArgumentList "$HOME/labbuildr/" -Force
	Import-Module $Git_Dir/labbuildr/labtools -Force 
	Invoke-Expression "./profile.ps1"
	}
else
	{
	Write-Host -ForegroundColor Yellow " ==>Sorry, you need git to run Update"
	}


