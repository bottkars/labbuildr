## labbuildr beta Support for LINUX/OSX
with powershell on OSX/LINUX labbuildr will start to support labbuildr on OSX and Linux
this will incude:
* vmxtoolkit
* labbuildr-scripts
* labtools
* labbuildr

See [LINUX VIDEO](https://www.youtube.com/watch?v=ZjXEVWe9KU4) for a demo  
however, as not jet ready for prime with many changes, it is only available via git pull from the current master branch

![github_osx_powershell_vmxtoolkit](https://cloud.githubusercontent.com/assets/8255007/17848963/c08f8588-6856-11e6-8714-82d50f96dc93.gif)

## Requirements on OSX
to run vmxtoolkit on OSX, you need to have  
* PowerShell for OSX installed  ( Preferrably 6.0Beta )
* .Net Core
* p7zip /rudix  
see [PowerShell for OSX](https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md#os-x-1011) for instructions  it is also recommended to install .NET Core for OSX from for details on installation of .NET Core LIBS see [.NET Core on MACOS](https://www.microsoft.com/net/core#macos)   
OSX port is currently only available via Git clone, no auto installer
as i decided to use 7zip on all platforms as Primary master Distribution Format, please install p7zip !
![image](https://cloud.githubusercontent.com/assets/8255007/18025670/62fe7e7c-6c31-11e6-9972-bbde6aa40d00.png) 
i recommend rudix for p7zip  
**RUDIX and p7zip**
```bash
curl -s https://raw.githubusercontent.com/rudix-mac/rpm/2015.10.20/rudix.py | sudo python - install rudix
sudo rudix install p7zip
```

  

## Requirements on LINUX
to run vmxtoolkit on LINUX, you need to have PowerShell for LINUX installed  
see [PowerShell for LINUX](https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md) for instructions
it is also recommended to install .NET Core for OSX from for details on installation of .NET Core LIBS see [.NET Core on LINUX](https://www.microsoft.com/net/core#LINUX)   
i also require  p7zip, curl and git on your Linux Distribution
Ubuntu
```bash
sudo apt-get install p7zip-full curl git -y
```
LINUX requires the vmnet´s to be configured in VMware Workstation  

Before testing the first scenario you should create your VMnet ( default: VMnet2) with the VMware Virtual Network Editor. Labbuildr is using this net. 
When you try to start you first test VM Receive-LABOpenWRT -unzip | Start-VMX
VMware workstation is complaining that it is not possible to set a network adapter to Promiscuous Mode. Below a VMware KB how to fix that.
https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=287#.V-De9Q28qRE.email


# LINUX/OSX port is currently only available via Git clone, no auto installer 
## Install labbuildr on OSX/LINUX

to clone labbuildr for VMware/Fusion and required Tools and scripts, use   
```Bash
git clone -b master https://github.com/bottkars/labbuildr
cd labbuildr
git clone -b master https://github.com/bottkars/labbuildr-scripts 
git clone -b master https://github.com/bottkars/labtools
git clone -b master https://github.com/bottkars/vmxtoolkit
```
# USAGE
## Automatic start via profile.ps1
once powereshell is installed and the repos are pulled,, labbuildr can set your environment with the included profile.ps1   
```Powershell
powershell
./profile.ps1
```

test your deployment with
```Powershell
Receive-LABOpenWRT -unzip | Start-VMX
```


updates can be run by  
```Powershell
./update.ps1
```

## Manually loading

with vmxtookit on OSX and LINUX, i will change the way the modules are loaded  
vmxtoolkit will use the OS specific User Homedirectory to browse vm´s.  

*for OSX, this is $HOME/Documents/Virtual Machines.localized
*for Windows $ENV:HOME/Virtual Machines
*for Linux /var/lib/vmware/Shared VMs'   
if you want to use another VM Directory as search base, load vmxtoolkit with -ArgumentList [Directory]
## loading the modules
```Powershell
ipmo $HOME/vmxtoolkit -ArgumentList "/$HOME/labbuildr" -Force
ipmo $HOME/labbuildr/labtools -Force
```

this will set the $Global:vmxdir to /Users/bottk/labbuildr
when running Get-VMX without parameter, i will use this Directory as Base Search path for VM´s.   
**NOTE RELOAD Modules with -Force on every pull**

## Updating
to update the modules / scripts, just do

```Powershell
git -C $HOME/labbuildr pull
git -C $HOME/labbuildr/labbuildr-scripts pull
git -C $HOME/labbuildr/vmxtoolkit pull
git -C $HOME/labbuildr/labtools pull
ipmo $HOME/labbuildr/vmxtoolkit -ArgumentList "$HOME/labbuildr/" -Force
ipmo $HOME/labbuildr/labtools -Force  
```
## create a launcher icon on (ubuntu) linux
create a file named labbuildr.desktop on your desktop
```
touch ~/Desktop/labbuildr.desktop
```
edit the file and adjust to you settings:
```
[Desktop Entry]
Name=labbuildr 2017
Path=/home/bottk/Downloads/labbuildr
Type=Application
GenericName[en_US]=Powershell
Exec=/usr/bin/powershell -NoExit -command ./profile.ps1
Comment[en_US]=Execute labbuildr
Terminal=true
Icon=/home/bottk/Pictures/labbuildr
```
this should generate  launcher icon


## progress
* a list of tested Command is checked in [Issue 8](https://github.com/bottkars/vmxtoolkit/issues/8)   
* a list of OS relevant changes can be found here [Issue 9](https://github.com/bottkars/vmxtoolkit/issues/9)   