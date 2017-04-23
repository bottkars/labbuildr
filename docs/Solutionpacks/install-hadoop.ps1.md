## install-hadoop

install-haddop installs a default hadoop setup in your vmware workstation, based upon centos7
to start the installation, simply run
```Powershell
.\install-hadoop.ps1 -Defaults
```
if no operating system master for centos is found, it will be downloaded automatically from labbuildr repo on azure.  
haddop will be loaded from the hadoop repo with the latest/specified version
once the linked clone is created, the basic node configuration is started
![image](https://cloud.githubusercontent.com/assets/8255007/17024223/6236d166-4f57-11e6-8900-bbd89493784d.png)
once the node setup is complete, the hadoop configuration starts
![image](https://cloud.githubusercontent.com/assets/8255007/17024795/854fecee-4f59-11e6-9602-772cd8f3c53a.png)
connect to the ressourcemanager ui:
![image](https://cloud.githubusercontent.com/assets/8255007/17024147/0b528cf0-4f57-11e6-8247-bf0e1f5702f7.png)
or to the namenode:
![image](https://cloud.githubusercontent.com/assets/8255007/17024424/233c7316-4f58-11e6-86a0-6b9b57a20e5c.png)
