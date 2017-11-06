This is an example to create a windows master for labbuildr

```Powershell
$winserviso = Receive-LABWinservISO -Destination $labdefaults.Sourcedir -winserv_ver 2016 -lang en_US  
$newvmx = New-VMX -VMXName 2016_1705 -Type Server2016 -Firmware EFI  
$disk = New-VMXScsiDisk -NewDiskSize 200GB -NewDiskname disk0 -Path $newvmx.Path  
$disk | Add-VMXScsiDisk -VMXName $newvmx.VMXName -config $newvmx.Config -LUN 0 -Controller 0 -VirtualSSD | Out-Null 
$newvmx | Connect-VMXcdromImage -ISOfile $winserviso.fullname -Contoller sata -Port 0:1 | Out-Null  
$newvmx | start-vmx | Out-Null  
```


Download

![image](https://user-images.githubusercontent.com/8255007/32428375-a937399c-c2c5-11e7-8fd6-57ad5c289e16.png)


Once the master is created, connect to git to download:

https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/Server2016.xml
https://raw.githubusercontent.com/bottkars/labbuildr-scripts/master/labbuildr-scripts/Sysprep/prepare.ps1
