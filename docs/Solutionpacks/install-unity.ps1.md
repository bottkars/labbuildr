## install-unity
install-unity is the import / installation tool for emc unity vsa   
## requirements  
> Processor          : 2  
Memory             : 12288  
VirtualMemory      : 12562  
PhysicalMemory     : 8095     

 
the installation runs in 3 steps
* [import](https://github.com/bottkars/labbuildr/wiki/install-unity.ps1#import)  
* [install](https://github.com/bottkars/labbuildr/wiki/install-unity.ps1#install)  
* [initial setup wizard](https://github.com/bottkars/labbuildr/wiki/install-unity.ps1#starting-the-initial-installation-wizard)

also, view the [options](https://github.com/bottkars/labbuildr/wiki/install-unity.ps1#options) for unity install  
for labbuildr windows machines, there is a powershell script to configure iSCSI  
* [labbuildr-iscsi](https://github.com/bottkars/labbuildr/wiki/install-unity.ps1#labbuildr-iscsi)   

## import  
you must download you version of unity vsa from http://www.emc.com/products-solutions/trial-software-download/unity-vsa.htm  
a login / registration is required for download, that is why an automatic download is not provided. 
once the download has finished, simply enter
```Powershell
.\install-unity.ps1 -ovf D:\EMC_VAs\UnityVSA-4.0.0.7329527.ova
```
where -ovf specifies the path to your downloaded OVA file

labbuildr then uses vmxtoolkit to convert the OVA image to a vmware workstation format. you can ignore the warnings

![image](https://cloud.githubusercontent.com/assets/8255007/17103322/17b92e8e-527e-11e6-9e26-560b8059eff5.png)

once finished, the command to continue with install is displayed
## fully automated install ( configures System with user / Password / eula )

for easy install, just use
```Powershell
.\install-unity.ps1 -Defaults -configure 
```
you may also add an existing lic file if you re-install a previous registered system
```Powershell
.\install-unity.ps1 -Defaults -configure -Lic_file D:\Downloads\564D1FA6-F3C4-A7BC-EC74-D7943BC7ABB
A_2777136_15-Jul-2016.lic
```
![unity_labbuildr_way](https://cloud.githubusercontent.com/assets/8255007/17815471/bc0112f8-6634-11e6-9b5d-df075bdd10f4.gif)
## install
for easy install, just use
```Powershell
.\install-unity.ps1 -Defaults
```
a new linked clone is created, drives are added ( a default of 2 drives, may be customized )

![image](https://cloud.githubusercontent.com/assets/8255007/17103417/7b6a2816-527e-11e6-9da7-69a5d8960707.png)

allow for the vm to boot, than start with the displayed confif commands on the vm console.
from the console, login with service/service and run    
```bash
svc_initial_config -4 "192.168.2.85 255.255.255.0 192.168.2.4"
```
where adding your specific IP requirements

the command may fail, if the system is not fully initialized. Just wait some more minites and repeat  
![image](https://cloud.githubusercontent.com/assets/8255007/17103703/eeeabe76-527f-11e6-8c06-04ef201aee98.png)  
once the configuration was sucessfull, you can proceed with your browser to configure unity 
![image](https://cloud.githubusercontent.com/assets/8255007/17103809/68ef5d30-5280-11e6-8aa1-65a9c2a71bdb.png)
  
### starting the initial installation wizard
login to https://unity_ip:443 with admin/Password123#

![image](https://cloud.githubusercontent.com/assets/8255007/17103898/d51ac1fc-5280-11e6-97f7-c340c3524e2e.png)

the installation wizard will welcome you   
![image](https://cloud.githubusercontent.com/assets/8255007/17126207/44063540-52fb-11e6-8c4f-89b95b3ecea0.png)   
Accept the license agreement   
![image](https://cloud.githubusercontent.com/assets/8255007/17126228/76a4b6d4-52fb-11e6-9672-74c9413dd866.png)  
change your password (s)   
![image](https://cloud.githubusercontent.com/assets/8255007/17126237/9070af1e-52fb-11e6-815e-1630f287db54.png)
upload your licensefile
![image](https://cloud.githubusercontent.com/assets/8255007/17126241/98f1e31a-52fb-11e6-974f-154e8e554f57.png)
view results
![image](https://cloud.githubusercontent.com/assets/8255007/17126245/a5f93ef0-52fb-11e6-82c7-04477b04b654.png)  
continue to with the wizard
![image](https://cloud.githubusercontent.com/assets/8255007/17126253/bc8dab88-52fb-11e6-9ba8-19b114facf1f.png)

add your dns servers  
![image](https://cloud.githubusercontent.com/assets/8255007/17126259/c568380e-52fb-11e6-9bc7-11ba1dea7695.png)  
proceed to create pools  
![image](https://cloud.githubusercontent.com/assets/8255007/17126268/e0a57226-52fb-11e6-9851-afbda60a1c5f.png)



specify a name for the new pool to be created
![image](https://cloud.githubusercontent.com/assets/8255007/17126452/bf2357b0-52fd-11e6-9e24-82b1532fdca3.png)  
assign available drives to their tiers
![image](https://cloud.githubusercontent.com/assets/8255007/17126613/1b533c3e-52ff-11e6-88db-b2419d7ba699.png)
and then select a tier from the abvailable tiers
![image](https://cloud.githubusercontent.com/assets/8255007/17126642/4f4834ea-52ff-11e6-96bf-a8a7934376dc.png)  
select the virtual disks to use  
![image](https://cloud.githubusercontent.com/assets/8255007/17126655/7e058710-52ff-11e6-8dae-28c8c2b66918.png)  
review your selection  
![image](https://cloud.githubusercontent.com/assets/8255007/17126663/8aca18bc-52ff-11e6-866b-655d519ce0f9.png)  
wait for the pool wizard to finish creation    
![image](https://cloud.githubusercontent.com/assets/8255007/17126674/a499625c-52ff-11e6-88b2-47c64cee7dc2.png)  
procced to next step
![image](https://cloud.githubusercontent.com/assets/8255007/17126680/ae0fa148-52ff-11e6-92be-d1f03ca6d24b.png)  
click the + sign to add iSCSI interfaces
![image](https://cloud.githubusercontent.com/assets/8255007/17126699/d19c2af0-52ff-11e6-8636-a6cdad2873e3.png)  
fill in the information, this example  is a labbuildr default setup:
![image](https://cloud.githubusercontent.com/assets/8255007/17126707/e558bca2-52ff-11e6-8c5c-38151d435ac4.png)  
finish the iSCSI Wizard
we skip the nas wizard for now and quit to get to the Unity Dashboard  
![image](https://cloud.githubusercontent.com/assets/8255007/17126875/76027af8-5301-11e6-8191-465b2390ddc0.png)

## labbuildr-iscsi
to enable / register iscsi targets with your labbuildr [windows] hosts, a helper script is available. open a labbuildr command prompt from the desktop link.cd into the node directoy and run  
```Powershell
.\enable-labiscsi.ps1 -target_ip 192.168.2.201
```
where target_ip should represent the Target IP you specified for unity.  
proceed in your unisphere management station.
##register initiator
go to access-->iscsi. you should see your newly registered iscsi connection(s)
![image](https://cloud.githubusercontent.com/assets/8255007/17141183/7b2c9424-534b-11e6-891b-06db37479695.png)  
from access-->host add a new iSCSI host:  
enter the host name  
![image](https://cloud.githubusercontent.com/assets/8255007/17142115/3a513366-534f-11e6-937a-4d97abab33a7.png)  
specify type an ip address  
![image](https://cloud.githubusercontent.com/assets/8255007/17142149/5b684698-534f-11e6-822e-fd465ba95376.png)  
select initiator from the list  
![image](https://cloud.githubusercontent.com/assets/8255007/17142184/76d2221e-534f-11e6-8530-feba01cf88f3.png)  
review settings and finish   
![image](https://cloud.githubusercontent.com/assets/8255007/17142254/bb6fd56a-534f-11e6-83e8-7b196c40fbc8.png)  
once completed, the initiatore is registered and ready to acces luns
![image](https://cloud.githubusercontent.com/assets/8255007/17142298/e72d583a-534f-11e6-974e-885df599a507.png)  
the initiator should have a green checkmark now  
![image](https://cloud.githubusercontent.com/assets/8255007/17142303/ec4a9404-534f-11e6-80ba-7e228068e949.png)

##create and map lun(s)
in the unity ui go to storage-->block-->LUNs and click the + sign  
enter lun name and description  
![image](https://cloud.githubusercontent.com/assets/8255007/17150425/b670660e-536f-11e6-937f-4971fc11c3eb.png)  
select pool and size  
![image](https://cloud.githubusercontent.com/assets/8255007/17150650/8523213a-5370-11e6-8a44-7da66bfcb6e2.png)  
in configure access, add desired host  
![image](https://cloud.githubusercontent.com/assets/8255007/17150699/b98547b4-5370-11e6-8981-f18cec8cc139.png)  

finish the wizard without adding replica´s or snapshots´s   
![image](https://cloud.githubusercontent.com/assets/8255007/17150913/93a2ddee-5371-11e6-829d-89de8c3825ca.png)

from the host, use diskpart/powershel/diskmgmt.msc to add the new disk




##options

Fully Automated installs require an existing license. The Fully Automated installs can pre-Configure Hosts, LUN and NAS Servers for Cifs and NFS, and pre -register iSCSI Hosts. This can be usefull in conjunction with other Scenario´s, such as Exchange 2016 or OpenStack.


Example 
```Powershell
 .\install-unity.ps1 -Defaults -MasterPath C:\Users\bottk\Master.labbuildr\UnityVSA-4.0.1.8404134\ -Lic_file .\564d9f7d-aa2a-deb6-569c-fdaa02d2e732_2871812_24-Oct-2016.lic -configure -Disks 6 -iscsi_hosts E2016 -Protocols iscsi
```
this will configure a unity System including iSCSI Target Port
-iscsi_hosts will configure a set of Example Hosts and Luns ( DCnode, Exchange 2016, AlwaysOn )

![image](https://cloud.githubusercontent.com/assets/8255007/19850476/fa0ba09c-9f58-11e6-8259-ea9372c331e4.png)


```
Powershell
SYNTAX
    C:\labbuildr2016\install-unity.ps1 [-Disks <Int32>] [<CommonParameters>]

    C:\labbuildr2016\install-unity.ps1 -ovf <String> [-Mastername <String>] [-MasterPath <Object>] [-Disks <Int32>] [<CommonParameters>]

    C:\labbuildr2016\install-unity.ps1 -Mastername <String> -MasterPath <Object> [-subnet <IPAddress>] [-BuildDomain <String>] [-VMnet
    <Object>] [-Disks <Int32>] [<CommonParameters>]

    C:\labbuildr2016\install-unity.ps1 [-Mastername <String>] [-MasterPath <Object>] -Defaults [-Defaultsfile <Object>] [-Disks <Int32>]
    [<CommonParameters>]
```