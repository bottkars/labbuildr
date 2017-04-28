# how to run networker beta software 

labbuildr allows for unknown Networker Versions  
Therefore, simply extract your binaries to the _nwunknown_ folder:  

# update to latest labbuildr

```Pofwershell
./build-lab.ps1 -update -branch develop
./build-lab.ps1
```
## This Example will install a Beta Version of Networker on a 2016core:
( replace Destination with your sourcedir /Networker/nwunknown)


```
# Expand the software
Expand-LABpackage -Archive /home/bottk/Downloads/nw_win_x64.zip -destination /home/bottk/Sources.labbuildr/Networker/nwunknown/
# Build NW Server on Server 2016 Core
./build-lab.ps1 -NWServer -defaults -nw_ver nwunknown -Master 2016core  
```

## this example builds a Exchange 2016 Server (single Node) with a NMM Beta Version:

```
# Extract the package to nmmunknown
Expand-LABpackage -Archive /home/bottk/Downloads/nmm_win_x64.zip -destination /home/bottk/Sources.labbuildr/Networker/nmmunknown/    
# Run Exchange Setup
/build-lab.ps1 -Exchange2016 -nmm  -nmm_ver nmmunknown -nw_ver nwunknown -DAG -EXNodes 1 -Master 2016 -defaults  
```