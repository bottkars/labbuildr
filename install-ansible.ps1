<#
.Synopsis
   .\install-scaleio.ps1
.DESCRIPTION
  install-centos7_4scaleio is  the a vmxtoolkit solutionpack for configuring and deploying centos VM´s for ScaleIO Implementation

      Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
.LINK
   https://github.com/bottkars/labbuildr/wiki/install-ansible.ps1
.EXAMPLE
#>
[CmdletBinding(DefaultParametersetName = "install",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
Param(
	[Parameter(ParameterSetName = "install",Mandatory=$False)]
	[ValidateRange(1,3)]
	[int32]$Disks = 1,
	[Parameter(ParameterSetName = "install",Mandatory = $false)]
	[ValidateSet('Centos7_1_1511','Centos7_1_1503')]
	[string]$centos_ver = "Centos7_1_1511",
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[ValidateRange(1,1)]
	[int32]$Nodes=1,
	[Parameter(ParameterSetName = "install",Mandatory=$false)]
	[int32]$Startnode = 1,
	[int]$ip_startrange = 248,
    <#
    Size
    'XS'  = 1vCPU, 512MB
    'S'   = 1vCPU, 768MB
    'M'   = 1vCPU, 1024MB
    'L'   = 2vCPU, 2048MB
    'XL'  = 2vCPU, 4096MB 
    'TXL' = 4vCPU, 6144MB
    'XXL' = 4vCPU, 8192MB
    #>
	[ValidateSet('XS', 'S', 'M', 'L', 'XL','TXL','XXL')]$Size = "XL",
	$Nodeprefix = "ansible",
	$DNS_DOMAIN_NAME = "$($Global:labdefaults.BuildDomain).$($Global:labdefaults.Custom_DomainSuffix)",
	[switch]$Defaults
)
#requires -version 3.0
#requires -module vmxtoolkit
if ($Defaults.IsPresent)
	{
	Deny-LABDefaults
	Break
	}
$Logfile = "/tmp/labbuildr.log"
If ($ConfirmPreference -match "none")
    {$Confirm = $false}
else
    {$Confirm = $true}
$Builddir = $PSScriptRoot
$Scriptdir = Join-Path $Builddir "labbuildr-scripts"
$ip_startrange = $ip_startrange+$Startnode
$OS = "Centos"
[System.Version]$subnet = $Global:labdefaults.MySubnet
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
$rootuser = "root"
$Guestpassword = "Password123!"
$Guestuser = 'labbuildr'
[uint64]$Disksize = 100GB
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$machinesBuilt = @()
foreach ($Node in $Startnode..(($Startnode-1)+$Nodes))
    {
		$IP = "$subnet.$ip_startrange"
		Write-Verbose "will use IP $IP"
        Write-Host -ForegroundColor White "Checking for $Nodeprefix$node"
        If (!(get-vmx $Nodeprefix$node -WarningAction SilentlyContinue))
        {
		$Host_Name = "$Nodeprefix$node"
        Write-Host -ForegroundColor Gray "==>Creating $host_name"
		$Lab_VMX = New-LabVMX -CentOS -CentOS_ver $centos_ver -Size $Size -SCSI_DISK_COUNT $Disks -SCSI_DISK_SIZE $Disksize -VMXname $Nodeprefix$Node -SCSI_Controller 0
	    $Global:labdefaults.AnsiblePublicKey = ""
		$Annotation = $Lab_VMX | Set-VMXAnnotation -Line1 "rootuser:$Rootuser" -Line2 "rootpasswd:$Guestpassword" -Line3 "Guestuser:$Guestuser" -Line4 "Guestpassword:$Guestpassword" -Line5 "labbuildr by @sddc_guy" -builddate
		$Lab_VMX | Set-LabCentosVMX -ip $IP -CentOS_ver $centos_ver -Additional_Epel_Packages ansible -Host_Name $Host_Name
		##

		Write-Host -ForegroundColor Gray " ==>installing ansible"
        $Scriptblock = "yum install ansible python-devel krb5-devel krb5-libs krb5-workstation python-pip build-essential libssl-dev libffi-dev python-dev python-cffi -y"
        $LAB_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null
		
		$Scriptblock = ("cat >> /etc/krb5.conf <<EOF
[realms]`
 $($DNS_DOMAIN_NAME.ToUpper()) = {`
    kdc = $($Global:labdefaults.BuildDomain)dc.$DNS_DOMAIN_NAME`
 }`
`
[domain_realm]`
    .$($DNS_DOMAIN_NAME.tolower()) = $($DNS_DOMAIN_NAME.toupper())`
")
        $LAB_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

		$Scriptblock = 'pip install "pywinrm>=0.1.1" kerberos requests_kerberos python-openstackclient'
		$LAB_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

		$Scriptblock = ("mkdir /etc/ansible/group_vars;cat >> /etc/ansible/group_vars/windows.yml <<EOF
# created by labbuildr`
ansible_user: Administrator@$($DNS_DOMAIN_NAME.toupper())`
ansible_password: Password123!`
ansible_port: 5986`
ansible_connection: winrm`
ansible_winrm_server_cert_validation: ignore`
")
		$LAB_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword | Out-Null

		#### retrieving guest_rsakey
		Write-Host -ForegroundColor Gray " ==>retrieving root key for ansible"
		$Scriptblock = '/usr/sbin/vmtoolsd --cmd="info-set guestinfo.ROOT_PUBLIC_KEY $(cat /root/.ssh/id_rsa.pub)"'
		Write-Verbose $Scriptblock
		$Bashresult = $Lab_VMX | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $Rootuser -Guestpassword $Guestpassword # -logfile $Logfile
		$Public_Key = $Lab_VMX | Get-VMXVariable -GuestVariable ROOT_PUBLIC_KEY
		Set-LABAnsiblePublicKey -AnsiblePublicKey $Public_Key.ROOT_PUBLIC_KEY
        }
	}	
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
write-Host -ForegroundColor White "Login to the VM´s with root/Password123!"

