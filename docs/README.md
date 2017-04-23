
![logo](https://cloud.githubusercontent.com/assets/8255007/17669992/3d3a18ba-6310-11e6-829a-2d8fc7995712.jpg)  
:new: **NEW BETA ARRIVED FOR OSX and LINUX [wiki for details](https://github.com/bottkars/labbuildr/wiki/NEW-BETA-LABBUILDR-LINUX-OSX)**   
labbuildr 2016-3 3rd Anniversary   
=======

labbuildr is a Framework based upon vmxtookit.
labbuildr allows on demand creation of lab environments
labbuildr deploys the folowing scenarios:
  - Exchange / Exchange DAG 2010,2013,2016
  - SQL / SQL Always on 2012,2014,2016
  - Hyper-V
  - Standalone VMÂ´s
  - Mastering ESXi Installs
  - Automating EMC ScaleIO Installs
 

  
Labbuildr requires dowload of a prebuilt sources.vhd and prebuilt os masters.
See https://github.com/bottkars/labbuildr/wiki/Master for details

For the 2016 release, the following changes applied to labbuildr:

- seperation of scripts to labbuildr-scripts
- this allows scripts to be used independant  
- new scenarios
- new 2016 Support
- Support for Syctr TP4 ( SCOM and SCVMM )
- Support for Spaces Direct ( currently with Blank Nods Scenario )
Currently Prared for testing:
- Hyper-V
- SCOM
- SQL
- Exchange 2016
- Networker   
Currently not tested / ported
A SOFS   

Update    
========
to update from labbuildr harmony release, run update for 3 times:   
build-lab.ps1 -updatefromgit   
build-lab.ps1 -updatefromgit -branch master      
build-lab.ps1 -update -branch master   


Install    
=========

it is not recommended to use git for installing labbuildr.
labbuildr comes with its own installer:

### Fully automated Installation from powershell
````Powershell
$Uri = "https://gist.githubusercontent.com/bottkars/410fe056809c38d96562/raw/install-labbuildr.ps1"
$DownloadLocation = "$Env:USERPROFILE\Downloads"
$File = Split-Path -Leaf $Uri
$OutFile = Join-Path $DownloadLocation $File
Invoke-WebRequest -Uri $Uri -OutFile $OutFile
Unblock-File -Path $Outfile
Invoke-Expression $OutFile
````


Directory Structure   
=========

labbuildr --  |    
              |--scripts    
              |--labtools    
              |--vmxtoolkit    
                




Contributing   
==========
Please contribute in any way to the project. Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.

Licensing   
==========
Licensed under the Apache License, Version 2.0 (the License); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS"Â BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Support   
==========
Please file bugs and issues at the Github issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.


