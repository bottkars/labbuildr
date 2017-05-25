## install-scaleiosvm   

![image](https://cloud.githubusercontent.com/assets/8255007/17015009/11a78116-4f28-11e6-8255-c8ded6529acc.png)

install-scaleiosvm installs a 3-Node ScaleIO Cluster based upon the ScaleIO VMware Storage Virtual Machine ( SVM ).  
the process is devided in 2 steps:
* [import](http://labbuildr.readthedocs.io/en/latest/Solutionpacks//install-scaleiosvm.ps1#import)
* [install](http://labbuildr.readthedocs.io/en/latest/Solutionpacks//install-scaleiosvm.ps1#install)

## import  

we import the SVM with 
```Powershell
.\install-scaleiosvm.ps1 -import
```
labbuildr will select the sourcedir from defaults as well as the master directory  
if no svm to import is found, you will be asked fro download ( can be surpressed with -confirm:$false )
![image](https://cloud.githubusercontent.com/assets/8255007/17014178/723d85d4-4f23-11e6-9902-6f07029a45d5.png)

the download i then started by using the labbuildr command receive-labscaleio

![image](https://cloud.githubusercontent.com/assets/8255007/17014288/1ee2a4f4-4f24-11e6-8970-17ce85e6d507.png)  

during the import, you may see some warnings from the ova tool, you can just ignore them. 
when the import is successfull, the command for creating a default ScaleIO Cluster  is presented:

![image](https://cloud.githubusercontent.com/assets/8255007/17014369/8937e4ae-4f24-11e6-9e04-7509cecafe44.png)
 
## install 
the installaion is started with 
```Powershell
.\install-scaleiosvm.ps1 -ScaleIOMaster C:\SharedMaster\ScaleIOVM_2nics_2.0.6035.0
```
labbuildr will first will check for the specified master and cerate a base snapshot.
after the basesnapshot is done, 3 VM´s are cerated, and each get a default of 3 additional diskdrives

![image](https://cloud.githubusercontent.com/assets/8255007/17014512/3c8c9072-4f25-11e6-95fe-94dad028c770.png)

in the node configuration sequence, labbuildr will show the commands issued to the nodes for base configuration and scaleio software installation  
![image](https://cloud.githubusercontent.com/assets/8255007/17014792/dc52ed8a-4f26-11e6-9a70-064997d7739a.png)

in the configure scaleio section, a Default Scaleio Cluster is created

all commands issued are shown in the output
![image](https://cloud.githubusercontent.com/assets/8255007/17014930/90edbfb8-4f27-11e6-862d-eb1a86fbfb5a.png)
thw comlete installation shouls be donw within 6 Minutes:

![image](https://cloud.githubusercontent.com/assets/8255007/17014987/ed79e248-4f27-11e6-9741-432deb766c86.png)



![image](https://cloud.githubusercontent.com/assets/8255007/17015009/11a78116-4f28-11e6-8255-c8ded6529acc.png)


