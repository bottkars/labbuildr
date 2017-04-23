##about
install-esxiova.ps1 installs nested ESX Servers using  William Lam´s templates from [VirtuallyGhetto](http://www.virtuallyghetto.com/2015/12/deploying-nested-esxi-is-even-easier-now-with-the-esxi-virtual-appliance.html)    
the installation is in 2 steps:
* download and Import template
* install machine(s)

##Import
to download and Import the ova, simply enter
```Powershell
.\install-esxova.ps1  -nestedesx_ver Nested_ESXi6.5 -import
```
this will browse @lamw´s blog for the latest template version (hostet on VMware download site)
if not locally available, the template will be downloaded  
the OVA will be imported using vmxtoolkit features

![import_esxova](https://cloud.githubusercontent.com/assets/8255007/17780246/f9601cea-656a-11e6-991d-a935376939b2.gif)


##Install
the install utilizes labbuildr default environment to prepopulate the guestconfig.  
to start the Installation, use
```Powershell
.\install-esxova.ps1 -nestedesx_ver Nested_ESXi6.5 -Nodes 3
```
this example installs 3 nodes.   
![nested_esxi_3_nodes](https://cloud.githubusercontent.com/assets/8255007/17780248/fce5219e-656a-11e6-9439-14fcd4925267.gif)

##Syntax
`
SYNTAX
    D:\ProjectDODO\install-esxiova.ps1 [-nestedesx_ver <String>] [-Mastername <String>] [-Disks <Int32>] [-Size <Object>] [-Nodes <Int32>]
    [-Defaults] [-subnet <IPAddress>] [-Sourcedir <Object>] [-Masterpath <Object>] [<CommonParameters>]

    D:\ProjectDODO\install-esxiova.ps1 [-ovf <String>] [-nestedesx_ver <String>] [-Mastername <String>] [-Disks <Int32>] [-Size <Object>]
    [-Nodes <Int32>] [-Defaults] [-subnet <IPAddress>] [-Sourcedir <Object>] [-Masterpath <Object>] [<CommonParameters>]

    D:\ProjectDODO\install-esxiova.ps1 -import [-nestedesx_ver <String>] [-Mastername <String>] [-Disks <Int32>] [-Size <Object>] [-Nodes
    <Int32>] [-Defaults] [-subnet <IPAddress>] [-Sourcedir <Object>] [-Masterpath <Object>] [<CommonParameters>]

    D:\ProjectDODO\install-esxiova.ps1 [-nestedesx_ver <String>] [-Mastername <String>] [-Disks <Int32>] [-Startnode <Int32>] [-Size <Object>]
    [-Nodes <Int32>] [-Defaults] [-subnet <IPAddress>] [-VMnet <Object>] [-Sourcedir <Object>] [-Masterpath <Object>] [<CommonParameters>]
