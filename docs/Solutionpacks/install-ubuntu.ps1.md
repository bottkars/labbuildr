## install-ubuntu.ps1 will install a Default ubuntu minimal System   
currently, ubuntu 14_1,15_10 and 16_4 can be deployed.  
Masters are automatically downloaded from Azure labbuildr repo   
![labbuildr_ubuntu_nowatermark](https://cloud.githubusercontent.com/assets/8255007/17725857/106c9cbe-644f-11e6-9b2f-6e1d7b67815a.gif)
A grapical Desktop can be installed.  
The size can be controlled with [-Size](https://github.com/bottkars/vmxtoolkit/wiki/Commands#set-vmxsize)  
Disks can be added with -Disks ( e.g. for ScaleIO testing )  
the Option -docker adds the latest docker-engine´ 

examples for desktops:


```Powershell
.\install-ubuntu.ps1 -Defaults -ubuntu_ver 16_4 -Desktop cinnamon-desktop-environment
```    

![image](https://cloud.githubusercontent.com/assets/8255007/17455084/f3086620-5bad-11e6-8d44-3a40e58a1155.png)  
  
```Powershell
.\install-ubuntu.ps1 -Defaults -ubuntu_ver 16_4 -Desktop lxde -Startnode 2
```  
![image](https://cloud.githubusercontent.com/assets/8255007/17455101/246d6e5e-5bae-11e6-9073-8d1082322933.png)    

```Powershell
.\install-ubuntu.ps1 -Defaults -ubuntu_ver 16_4 -Desktop xfce4  -Startnode 3
``` 
![image](https://cloud.githubusercontent.com/assets/8255007/17455139/23bac26c-5baf-11e6-9a4e-64f72b7ca5fe.png)  

```Powershell
.\install-ubuntu.ps1 -Defaults -ubuntu_ver 16_4 -Desktop cinnamon -Startnode 4
```
![image](https://cloud.githubusercontent.com/assets/8255007/17455078/d8e7ffee-5bad-11e6-80f6-33cdeb372f3a.png)  
```Powershell
SYNTAX
    C:\labbuildr2016\install-ubuntu.ps1 -Defaults [-Disks <Int32>] [-ubuntu_ver <String>] [-Desktop <String>] [-Nodes
    <Int32>] [-Startnode <Int32>] [-Defaultsfile <Object>] [-forcedownload] [-ip_startrange <Int32>] [-WhatIf] [-Confirm]
    [<CommonParameters>]

    C:\labbuildr2016\install-ubuntu.ps1 [-Disks <Int32>] [-ubuntu_ver <String>] [-Desktop <String>] [-Sourcedir <Object>]
    [-Nodes <Int32>] [-Startnode <Int32>] [-subnet <IPAddress>] [-BuildDomain <String>] [-vmnet <Object>] [-forcedownload]
    [-ip_startrange <Int32>] [-WhatIf] [-Confirm] [<CommonParameters>]
```