param (
[ValidateSet(
    'beta','stable'
    )]
    [string]$branch="stable"
)

if (($env:Path) -notmatch ("/docker"))
    {
    Write-Host "Adjusting Path"
    $env:Path="$env:Path;$PSScriptRoot/docker"
    }
if (!(Test-Path "$PSScriptRoot/docker/docker-machine-driver-vmwareworkstation.exe"))
    {
    Write-Warning "Docker Tools for labbuildr not installed, trying to install"
    $Destination = (Get-LABDefaults).sourcedir
    Receive-LABDocker -install -Install_Dir $PSScriptRoot -Destination $labdefaults.sourcedir -branch $branch
    #break
    }

write-host -ForegroundColor Yellow '
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

'
Write-Host "Welcome to labbuildr Boot2Docker Environment
you are running on VMware $vmxtoolkit_type $($vmwareversion.ToString()) "
Write-Host -ForegroundColor White "Active Docker-Machine Hosts:"
docker-machine ls
write-host "
create a docker 'test' machine:
docker-machine create test --driver vmwareworkstation

To run a ubuntu container on 'test'
docker-machine env test | Invoke-Expression
docker run -it ubuntu

To remove all docker machines, run: 
docker-machine ls -q | foreach { docker-machine rm $_}"
