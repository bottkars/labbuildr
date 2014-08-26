Add-WindowsFeature dhcp -IncludeManagementTools
Add-DhcpServerv4Scope -StartRange 10.10.0.250 -EndRange 10.10.0.253 -Name Scope-PXE -SubnetMask 255.255.255.0 -LeaseDuration 0.1:0:0 -State Active -Type Dhcp
Set-DhcpServerv4OptionValue -ScopeId 10.10.0.0 -OptionId 3 -Value 10.10.0.103
Set-DhcpServerv4OptionValue -ScopeId 10.10.0.0 -OptionId 6 -Value 10.10.0.10  -Force
Set-DhcpServerv4OptionValue -ScopeId 10.10.0.0 -OptionId 15 -Value labbuildr.local -Force
Add-DhcpServerInDC -DnsName labbuildr.local




Add-WindowsFeature WDS -IncludeManagementTools


Mount-DiskImage -ImagePath C:\images\\Windows_BMR_Wizard_x64_WinPE5-7.1.100-302.iso -StorageType ISO


Import-WdsBootImage -Path E:\sources\Boot.wim -NewImageName "Avamar BMR x64" –SkipVerify
DisMount-DiskImage -ImagePath C:\images\\Windows_BMR_Wizard_x64_WinPE5-7.1.100-302.iso

Mount-DiskImage -ImagePath C:\images\NetWorker_8.2.0.445_Windows_BMR_Wizard_x64_WinPE_50.iso -StorageType ISO
Import-WdsBootImage -Path E:\sources\Boot.wim -NewImageName "Networker BMR x64" –SkipVerify
Mount-DiskImage -ImagePath C:\images\NetWorker_8.2.0.445_Windows_BMR_Wizard_x64_WinPE_50.iso