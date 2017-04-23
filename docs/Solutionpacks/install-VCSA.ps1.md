##about
intsall-vcsa will install a vCenter Server Virtual Appliance on VMware Workstation.  
It will utilize labbuildr dfault vlues to integrate into your Environment.  
It is a 2 Step process:
* Import the OVA from Template to create a Master 
* Create a VCSA Appliance from Master

##Import the OVA
Prior Import, you Need to download the [VCSA Appliance ISO from VMware](https://my.vmware.com/de/web/vmware/details?productId=491&downloadGroup=VC60U2)   ( Login required )   
once downloaded, extract the VMware-vcsa file and save it with Extension.ova  
![image](https://cloud.githubusercontent.com/assets/8255007/17770991/12cda41a-6541-11e6-81df-97c0b676c564.png)
run
```Powershell
.\install-vcsa.ps1 -ovf C:\Sources\vmware-vcsa.ova
```
![import-vcsa](https://cloud.githubusercontent.com/assets/8255007/17772123/4856fc7a-6547-11e6-8c5c-4a83c980e9b2.gif)  

##Install VCSA Node
```Powershell
.\install-vcsa.ps1 -Masterpath c:\SharedMaster -Mastername vmware-vcsa
```
![install-vcsa](https://cloud.githubusercontent.com/assets/8255007/17772592/f324f6f0-6549-11e6-80e7-b06656f82c5f.gif)
once installed, give it 10 minutes to configure / warm up.
the systgem is ready once you see the Login Screen
![image](https://cloud.githubusercontent.com/assets/8255007/17772660/4fe21a44-654a-11e6-997d-cf2d23ac209a.png)  
you can no browse to the welcome page   
##Welcome Page  
![image](https://cloud.githubusercontent.com/assets/8255007/17772700/94d9f41e-654a-11e6-9184-e6f1f0476f99.png)


##Login page
Connect to the System using the proposed credentials: Username "Administrator@labbuildr.vmware.local" Password "Password123!"

![image](https://cloud.githubusercontent.com/assets/8255007/17772719/b068c746-654a-11e6-8f77-8bb672a8b998.png)
You may now customize your Vcenter for your needs

![image](https://cloud.githubusercontent.com/assets/8255007/17770692/69625b42-653f-11e6-84ee-679982517342.png)  

Special thanks to @liamw for his awesoome work.
See http://www.virtuallyghetto.com/ for all his stuff on automating VMware vCenter / ESX