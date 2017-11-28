## CheatSheet to install networker and Cloudboost into labbuildr

1. Setup Base environment ( not required if using defaults )

align settings to your need, example
```Powershell
Set-LABvmnet vmnet3 # here we use a differnt network 
Set-LABsubnet 10.10.3.0 # assign a Subnet  
Set-LABDefaultGateway 10.10.3.4 #set our gateway host  
Set-LABDNS -DNS1 10.10.3.4 -DNS2 10.10.3.10 # 
Set-LABAPT_Cache_IP 10.10.3.200 # for Ubuntu
Set-LABNWver -nw_ver nw9210 # set to you desired NW version
Set-LABMaster -Master 2016_1711 # set to the latest Master for Server 2016
```


2. Setup Networker  
```Powershell
./build-lab.ps1 -Nwserver -nw_ver nw9210 
```

install and configure cloudboost 
[cloudboost setup](http://labbuildr.readthedocs.io/en/master/Solutionpacks/install-cloudboost.ps1/)

enable the remote mount password, needed later in Networker Wizard
```bash
remote-mount-password enable Password123!
```
![grafik](https://user-images.githubusercontent.com/8255007/33317182-bf5f9944-d436-11e7-8deb-3ee55c97fec3.png)

got to Networker Administration and configure Cloud Boost using the Cloudboost Wizard  

From Devices, right Click on Cloud Boost-->New Device Wizard
![image](https://user-images.githubusercontent.com/8255007/33317477-9c01f5f4-d437-11e7-98ed-5fbd515ba30a.png)
Select CloudBoost as Device Type
![image](https://user-images.githubusercontent.com/8255007/33317595-e1c0d998-d437-11e7-9bc7-16893845cc9e.png)
Confirm the Cloudboost Checklist 
![image](https://user-images.githubusercontent.com/8255007/33317644-094dceee-d438-11e7-8800-b64ce9f5d047.png)
in the CloudBoost Configuration Options specify 'remotebackup' as uername and the password you specified earlier
![image](https://user-images.githubusercontent.com/8255007/33317787-908ac6e6-d438-11e7-86d3-699e149829bd.png)

click next to continue ...
