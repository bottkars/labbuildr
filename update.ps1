if (git)
	{
	Write-Host -ForegroundColor Gray " ==> git installed, running update"
	$Repos = ('/labbuildr','/labbuildr/labbuildr-scripts','/labbuildr/vmxtoolkit','/labbuildr/labtools')
	foreach ($Repo in $Repos)
		{
		Write-Host -ForegroundColor Gray " ==>Checking for Update on $Repo"
		git -C $HOME/$Repo pull
		}
	ipmo $HOME/labbuildr/vmxtoolkit -ArgumentList "$HOME/labbuildr/" -Force
	ipmo $HOME/labbuildr/labtools -Force 
	}
else
	{
	Write-Host -ForegroundColor Yellow " ==>Sorry, you need git to run Update"
	}


