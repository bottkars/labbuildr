# how to run networker beta software 

labbuildr allows for unknown Networker Versions
Therefore, simply extract your binaries to the nwunknown folder:
## This Example will install a Beta Version of Networker on a 2016core:
( replace Destination with your sourcedir /Networker/nwunknown)

```Powershell
./build-lab.ps1 -update -branch develop
./build-lab.ps1
Expand-LABpackage -Archive /home/bottk/Downloads/nw_win_x64.zip -destination /home/bottk/Sources.labbuildr/Networker/nwunknown/
./build-lab.ps1 -NWServer -defaults -nw_ver nwunknown -Master 2016core  
```
