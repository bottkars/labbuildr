s Student Guide is used to run labbuildr classes.  
Manadatory in each class is the preparation of Student Laptops/pc´s
For Windows 10 users, please make sure no not use edge browser for copy paste operations 

This Guide is divided in Multiple Chapters
* [Prerequirements](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#01-prerequirements)
* [install and run labbuildr](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#10-install-and-run-labbuildr)  
* [defaults](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#12-adjusting-defaults)
* [Running VM´s](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#13-running-vms)    

# 0.1 Prerequirements
In this part, students check / install the required software
requirements are
* VMware Workstationversion 12
* Powershell Version 3.0 or greater ( 4 gets installed in this guide )
* Virtualization enbled in Bios   
Check that VT Bit and virtualization is enabled in you Computers Bios    
***For Lenovo:***  
Press enter to interrupt Startup, the F1 for BIOS   
In Security enable both, Intel Virtualization Technology and VT-d Feature   
## 0.1.0 VMware Workstation 12
VMware Workstation 12 is recommended for the class. get you eval copy here [VMware 12 eval]( http://www.vmware.com/go/tryworkstation-win) 
EMCer can get their Licence Key here: [EMC VMware eval Keys](https://community.emc.com/docs/DOC-36202) ( login required )   

## 0.1.1 Check Powershell Version
labbuildr uses powershell for all automation tasks. A minimum Version of 3.0 is required.    
to check the powershell version, use keyboard shortcut [WIN+R] to open a run prompt, and enter "powershell.exe"
![image](https://cloud.githubusercontent.com/assets/8255007/17082305/27b8e622-5179-11e6-9800-f7ee6c4d6ada.png)
a new powershell window opens.
at the prompt, enter  
```Powershell
($PSVersionTable).PSVersion -ge "3.0"
```  
if the answer is "true", skip to [0.1.4 Execution Policy](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#014-execution-policy) 
![image](https://cloud.githubusercontent.com/assets/8255007/17082310/aa99e2c6-5179-11e6-8347-0ce2982b4fea.png)   

## 0.1.2 Check .Net Framework 
Prereq for Powershell 3.0/4.0 is Net Framework 4.5  
``` Powershell
(Get-ItemProperty -Path 'HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Version -ge '4.5*'
``` 
if the answer is true, skip to step [0.1.3 Install Powershell](http://labbuildr.readthedocs.io/en/master/Solutionpacks///Student-Guide#013-install-powershell-40) 
for any other answers, download and run [.Net 4.5.2 Installer]($Url=http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe")  
## 0.1.3 install Powershell 4.0  
Powershell (4.0) is part of Windows Management Framework (WMF) 4.0.   
Download and run WMF 4.0  from here [WMF 4.0 x64](https://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu)  

## 0.1.4 Execution Policy
Powershell resticts the execution of scripts with Execution Policy´s. Depending on your Version of OS, this might be a different setting. We need an unrestricted setting for labbuildr, to allow for run the downloaded code from GitHub.
If you do not have a Powershell Windows Open, do so now with [WIN+R] powershell.exe
enter
```Powershell
 Get-ExecutionPolicy
```
![image](https://cloud.githubusercontent.com/assets/8255007/17082394/c225b6e2-517c-11e6-9f9e-316a67e2cb8d.png)  
If the answer is not unrestricted, we have to set the execution policy. this can only be done as administrator.
from the taskbar, right-click on your powershell session and select "Run as Administrator"
![image](https://cloud.githubusercontent.com/assets/8255007/17082399/04bd889a-517d-11e6-9f11-b21ec0053abb.png)  
in the new powershell window, enter
```Powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
```
![image](https://cloud.githubusercontent.com/assets/8255007/17082406/3a145c1c-517d-11e6-8626-7d39d91d297a.png)  
close the admin window.  
from the other powershell session, enter
```Powershell
Get-ExecutionPolicy
```
_hint: use up / down keys_  
it should be set to _unrestricted_ now
![image](https://cloud.githubusercontent.com/assets/8255007/17082427/4831ce0a-517e-11e6-848a-343f3db854ce.png)  
## 0.1.5 sign into labbuildr slack channel
register yourself at http://community.emccode.com/ to get access to the emccode slack.
once registered, join the labbuildr slack channel at https://codecommunity.slack.com/messages/labbuildr/ 
that way i can check students completed the prework. we will use slack during the class for shareing of snippets etc

![image](https://cloud.githubusercontent.com/assets/8255007/17097122/adf88290-525c-11e6-8d9d-0b834c6fd9b0.png)

## 0.1.6  Optional
create your github account to be able to submit issues and  
do not Forget to star labbuildr :-)   
# 1.0 install and run labbuildr
In this section Studends wll install labbuildr, review basic settings and get introduced to some basic commands  

## 1.1 installation
in this chapter, students will learn how to install labbuildr.  
make shure vmware workstation is closed. this will allow for deletion of vm´s if required.  
this section can be re-used as a guide to install multiple instances of labbuildr
to install labbuildr, copy the content of [ get labbuildr installer](https://gist.githubusercontent.com/bottkars/212bc227190f47dbe4ef71b4bc5c1f9a/raw/labbuildr%2520installer) to your powershell window ( note: edge might block this )
![image](https://cloud.githubusercontent.com/assets/8255007/17082498/9f4200fa-5180-11e6-96be-7c393cdb5ade.png)

the tool will download the installer from git, and will end with the default installation program.  
before starting the installer, check where you want to install. the default location is c:\labbuildr2016 
with 
```Powershell
.\install-labbuildr.ps1 -Installpath [path]
```
you may want to set your own path. You can have multiple instances of labbuildr running on your machine, each should get it´s own Path
start your installation by hitting enter
![image](https://cloud.githubusercontent.com/assets/8255007/17082574/1c7241ae-5184-11e6-90f6-a1df255e0e7d.png)   

after the installation is finished, read the message that is displayed, and press return to continue. 
![image](https://cloud.githubusercontent.com/assets/8255007/17082584/53e0cda4-5184-11e6-8c2c-8d3037bbdd87.png)  
you should now have a labbuildr2016 icon on your desktop ( the name of the icon indicates the directory name )

## 1.2 run labbuildr
double click on the labbuildr icon on your desktop  
![image](https://cloud.githubusercontent.com/assets/8255007/17082705/d46c0c74-5187-11e6-9934-5b57f990d139.png)  

your labbuildr window should start.  
the actual version(s) will be displayed ( labdefaults )
If OpenWRT is not Available, it will be loaded and started
  
![image](https://cloud.githubusercontent.com/assets/8255007/20619716/4390133c-b2f6-11e6-8924-8345406edb18.png)

some defaults can now be adjusted to your needs
## 1.2 adjusting defaults
## 1.2.1 Masterpath
a central part of labbuildr are MASTER images, wich represent the Base for OS installations.
to be space effective, linked clones are used.  
the MASTERS are stored in a Central repo. the default is c:\sharedmaster
you can adjust the setting with    
```Powershell
Set-LABMasterpath -Masterpath [your path]
```
Note: use a fast ssd drive, and do NOT use usb, as disconnects will fail you VM.

## 1.2.2 Sources  
sources are the place where software for add on installations like SQL, Sharepoint, ScaleIO, Networker etc are downloaded to.
Should be on a drive with enough space, USB Stick etc. UNC currently not tested.  
Default is c:\sources  
create the desired Directory with   
```Powershell
New-Item -ItemType Directory C:\sources
```
if you choose another path // stick, adjust with

create the desired Directory with   
```Powershell
Set-LABSources d:\sources
```
## 1.2.3 MySubnet
192.168.2.0 is default for all Machines Subnet
## 1.2.4 vmnet
Virtual net used by labbuildr machines. doess not need to exist unless you want to connect to your machines from your host  
for host connection, add the netwwok using the vmware virtual network editor. Create vmnet2 with  
* dhcp disabled
* connect host virtual adapter
* subnet ip 192.168.2.0
<script src="https://gist.github.com/bottkars/212bc227190f47dbe4ef71b4bc5c1f9a.js"></script>   
![image](https://cloud.githubusercontent.com/assets/8255007/17090582/243470fc-5232-11e6-87f5-f8c576eb8690.png)
 
## 1.3 running vm´s
in this chapter students will run / download their first vm(s) 
## 1.3.1 OpenWRT
OpenWRT is used as a tiny NAT gateway. it routes traffic from your vm´s subnet to the internet and allows VM´s to register ( windows 180 days license ) or download packages ( mainly linux )
to manually download an unzip OpenWRT use  
```Powershell
Receive-LABOpenWRT -start
```
![image](https://cloud.githubusercontent.com/assets/8255007/17090679/193660ec-5233-11e6-8724-0f5b3102634e.png)once this will start you OpenWRT vm. 
![image](https://cloud.githubusercontent.com/assets/8255007/17090792/6855e228-5234-11e6-9ad7-de0d5287a8c5.png)  
in the vm´s console, enter  
```bash
ifconfig eth1
```
this will show you the dhcp address received by your host  
![image](https://cloud.githubusercontent.com/assets/8255007/17090840/d67ee196-5234-11e6-84f0-bb85aa812fc1.png) 
use this ip address ( or MySubnet.4) with your browser to connect to the admin interface 
![image](https://cloud.githubusercontent.com/assets/8255007/17090880/2e162586-5235-11e6-8c5f-fd0dcf0e55fb.png)  
Login to the ui an be done with your Webbrowser with user root/Password123!  
## 1.3.2 Build a domain controller
to build the domain controller, follow
[Build-lab.ps1 -DConly](http://labbuildr.readthedocs.io/en/master/Solutionpacks///build-lab.ps1---DConly)
# 2.0 Managing VM´s  
get a list of all all labbuildr commands  
```Powershell
get-command -module labtools
```
getting a list of running vm´s  
```Powershell
get-vmx | where state -Match running  | ft
```

A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A

