## install-coprhd

install-coprhd.ps1 will install the latest coprhd ( open-source emc vipr, see https://coprhd.github.io/ ).  
start the deployment with  
```Powershell
.\install-coprhd.ps1 -Defaults
```
as a base, an OpenSuse Master image is required and will be downloaded from labbuildr repo on azure.  
![image](https://cloud.githubusercontent.com/assets/8255007/17092565/dcacb8cc-5243-11e6-9ae2-3f62bdd652e9.png)  

after successful download, the base machine is built  
![image](https://cloud.githubusercontent.com/assets/8255007/17092632/37609630-5244-11e6-89ee-a5f9f41c7bb8.png)
the configuration of the machine will be adjusted to meet the requirements of CoprHD
once the basic machine config is done, the machine will be started and the basic network  configuration is done.
make sure to have a proper default gateway / openwrt installed for the virtual machine to access the internet.  

![image](https://cloud.githubusercontent.com/assets/8255007/17092656/559cb00c-5244-11e6-88fb-b70573a27b5f.png)  

right after the basic network configs and ssh configuration is finished, the machine will clone into CoprHD on GitHub
all bash command issued will be displayed form invoke-vmxbash ( vmxtoolkit bash for powershell ) with a state of success or failed.   

![image](https://cloud.githubusercontent.com/assets/8255007/17092792/400b9bc6-5245-11e6-9dab-8c0204eb6c7c.png)    
the log written under /tmp for the installation can be viewed from inside the vm with
```bash
tail -f /tmp/installPackages.log
```
the log used can be taken form the powershell command ( in this example installPackages.log ).  
![image](https://cloud.githubusercontent.com/assets/8255007/17092863/c2c79056-5245-11e6-983f-be7b7d32b946.png)   

a zypper cache is installed in your sources directory, to speed up subsequent deployments of coprhd.  
![image](https://cloud.githubusercontent.com/assets/8255007/17092915/1a1be35c-5246-11e6-8d21-3a65cd2ceff1.png)  

the same applies to the build process of CoprHD  
![image](https://cloud.githubusercontent.com/assets/8255007/17092991/a6017a58-5246-11e6-9bc8-8b21658aae8e.png)    

![image](https://cloud.githubusercontent.com/assets/8255007/17093022/cdac3f20-5246-11e6-90e1-419351fb7be8.png)  
once CoprHD is installed, the deployment has finished.  
![image](https://cloud.githubusercontent.com/assets/8255007/17093875/2cf0a188-524c-11e6-8e03-bcb603f67dc0.png)  
in order to access the UI for further configuration, you may need to restart the vm.
login to the ui with root/ChangeMe  
![image](https://cloud.githubusercontent.com/assets/8255007/17093640/bbdccc98-524a-11e6-8a7f-c515f20d026b.png)  
during the initail setup, you are asked to change the passwords:  
![image](https://cloud.githubusercontent.com/assets/8255007/17093970/b1d5da58-524c-11e6-86b4-c54383b262a5.png)   
enter your dns server ( e.g. dcnode and or OpenWRT ) as well as ntp server. if building in default labbuildr environment, the dcnode can be used as ntp.  
![image](https://cloud.githubusercontent.com/assets/8255007/17094487/e2c5b4be-524f-11e6-9035-b16081b941cb.png)  
you may finish now or enter an smtp server.   
here is an example for using Office365 as smtp relay:  
![image](https://cloud.githubusercontent.com/assets/8255007/17094103/637494ca-524d-11e6-8b00-0f3980caa0eb.png)
