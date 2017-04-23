# about

install-unity-falcon.ps1 deploys a DELL|EMC Unity VSA on VMware Workstation.  
it is a fully automated process.  
other than pre-falcon release, some tweaks have to be made.

* unity needs to run pvscsi devices
* only system disks are allowed at system boot time
* uuid has changed from a SP uuid to a system UUID ( randomly changed with every deployment ), so a license file can not be re-used as the first byte changes with every deployment of the same machine:
![image](https://cloud.githubusercontent.com/assets/8255007/24233381/28992642-0f92-11e7-9cf5-45e759324d33.png)

the changes requires a Change in the deployment process to invoke at least one **shutdown - reconfig** and a **injection of the lic_file from a "drop-in" directory** ( only if you want to autoconfigure luns, iscsi and fileservices )

# Import   
to start a unity deployment, we have to initially Import the ova. simply run    

```Powershell
.\install-unity-falcon.ps1 -ovf C:\Downloads\UnityVSA-4.1.0.9058043.ova  
```

where you have to replace the ovf with your downloaded Version

# Deploy

there are multiple options to deploy unity.  

* base deployment ( no license required, all config done vi web ui)

````Powershell
.\install-unity-falcon.ps1 -Masterpath C:\Users\KarstenBottlabbuildr\Master.labbuildr -Mastername UnityVSA-4.1.1* -configure -Defaults 
````
* a full flavored unity including join to an active directory can be done with: 

````Powershell
.\install-unity-falcon.ps1 -Masterpath C:\Users\KarstenBottlabbuildr\Master.labbuildr -Mastername UnityVSA-4.1.1* -configure -Defaults -lic_dir C:\labbuildr2017\ -Protocols cifs,
iscsi,nfs -Disks 6 -iscsi_hosts all
````

### used switches
* **lic_dir**  drop-in directory fo the licence we have to download once we get the system uuid upon first reboot
* **Masterpath** directory where the master was deployed from the ova  
* **Mastername** name of the master to be picked
* **configure** do a base configuration
* **Protocols** if lic_dir is present, the provided protocols are deployed

the workflow starts with the deployment and first boot of the unity System.
the first boot may take up to 10 minutes ( a lot of checks, key generation and image copies are taking place )

image of step1 imaging on console:
![image](https://cloud.githubusercontent.com/assets/8255007/24233063/e5886bd0-0f8f-11e7-932a-948687105842.png)

image of powershell output on step1
![image](https://cloud.githubusercontent.com/assets/8255007/24214548/24c009b6-0f36-11e7-9fa0-9956beee042f.png)

once the system imaging is done and the system Management os has booted, the runtime Services are configured.
this is a 27 step process
you may also watch the 27 steps in the VM´s console:   
![image](https://cloud.githubusercontent.com/assets/8255007/24215091/f09b74de-0f37-11e7-981d-a6cbf7a21832.png)
ip-addresses will be configured once step 27 is reached.


once the first deployment Phase reached System ready, the System uuid is presented and the System reboots. Copy the UUID and paste it in https://www.emc.com/auth/elmeval.htm to get your license.


![image](https://cloud.githubusercontent.com/assets/8255007/24215489/37da7132-0f39-11e7-9aff-7cb933466957.png)
![image](https://cloud.githubusercontent.com/assets/8255007/24215511/4f5b50c4-0f39-11e7-8f7a-c5c4d6263b80.png)

 download the license and copy the file into the drop-in Directory specified with -lic_dir

![image](https://cloud.githubusercontent.com/assets/8255007/24215553/6f53b2c2-0f39-11e7-8d16-c1fd9344fa9b.png)

The System will do a second boot now and start the configuration of the System:

![image](https://cloud.githubusercontent.com/assets/8255007/24215815/42a05a86-0f3a-11e7-88a2-0fab488965eb.png)  

if you have not already presented a license file, the installer will wait for you and check the drop-in dir until the file is present. note: do not rename the file upon save or copy, as the installer watches for the uuid in the Name.

once the license file is found, the System customization starts with the selected protocols:

![image](https://cloud.githubusercontent.com/assets/8255007/24215875/820386e4-0f3a-11e7-8686-d298f4f50227.png)  

if cifs needs to be configured, a second reboot might be required for the NTP adjustment

![image](https://cloud.githubusercontent.com/assets/8255007/24236851/fa3d5d38-0fa3-11e7-9ec8-27425115529c.png)

# final views 
These samples are an example representing the full config done by labbuildr 
![image](https://cloud.githubusercontent.com/assets/8255007/24232876/4c6b0788-0f8e-11e7-808e-4118af2f38be.png)

![image](https://cloud.githubusercontent.com/assets/8255007/24236899/3fe076fe-0fa4-11e7-998c-ff497bf1fbfa.png)

![image](https://cloud.githubusercontent.com/assets/8255007/24236918/5eb5ef64-0fa4-11e7-9753-6ccde94b8a07.png)

















