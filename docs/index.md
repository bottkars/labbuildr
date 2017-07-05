
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
to update from labbuildr from prevoious release, run update:   
build-lab.ps1 -update  
   

## Install    

labbuildr can be installed using PowershellGet. If you are note running Windows 10, install PowershellGet from
[Powershell Gallery](https://www.powershellgallery.com)

![Installation via Powershell Get](https://user-images.githubusercontent.com/8255007/27817547-0991ef12-6092-11e7-9f57-0860e5cb6c83.png)
### Fully automated Installation Using Powershell Get Method
```Powershell
Install-Script install-labbuildr -Force -Scope CurrentUser
install-labbuildr.ps1 -branch master
```


### Fully automated Installation from powershell Using Download Method
```Powershell
$Uri = "https://gist.githubusercontent.com/bottkars/410fe056809c38d96562/raw/install-labbuildr.ps1"
$DownloadLocation = "$Env:USERPROFILE\Downloads"
$File = Split-Path -Leaf $Uri
$OutFile = Join-Path $DownloadLocation $File
Invoke-WebRequest -Uri $Uri -OutFile $OutFile
Unblock-File -Path $Outfile
Invoke-Expression $OutFile
```
fo detailed installation instructions, see [Student Guide](student_guide.md)

## Directory Structure   


labbuildr --  |    
              |--labbuildr-scripts    
              |--labtools    
              |--vmxtoolkit    
                




## Contributing   
Please contribute in any way to the project. Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.

## Licensing   
Licensed under the Apache License, Version 2.0 (the License); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS"Â BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Support   
Please file bugs and issues at the Github issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.


