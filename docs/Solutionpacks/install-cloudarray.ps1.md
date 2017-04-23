##install-clpoudarray.ps1

cloudarray installation also follows labbuildr´s two step process:
* import ova as template
* deploy from template
 
## import
to get your copy and license for cloudarray, contact https://cloudarray.com
to import cloudarray ova, use 
```Powershell
.\install-cloudarray.ps1 -ovf C:\Users\bottk\Downloads\CloudArray_ESXi5_7.0.6.0.8713\CloudArray_ESXi5_7.0.
6.0.8713.ovf
```

the import will present you the default CloudArray installation Option once finished
![image](https://cloud.githubusercontent.com/assets/8255007/18385999/35c640bc-7694-11e6-8148-1cb4d463af57.png)   

##installation
to install cloudarray using 3 Cache Volumes, use

```Powershell
.\install-cloudarray.ps1 -Defaults -MasterPath [you masterpath]\CloudArray_ESXi5_7.0.6.0.8713\ -Cachevols 3 -Cachevolsize 146GB
```
this will create a new cloudarray instance with 3 Cachevolumes  
![image](https://cloud.githubusercontent.com/assets/8255007/18386070/b0ba18d4-7694-11e6-9b0b-35286627fbe4.png)  


proceed to the vm console
![image](https://cloud.githubusercontent.com/assets/8255007/18386144/35b44212-7695-11e6-8de9-6052aff852fe.png)  

login with admin password   
![image](https://cloud.githubusercontent.com/assets/8255007/18386185/890802e6-7695-11e6-92f4-8d7e4177f479.png)  

you will be promptet to change your password  
![image](https://cloud.githubusercontent.com/assets/8255007/18386236/d9a3aa20-7695-11e6-9951-0c51907a6e7d.png)  

proceed with network configuration 

![image](https://cloud.githubusercontent.com/assets/8255007/18386289/4a25c440-7696-11e6-8a91-101b553d782c.png)  

fill in your dns and gateway config 

![image](https://cloud.githubusercontent.com/assets/8255007/18386327/a0cd93b8-7696-11e6-8723-0a37c88bd3fd.png)  

and enter defaults for your primary nic  

![image](https://cloud.githubusercontent.com/assets/8255007/18386346/c91d920a-7696-11e6-87fd-1904335cc1d0.png)


save twice and continue configuration using the web ui.

click on setup to start configuration  
![image](https://cloud.githubusercontent.com/assets/8255007/18386408/2c675a58-7697-11e6-99c1-cf8bc41c2f81.png) 

make sure to have your cloudprovider and cloudportal credentials  
![image](https://cloud.githubusercontent.com/assets/8255007/18386447/7c7c93b4-7697-11e6-88a4-bf9d251a847a.png)  

leave cloudportal enabled  ( this will give you a free trial account for google storage )
![image](https://cloud.githubusercontent.com/assets/8255007/18386461/9ff99e54-7697-11e6-96f9-7c39aad7ccb3.png)  

enter your cloudportal details and license tag
![image](https://cloud.githubusercontent.com/assets/8255007/18386503/e2763ee0-7697-11e6-9fa9-790f90a4e1cd.png)  

create and Administrator Account  
![image](https://cloud.githubusercontent.com/assets/8255007/18429956/991d32a8-78d6-11e6-83cf-f24b9d0e249e.png) 
  
and accept the eula ( scroll down )  
![image](https://cloud.githubusercontent.com/assets/8255007/18386587/416de150-7698-11e6-90a2-8995304fa8a4.png)
  
start the configuration wizard
![image](https://cloud.githubusercontent.com/assets/8255007/18386621/608e4962-7698-11e6-80b1-3a09afe4a976.png)

skip the managed cloud provider if you do not want to use google  
![image](https://cloud.githubusercontent.com/assets/8255007/18386652/95905646-7698-11e6-8fc1-33fd0a9d0fa5.png)  

## Configure EMC ECS
select EMC ViPR as the cloud provider 
![image](https://cloud.githubusercontent.com/assets/8255007/18386683/c7c5c7b8-7698-11e6-9c64-926873bf1035.png)  

enter your ecs details:  
![image](https://cloud.githubusercontent.com/assets/8255007/18386780/64caf68c-7699-11e6-9f3a-e26cc988fbb0.png)

confirm your Bandwith 
![image](https://cloud.githubusercontent.com/assets/8255007/18433012/7f3b95dc-78e5-11e6-81ec-a1576a7dc267.png)  

and select your Cache Volume:
![image](https://cloud.githubusercontent.com/assets/8255007/18433056/c8cf2588-78e5-11e6-817e-d756d07441a4.png)  


the provider is configured for now 
![image](https://cloud.githubusercontent.com/assets/8255007/18433078/f51e31ec-78e5-11e6-8914-1a31a49d52bb.png)


## tips

* set ntp servers to a valid value !
the pre-configured ntp server can not be used. use one of pooled dns server addresses
![image](https://cloud.githubusercontent.com/assets/8255007/18430073/3bdb9192-78d7-11e6-8a94-e826afe8a8eb.png)  

* if your ECS uses self-signed certificates, you will receive the following message  
![image](https://cloud.githubusercontent.com/assets/8255007/18386803/7cb60d18-7699-11e6-87e7-fd1bda179927.png)

in that case, open a new cloudarray tab end go user interface --> Administration -->  utilities  
and enter the following code in the execute cli window
```bash
set_option disable_cloud_certs --disable true
```
![image](https://cloud.githubusercontent.com/assets/8255007/18386952/060ef160-769a-11e6-95d5-e246f59e2bdb.png)  

* for provider setting examples ( ecs ) see 
https://community.emc.com/blogs/bottk/2016/01/24/using-the-emc-elastic-cloud-storage-with-emc-software-and-appliances-part1-cloudarray

* If you retrieve access denied from ECS, it might be that your BASE URL in ECS is not configured correctly:
![image](https://cloud.githubusercontent.com/assets/8255007/18433282/f8a10f1e-78e6-11e6-9907-bca28651c9c3.png)


