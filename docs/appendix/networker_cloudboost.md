## CheatSheet to install networker and Cloudboost into labbuildr

1. Setup Base environment ( not required if using defaults )

align settings to your need, example
```Powershell
Set-LABvmnet vmnet3 # here we use a differnt network 
Set-LABsubnet 10.10.3.0 # assign a Subnet  
Set-LABDefaultGateway 10.10.3.4 #set our gateway host  
Set-LABDNS -DNS1 10.10.3.4 -DNS2 10.10.3.10 # 
Set-LABAPT_Cache_IP 10.10.3.200 # for Ubuntu 
```


2. Setup Networker  
```Powershell
./build-lab.ps1 -Nwserver -nw_ver nw9210 
```

install and configure cloudboost 
[cloudboost setup](http://labbuildr.readthedocs.io/en/master/Solutionpacks/install-cloudboost.ps1/)

enable the remote mount password

![grafik](https://user-images.githubusercontent.com/8255007/33317182-bf5f9944-d436-11e7-8deb-3ee55c97fec3.png)

