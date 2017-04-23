## about install-esxi.ps1
insatll-esxi.ps1 installs e ESXi (6) Server in labbuildr
the Installation uses a customized ISO for kickstarting  
the iso is downloaded automatically  
![esxi_installer](https://cloud.githubusercontent.com/assets/8255007/17742389/1fe0122e-64a0-11e6-8ef8-1550390a6d21.gif)

to run the installer, simply run

```Powershell
.\install-esxi.ps1 -Defaults -esxi_ver '6.0.0.update02'  
```  

if you want to try the esxui fling, use

```Powershell
.\install-esxi.ps1 -Defaults -esxi_ver '6.0.0.update02' -esxui 
```
## prebuilt nfs
you can prepare your labbuildr dcnode for serving nfs  
just execute .\dcnode\configure-nfs.ps1 from the labbuildr Shell on dcnode
all required roles will be installed and a nfs share will be created  
if you then call the installer with
```Powershell
.\install-esxi.ps1 -Defaults -esxi_ver '6.0.0.update02' -esxui -nfs 
```
the SWDEPOT NFS Datastore will be available

![image](https://cloud.githubusercontent.com/assets/8255007/17742365/07d820f4-64a0-11e6-86a6-fcdc43a2bac6.png)
##versions  
currently,  '6.0.0.update02' and '6.0.0.update01' ISO´s are available, patch Levels are in the work 