This is an example to create a  ( no Preview ) windows master for labbuildr

```Powershell
$winserviso = Receive-LABWinservISO -Destination $labdefaults.Sourcedir -winserv_ver 2016 -lang en_US  
$newvmx = New-VMX -VMXName 2016_1705 -Type Server2016 -Firmware EFI  
$disk = New-VMXScsiDisk -NewDiskSize 200GB -NewDiskname disk0 -Path $newvmx.Path  
$disk | Add-VMXScsiDisk -VMXName $newvmx.VMXName -config $newvmx.Config -LUN 0 -Controller 0 -VirtualSSD | Out-Null 
$newvmx | Connect-VMXcdromImage -ISOfile $winserviso.fullname -Contoller sata -Port 0:1 | Out-Null  
$newvmx | Set-VMXNetworkAdapter -Adapter 0 -AdapterType vmxnet3 -ConnectionType bridged
$newvmx | start-vmx | Out-Null  
```


Download

![image](https://user-images.githubusercontent.com/8255007/32428375-a937399c-c2c5-11e7-8fd6-57ad5c289e16.png)

Install vmware tools with setup64.exe 

Once the master is created, connect to git to download:
```Powershell
$sysprep = 'C:\sysprep'
New-Item -ItemType Directory $sysprep -Force | Out-Null
Set-Location $sysprep
foreach ($uri in ("https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/Server2016.xml",
"https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/prepare.ps1"))
    {
    $file = Split-Path -Leaf $uri
    Invoke-WebRequest -Uri $uri -OutFile (Join-Path $sysprep $file)
    }
./prepare.ps1
```


Once done with teh Master Creation delete all files except the VMDK and vmx, and remove all UUID, Bios and MAC information fromn the .vmx ( or use the templates here: 
https://raw.githubusercontent.com/bottkars/labbuildr/master/labbuildr/template/WS_1709.template
(rename to .vmx)
)

Pack thee complete folder into a 7z and place the file into Master.Labbuildr folder.

Labbuildr will catchup from there



## Creating a Preview Master 
Preview Masters require one initial step
1. Prepare Base Machine: 
```Powershell
# you have to download the iso file for preview from Server insider
# you have do download the iso file for WS 1709 from MSDN or Volume License

[System.IO.FileInfo]$winserviso = "$HOME/Downloads/Windows_InsiderPreview_Server_16278.iso"
$Winserv = 'WS_Preview_RS4'
$newvmx = New-VMX -VMXName $Winserv -Type Server2016 -Firmware EFI  
$disk = New-VMXScsiDisk -NewDiskSize 200GB -NewDiskname disk0 -Path $newvmx.Path  
$disk | Add-VMXScsiDisk -VMXName $newvmx.VMXName -config $newvmx.Config -LUN 0 -Controller 0 -VirtualSSD | Out-Null 
$newvmx | Connect-VMXcdromImage -ISOfile $winserviso.fullname -Contoller sata -Port 0:1 | Out-Null  
$newvmx | Set-VMXNetworkAdapter -Adapter 0 -AdapterType vmxnet3 -ConnectionType bridged
$newvmx | start-vmx | Out-Null  
```

Once host has configured, enter powershell into the cmd shell to start powershell

once in Powershell, run  
```Powershell
Disable-Ual
```

2. Inject vmware tools cd, run 

once in Powershell, run  
```Powershell
d:\setup64.exe
```

reboot VM when install has finished.

Now start Powershell again and Run:
```Powershell
$sysprep = 'C:\sysprep'
New-Item -ItemType Directory $sysprep -Force | Out-Null
Set-Location $sysprep
foreach ($uri in ("https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/Server2016.xml",
"https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/prepare.ps1"))
    {
    $file = Split-Path -Leaf $uri
    Invoke-WebRequest -Uri $uri -OutFile (Join-Path $sysprep $file)
    }
./prepare.ps1
```

Once done with teh Master Creation delete all files except the VMDK and vmx, and remove all UUID, Bios and MAC information fromn the .vmx ( or use the templates here: 
https://raw.githubusercontent.com/bottkars/labbuildr/master/labbuildr/template/WS_Preview_RS4.template
(rename to .vmx)
)

Pack thee complete folder into a 7z and place the file into Master.Labbuildr folder.

Labbuildr will catchup from there