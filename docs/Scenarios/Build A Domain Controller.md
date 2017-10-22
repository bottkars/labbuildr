## This guide describes how to build a Domaincontroller with labbuildr

```Powershell
   .\build-lab.ps1 [-DConly] [-defaults] [-Toolsupdate] [-Master <String>] [-Masterpath <Object>] [-Gateway] [-VMnet
    <Object>] [-Size <Object>] [-BuildDomain <String>] [-NW] [-nw_ver <Object>] [-NoDomainCheck] [-MySubnet <Object>] [-AddressFamily
    <Object>] [-IPV6Prefix <Object>] [-IPv6PrefixLength <Object>] [-Sourcedir <String>] [-USE_SOURCES_ON_SMB] [-WhatIf] [-Confirm]
    [<CommonParameters>]
```


The easiest way to install a domaincontroller is by running 
```Powershell
./build-lab.ps1 -DConly
```
All required Parameters for networking will be taken from labdefaults

