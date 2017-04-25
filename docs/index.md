
![logo](https://cloud.githubusercontent.com/assets/8255007/17669992/3d3a18ba-6310-11e6-829a-2d8fc7995712.jpg)  


## About
labbuildr is a Framework based upon vmxtookit.  
labbuildr allows on demand creation of lab environments  
labbuildr deploys the folowing scenarios:  
  - Exchange / Exchange DAG 2010,2013,2016  
  - SQL / SQL Always on 2012,2014,2016  
  - Hyper-V  
  - Standalone VM´s  
  - Sharepoint  
  - Mastering ESXi Installs  
  - Automating EMC ScaleIO Installs  
  - DELL|EMC Isilon  
  - Networker  
  - Avamar  
  - System Center    
  .....
 


## Update    
to update from labbuildr harmony release, run update:   
build-lab.ps1 -update  
   

## Install    

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
fo detailed installation instructions, see [Student Guide](student_guide.md)

## Directory Structure   


labbuildr --  |    
              |--scripts    
              |--labtools    
              |--vmxtoolkit    
                




## Contributing   
Please contribute in any way to the project. Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.

## Licensing   
Licensed under the Apache License, Version 2.0 (the License); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS"Â BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Support   
Please file bugs and issues at the Github issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.


