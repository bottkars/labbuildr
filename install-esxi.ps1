[CmdletBinding()]
Param(

[Parameter(Mandatory=$false)][int32]$Nodes =1,
[Parameter(Mandatory=$false)][int32]$Startnode = 1,
[Parameter(Mandatory=$False)][int32]$Disks = 1,
[Parameter(Mandatory=$False)][ValidateSet('36GB','72GB','146GB')][string]$Disksize = "146GB",
[Parameter(Mandatory=$False)]$Subnet = "10.10.0",
[Parameter(Mandatory=$False)][ValidateLength(1,1)][Validatepattern('[A-Z]')][String]$Driveletter = $env:SystemDrive,
[Parameter(Mandatory=$False)][ValidatePATTERN("[a-zA-Z]")][string]$Builddomain = "labbuildr",
[Parameter(Mandatory=$false)][ValidateScript({ Test-Path -Path $_ -PathType Leaf -Include "ESX*labbuildr-ks.iso" -ErrorAction SilentlyContinue })]$esxiso = "c:\sources\esx\ESXi-5.5.0-1331820-labbuildr-ks.iso",
[Parameter(Mandatory=$true)][ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]$ESXIMasterPath = '.\VMware ESXi 5',
[Parameter(Mandatory = $false)][ValidateSet('vmnet1', 'vmnet2','vmnet3')]$vmnet = "vmnet2",
[Parameter(Mandatory = $false)][switch]$kdriver

)
#requires -version 3.0
#requires -module vmxtoolkit 
$Driveletter = $Driveletter.Substring(0,1)
$Mountroot = $Driveletter.ToUpper() + ":"
[string]$Sources = "Sources"
$Sourcedir = "$Mountroot\$Sources"
$Nodeprefix = "ESXiNode"
$MasterVMX = get-vmx -path $ESXIMasterPath


if (!$MasterVMX.Template) 
    {
    write-verbose "Templating Master VMX"
    $template = $MasterVMX | Set-VMXTemplate
    }
$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"

if (!$Basesnap) 
    {
    Write-verbose "Base snap does not exist, creating now"
    $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
    }

####Build Machines#

foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
    Write-Verbose "Checking VM $Nodeprefix$node already Exists"
    If (!(get-vmx $Nodeprefix$node))
    {
    # $Config = $config | ForEach-Object { $_ -replace "lsilogic" , "pvscsi" }
    Write-Verbose "Creating Kickstart CD"
    Write-Verbose "Clearing out old content"
    if (Test-Path .\iso\ks) { Remove-Item -Path .\iso\ks -Recurse }
    $KSDirectory = New-Item -ItemType Directory .\iso\KS
    
    $Content = Get-Content .\Scripts\ESX\KS.CFG
    ####modify $content
    $Content = $Content | where {$_ -NotMatch "network"}
    $Content += "network --bootproto=static --device=vmnic0 --ip=$subnet.8$Node --netmask=255.255.255.0 --gateway=$Subnet.103 --nameserver=$Subnet.10 --hostname=$Nodeprefix$node.$Builddomain.local"
    $Content += "keyboard German"
    
        foreach ( $Disk in 1..$Disks)
        {
        write-Verbose "Customizing Datastore$Disk"
        $Content += "partition Datastore$Disk@$Nodeprefix$node --ondisk=mpx.vmhba1:C0:T$Disk"+":L0"
        }
    # $Content += Get-Content .\Scripts\ESX\KS_PRE.cfg
    ### everything here goes to pre
    # $Content += "timezone Europe/Berlin" 
    #>

    $Content += Get-Content .\Scripts\ESX\KS_POST.cfg
    ### everything here goes to post
    
    if ($kdriver.IsPresent)
    {
    write-verbose "injecting K-Driver"
    $Content += "cp -a /vmfs/volumes/mpx.vmhba32:C0:T0:L0/KS/KDRIVER.VIB /vmfs/volumes/Datastore1@$Nodeprefix$node"
    Get-ChildItem "$Sourcedir\ESX\kdriver_RPESX-00.4.2*.vib" | Sort-Object -Descending | Select-Object -First 1 | Copy-Item -Destination .\iso\KS\KDRIVER.VIB
    }

    

    $Content += Get-Content .\Scripts\ESX\KS_FIRSTBOOT.cfg

 if ($kdriver.IsPresent)
    {
     $Content += "esxcli software acceptance set --level=CommunitySupported"
     $Content += "esxcli software vib install -v /vmfs/volumes/Datastore1@$Nodeprefix$node/KDRIVER.VIB"
    }
    $Content += "cp /var/log/hostd.log /vmfs/volumes/Datastore1@$Nodeprefix$node/firstboot-hostd.log"
    $Content += "cp /var/log/esxi_install.log /vmfs/volumes/Datastore1@$Nodeprefix$node/firstboot-esxi_install.log" 
    $Content += Get-Content .\Scripts\ESX\KS_REBOOT.cfg
    ######

    $Content += Get-Content .\Scripts\ESX\KS_SECONDBOOT.cfg
    #### finished
    $Content | Set-Content $KSDirectory\KS.CFG 

    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Host -ForegroundColor Yellow "Kickstart Config:"
    $Content | Write-Host -ForegroundColor DarkGray
    pause
    }
    
    ####create iso, ned to figure out license of tools
   

    # Uppercasing files for joliet
    Get-ChildItem $KSDirectory -Recurse | Rename-Item -newname { $_.name.ToUpper() } -ErrorAction SilentlyContinue


    ####have to work on abs pathnames here

    write-verbose "Cloning $Nodeprefix$node"
    $NodeClone = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base" | New-VMXClone -CloneName $Nodeprefix$node 
    $Config = Get-VMXConfig -config $NodeClone.config

    
    
    .\DiscUtilsBin-0.10\ISOCreate.exe "$($NodeClone.path)\ks.iso" .\iso\ | Out-Null
    
    Write-Verbose "Creating Disks"

  <#
    foreach ( $Disk in 1..$Disks)
        {
        $Diskpath = "$($NodeClone.Path)\0_"+$Disk+"_100GB.vmdk"
        Write-Verbose "Creating Disk # $Disk"
        & $VMWAREpath\vmware-vdiskmanager.exe -c -s 100GB -a lsilogic -t 0 $Diskpath 2>&1 | Out-Null
        $AddDrives  = @('scsi0:'+$Disk+'.present = "TRUE"')
        $AddDrives += @('scsi0:'+$Disk+'.deviceType = "disk"')
        $AddDrives += @('scsi0:'+$Disk+'.fileName = "0_'+$Disk+'_100GB.vmdk"')
        $AddDrives += @('scsi0:'+$Disk+'.mode = "persistent"')
        $AddDrives += @('scsi0:'+$Disk+'.writeThrough = "false"')
        $Config += $AddDrives
        }
   #>
   
   
   


    Write-Verbose "Creating Disks"

  
    foreach ($Disk in 1..$Disks)
        {
     if ($Disk -le 6)
        {
        $SCSI = 0
        $Lun = $Disk
        }
     if (($Disk -gt 6) -and ($Disk -le 14))
        {
        $SCSI = 0
        $Lun = $Disk+1
        }
     if (($Disk -gt 14) -and ($Disk -le 21))
        {
        $SCSI = 1
        $Lun = $Disk-15
        }
     if (($Disk -gt 21) -and ($Disk -le 29))
        {
        $SCSI = 1
        $Lun = $Disk-14
        }
     if (($Disk -gt 29) -and ($Disk -le 36))
        {
        $SCSI = 2
        $Lun = $Disk-30
        }
     if (($Disk -gt 36) -and ($Disk -le 44))
        {
        $SCSI = 2
        $Lun = $Disk-29
        }
     if (($Disk -gt 44) -and ($Disk -le 51))
        {
        $SCSI = 3
        $Lun = $Disk-45
        }
     if (($Disk -gt 51) -and ($Disk -le 59))
        {
        $SCSI = 3
        $Lun = $Disk-44
        }

        Write-Verbose "SCSI$($Scsi):$lun"
        $Diskname = "SCSI$SCSI"+"_LUN$LUN"+"_$Disksize.vmdk"
        $Diskpath = "$($NodeClone.Path)\$Diskname"
        Write-Verbose "Creating Disk #$Disk with $Diskname and a size of $Disksize"
        & $VMWAREpath\vmware-vdiskmanager.exe -c -s $Disksize -a lsilogic -t 0 $Diskpath 2>> error.txt
        
        $AddDrives  = @('scsi'+$scsi+':'+$LUN+'.present = "TRUE"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.deviceType = "disk"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.fileName = "'+$Diskname+'"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.mode = "persistent"')
        $AddDrives += @('scsi'+$scsi+':'+$LUN+'.writeThrough = "false"')
        $Config += $AddDrives
        }
    
    $Config | set-Content -Path $NodeClone.Config
    write-verbose "Setting NICs"
    #Set-VMXNetworkAdapter -Adapter 0 -ConnectionType hostonly -AdapterType vmxnet3 -config $NodeClone.Config
    # if ($vmnet)
    #     {
    #      Write-Verbose "Configuring NIC 2 and 3 for $vmnet"
    #      Set-VMXNetworkAdapter -Adapter 1 -ConnectionType custom -AdapterType vmxnet3 -config $NodeClone.Config 
         write-verbose "Setting NIC0"
         Set-VMXNetworkAdapter -Adapter 0 -ConnectionType custom -AdapterType e1000 -config $NodeClone.Config 
         Set-VMXVnet -Adapter 0 -vnet $vmnet -config $NodeClone.Config 
    #     Set-VMXVnet -Adapter 2 -vnet $vmnet -config $NodeClone.Config

    #    }
    $Scenario = Set-VMXscenario -config $NodeClone.Config -Scenarioname ESXi -Scenario 6
    $ActivationPrefrence = Set-VMXActivationPreference -config $NodeClone.Config -activationpreference $Node 
    Write-Verbose "Starting $Nodeprefix$node"
    # Set-VMXVnet -Adapter 0 -vnet vmnet2
    Set-VMXDisplayName -config $NodeClone.Config -Value "$($NodeClone.CloneName)@$Builddomain"
    start-vmx -Path $NodeClone.Path -VMXName $NodeClone.CloneName
    } # end check vm
    else
    {
    Write-Verbose "VM $Nodeprefix$node already exists"
    }
    }






