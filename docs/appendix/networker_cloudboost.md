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
3. Import CloudBoost OVA  
```Powershell
/install-cloudboost.ps1 -ovf $HOME/Downloads/CloudBoost-2.2.2.ova  
```
![Import](https://user-images.githubusercontent.com/8255007/33307618-72fad916-d417-11e7-8563-340616c2e9a1.png)  

4. Install CloudBoost

There are various option for CloudBoost Deployment, but you simply could go with
```Powershell
./install-cloudboost.ps1 -Master $HOME/Master.labbuildr/CloudBoost-2.2.2
```


```Powershell
./install-cloudboost.ps1 -Master $HOME/bottk/Master.labbuildr/CloudBoost-2.2.2 -Site_Cache_Disks 3 -Site_Cache_Disk_Size 200GB
```
![InstallATION](https://user-images.githubusercontent.com/8255007/33308309-3a43a51e-d41a-11e7-89c8-1599ad5235e9.png)