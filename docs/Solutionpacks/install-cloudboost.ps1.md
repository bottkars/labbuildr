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

Once the Network is configured, trype in 'register' to register the Appliance with dpccloud.com:

![grafik](https://user-images.githubusercontent.com/8255007/33314808-0256ef52-d42f-11e7-8d13-e600d4f4e460.png)

login to https://console.dpccloud.com and select the cloudboost registration from the menu
![grafik](https://user-images.githubusercontent.com/8255007/33314862-2d6adbb8-d42f-11e7-9dac-91a46e079d48.png)
Enter your Claim Code and register

![grafik](https://user-images.githubusercontent.com/8255007/33314926-6c8ab782-d42f-11e7-9d72-3dde537ea1c9.png)

![grafik](https://user-images.githubusercontent.com/8255007/33314949-7f87f9f8-d42f-11e7-9cfc-911713872752.png)


Click on the direct link to the cloudboost appliance for configuration
it may take a few moments antil heartbeat is synched an the configure tab is enabled:

![grafik](https://user-images.githubusercontent.com/8255007/33315224-580c0904-d430-11e7-8642-c378b1a26bd9.png)

edit you specific configuration details for the appliance

![grafik](https://user-images.githubusercontent.com/8255007/33315509-32b87da8-d431-11e7-83d8-7f6b35c003bf.png)

click on update changes and the appliance will start fongiguring. this will take a few minutes:

![grafik](https://user-images.githubusercontent.com/8255007/33315646-8d93b0ee-d431-11e7-977b-4712ad1f3c13.png)

once the appliance has finished configuring, procced with integartion into you backup software.


![grafik](https://user-images.githubusercontent.com/8255007/33316131-205a7164-d433-11e7-965e-20742ee7b965.png)
![grafik](https://user-images.githubusercontent.com/8255007/33316175-57181990-d433-11e7-8202-a6068889d468.png)

see networker cloudboost integration as an example:
[cludboost networker](http://labbuildr.readthedocs.io/en/master/appendix/networker_cloudboost/)




