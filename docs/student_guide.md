![image](https://cloud.githubusercontent.com/assets/8255007/17090840/d67ee196-5234-11e6-84f0-bb85aa812fc1.png) 
use this ip address ( or MySubnet.4) with your browser to connect to the admin interface 
![image](https://cloud.githubusercontent.com/assets/8255007/17090880/2e162586-5235-11e6-8c5f-fd0dcf0e55fb.png)  
Login to the ui an be done with your Webbrowser with user root/Password123!  
## 1.3.2 Build a domain controller
to build the domain controller, follow
[Build-lab.ps1 -DConly](https://github.com/bottkars/labbuildr/wiki/build-lab.ps1---DConly)
# 2.0 Managing VM´s  
get a list of all all labbuildr commands  
```Powershell
get-command -module labtools
```
getting a list of running vm´s  
```Powershell
get-vmx | where state -Match running  | ft
```

