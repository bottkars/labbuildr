## install-nve to install networker virtual edition
nve (networker virtual edition) is a ova deliverd, pre-configured networker server.
nve uses the avp package format to deliver upgrades.

install-nve is a 2-step process:
* [import](https://github.com/bottkars/labbuildr/wiki/install-nve.ps1#import)
* [install](https://github.com/bottkars/labbuildr/wiki/install-nve.ps1#install)

## import
to download / import an nve from OVA as a master, run
```Powershell
.\install-nve.ps1 -import
```
if no downloaded nve is available, labbuildr will download the required nve from ftp://ftp.legato.com
![image](https://cloud.githubusercontent.com/assets/8255007/17021437/4e0728da-4f48-11e6-89b3-7a860b76c447.png)
once the download has finished, labbuildr will extract the file an import the master
![image](https://cloud.githubusercontent.com/assets/8255007/17021889/2dc8afc8-4f4b-11e6-90cc-8706d35397ec.png)


## install 
to install a defaul nve, run
```Powershell
.\install-nve.ps1 -Defaults -nve_ver '9.0.1-72'
```
if no base snapshot exists, it will be created.
than a linked clone will be created with a network connection to the default vmnet2
![image](https://cloud.githubusercontent.com/assets/8255007/17022025/026fe0b6-4f4c-11e6-8577-95a56ce44f7d.png)
once the vm has been booted, the network will be configured.
![image](https://cloud.githubusercontent.com/assets/8255007/17022094/532159ea-4f4c-11e6-9d14-3d763628ef29.png)

when prompted, continue installation by bointing your browser to the nve address. 
sign in with root/changeme
![image](https://cloud.githubusercontent.com/assets/8255007/17022165/a4a56432-4f4c-11e6-9606-1edf6376bc3d.png)
the avp installer for nve will start
click on install to start the installation:
![image](https://cloud.githubusercontent.com/assets/8255007/17022218/016ddece-4f4d-11e6-920b-43c577c14b06.png)
fill in all wizard options as desired, then click continue
![image](https://cloud.githubusercontent.com/assets/8255007/17022262/4af2fdb8-4f4d-11e6-8f36-b71ed72a574a.png)
wait until partitioning and rpm installation has been done.
![image](https://cloud.githubusercontent.com/assets/8255007/17022324/a29f5f7a-4f4d-11e6-8006-4e11b0f8f09f.png)
if you want to run Networker Administrator from your VM Host, add the fqdn of your nve to your hosts file
![image](https://cloud.githubusercontent.com/assets/8255007/17022378/f5d7586e-4f4d-11e6-9a6a-5bb1cb8038da.png)

![image](https://cloud.githubusercontent.com/assets/8255007/17022492/8100f77e-4f4e-11e6-9624-7b4aa2241394.png)

