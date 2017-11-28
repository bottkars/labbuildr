# labbuildr cloudboost installation Guide

Cloudboost Networker Installation 

## Import CloudBoost OVA  
```Powershell
/install-cloudboost.ps1 -ovf $HOME/Downloads/CloudBoost-2.2.2.ova  
```
![Import](https://user-images.githubusercontent.com/8255007/33307618-72fad916-d417-11e7-8563-340616c2e9a1.png)  

## Install CloudBoost

There are various option for CloudBoost Deployment, but you simply could go with
```Powershell
./install-cloudboost.ps1 -Master $HOME/Master.labbuildr/CloudBoost-2.2.2
```

If ou want to add cache disks, use this command
```Powershell
./install-cloudboost.ps1 -Master $HOME/bottk/Master.labbuildr/CloudBoost-2.2.2 -Site_Cache_Disks 3 -Site_Cache_Disk_Size 200GB
```

The Installation will use a Full Clone and add the required disks to it.

Once finished, the required config commands are presented.
![InstallATION](https://user-images.githubusercontent.com/8255007/33308309-3a43a51e-d41a-11e7-89c8-1599ad5235e9.png)  

in this example, go to the cloudboost console and lofin with Password password.
you will be asked to change the password:

![login](https://user-images.githubusercontent.com/8255007/33313584-608163b8-d42b-11e7-9e24-5888addfd2f6.png)

now type in the commands to configure provided from the installer.
Example
```Bash
net config eth0 10.10.3.71 netmask 255.255.255.0
route add 0.0.0.0 netmask 0.0.0.0 gw 10.10.3.4
dns set primary 10.10.3.4
fqdn cloudboost1.labbuildr.local
```

depending on your workstation settings, this might work with copy / paste :-)

![grafik](https://user-images.githubusercontent.com/8255007/33314305-8518fd88-d42d-11e7-90d2-e2058ef4c1f3.png)

