I have a recurring task where I need a bunch of Linux VMs to do a distributed binary install of ViPR SRM on them.
I solved this with yet another wrapper script using the install_centos.ps1.

It can install, start, stop and remove VMs for distributed and all-in-one setups.
You will find your install sources mounted under /mnt/SRMshare (providing you tweak the script to your system)

The challenge for me was getting different sizes on the VMs and having the prereqs for SRM install present.

Update: Installed ViPR SRM 4.0.1 on this setup.
4.0.1 by default installs the health collectors on all hosts.
Thus, increase memory for the two backends (viprsrm1 and 2) to 2 GB.

````
# Setup one or many Linux boxes to install ViPR SRM on
#

param (
	<# 
	Can be one of the following:
	    'aio'   	Setup one Centos for All-In-One installation
	    'distrib'   Setup four Centos for distributed install:
					   viprsrm0 - XL - Frontend
					   viprsrm1 -  L - Prim Backend
					   viprsrm2 -  L - Additional Backend
					   viprsrm3 - XL - Collector
    #>
	[ValidateSet('aio','distrib','nothing')]$Type="nothing",
	[ValidateSet('remove','install','fixme','start','stop','none')]$Action="none"
	  );

function Wait-VMXStatus
{
	param(
		[Parameter(Mandatory=$true)][object]$vmx,
		[Parameter(Mandatory=$true)][string]$state
		)
	$vmx_act=Get-VMX -vmxname $vmx.vmxname
    do 
	{
		$vmx_act=Get-VMX -vmxname $vmx.vmxname
		$vmxname=$vmx_act.vmxname
		$vmxstate=$vmx_act.state
		write-output "VM $vmxname is in state of $vmxstate, waiting for it to be $state"
		sleep 5
	}
	while ($vmx_act.state -NotMatch $state)
}

if($Type -eq 'nothing')
{
	write-output "choose an install type (aio or distrib)"
	exit 1
}
if($Action -eq 'none')
{
	write-output "choose an action: start/stop/install/remove"
	exit 1
}

if($Action -eq 'start')
{
	if($Type -eq 'distrib')
	{
		get-vmx|where vmxname -like "viprsrm?" | start-vmx
	}
	if($Type -eq 'aio')
	{
		get-vmx|where vmxname -match viprsrmaio0| start-vmx
	}
    # we don't want to install the thing
	exit 0
}

if($Action -eq 'stop')
{
	if($Type -eq 'distrib')
	{
		get-vmx|where vmxname -like "viprsrm?" | stop-vmx
	}
	if($Type -eq 'aio')
	{
		get-vmx|where vmxname -match viprsrmaio0| stop-vmx
	}
    # we don't want to install the thing
	exit 0
}

if($Action -eq 'install')
{
    if($Type -eq 'aio')
    {
	    ./install-centos.ps1 -Defaults -centos_ver 7_1_1511 -Nodeprefix viprsrmaio -ip_startrange 99 -startnode 0 -nodes 1 -size XL
	    $vm=get-vmx | where vmxname -eq viprsrmaio0
	    $vm|stop-vmx
	    Wait-VMXStatus -vmx $vm -state "stopped"
	    $vm|set-vmxmemory -MemoryMB 6144
	    $vm | start-vmx
	    Wait-VMXStatus -vmx $vm -state "running"
	    $vm|Set-VMXSharedFolder -add -Sharename SRMShare -Folder C:\Users\schnem4\Documents\70-Software\SRM_W4N
	    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "yes|yum install unzip libaio bindutils"
	    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "rm /etc/localtime;ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime"
	    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "/usr/bin/vmware-toolbox-cmd timesync enable"
    }
    
    if($Type -eq 'distrib')
    {
	    ./install-centos.ps1 -Defaults -centos_ver 7_1_1511 -Nodeprefix viprsrm -ip_startrange 110 -startnode 0 -nodes 4 -size M
	    for($i=0;$i -le 3;$i++)
	    {
		    $vm = get-vmx | where vmxname -eq viprsrm$i
		    if( ($i -eq 0) -or ($i -eq 3) )
		    {
			    $vm | stop-vmx
			    Wait-VMXStatus -vmx $vm -state "stopped"
			    $vm = get-vmx | where vmxname -eq viprsrm$i
			    $vm |set-vmxmemory -MemoryMB 4096
			    $vm | start-vmx
			    Wait-VMXStatus -vmx $vm -state "running"
		    }
		    $vm | Set-VMXSharedFolder -add -Sharename SRMShare -Folder C:\Users\schnem4\Documents\70-Software\SRM_W4N
		    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "yes|yum install unzip libaio bindutils"
		    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "rm /etc/localtime;ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime"
		    $vm | Invoke-VMXBash -Guestuser root -Guestpassword Password123! -Scriptblock "/usr/bin/vmware-toolbox-cmd timesync enable"
	    }
    }
}

if($Action -eq 'remove')
{
    if($Type -eq 'aio')
    {
	    $vm=get-vmx | where vmxname -eq viprsrmaio0
		$vm | stop-vmx
		$vm | remove-vmx
	}
    if($Type -eq 'distrib')
    {
	    for($i=0;$i -le 3;$i++)
	    {
		    $vm = get-vmx | where vmxname -eq viprsrm$i
			$vm | stop-vmx
			$vm | remove-vmx
		}
	}
}

if($Action -eq 'fixme')
{
}
````
