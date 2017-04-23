install-centos is used to install a new, blank centos system.  
it is a general purpose machine to be used for sdc / networker storage node / iscsi or other things.  
options to pre-install a praphical ui like cinnamon desktop are available.  
the sources directory is available via _/mnt/hgfs_   
start the installer with  
```Powershell
.\install-centos.ps1 -Defaults -centos_ver 7
```
this will launch the centos install. if no master is available for $MasterPath, labbuildr will ask for download ( remember, -confirm:$false will do without asking )  
![image](https://cloud.githubusercontent.com/assets/8255007/17127022/a2d2bf10-5302-11e6-989e-4b614c80aeb7.png)
once the master is extracted an prepared, the vm will be prepared and boot for customization

![image](https://cloud.githubusercontent.com/assets/8255007/17127086/31cb1582-5303-11e6-8c23-737692475245.png)  
during the node configuration, all bash commands with return state are beeing displayed  
![image](https://cloud.githubusercontent.com/assets/8255007/17127109/689bce6c-5303-11e6-90ee-b4d1de22b77e.png)  

to view the passwords of the vm in the annotation, just enter:  
```Powershell
Get-VMX .\Centos1\ | Get-VMXAnnotation
```
![image](https://cloud.githubusercontent.com/assets/8255007/17129181/e9da5e18-5311-11e6-9d41-468719266a10.png)

passwordless authentication is supported vi ssh rsa keys. see https://community.emc.com/blogs/bottk/2016/01/31/labbuildrthe-hidden-secrets-connect-linux-vm-with-putty-and-private-key


## options
```Powershell
SYNTAX
    C:\labbuildr2016\install-centos.ps1 -Defaults [-Disks <Int32>] [-centos_ver <String>] [-Desktop <String>] [-Nodes <Int32>] [-Startnode
    <Int32>] [-Defaultsfile <Object>] [-forcedownload] [-ip_startrange <Int32>] [-WhatIf] [-Confirm] [<CommonParameters>]

    C:\labbuildr2016\install-centos.ps1 [-Disks <Int32>] [-centos_ver <String>] [-Desktop <String>] [-Sourcedir <Object>] [-Nodes <Int32>]
    [-Startnode <Int32>] [-subnet <IPAddress>] [-BuildDomain <String>] [-vmnet <Object>] [-forcedownload] [-ip_startrange <Int32>] [-WhatIf]
    [-Confirm] [<CommonParameters>]
```

```
OPTIONS
	  -Defaults 
	  [-Disks <Int32>] 
	  [-centos_ver <String>] 
	      Centos Version to use. 
		  Must correlate with version of an available source master
	  [-Desktop <String>] 
	      What desktop to install.
		  Can be "cinnamon" or "none" (default: "none")
	  [-Nodes <Int32>] 
	      Number of nodes to install. Default is 1
	  [-Startnode <Int32>] 
	      Start numbering the nodes at this number.
	  [-Defaultsfile <Object>] 
	  [-forcedownload] 
	  [-ip_startrange <Int32>] 
	      Last octet of the ip address which to assign to the nodes.
		  First ip assigned will be ip_startrange+startnode.
		  I.e. if you start at startnode=1 and ip_startrange=100,
		  the first IP will be X.X.X.101
		  If you think this to be too confusing, just start your nodes at 0
	  [-docker] 
	  [-Size <Object>] 
	      Choose a size for the VM. 
		  See source code of build-lab for sizes and what they mean.
	  [-WhatIf] 
	      Does nothing. Not found in source code.
	  [-Confirm] 
	  [<CommonParameters>]
```