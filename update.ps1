if (git)
	{
	Write-Host -ForegroundColor Gray " ==> git installed, running update"
	git -C $HOME/labbuildr pull
	git -C $HOME/labbuildr/labbuildr-scripts pull
	git -C $HOME/labbuildr/vmxtoolkit pull
	git -C $HOME/labbuildr/labtools pull
	ipmo $HOME/labbuildr/vmxtoolkit -ArgumentList "$HOME/labbuildr/" -Force
	ipmo $HOME/labbuildr/labtools -Force 
	}
else
	{
	Write-Host -ForegroundColor Yellow " ==>Sorry, you need git to run Update"
	}


