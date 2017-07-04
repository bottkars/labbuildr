# this guide describes how to deploy A scom testbed using the EMC Storage Integrator
![image](https://user-images.githubusercontent.com/8255007/27825344-7a20d604-60af-11e7-9509-3bca5efd693b.png)  

follow the deployment, and choose some otional hosts/Storage Devices to install:

<script src="https://gist.github.com/bottkars/b28326bb6b0595192508530777abed84.js"></script>


after the ESI Powershell is installed, verify the service is up and Running

![image](https://user-images.githubusercontent.com/8255007/27819069-cc536502-6098-11e7-8aa0-448266ed8c66.png)

browse to https://localhost:54501/esi/console to view the Service for you webbrowser

Adding systems ( on Controller node, EG, Blanknode ):

## Add add UnityVSA to ESI Service:


first, verify connection with uemcli
```Powershell
uemcli.exe -d 192.168.2.171 -u admin -p Password123! /sys/soft/ver show -detail
```

Add the System
```Powershell
$params = @{"Username"="admin";"Password"="Password123!";"ManagementIp"="192.168.2.171"};
Add-EmcSystem -SystemType Unity -Params $params -UserFriendlyName UnityVSA
```
## add a ScaleIO System
```Powershell
$params = @{"Username"="admin";"Password"="Password123!";"IpAddress"="192.168.2.153"};
Add-EmcSystem -SystemType ScaleIO -Params $params -UserFriendlyName SIO_HyperV
```
![image](https://user-images.githubusercontent.com/8255007/27827573-3155cfac-60b8-11e7-9ba7-281210b115fa.png)

verify the system has added to the ESI Console with  https://localhost:54501/esi/console


![image](https://user-images.githubusercontent.com/8255007/27827635-81338956-60b8-11e7-9f39-0c0b3aacd92f.png)

Now proceed with the install of the SCOM Management Packs on SCOM Host
```Powershell
Start-Process msiexec.exe -ArgumentList "/i `"\\vmware-host\shared Folders\sources\esi\ESI.SCOM.ManagementPacks.5.0.1.3.Setup\ESI.SCOM.ManagementPacks.5.0.1.3.Setup.msi`" /passive /log c:\scripts\esilog" -Wait -PassThru
```
## On the SCOM Server
### install management packs
Open SCOM Powershell to import the Management Packs into SCOM
```Powershell
Get-SCOMManagementPack -ManagementPackFile 'C:\Program Files (x86)\EMC\ESI SCOM Management Packs\*.*'
Import-SCOMManagementPack -Fullname 'C:\Program Files (x86)\EMC\ESI SCOM Management Packs\*.*'
```
### deploy Management Agent to ESI Controller
```Powershell
$PrimaryMgmtServer = Get-SCOMManagementServer -ComputerName "SCOM.labbuildr.local"
Install-SCOMAgent -DNSHostName "gennode1.labbuildr.local" -PrimaryManagementServer $PrimaryMgmtServer
```
### edit regitry on ESI Host for Store Maximum
```Powershell
Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Services\HealthService\Parameters -Value 0x00001400 -Type dword -name "Persistence Version Store Maximum"
Restart-Service HealthService
```

### create object discovery override for ESI Host


In SCOM Management Console, go to 
--> Authoring --Discovery
and search for EMC SI Sevice Discovery
right click on Overrides, Override the Object Discovery, for a specific Object of Class Windows Computer
![image](https://user-images.githubusercontent.com/8255007/27821583-0e74879a-60a3-11e7-81a3-f584e962b067.png)
Select teh ESI Controller host
Adjust the Values

![image](https://user-images.githubusercontent.com/8255007/27821818-e368af3a-60a3-11e7-9d66-8d41160eb8af.png)

Wait some time for the Discovery Cycles to Fully discover your ESI Environment
