## labbuildr cloudboost installation Guide

Cloudboost Networker Installation 

1. Import CloudBoost OVA  
```Powershell
/install-cloudboost.ps1 -ovf $HOME/Downloads/CloudBoost-2.2.2.ova  
```
![Import](https://user-images.githubusercontent.com/8255007/33307618-72fad916-d417-11e7-8563-340616c2e9a1.png)  

2. Install CloudBoost

There are various option for CloudBoost Deployment, but you simply could go with
```Powershell
./install-cloudboost.ps1 -Master $HOME/Master.labbuildr/CloudBoost-2.2.2
```


```Powershell
./install-cloudboost.ps1 -Master $HOME/bottk/Master.labbuildr/CloudBoost-2.2.2 -Site_Cache_Disks 3 -Site_Cache_Disk_Size 200GB
```
![InstallATION](https://user-images.githubusercontent.com/8255007/33308309-3a43a51e-d41a-11e7-89c8-1599ad5235e9.png)