<#
.Synopsis
   labbuildr allows you to create Virtual Machines with VMware Workstation from Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM, SCaleIO, OneFS
.DESCRIPTION
   labbuildr is a Self Installing Lab tool for Building VMware Virtual Machines on VMware Workstation
      
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
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
.EXAMPLE
    build-lab.ps1 -createshortcut
    Creates a Desktop Shortcut for labbuildr
.EXAMPLE
    PS F:\labbuildr_beta> .\build-lab.ps1 -HyperV -ScaleIO -clusteredmdm -Disks 3 -defaults -SCVMM -ConfigureVMM -Sourcedir G:\Sources
    installs a Hyper-V Cluster with 3 Nodes, ScaleIO MDM, SDS,SDC deployed, SCVMM will be deployed on node 3
.EXAMPLE
    .\build-lab.ps1 -defaults -DConly -NW  
    Builds a DC along with Networker Server
.EXAMPLE
    .\build-lab.ps1 -defaults -HV -ScaleIO -singlemdm -NMM 
     Builds a HyperV Cluster with Scaleio in Single MDM Mode and NMM Modules 
.EXAMPLE
    .\build-lab.ps1 -defaults -DAG -EXNodes 1 -NMM 
    Builds a single-node Exchange DAG  
.EXAMPLE
    .\build-lab.ps1 -defaults -Sharepoint  
    Builda a Sharepoint Foundation with integrated SQL Server
#>
[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <#
    run build-lab version    #>
	[Parameter(ParameterSetName = "version",Mandatory = $false, HelpMessage = "this will update labbuildr")][switch]$version,
    <# 

    <#
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will update labbuildr")][switch]$Update,
    <# 
    create deskop shortcut
    #>	
    [Parameter(ParameterSetName = "shortcut", Mandatory = $false)][switch]$createshortcut,
    <#
    Installs only a Domain Controller. Domaincontroller normally is installed automatically durin a Scenario Setup
    IP-Addresses: .10
    #>	
	[Parameter(ParameterSetName = "DConly")][switch][alias('dc')]$DConly,	
    <#
    Selects the Always On Scenario
    IP-Addresses: .160 - .169
    #>
	[Parameter(ParameterSetName = "AAG",Mandatory = $true)][switch][alias('ao')]$AlwaysOn,
    <#
    Selects the Hyper-V Scenario
    IP-Addresses: .150 - .159
    #>
	[Parameter(ParameterSetName = "Hyperv")][switch][alias('hv')]$HyperV,
    <# 
    Exchange Scenario: Installs a Standalone or DAG Exchange 2013 Installation.
    IP-Addresses: .110 - .119
    #>
	[Parameter(ParameterSetName = "Exchange")][switch][alias('ex')]$Exchange,
    <#
    Selects the Sharepoint
    IP-Addresses: .140
    #>
	[Parameter(ParameterSetName = "Sharepoint")][switch]$Sharepoint,
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $true)][ValidateSet('BuiltIn','AlwaysOn')]$SPdbtype = "BuiltIn",
    <#
    Selects the SQL Scenario
    IP-Addresses: .130
    #>
	[Parameter(ParameterSetName = "SQL")][switch]$SQL,
    <#
    Specify if Networker Scenario sould be installed
    IP-Addresses: .103
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[switch][alias('nsr')]$NWServer,
    <#
    Installs Isilon Nodes
    IP-Addresses: .40 - .56
    #>
	[Parameter(ParameterSetName = "Isilon")]
    [switch][alias('isi')]$Isilon,
    <#
    Selects the Storage Spaces Scenario, still work in progress
    IP-Addresses: .170 - .179
    #>
	[Parameter(ParameterSetName = "Spaces")][switch]$Spaces,
    <#
    Selects the Syncplicity Panorama Server
    IP-Addresses: .15
    #>
	[Parameter(ParameterSetName = "Panorama")][switch][alias('pn')]$Panorama,
    <#
    Selects the Blank Nodes Scenario
    IP-Addresses: .180 - .189
    #>
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bn')]$Blanknode,
    <#
    Selects the SOFS Scenario
    IP-Addresses: .210 - .219
    #>
    [Parameter(ParameterSetName = "SOFS")][switch]$SOFS,
    #### scenario options #####
    <#
    Determines if Exchange should be installed in a DAG
    #>
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)][switch]$DAG,
    <# Specify the Number of Exchange Nodes#>
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)][ValidateRange(1, 10)][int][alias('exn')]$EXNodes = "1",
    <# Specify the Starting exchange Node#>
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)][ValidateRange(1, 9)][int][alias('exs')]$EXStartNode = "1",
	<#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'cu1','cu2','cu3','cu4','sp1','cu6','cu7'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
    [ValidateSet('cu1', 'cu2', 'cu3', 'sp1','cu5','cu6','cu7','cu8','cu9')]$ex_cu,
    <# schould we prestage users ? #>	
    [Parameter(ParameterSetName = "Exchange", Mandatory = $false)][switch]$nouser,
    <# Install a DAG without Management IP Address ? #>
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)][switch]$DAGNOIP,
    <# Specify Number of Spaces Hosts #>
    [Parameter(ParameterSetName = "Spaces", Mandatory = $false)][ValidateRange(1, 2)][int]$SpaceNodes = "1",
    <# Specify Number of Hyper-V Hosts #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 9)][int][alias('hvnodes')]$HyperVNodes = "1",
	<# ScaleIO on hyper-v #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch][alias('sc')]$ScaleIO,
	<# ScaleIO on hyper-v #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][string][ValidateSet('1.30-426.0','1.31-258.2','1.31-1277.3','1.31-2333.2','1.32-277.0','1.32-402.1')][alias('siover')]$ScaleIOVer,
    <# single mode with mdm only on first node ( no secondary, no tb ) #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$singlemdm,
    <# Cluster modemdm automatically#>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$clusteredmdm,
    <# SCVMM on last Node ? #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$SCVMM,
    <# Starting Node for Blank Nodes#>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$ConfigureVMM,
    <# Starting Node for Blank Nodes#>
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 9)][alias('bs')]$Blankstart = "1",
    <# How many Blank Nodes#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 10)][alias('bns')]$BlankNodes = "1",
    <# Wich Number of isilon Nodes #>
    [Parameter(ParameterSetName = "Isilon")]
	[ValidateRange(2, 16)][alias('isn')]$isi_nodes = 2,
    <# Wich ISIMASTER to Pick #>
   	[Parameter(ParameterSetName = "Isilon")]
	[ValidateSet('ISIMASTER')]$ISIMaster,
    <# How many SOFS Nodes#>
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)][ValidateRange(1, 10)][alias('sfn')]$SOFSNODES = "1",
    <# Starting Node for SOFS#>
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)][ValidateRange(1, 9)][alias('sfs')]$SOFSSTART = "1",  
    <# Specify the Number of Always On Nodes#>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)][ValidateRange(1, 5)][int][alias('aan')]$AAGNodes = "2",
    <#
    'SQL2012SP1',SQL2012SP2,SQL2012SP1SLIP, 'SQL2014'
    SQL version to be installed
    Needs to have:
    [sources]\SQL2012SP1 or
    [sources]\SQL2014
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[ValidateSet('SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014')]$SQLVER,
    <# Wich version of OS Master should be installed
    '2012R2FallUpdate','2012R2U1MASTER','2012R2MASTER','2012R2UMASTER','2012MASTER','2012R2UEFIMASTER','vNextevalMaster','RELEASE_SERVER'
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [ValidateSet('2012R2FallUpdate','2012R2UMASTER','2012R2MASTER','2012MASTER','2012R2U1MASTER','2012R2UEFIMASTER','vNextevalMaster','RELEASE_SERVER')]$Master,
    <#do we want a special path to the Masters ? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ })]$Masterpath,
    <# Do we want Additional Disks / of additional 100GB Disks for ScaleIO. The disk will be made ready for ScaleIO usage in Guest OS#>	
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 6)][int][alias('ScaleioDisks')]$Disks,
      <#
    Enable the default gateway 
    .103 will be set as default gateway, NWserver will have 2 Nics, NIC2 Pointing to NAT serving as Gateway
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [switch][alias('gw')]$IsGateway,
<# select vmnet, number from 1 to 19#>                                        	
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)][ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet,

 #   [Parameter(Mandatory = $false, HelpMessage = "Enter a valid VMware network Number vmnet between 1 and 19 ")]
<# This stores the defaul config in defaults.xml#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$savedefaults,

<# reads the Default Config from defaults.xml
<config>
<nmm_ver>nmm82</nmm_ver>
<nw_ver>nw82</nw_ver>
<master>2012R2UEFIMASTER</master>
<sqlver>SQL2014</sqlver>
<ex_cu>cu6</ex_cu>
<vmnet>2</vmnet>
<BuildDomain>labbuildr</BuildDomain>
<MySubnet>10.10.0.0</MySubnet>
<AddressFamily>IPv4</AddressFamily>
<IPV6Prefix>FD00::</IPV6Prefix>
<IPv6PrefixLength>8</IPv6PrefixLength>
<NoAutomount>False</NoAutomount>
</config>
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
   	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$defaults,
<# Specify if Machines should be Clustered, valid for Hyper-V and Blanknodes Scenario  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$Cluster,
<#
Machine Sizes
'XS'  = 1vCPU, 512MB
'S'   = 1vCPU, 768MB
'M'   = 1vCPU, 1024MB
'L'   = 2vCPU, 2048MB
'XL'  = 2vCPU, 4096MB 
'TXL' = 2vCPU, 6144MB
'XXL' = 4vCPU, 6144MB
'XXXL' = 4vCPU, 8192MB
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "Spaces", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL', 'TXL', 'XXL', 'XXXL')]$Size = "M",
	
<# Specify your own Domain name#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain,
	
<# Turn this one on if you would like to install a Hypervisor inside a VM #>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$VTbit,
		
####networker 	
    <# install Networker Modules for Microsoft #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NMM,
    <#
Version Of Networker Modules
'nmm300','nmm301','nmm2012','nmm3012','nmm82'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateSet('nmm8212','nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82','nmm85','nmm85.BR1','nmm85.BR2','nmm85.BR3')]
$nmm_ver,
	
<# Indicates to install Networker Server with Scenario #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NW,
    <#
Version Of Networker Server / Client to be installed
'nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81', 'nwunknown'
mus be extracted to [sourcesdir]\[nw_ver], ex. c:\sources\nw82
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [ValidateSet('nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nwunknown')]
    $nw_ver,

### network Parameters ######

<# Disable Domainchecks for running DC
This should be used in Distributed scenario´s
 #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [switch]$NoDomainCheck,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
      [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Validatepattern(‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’)]$MySubnet,

<# Specify your IP Addressfamilie/s
Valid values 'IPv4','IPv6','IPv4IPv6'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
      [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily, 

<# Specify your IPv6 ULA Prefix, consider https://www.sixxs.net/tools/grh/ula/  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [ValidateScript({$_ -match [IPAddress]$_ })]$IPV6Prefix,

<# Specify your IPv6 ULA Prefix Length, #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    $IPv6PrefixLength,
<# 
Specify the Path to your Sources 
Example[Driveletter]:\Sources, eg. USB Device, local drive c
Sources should be populated from a bases sources.zip
#>
	#[Parameter(ParameterSetName = "default", Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Validatescript({Test-Path -Path $_ })][String]$Sourcedir,
<# Turn on Logging to Console#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Exchange", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[switch]$ConsoleLog
) # end Param

#requires -version 3.0
#requires -module vmxtoolkit
#requires -module labtools 
###################################################
### VMware Master Script
### Karsten Bott
### 09.08 Added -action Switch
### 11.08.added First Time VMware Start vor Master to be imported
### 12.08.2013 Added vmx Evaluation upon Memory
### 07.10.2013. Official release 1.0
### 08.10.2013 Cosmetical firstrun.pass fix for onerroraction
### 30.10.2013 Added SQL
### 30.10.2013 Added Online Update
### 30.10.2013 Added Console Logging
### 30.10.2013 Function Cleanup, started re-writeing for Log Functions
### 30.10.2013 changed checkuser to tes-user
### 30.10.2013 Added Advanced Mount Script
### 30.10.2013 New VHD for SQL, WAIK and SCVMM
### 03.11.2013 Munt-Routine completly Wre-Written tocheck for valid Mount Mountdrives
### 14.01.2014 Lots of Changes: Support for NMM Version, NW Versions and CU Versions. Starting / Stopping/Pausing/Resumiong of VM´s and many more
### 06.03.2014 Major Release networker2go
### 24.03.2014 Major release 2.5
### 08.04.2014 Finished SQL 2014, included always on for 2014
### 11.06.2014 Changed  Exchange Install Scripts for flexible DAG Creation, 1 to Multi Node DAG´s
### see all new changeson git
###################################################
## COnstants to be moved to Params


###################################################
[string]$Myself = $MyInvocation.MyCommand
#$AddressFamily = 'IPv4'
$IPv4PrefixLength = '24'
$myself = $Myself.TrimEnd(".ps1")
$Starttime = Get-Date
$Builddir = $PSScriptRoot
if (!(Test-Path ($Builddir+"\labbuildr4.version")))
    {
    Set-Content -Value "00.0000" -Path ($Builddir+"\labbuildr4.version")
    }
if (!(Test-Path ($Builddir+"\vmxtoolkit.version")))
    {
    Set-Content -Value "00.0000" -Path ($Builddir+"\vmxtoolkit.version")
    }

$verlabbuildr = New-Object System.Version (Get-Content  ($Builddir + "\labbuildr4.version") -ErrorAction SilentlyContinue).Replace("-",".")
$vervmxtoolkit = New-Object System.Version (Get-Content  ($Builddir + "\vmxtoolkit.version") -ErrorAction SilentlyContinue).Replace("-",".")
$LogFile = "$Builddir\$(Get-Content env:computername).log"
$WAIKVER = "WAIK"
$domainsuffix = ".local"
$AAGDB = "AWORKS"
$major = "4.0"
$latest_ScaleIO = '1.32-402.1'
$latest_nmm = 'nmm8212'
$latest_nw = 'nw8213'
$latest_ex = 'cu9'
$latest_sql  = 'SQL2014'
$latest_master = '2012R2FallUpdate'
$latest_sql_2012 = 'SQL2012SP2'
$NW85_requiredJava = "jre-7u61-windows-x64"
$SourceScriptDir = "$Builddir\Scripts\"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$Targetscriptdir = "C:\Scripts\"
$NodeScriptDir = "$Builddir\Scripts\Node\"
$Dots = [char]58
[string]$Commentline = "#######################################################################################################################"
$SCVMMVER = "SCVMM2012R2"
$WAIKVER = "WAIK"
#$SQLVER = "SQL2012SP1"
$DCNODE = "DCNODE"
$NWNODE = "NWSERVER"
$SPver = "SP2013SP1fndtn"
$SPPrefix = "SP2013"
$EX_Version = "E2013"
$vmxtoolkit = "vmxtoolkit.zip"
$labbuildr = "labbuildr4.zip"
$Updatefiles = ($labbuildr,$vmxtoolkit)
$UpdateUri = "https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta"
$Edition = "NWBeta"
$Sleep = 10
[string]$Sources = "Sources"
$Sourcedirdefault = "c:\Sources"
$Script_dir = "Scripts"
$Sourceslink = "https://my.syncplicity.com/share/wmju8cvjzfcg04i/sources"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "103" 
##################
### VMrun Error Condition help to tune the Bug wher the VMRUN Command can not communicate with the Host !
$VMrunErrorCondition = @("Waiting for Command execution Available", "Error", "Unable to connect to host.", "Error: The operation is not supported for the specified parameters", "Unable to connect to host. Error: The operation is not supported for the specified parameters", "Error: vmrun was unable to start. Please make sure that vmrun is installed correctly and that you have enough resources available on your system.", "Error: The specified guest user must be logged in interactively to perform this operation")
$Host.UI.RawUI.WindowTitle = "$Buildname"

[switch]$Gateway = $False


###################################################
# main function go here
###################################################
function copy-tovmx
{
	param ($Sourcedir)
	$Origin = $MyInvocation.MyCommand
	$count = (Get-ChildItem -Path $Sourcedir -file).count
	$incr = 1
	foreach ($file in Get-ChildItem -Path $Sourcedir -file)
	{
		Write-Progress -Activity "Copy Files to $Nodename" -Status $file -PercentComplete (100/$count * $incr)
		do
		{
			($cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword copyfilefromhosttoguest $CloneVMX $Sourcedir$file $TargetScriptdir$file) 2>&1 | Out-Null
			write-log "$origin $File $cmdresult"
		}
		until ($VMrunErrorCondition -notcontains $cmdresult)
		write-log "$origin $File $cmdresult"
		$incr++
	}
}

function convert-iptosubnet
{
	param ($Subnet)
	$subnet = [System.Version][String]([System.Net.IPAddress]$Subnet)
	$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
	return, $Subnet
} #enc convert iptosubnet

function copy-vmxguesttohost
{
	param ($Guestpath, $Hostpath, $Guest)
	$Origin = $MyInvocation.MyCommand
	do
	{
		($cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword copyfilefromguesttohost "$Builddir\$Guest\$Guest.vmx" $Guestpath $Hostpath) 2>&1 | Out-Null
		write-log "$origin $Guestpath $Hostpath $cmdresult "
	}
	until ($VMrunErrorCondition -notcontains $cmdresult)
	write-log "$origin $File $cmdresult"
} # end copy-vmxguesttohost

function get-update
{
	param ([string]$UpdateSource, [string] $Updatedestination)
	$Origin = $MyInvocation.MyCommand
	$update = New-Object System.Net.WebClient
	$update.DownloadFile($Updatesource, $Updatedestination)
}

function Extract-Zip
{
	param ([string]$zipfilename, [string] $destination)
	$copyFlag = 16 # overwrite = yes
	$Origin = $MyInvocation.MyCommand
	if (test-path($zipfilename))
	{		
        if (!(Test-Path $destination))
            {New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        Write-Verbose "extracting $zipfilename"
        $shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(), $copyFlag)
	}
}



function get-prereq
{ 
param ([string]$DownLoadUrl,
        [string]$destination )
$ReturnCode = $True
if (!(Test-Path $Destination))
    {
        Try 
        {
        if (!(Test-Path (Split-Path $destination)))
            {
            New-Item -ItemType Directory  -Path (Split-Path $destination) -Force
            }
        Start-BitsTransfer -Source $DownLoadUrl -Destination $destination -DisplayName "Getting $destination" -Priority Foreground -Description "From $DownLoadUrl..." -ErrorVariable err 
                If ($err) {Throw ""} 

        } 
        Catch 
        { 
            $ReturnCode = $False 
            Write-Warning " - An error occurred downloading `'$FileName`'" 
            Write-Error $_ 
        }
    }
    else
    {
    write-Warning "No download needed, file exists" 
    }
    return $ReturnCode 
}


function domainjoin
{

    param (
    $nodeIP,
    $nodename,
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
    $AddonFeatures
    )
    $Origin = $MyInvocation.MyCommand
    Write-Verbose "Configuring Node and Features"
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configurenode.ps1 -Parameter "-nodeip $Nodeip -IPv4subnet $IPv4subnet -nodename $Nodename -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily $AddGateway -AddOnfeatures '$AddonFeatures' -Domain $BuildDomain $CommonParameter" -nowait -interactive
	write-verbose "Waiting for Pass 2 (Node Configured)"
    
    do {
        $ToolState = Get-VMXToolsState -config $CloneVMX
        Write-Verbose $ToolState.State
        }
    until ($ToolState.State -match "running")

	While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\2.pass) -ne "The file exists.")
    { 
        Write-Host -NoNewline "."
        sleep $Sleep
    }
	write-host
	test-user Administrator
	do
        {
        Write-Verbose "Joining Domain $BuildDomain"
        $domainadd = invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script addtodomain.ps1 -Parameter "-Domain $BuildDomain -domainsuffix $domainsuffix -subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily" -nowait -interactive # $CommonParameter
	    Write-Host $domainadd
        }
    until ($domainadd -match "success")

    write-verbose "Waiting for Pass 3 (Domain Joined)"
    do {
        $ToolState = Get-VMXToolsState -config $CloneVMX
        Write-Verbose $ToolState.State
        }
    until ($ToolState.state -match "running")
    Write-Verbose "Paranoia, checking shared folders second time"
    Set-VMXSharedFolderState -VMXName $nodename -config $CloneVMX -enabled
    Write-Verbose "Please Check inside VM for Network Warnings"
	While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\3.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
    # Write-Host

}


function status
{
	param ([string]$message)
	write-host -ForegroundColor Yellow $message
}

function workorder
{
	param ([string]$message)
	write-host -ForegroundColor Magenta $message
}

function progress
{
	param ([string]$message)
	write-host -ForegroundColor Gray $message
}

function debug
{
	param ([string]$message)
	write-host -ForegroundColor Red $message
}

function runtime
{
	param ($Time, $InstallProg)
	$Timenow = Get-Date
	$Difftime = $Timenow - $Time
	$StrgTime = ("{0:D2}" -f $Difftime.Hours).ToString() + $Dots + ("{0:D2}" -f $Difftime.Minutes).ToString() + $Dots + ("{0:D2}" -f $Difftime.Seconds).ToString()
	write-host "`r".padright(1, " ") -nonewline
	Write-Host -ForegroundColor Yellow "$InstallProg Setup Running Since $StrgTime" -NoNewline
}

function write-log
{
	Param ([string]$line)
	$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
	Add-Content $Logfile -Value "$Logtime  $line"
}


function pause-vmx
{
	param ($vmname)
	$Origin = $MyInvocation.MyCommand
	do
	{
		($cmdresult = &$vmrun pause "$Builddir\\$vmname\\$vmname.vmx" 2>&1 | Out-Null)
		write-log "$Origin pause $vmname $cmdresult"
	}
	until ($VMrunErrorCondition -notcontains $cmdresult)
}


function unpause-vmx
{
	param ($vmname)
	$Origin = $MyInvocation.MyCommand
	do
	{
		($cmdresult = &$vmrun unpause "$Builddir\\$vmname\\$vmname.vmx" 2>&1 | Out-Null)
		write-log "$Origin unpause $vmname $cmdresult"
	}
	until ($VMrunErrorCondition -notcontains $cmdresult)
}




<#	
	.SYNOPSIS
		We test if the Domaincontroller DCNODE is up and Running
	
	.DESCRIPTION
		A detailed description of the test-dcrunning function.
	
	.EXAMPLE
		PS C:\> test-dcrunning
	
	.NOTES
		Requires the DC inside labbuildr Runspace
#>
function test-dcrunning
{
	$Origin = $MyInvocation.MyCommand
    
    if (!$NoDomainCheck.IsPresent){
	if (Test-Path "$Builddir\$DCNODE\$DCNODE.vmx")
	{
		if ((get-vmx $DCNODE).state -ne "running")
		{
			status "Domaincontroller not running, we need to start him first"
			get-vmx $DCNODE | Start-vmx  
		}
	}#end if
	else
	{
		debug "Domaincontroller not found, giving up"
		break
	}#end else
} # end nodomaincheck
} #end test-dcrunning

<#	
	.SYNOPSIS
		This Function gets IP, Domainname and VMnet from the Domaincontroller.
	
	.DESCRIPTION
		A detailed description of the test-domainsetup function.
	
	.EXAMPLE
		PS C:\> test-domainsetup
	
	.NOTES
		Additional information about the function.
#>
function test-domainsetup
{
	test-dcrunning
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Domain Name ...: "
	copy-vmxguesttohost -Guestpath "C:\$Script_dir\domain.txt" -Hostpath "$Builddir\domain.txt" -Guest $DCNODE
	$holdomain = Get-Content $Builddir"\domain.txt"
	status $holdomain
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Subnet.........: "
	copy-vmxguesttohost -Guestpath "C:\$Script_dir\ip.txt" -Hostpath "$Builddir\ip.txt" -Guest $DCNODE
	$DomainIP = Get-Content $Builddir"\ip.txt"
	$IPv4subnet = convert-iptosubnet $DomainIP
	status $ipv4Subnet

	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Default Gateway: "
	copy-vmxguesttohost -Guestpath "C:\$Script_dir\Gateway.txt" -Hostpath "$Builddir\Gateway.txt" -Guest $DCNODE
	$DomainGateway = Get-Content $Builddir"\Gateway.txt"
	status $DomainGateway

	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing VMnet .........: "
    $MyVMnet = (get-vmx .\DCNODE | Get-VMXNetwork).network
	# $Line = Select-String -Pattern "ethernet0.vnet" -Path "$Builddir\$DCNODE\$DCNODE.vmx"
	# $myline = $Line.line.Trim('ethernet0.vnet = ')
	# $MyVMnet = $myline.Replace('"', '')
	status $MyVMnet
	Write-Output $holdomain, $Domainip, $VMnet, $DomainGateway
} #end 



function test-user
{
	param ($whois)
	$Origin = $MyInvocation.MyCommand
	do
	{
		([string]$cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword listProcessesInGuest $CloneVMX)2>&1 | Out-Null
		write-log "$origin $UserLoggedOn"
		start-sleep -Seconds $Sleep
	}
	
	until (($cmdresult -match $whois) -and ($VMrunErrorCondition -notcontains $cmdresult))
	
}

function test-vmx
{
	param ($vmname)
	$return = Get-ChildItem "$Builddir\\$vmname\\$vmname.vmx" -ErrorAction SilentlyContinue
	return, $return
}

function test-source
{
	param ($SourceVer, $SourceDir)
	
	
	$SourceFiles = (Get-ChildItem $SourceDir -ErrorAction SilentlyContinue).Name
	#####
	
	foreach ($Version in ($Sourcever))
	{
		if ($Version -ne "")
		{
			write-verbose "Checking $Version"
			if (!($SourceFiles -contains $Version))
			{
				write-Host "$Sourcedir does not contain $Version"
				debug "Please Download and extraxct $Version to $Sourcedir"
				$Sourceerror = $true
			}
			else { write-verbose "found $Version, good..." }
		}
		
	}
	If ($Sourceerror) { return, $false }
	else { return, $true }
}

<#	
	.SYNOPSIS
		A brief description of the checkpoint-progress function.
	
	.DESCRIPTION
		A detailed description of the checkpoint-progress function.
	
	.PARAMETER Guestpassword
		A description of the Guestpassword parameter.
	
	.PARAMETER Guestuser
		A description of the Guestuser parameter.
	
	.PARAMETER pass
		A description of the pass parameter.
	
	.PARAMETER reboot
		A description of the reboot parameter.
	
	.EXAMPLE
		PS C:\> checkpoint-progress -Guestpassword 'Value1' -Guestuser $value2
	
	.NOTES
		Additional information about the function.
#>
function checkpoint-progress
{
	param (
        $step,
        [switch]$reboot,
        [switch]$Nowait,
        $Guestuser = $Adminuser,
        $Guestpassword = $Adminpassword
        )
	$Origin = $MyInvocation.MyCommand
    if ($reboot.IsPresent)
        {
        $AddParameter = " -reboot"
        }
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script set-step.ps1 -nowait -interactive -Parameter " -step $step $AddParameter" # $CommonParameter
	write-Host
    if (!$Nowait.IsPresent)
        {
	    write-verbose "Waiting for Checkpoint $step"
        do {
            $ToolState = Get-VMXToolsState -config $CloneVMX
            Write-Verbose $ToolState.State
            }
        until ($ToolState.state -match "running")
	    While ($FileOK = (&$vmrun -gu $Adminuser -gp $Adminpassword fileExistsInGuest $CloneVMX c:\$Script_dir\$step.pass) -ne "The file exists.") { Write-Host -NoNewline "."; write-log "$FileOK $Origin"; sleep $Sleep }
	    write-host
        }
    else
        {
        Write-Verbose "Not Waiting for Reboot"
        }
}

function CreateShortcut
{
	$wshell = New-Object -comObject WScript.Shell
	$Deskpath = $wshell.SpecialFolders.Item('Desktop')
	# $path2 = $wshell.SpecialFolders.Item('Programs')
	# $path1, $path2 | ForEach-Object {
	$link = $wshell.CreateShortcut("$Deskpath\$Buildname.lnk")
	$link.TargetPath = "$psHome\powershell.exe"
	$link.Arguments = "-noexit -command $Builddir\profile.ps1"
	#  -command ". profile.ps1" '
	$link.Description = "$Buildname"
	$link.WorkingDirectory = "$Builddir"
	$link.IconLocation = 'powershell.exe'
	$link.Save()
	# }
	
}


function invoke-postsection
    {
    param (
    [switch]$wait)
    write-verbose "Setting Power Scheme"
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script powerconf.ps1 -interactive # $CommonParameter
	write-verbose "Configuring UAC"
    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script set-uac.ps1 -interactive # $CommonParameter
    if ($wait.IsPresent)
        {
        checkpoint-progress -step UAC -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
        }
    else
        {
        checkpoint-progress step UAC -reboot -Nowait -Guestuser $Adminuser -Guestpassword $Adminpassword
        }
    }
####################################################
$newLog = New-Item -ItemType File -Path $LogFile -Force
If ($ConsoleLog) { Start-Process -FilePath $psHome\powershell.exe -ArgumentList "Get-Content  -Path $LogFile -Wait " }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    $CommonParameter = ' -verbose'
    }
if ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent)
    {
    $CommonParameter = ' -debug'
    }
####################################################

<#
###################################################
foreach ($Module in $RequiredModules){
# if(-not(Get-Module -name $Module))
#{
Write-Verbose "Loading $Module Modules"
Import-Module "$Builddir\$Module" -Force
#}
}
#>

###################################################
switch ($PsCmdlet.ParameterSetName)
{
			"update" {
                $Webrequest = Invoke-WebRequest -Uri $UpdateUri
                foreach ($Updatefile in $Updatefiles)
                {
                Write-Verbose "testing $Updatefile"
                switch ($Updatefile)
                                {
                                $labbuildr
                                    {
                                    $Currentver = $verlabbuildr
                                    }
                                $vmxtoolkit
                                    {
                                    $Currentver = $vervmxtoolkit
                                    }
                                } # end switch

				write-verbose "Checking for $Updatefile"
				if ($Link = ($Webrequest).Links | where { $_.OuterHTML -Match "$Updatefile" -and $_.Innertext -match "$Updatefile"} )
				    {
				    $uri = $link.href
				    $Updateversion = $uri.TrimStart("/servlet/JiveServlet/download/")
				    $Updateversion = $Updateversion.TrimEnd("/$updatefile")
                    $Updatever = New-Object System.Version $Updateversion.replace("-",".")
				    Write-Verbose "found  $Updatever"
                    Write-host "Comparing versions for $Updatefile"
                    Write-Host "Installed $Currentver, found $Updatever"
				    Write-Verbose "installed $Currentver"
				    Write-Verbose "comparing Versions"
                    write-verbose "Building version"
                    if ($Currentver -lt $Updatever)
				        {
                        $Isnew = $true
					    status "Downloading Update for $Updatefile, please be patient ....."
					    $Updatepath = "$Builddir\Update"
					    if (!(Get-Item -Path $Updatepath -ErrorAction SilentlyContinue))
					        {
						$newDir = New-Item -ItemType Directory -Path "$Updatepath"
					}
					    $UpdateSource = "https://community.emc.com/$uri"
					    $UpdateDestination = "$Updatepath\$Updatefile"
					    get-update -UpdateSource $UpdateSource -Updatedestination $UpdateDestination
					    switch ($Updatefile)
                            {
                                $vmxtoolkit
                                    {
                                    Extract-Zip -zipfilename "$Builddir\update\$Updatefile" -destination $Builddir\vmxtoolkit
                                    }
                                $labbuildr
                                    {
                                    Remove-Item $Builddir\Scripts -Recurse
                                    Extract-Zip -zipfilename "$Builddir\update\$Updatefile" -destination $Builddir
                                    }
                                } # end switch
                        $Part = $Updatefile.Replace(".zip","")
                        $Updatever | Set-Content ($Builddir+"\$part.version") 
					    if (Test-Path "$Builddir\deletefiles.txt")
					        {
						$deletefiles = get-content "$Builddir\deletefiles.txt"
						foreach ($deletefile in $deletefiles)
						{
							if (Get-Item $Builddir\$deletefile -ErrorAction SilentlyContinue)
							{
								Remove-Item -Path $Builddir\$deletefile -Recurse -ErrorAction SilentlyContinue
								status "deleted $deletefile"
								write-log "deleted $deletefile"
							}
						}


					}#end testpath deletfiles
				        } # end current version
				     else 
                        {
                        Status "No update required for $updatefile, already newest version "
                        }
				    }# end if updatefile
                    else
				        {
				        Write-Host "no updatefile available"
				        }#>
                } # end foreach
                if ($Isnew)
                    {
				    status "Update Done"
                    status "press any key for reloading vmxtoolkit Modules"
                    pause
                    ./profile.ps1
                    }
	return		
    } # end Update
			
			"Shortcut"{
				status "Creating Desktop Shortcut for $Buildname"
				createshortcut
                return
			}# end shortcut


			"Version" {
				Status "labbuildr version $major-$verlabbuildr $Edition"
                Status "vmxtoolkit version $major-$vervmxtoolkit $Edition"
                Write-Output '   Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.'
                 
				return
			} #end Version
}
write-verbose "Config pre defaults"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-output $PSCmdlet.MyInvocation.BoundParameters
    }
###################################################
## do we want defaults ?
if ($defaults.IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        status "Loading defaults from $Builddir\defaults.xml"
        [xml]$Default = Get-Content -Path $Builddir\defaults.xml
        $DefaultGateway = $Default.config.DefaultGateway
        if (!$nmm_ver)
            {
            $nmm_ver = $Default.config.nmm_ver
            } 
        if (!$nw_ver) {$nw_ver = $Default.config.nw_ver}
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = $Default.Config.Masterpath
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Warning "No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
       
        if (!$Sourcedir)
            {
            try
                {
                $Sourcedir = $Default.Config.Sourcedir
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Warning "No sources specified, trying default"
                $Sourcedir = $Sourcedirdefault
                }
            }

        if (!$Master) {$master = $Default.config.master}
        if (!$SQLVER) {$sqlver = $Default.config.sqlver }
        if (!$ex_cu | Out-Null) {$ex_cu = $Default.config.ex_cu}
        if (!$ScaleIOVer | Out-Null) {$ScaleIOVer = $Default.config.scaleiover}
        if (!$vmnet) {$vmnet = $Default.config.vmnet}
        # $NW = $Default.config.nw
        if (!$BuildDomain) {$BuildDomain = $Default.config.Builddomain}
        if (!$MySubnet) {$MySubnet = $Default.config.MySubnet} 
        if (!$AddressFamily) {$AddressFamily = $Default.config.AddressFamily}
        if (!$IPv6Prefix) {$IPV6Prefix = $Default.Config.IPV6Prefix}
        if (!$IPv6PrefixLength) {$IPv6PrefixLength = $Default.Config.IPV6PrefixLength}
        if (!($MyInvocation.BoundParameters.Keys.Contains("Gateway")))
            {
            
            If ($Default.Config.Gateway -eq "true" -or $IsGateway.IsPresent)
                {
                [switch]$Gateway = $True
                }
            }

        if (!($MyInvocation.BoundParameters.Keys.Contains("NMM")))
            {
            if ($Default.Config.NMM -eq "true")
                {
                $nmm = $true
                }
            }
        

        }
   
    else 
        { Write-Warning "no defaults.xml found, using labbuildr defaults" }
    }

if (!$MySubnet) {$MySubnet = "192.168.2.0"}
if (!$BuildDomain) { $BuildDomain = "labbuildr" }
if (!$ScaleIOVer) {$ScaleIOVer = $latest_ScaleIO}
if (!$nmm_ver) {$nmm_ver = $latest_nmm}
if (!$nw_ver) {$nw_ver = $latest_nw}
if (!$SQLVER) {$SQLVER = $latest_sql}
if (!$ex_cu) {$ex_cu = $latest_ex}
if (!$Master) {$Master = $latest_master}
if (!$vmnet) {$vmnet = "vmnet2"}
write-verbose "After defaults !!!! "
Write-Verbose "Noautomount: $($Noautomount.IsPresent)"
Write-Verbose "Mountroot : $Mountroot"
Write-Verbose "Sourcedir : $Sourcedir"
Write-Verbose "NWVER : $nw_ver"
Write-Verbose "Gateway : $($gateway.IsPresent)"
Write-Verbose "NMM : $($nmm.IsPresent)"
Write-Verbose "MySubnet : $MySubnet"
Write-Verbose "ScaleIOVer : $ScaleIOVer"
Write-Verbose "Masterpath : $Masterpath"
Write-Verbose "Defaults before Safe:"
$IPv4Subnet = convert-iptosubnet $MySubnet

        If ($gateway.ispresent -and (!($DefaultGateway)) -or $IsGateway.IsPresent)
            {
            $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
            }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Gray
        }
    }

#### do we have unset parameters ?
if (!$IPV6Prefix) 
    {
    $IPV6Prefix = 'FD00::'
    $IPv6PrefixLength = '8'
    }
if (!$AddressFamily){$AddressFamily = "IPv4" }

###################################################

if ($savedefaults.IsPresent)
{
$defaultsfile = New-Item -ItemType file $Builddir\defaults.xml -Force
Status "saving defaults to $Builddir\defaults.xml"
$config =@()
$config += ("<config>")
$config += ("<nmm_ver>$nmm_ver</nmm_ver>")
$config += ("<nw_ver>$nw_ver</nw_ver>")
$config += ("<master>$Master</master>")
$config += ("<sqlver>$SQLVER</sqlver>")
$config += ("<ex_cu>$ex_cu</ex_cu>")
$config += ("<vmnet>$VMnet</vmnet>")
$config += ("<BuildDomain>$BuildDomain</BuildDomain>")
$config += ("<MySubnet>$MySubnet</MySubnet>")
$config += ("<AddressFamily>$AddressFamily</AddressFamily>")
$config += ("<IPV6Prefix>$IPV6Prefix</IPV6Prefix>")
$config += ("<IPv6PrefixLength>$IPv6PrefixLength</IPv6PrefixLength>")
$config += ("<Gateway>$($Gateway.IsPresent)</Gateway>")
$config += ("<DefaultGateway>$($DefaultGateway)</DefaultGateway>")
$config += ("<Sourcedir>$($Sourcedir)</Sourcedir>")
$config += ("<ScaleIOVer>$($ScaleIOVer)</ScaleIOVer>")
$config += ("<NMM>$($NMM.IsPresent)</NMM>")
$config += ("<Masterpath>$($Masterpath)</Masterpath>")
$config += ("</config>")
$config | Set-Content $defaultsfile
}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose  "Defaults after Save"
    Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Magenta
    }
####### Master Check
if (!$Sourcedir)
    {
    Write-Warning "no Sourcedir specified, will exit now"
    exit
    }
else
    {
    if (!(Test-Path -Path $Sourcedir))
        {
        Write-Warning "Sourcedir $Sourcedir does not exist, should i Create one for you download ?"
        Write-Warning "Not yet implemented"
        exit
        }
     }
if (!$Master)

    {
    Write-Warning "No Master was specified. See get-help .\labbuildr.ps1 -Parameter Master !!"
    Write-Warning "Load masters from $UpdateUri"
    break
    } # end Master

    Try
    {
    $MyMaster = get-vmx -path "$Masterpath\$Master"
    }
    catch [Exception] 
    {
    Write-Warning "Could not find $Masterpath\$Master"
    Write-Warning "Please download a Master from https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released"
    Write-Warning "And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }

   $MasterVMX = $mymaster.config		
   Write-Verbose "We got master $MasterVMX"

write-verbose "After Masterconfig !!!! "

########

########
write-verbose "Evaluating Machine Type, Please wait ..."
#### Eval CPU
$Numcores = (gwmi win32_Processor).NumberOfCores
$NumLogCPU = (gwmi win32_Processor).NumberOfLogicalProcessors
$CPUType = (gwmi win32_Processor).Name
$MachineMFCT = (gwmi win32_ComputerSystem).Manufacturer
$MachineModel = (gwmi win32_ComputerSystem).Model
##### Eval Memory #####
$Totalmemory = 0
$Memory = (get-wmiobject -class "win32_physicalmemory" -namespace "root\CIMV2").Capacity
foreach ($Dimm in $Memory) { $Totalmemory = $Totalmemory + $Dimm }
$Totalmemory = $Totalmemory / 1GB

Switch ($Totalmemory)
{
	
	
	{ $_ -gt 0 -and $_ -le 8 }
	{
		$Computersize = 1
		$Exchangesize = "XL"
	}
	{ $_ -gt 8 -and $_ -le 16 }
	{
		$Computersize = 2
		$Exchangesize = "XL"
	}
	{ $_ -gt 16 -and $_ -le 32 }
	{
		$Computersize = 3
		$Exchangesize = "TXL"
	}
	
	else
	{
		$Computersize = 3
		$Exchangesize = "XXL"
	}
	
}

If ($NumLogCPU -le 4 -and $Computersize -le 2)
{
	debug "Bad, Running $mySelf on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logicalk CPUs and $Totalmemory GB Memory "
}
If ($NumLogCPU -gt 4 -and $Computersize -le 2)
{
	write-verbose "Good, Running $mySelf on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logical CPU and $Totalmemory GB Memory"
	Write-Host "Consider Adding Memory "
}
If ($NumLogCPU -gt 4 -and $Computersize -gt 2)
{
	Status "Excellent, Running $mySelf on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logical CPU and $Totalmemory GB Memory"
}
get-vmwareversion


####### Building required Software Versions Tabs

$Sourcever = @()

# $Sourcever = @("$nw_ver","$nmm_ver","E2013$ex_cu","$WAIKVER","$SQL2012R2")
if (!($DConly.IsPresent))
{
	if ($Exchange.IsPresent -or $DAG.IsPresent) 
        {
        # $Sourcever += "$EX_Version$ex_cu"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
	if (($NMM.IsPresent) -and ($Blanknode -eq $false)) { $Sourcever += $nmm_ver }
	# if ($NW.IsPresent) { $Sourcever += $nw_ver }
	if ($NWServer.IsPresent -or $NW.IsPresent -or $NMM.IsPresent ) 
        { 
        $Sourcever += $nw_ver 
        }
	if ($SQL.IsPresent -or $AlwaysOn.IsPresent) 
        {
        $Sourcever +=  $AAGDB #$SQLVER,
        $Scenarioname = "SQL"
        $SQL = $true
        $Scenario = 2
        }
	if ($HyperV.IsPresent)
	{
		
        $Scenarioname = "Hyper-V"
        $Scenario = 3
        if ($ScaleIO.IsPresent) 
            { 
            $Sourcever += "ScaleIO"
            }
	}
	if ($Sharepoint.IsPresent)
	{
		
        $Scenarioname = "Sharepoint"
        $Scenario = 4
	}
} # end not dconly


# Clear-Host
status $Commentline
status "# Welcome to labbuildr                                                                                                #"
status "# Version $($major).$Edition                                                                                  #"
status "# running Labuildr Build $verlabbuildr                                                                                     #"
status "# and vmxtoolkit   Build $vervmxtoolkit                                                                                     #"

status "# this is an automated Deployment for VMware Workstation VMs on Windows                                               #"
status "# current supportet Guests are:                                                                                       #"
status "# Exchange 2013 Standalone or DAG, SQL 2012SP1 and 2014, Always On, Hyper-V, SCVMM, Networker, Blank Nodes            #"
status "# Available OS Masters are 2012, 2012R2, 2012R2Update and Techical Preview of vNext                                   #"
status "# EMC Integration for Networker, OneFS, Avamar, DD, ScaleIO and other VADP´s                                          #"
status "# Idea and Scripting by @HyperV_Guy                                                                                   #"
status $Commentline
workorder "Building Proposed Workorder"
If ($DAG.IsPresent)
    {
    $Exchange = $True
    }
if ($Blanknode.IsPresent)
{
	workorder "We are going to Install $BlankNodes Blank Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
    if ($Gateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	if ($VTbit) { write-verbose "Virtualization will be enabled in the Nodes" }
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered" }
}
if ($SOFS.IsPresent)
{
	workorder "We are going to Install $SOFSNODES SOFS Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
    if ($Gateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}
if ($HyperV.IsPresent)
{
	
	
}#end Hyperv.ispresent
if ($ScaleIO.IsPresent)
{
	workorder "We are going to Install ScaleIO on $HyperVNodes Hyper-V  Nodes"
    if ($Gateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	# if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}


if ($AlwaysOn.IsPresent -or $PsCmdlet.ParameterSetName -match "AAG" -or $SPdbtype -eq "AlwaysOn")
{
	workorder "We are going to Install an SQL Always On Cluster with $AAGNodes Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet"
	$AlwaysOn = $true
    # if ($NoNMM -eq $false) {status "Networker Modules will be installed on each Node"}
}

if ($NWServer.IsPresent -or $NW.IsPresent)
    {
<#    $url = "http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jre-7u80-windows-x64.exe"
    $FileName = Split-Path -Leaf -Path $Url
    if (!(test-path  $Sourcedir\$FileName))
        {
        Write-Verbose "$FileName not found, trying Download"
        if (!( get-prereq -DownLoadUrl $URL -destination $Sourcedir\$FileName -verbose ))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            }
        }
#>
    $url = "ftp://ftp.adobe.com/pub/adobe/reader/win/Acrobat2015/1500630033/AcroRdr20151500630033_MUI.exe"
    $FileName = Split-Path -Leaf -Path $Url
    if (!(test-path  $Sourcedir\$FileName))
        {
        Write-Verbose "$FileName not found, trying Download"
        if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -UserName Anonymous -Password "Admin@labbuildr.local"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            }
        }

    }
if ($Exchange.IsPresent)
{

    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf",
    "http://www.emc.com/collateral/white-papers/h12234-emc-integration-for-microsoft-private-cloud-wp.pdf",
    "http://www.emc.com/collateral/software/data-sheet/h2257-networker-ds.pdf",
    "http://www.emc.com/collateral/software/data-sheet/h2479-networker-app-modules-ds.pdf",
    "http://www.emc.com/collateral/software/data-sheet/h4525-networker-ms-apps-ds.pdf",
    "http://www.emc.com/collateral/handouts/h14152-cloudboost-handout.pdf",
    "http://www.emc.com/collateral/software/data-sheet/h2257-networker-ds.pdf",
    "http://www.emc.com/collateral/software/data-sheet/h3979-networker-dedupe-ds.pdf"
    )
    
    if (!(Test-Path $Sourcedir\$Prereqdir)){New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir}
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                  Write-Warning "Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName"
                }
            }

        
        }
    
    $Prereqdir = $EX_Version+"prereq"

    Write-Verbose "We are now going to Test Exchange Prereqs"
    $DownloadUrls = (
		        "http://download.microsoft.com/download/A/A/3/AA345161-18B8-45AE-8DC8-DA6387264CB9/filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe",
                "http://download.microsoft.com/download/0/A/2/0A28BBFA-CBFA-4C03-A739-30CCA5E21659/FilterPack64bit.exe",
                "http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe",
                "http://download.microsoft.com/download/6/2/D/62DFA722-A628-4CF7-A789-D93E17653111/ExchangeMapiCdo.EXE"
                
                ) 
    if (Test-Path -Path "$Sourcedir\$Prereqdir")
        {
        Write-Verbose "Exchange Sourcedir Found"
        }
        else
        {
        Write-Verbose "Creating Sourcedir for Exchange Prereqs"
        New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir | Out-Null
        }


    foreach ($URL in $DownloadUrls)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }

        
        }
    
    if (!(test-path  "$Sourcedir\$Prereqdir\ExchangeMapiCdo.msi"))
        {
        Write-Verbose "Extracting MAPICDO"
        Start-Process -FilePath "$Sourcedir\$Prereqdir\ExchangeMapiCdo.EXE" -ArgumentList "/x:$Sourcedir\$Prereqdir /q" -Wait
        }

    if (Test-Path $Sourcedir/$EX_Version$ex_cu/setup.exe)
        {
        Write-Verbose "Exchange $ex_cu Found"
        }
        else
        {
        Write-Warning "We need to Extract Exchange $ex_cu, this may take a while"
        # New-Item -ItemType Directory -Path $Sourcedir\$EX_Version$ex_cu | Out-Null
        # }
        Switch ($ex_cu)

            {
                "CU1"
                {
                $URL = "http://download.microsoft.com/download/5/4/7/547784D7-2954-4BEE-AFD6-B4D11232DF82/Exchange-x64.exe"
                }
                "CU2"
                {
                $URL = "http://download.microsoft.com/download/A/F/C/AFC84463-E1CB-4C55-B012-AEC5927EEAA8/Exchange2013-KB2859928-x64-v2.exe"
                }
                "CU3"
                {
                $URL = "http://download.microsoft.com/download/3/2/2/3226085F-1B33-4899-8DEA-26E5E60D77BD/Exchange2013-x64-cu3.exe"
                }
                "SP1"
                {
                $URL = "http://download.microsoft.com/download/8/4/9/8494E4ED-8FA8-40CA-9E89-B9317995AD7E/Exchange2013-x64-SP1.exe"
                }
                "CU5"
                {
                $URL = "http://download.microsoft.com/download/F/E/5/FE5F57FF-A897-4A5B-8F47-00341B7BA8EE/Exchange2013-x64-cu5.exe"
                }
                "CU6"
                {
                $URL = "http://download.microsoft.com/download/C/D/0/CD08800B-0DF9-4A9F-9870-5A4CC6D8A261/Exchange2013-x64-cu6.exe"
                }
                "CU7"
                {
                $URL = "http://download.microsoft.com/download/F/1/8/F1855E0B-1B90-4E5B-B64E-B5B564D67637/Exchange2013-x64-cu7.exe"
                }
                "CU8"
                {
                $url = "http://download.microsoft.com/download/0/5/2/05265E88-F7E2-4386-8811-9071BAA1FD64/Exchange2013-x64-cu8.exe"
                }
                "CU9"
                {
                $url = "http://download.microsoft.com/download/C/6/8/C6899C99-F933-4181-9692-17A5BB7F1A4B/Exchange2013-x64-cu9.exe"
                }

            }

        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$FileName))
            {
            "We need to Download Exchange $ex_cu, this may take a while"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
            }
        }
        Write-Verbose "Extracting $FileName"
        Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/extract:$Sourcedir\$EX_Version$ex_cu /passive" -Wait
            
    } #end else
    if (!(Test-Path $Sourcedir\attachments))
        {
         Write-Warning "attachments Directory not found. Please Create $Sourcedir\attachments and copy some Documents for Mail and Public Folder Deployment"
            }
        else
            {
            Write-Verbose "Found attachments"
            }
	    workorder "We are going to Install Exchange 2013 $ex_cu with Nodesize $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
	    if ($DAG.IsPresent)
	        {
		    workorder "We will form a $EXNodes-Node DAG"
	        }

}

if ($NMM.IsPresent) { debug "Networker Modules $nmm_ver will be intalled by User selection" }
if ($Sharepoint.IsPresent)
    {
    $Prereqdir = "$spver"+"prereq"
    Write-Verbose "We are now going to Test Sharepoint Prereqs"
    $DownloadUrls = (
		    "http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi", # Microsoft SQL Server 2008 R2 SP1 Native Client
		    "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi", # Microsoft Sync Framework Runtime v1.0 SP1 (x64)
		    "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe", # Windows Server App Fabric
            "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe", # Cumulative Update Package 1 for Microsoft AppFabric 1.1 for Windows Server (KB2671763)
            "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu", #Windows Identity Foundation (KB974405)
		    "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi", # Microsoft Identity Extensions
		    "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi", # Microsoft Information Protection and Control Client
		    "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe" # Microsoft WCF Data Services 5.0
                
                ) 
    if (Test-Path $Sourcedir/$Prereqdir)
        {
        Write-Verbose "Sharepoint Prereq Sourcedir Found"
        }
        else
        {
        Write-Verbose "Creating Prereq Sourcedir for Sharepoint"
        New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir | Out-Null
        }
    foreach ($URL in $DownloadUrls)
        {
        $FileName = Split-Path -Leaf -Path $Url
        Write-Verbose "...checking for $FileName"
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { 
                write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
        }
        
        $URL = "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe"
        $FileName = "WcfDataServices56.exe"
        Write-Verbose "...checking for $FileName"
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { 
                write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
            
        $Url = "http://download.microsoft.com/download/6/E/3/6E3A0B03-F782-4493-950B-B106A1854DE1/sharepoint.exe"
        Write-Verbose "Testing Sharepoint SP1 Foundation exists in $Sourcedir"
        if (!(test-path  "$Sourcedir\$SPver"))
            {
            $FileName = Split-Path -Leaf -Path $Url
            Write-Verbose "Trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                { 
                write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            Write-Verbose "Extracting $FileName"
            Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/extract:$Sourcedir\$SPver /quiet /passive" -Wait
            }
    workorder "We are going to Install Sharepoint 2013 in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet and SQL"
    }# end SPPREREQ


if ($scvmm.IsPresent)
  {
    [switch]$SQL=$true
    if ($SQLVER -gt "SQL2012SP1")
        {
        Write-Warning "SCVMM can only be inbstalled on SQL2012, Setting to SQL2012SP1"
        $SQLVER = "SQL2012SP1"
        }
    $Prereqdir = "$SCVMMVER"+"prereq"
    
    Write-Verbose "We are now going to Test scvmm Prereqs"
    
    $DownloadUrls= (
            "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe",
            "http://download.microsoft.com/download/F/E/D/FEDB200F-DE2A-46D8-B661-D019DFE9D470/ENU/x64/SqlCmdLnUtils.msi",
            "http://download.microsoft.com/download/F/E/D/FEDB200F-DE2A-46D8-B661-D019DFE9D470/ENU/x64/sqlncli.msi"
            )
    
    Foreach ($URL in $DownloadUrls)
    {
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $FileName in $Prereqdir"
    if (!(test-path  "$Sourcedir\$Prereqdir\$FileName"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$Prereqdir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        }
    }
    $URL = "http://care.dlservice.microsoft.com/dl/download/evalx/sc2012r2/SC2012_R2_SCVMM.exe"
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $SCVMMVER"
    if (!(test-path  "$Sourcedir\$SCVMMVER"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        write-Warning "We are going to Extract $FileName, this may take a while"
        Start-Process "$Sourcedir\$FileName" -ArgumentList "/SP- /dir=$Sourcedir\$SCVMMVER /SILENT" -Wait
        }


    $Url = "http://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe" # ADKSETUP 8.1
    Write-Verbose "Testing WAIK in $Sourcedir"
    if (!(test-path  "$Sourcedir\$Prereqdir"))
        {
        $FileName = Split-Path -Leaf -Path $Url
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        Write-Warning "Getting WAIK, Could take a While"
        Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/quiet /layout $Sourcedir\$Prereqdir" -Wait
        }

    workorder "We are going to Install Hyper-V with $SCVMMVER in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet and $SQLVER"
    # exit
    }# end SCVMMPREREQ


if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
    {

    $SQL2012_inst = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Install.exe"
    $SQL2012_lang = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Lang.box"
    $SQL2012_core = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Core.box"
    $SQL2012_box = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.box"
    $SQL2012SP1SLIP_INST = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.exe"
    $SQL2012SP1SLIP_box= "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.box"
    $SQL2012_SP1 = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-KB2674319-x64-ENU.exe"
    $SQL2012_SP2 = "http://download.microsoft.com/download/D/F/7/DF7BEBF9-AA4D-4CFE-B5AE-5C9129D37EFD/SQLServer2012SP2-KB2958429-x64-ENU.exe"
    $SQL2014_ZIP = "http://care.dlservice.microsoft.com/dl/download/evalx/sqlserver2014/x64/SQLServer2014_x64_enus.zip"
    $AAGURL = "https://community.emc.com/servlet/JiveServlet/download/38-111250/AWORKS.zip"
    $URL = $AAGURL
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $FileName in $Sourcedir"
    if (!(test-path  "$Sourcedir\Aworks\AdventureWorks2012.bak"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        #New-Item -ItemType Directory -Path "$Sourcedir\Aworks" -Force
        Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
        }
    Write-Verbose "We are now going to Test $SQLVER"
    Switch ($SQLVER)
        {
            "SQL2012"
            {
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            }
            "SQL2012SP1"
            {
            #Getting SP1
            $url = $SQL2012_SP1
            $FileName = Split-Path -Leaf -Path $Url
            $Destination = "$Sourcedir\$SQLVER\$FileName"
            Write-Verbose "Testing $Destination"
                if (!(test-path  "$Destination"))
                    {
                    Write-Verbose "Trying Download"
                    if (!(get-prereq -DownLoadUrl $URL -destination $Destination))
                        { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
            #first check for 2012
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            # end 2012

            }
            "SQL2012SP2"
            {
            #first check for 2012
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            # end 2012

            #### Getting Sp2
            $url = $SQL2012_SP2
            $FileName = Split-Path -Leaf -Path $Url
            $Destination = "$Sourcedir\$SQLVER\$FileName"
            Write-Verbose "Testing $Destination"
            if (!(test-path  "$Destination"))
                {
                Write-Verbose "Trying Download"
                if (!(get-prereq -DownLoadUrl $URL -destination $Destination))
                    { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                    exit
                    }
                }

            }
            "SQL2012SP1Slip"
            {
            if (!(Test-Path $Sourcedir\$SQLVER\setup.exe))
                {
                foreach ($url in ($SQL2012SP1SLIP_box,$SQL2012SP1SLIP_INST))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            {  
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                    Write-Warning "Creating $SQLVER Installtree, this might take a while"
                    Start-Process $Sourcedir\$FileName -ArgumentList "/X:$Sourcedir\$SQLVER /q" -Wait
                }
            }

            "SQL2014"
            {
            if (!(Test-Path $Sourcedir\$SQLVER\setup.exe))
            {
            foreach ($url in ($SQL2014_ZIP))
                {
                $FileName = Split-Path -Leaf -Path $Url
                Write-Verbose "Testing $FileName in $Prereqdir"
                ### Test if the 2014 ENU´s are there
                if (!(test-path  "$Sourcedir\SQLServer2014-x64-ENU.exe"))
                    {
                    ## Test if we already have the ZIP
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                    }
                 Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
                 Remove-Item $Sourcedir\$FileName 
                 Move-Item $Sourcedir\enus\* $Sourcedir\
                 Remove-Item $Sourcedir\enus
                 }
                # New-Item -ItemType Directory $Sourcedir\$SQLVER
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                Start-Process "$Sourcedir\SQLServer2014-x64-ENU.exe" -ArgumentList "/X:$Sourcedir\$SQLVER /q" -Wait 
                }
            
            }
            }
          } #end switch
    }#end $SQLEXPRESS

if ($Panorama.IsPresent)
    {
    $Targetir = "$Sourcedir/panorama"
    if (Test-Path "$Sourcedir/panorama/Syncplicity Panorama.msi")
        {
        Write-Verbose "Syncplicity found"
        }
    else
        {
        Write-Warning "We need to get Panorama trying Automated Download"
        $url = "https://download.syncplicity.com/panorama-connector/Syncplicity Panorama.msi"
        if ($url)
            {
            $FileName = Split-Path -Leaf -Path $Url
            get-prereq -DownLoadUrl $url -destination "$Sourcedir/panorama/$FileName"
            }
        }
     }


if ($NWServer.IsPresent -or $NMM.IsPresent -or $NW.IsPresent)
    {

    if ((Test-Path "$Sourcedir/$nw_ver/win_x64/networkr/networker.msi") -or (Test-Path "$Sourcedir/$nw_ver/win_x64/networkr/lgtoclnt-8.5.0.0.exe"))
        {
        Write-Verbose "Networker $nw_ver found"
        }
    else
        {
        Write-Warning "We need to get $NW_ver, trying Automated Download"
        # New-Item -ItemType Directory -Path $Sourcedir\$EX_Version$ex_cu | Out-Null
        # }
        switch ($nw_ver)
        {
        "nw8213"
            {
            $url = "ftp://ftp.legato.com/pub/NetWorker/Cumulative_Hotfixes/8.2/8.2.1.3/nw821_win_x64.zip"
            }

        default
            {
            $url = $false
            }
        }
        if ($url)
            {
            $FileName = Split-Path -Leaf -Path $Url
            $FileName = $FileName -replace "$FileName","nw_$nw_ver.zip"
            if (!(test-path  $Sourcedir\$FileName))
                {
                Write-Verbose "$FileName not found, trying Download"
                if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -Defaultcredentials))
                    { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                    }
                } 
            Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\$nw_ver"
            }
      }
}

if ($NMM.IsPresent)
    {

    if ((Test-Path "$Sourcedir/$nmm_ver/win_x64/networkr/networker.msi") -or (Test-Path "$Sourcedir/$nmm_ver/win_x64/networkr/NWVSS.exe"))
        {
        Write-Verbose "Networker NMM $nmm_ver found"
        }
    else
        {
        Write-Warning "We need to get $NMM_ver, trying Automated Download"
        # New-Item -ItemType Directory -Path $Sourcedir\$EX_Version$ex_cu | Out-Null
        # }
        switch ($nmm_ver)
        {
        "nmm8212"
            {
            $urls = ("ftp://ftp.legato.com/pub/NetWorker/NMM/Cumulative_Hotfixes/8.2.1/8.2.1.2/nmm821_win_x64.zip",
                    "ftp://ftp.legato.com/pub/NetWorker/NMM/Cumulative_Hotfixes/8.2.1/8.2.1.2/scvmm821_win_x64.zip")
            }

        default
            {
            $url = $false
            }
        }
        if ($urls)
            {
            foreach ($url in $urls)
                {
                $FileName = Split-Path -Leaf -Path $Url
                if (!(test-path  $Sourcedir\$FileName))
                    {
                    Write-Verbose "$FileName not found, trying Download"
                    if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -Defaultcredentials))
                        { 
                        write-warning "Error Downloading file $Url, Please check connectivity"
                        }
                    }
                If ($FileName -match "nmm")
                    {     
                    Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\$nmm_ver"
                    }
                else
                    {
                    Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\$($FileName.replace(".zip"," "))"
                    }
                }
            }
      }
}






####SACELIO Downloader #####
if ($ScaleIO.IsPresent)
    {
    ##
    # ScaleIO_1.32_Complete_Windows_SW_Download\ScaleIO_1.32_Windows_Download #
    $ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
    if (Test-Path "$Sourcedir/ScaleIO/ScaleIO_$($ScaleIO_Major)_Complete_Windows_SW_Download/ScaleIO_$($ScaleIO_Major)_Windows_Download/*sds*$ScaleIOVer.msi") 
        {
        Write-Verbose "ScaleIO $ScaleIOVer found"
        }
    else
        {
        Write-Warning "We need to get $ScaleIOVer, trying Automated Download"
        switch ($ScaleIOVer)
        {
        "$latest_ScaleIO"
            {
            $url = "ftp://ftp.emc.com/Downloads/ScaleIO/ScaleIO_Windows_SW_Download.zip"
            }

        default
            {
            $url = $false
            Write-Warning "Sorry,no Autodownload for Scaleio $ScaleIOVer available"
            }
        }
        if ($url)
            {
            $FileName = Split-Path -Leaf -Path $Url
            $FileName = $FileName -replace "$FileName","ScaleIO_$ScaleIOVer.zip"
            if (!(test-path  $Sourcedir\$FileName))
                {
                Write-Verbose "$FileName not found, trying Download"
                if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -Defaultcredentials))
                    { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                    Remove-Item -Path $Sourcedir\$FileName -Verbose
                    }
                } 
            if (Test-Path "$Sourcedir\$FileName")
                {
                Expand-LABZip -zipfilename "$Sourcedir\$FileName" -destination "$Sourcedir\ScaleIO\"
                }
            }
       }
      Write-Verbose "Checking Diskspeed"
      $URL = "https://gallery.technet.microsoft.com/DiskSpd-a-robust-storage-6cd2f223/file/132882/1/Diskspd-v2.0.15.zip"
      $FileName = Split-Path -Leaf -Path $Url
      # $Directory = Split-Path 
      if (!(test-path  "$Sourcedir\diskspd\amd64fre\diskspd.exe"))
        {
        ## Test if we already have the ZIP
        if (!(test-path  "$Sourcedir\$FileName"))
            {
            Write-Verbose "Trying Download DiskSpeed"
            if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir"))
                { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                        exit
                }
            }
        Extract-Zip -zipfilename $Sourcedir\$FileName -destination "$Sourcedir\diskspd"

}
}
##end Autodownloaders
##########################################
if ($nw.IsPresent) { workorder "Networker $nw_ver Node will be installed" }
write-verbose "Checking Environment"
if ($NW.IsPresent -or $NWServer.IsPresent)
{
    if (!$Scenarioname) {$Scenarioname = "nwserver";$Scenario = 8}
	if (!($Acroread = Get-ChildItem -Path $Sourcedir -Filter 'a*rdr*.exe'))
	{
		status "Adobe reader not found ...."
	}
	else
	{
		$Acroread = $Acroread | Sort-Object -Property Name -Descending
		$LatestReader = $Acroread[0].Name
		write-verbose "Found Adobe $LatestReader"
	}
	
	##### Check Java
	if (!($Java7 = Get-ChildItem -Path $Sourcedir -Filter 'jre-7*x64*'))
	{
		write-warning "Java7 not found, please download from www.java.com"
	}
    else
        {
	    $Java7 = $Java7 | Sort-Object -Property Name -Descending
	    $LatestJava7 = $Java7[0].Name
        }
	if (!($Java8 = Get-ChildItem -Path $Sourcedir -Filter 'jre-8*x64*'))
	{
		Write-Warning "Java8 not found, please download from www.java.com"
	}
    else
        {
        $Java8 = $Java8 | Sort-Object -Property Name -Descending
	    $LatestJava8 = $Java8[0].Name
        }
If ($nw_ver -gt "nw85.BR1")
            {
            if ($LatestJava7)
                {
                $LatestJava = $LatestJava7
                }
            
            if ($LatestJava8)
                {
                $LatestJava = $LatestJava8
                }
            }
elseif ($nw_ver -gt "nw84")
            {
            if ($LatestJava7 -and $LatestJava7 -ge $NW85_requiredJava)
                {
                $LatestJava = $LatestJava7
                }
            else 
                {
                Write-warning "Currently you need at least $NW85_requiredJava for $nw_ver
                we only found $LatestJava7"
                exit
                }
            }
else
            {
            if ($LatestJava7)
                {
                $LatestJava = $LatestJava7
                }
                
            }
if (!$LatestJava)
    {
    Write-Warning "No Java was found. Please download required Java Version to $Sources"
    break
    }    
Write-Warning "we will use $LatestJava for Netwoker $nw_ver. Please make sure the Versions Match"

} 
#end $nw
if (!($SourceOK = test-source -SourceVer $Sourcever -SourceDir $Sourcedir))
{
	Write-Verbose "Sourcecomlete: $SourceOK"
	break
}
if ($Gateway.IsPresent) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
If ($VMnet -ne "VMnet2") { debug "Setting different Network is untested and own Risk !" }

if (!$NoDomainCheck.IsPresent){
####################################################################
# DC Validation
$Nodename = $DCNODE
$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
if (test-vmx $DCNODE)
{
	status "Domaincontroller already deployed, Comparing Workorder Parameters with Running Environment"
	test-dcrunning
    if ( $AddressFamily -match 'IPv4' )
        {
	    test-user -whois Administrator
	    write-verbose "Verifiying Domainsetup"
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script checkdom.ps1 # $CommonParameter
	    $BuildDomain, $RunningIP, $VMnet, $MyGateway = test-domainsetup
	    $IPv4Subnet = convert-iptosubnet $RunningIP
	    workorder "We will Use Domain $BuildDomain and Subnet $IPv4Subnet.0 for on $VMnet the Running Workorder"
	    If ($MyGateway) {$Gateway = $True 
        workorder "We will configure Default Gateway at $DefaultGateway"
        Write-Verbose -Message $Gateway.IsPresent
        if ($Gateway.IsPresent) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
        else {$AddGateway = ""}
        Write-Verbose -Message $AddGateway
        }
    else
        {
        write-verbose " no domain check on IPv6only"
        }
    }
}#end test-domain
else
{
	###################################################
	# Part 1, Definition of Domain Controller
	###################################################
	#$Nodename = $DCNODE
	$DCName = $BuildDomain + "DC"
	#$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
	$SourceScriptDir = "$Builddir\$Script_dir\dc\"
	###################################################
    
	Write-Verbose "IPv4Subnet :$IPv4Subnet"
    Write-Verbose "IPV6Prefix :$IPv6Prefix"
    Write-Verbose "IPv6Prefixlength : $IPv6PrefixLength"
    write-verbose "DCName : $DCName"
    Write-Verbose "Domainsuffix : $domainsuffix"
    Write-Verbose "Domain : $BuildDomain"
    Write-Verbose "AddressFamily : $AddressFamily"
    If ($Gateway.IsPresent)
        {
        Write-Verbose "Gateway : $DefaultGateway"
        }
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "Press any key to Continue Cloning"
    Pause
    }
	workorder "We will Build Domain $BuildDomain and Subnet $IPv4subnet.0  on $VMnet for the Running Workorder"
    if ($Gateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	
	$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 0 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Size 'L' -Sourcedir $Sourcedir"
	
	###################################################
	#
	# DC Setup
	#
	###################################################
	if ($CloneOK)
	{
		write-verbose "Waiting for User logged on"

		test-user -whois Administrator
		Write-Host
        copy-tovmx -Sourcedir $NodeScriptDir
		copy-tovmx -Sourcedir $SourceScriptDir
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script new-dc.ps1 -Parameter "-dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix  -AddressFamily $AddressFamily $AddGateway $CommonParameter" -interactive -nowait
   
        status "Preparing Domain"
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            write-verbose "verbose enabled, Please press any key within VM $Dcname"
            While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\2.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
            }
        else 
            {

		    While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\2.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
            Write-Host
		    }
		test-user -whois Administrator
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finishdomain.ps1 -Parameter "-domain $BuildDomain -domainsuffix $domainsuffix $CommonParameter" -interactive -nowait
		status "Creating Domain $BuildDomain"
		While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\3.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
		write-host
		status  "Domain Setup Finished"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script dns.ps1 -Parameter "-IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix $CommonParameter"  -interactive
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script add_serviceuser.ps1 -interactive
	    write-verbose "Setting Password Policies"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir  -Script pwpolicy.ps1 -interactive
        if ($NW.IsPresent)
            {
            write-verbose "Install NWClient"
		    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
            }
        invoke-postsection 
		# run-vmpowershell -Script gpo.ps1 -interactive
		# GPO on freetype domain ? Exchange Powershell Issues ?
	} #DC node End
}#end else createdc

####################################################################
### Scenario Deployment Begins .....                           #####
####################################################################
}


#### Is AlwaysOn Needed ?
If ($AlwaysOn.IsPresent -or $PsCmdlet.ParameterSetName -match "AAG")
{
		# we need a DC, so check it is running
		test-dcrunning
		status "Avalanching SQL Install on $AAGNodes Always On Nodes"
        $ListenerIP = "$IPv4Subnet.169"
        $AAGName = $BuildDomain+"AAG"
        If ($AddressFamily -match 'IPv6')
            {
            $ListenerIP = "$IPV6Prefix$ListenerIP"
            } # end addressfamily
		$AAGLIST = @()
		foreach ($AAGNode in (1..$AAGNodes))
		{
			###################################################
			# Setup of a AlwaysOn Node
			# Init
			$Nodeip = "$IPv4Subnet.16$AAGNode"
			$Nodename = "AAGNODE" + $AAGNODE
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$AAGLIST += $CloneVMX
			$SourceScriptDir = "$Builddir\$Script_dir\AAG\"
            $SQLScriptDir = "$Builddir\$Script_dir\sql\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Failover-Clustering, RSAT-Clustering, WVR"
			###################################################
			Write-Verbose $IPv4Subnet
            write-verbose $Nodeip
            Write-Verbose $Nodename
            Write-Verbose $ListenerIP
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            { 
            Write-verbose "Now Pausing"
            pause
            }
			# Clone Base Machine
			status $Commentline
			status "Creating $Nodename with IP $Nodeip for Always On Availability Group"
			$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $AAGNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -sql"
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $SourceScriptDir
				copy-tovmx -Sourcedir $NodeScriptDir
                copy-tovmx -Sourcedir $SQLScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                invoke-postsection -wait
                write-verbose "Setup Database Drives"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script prepare-disks.ps1
				write-verbose "Starting $SQLVER Setup on $Nodename"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -reboot" -interactive -nowait
                				
                $SQLSetupStart = Get-Date
                
			}
			
		} ## end foreach AAGNODE
		
		If ($CloneOK)
		{
			####### Check for all SQl Setups Done .. ####
			write-verbose "Checking SQL INSTALLED and Rebooted on All Machines"
			foreach ($AAGNode in $AAGLIST)
			{
				
				While ($FileOK = (&$vmrun -gu $builddomain\Administrator -gp Password123! fileExistsInGuest $AAGNode c:\$Script_dir\sql.pass) -ne "The file exists.")
				{
					runtime $SQLSetupStart "$SQLVER $Nodename"
				}

            Write-Verbose "Setting SQL Server Roles on $AAGNode"
            invoke-vmxpowershell -config $AAGNode -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script set-sqlroles.ps1 -interactive
            

			} # end aaglist
			
			write-host
			write-verbose "Forming AlwaysOn WFC Cluster"
	        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'AAGNODE' -IPAddress '$IPv4Subnet.160' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			
			write-verbose "Enabling AAG"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script enable-aag.ps1 -interactive
			
			write-verbose "Creating AAG"

			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script create-aag.ps1 -interactive -Parameter "-Nodeprefix 'AAGNODE' -AgName '$AAGName' -DatabaseList 'AdventureWorks2012' -BackupShare '\\vmware-host\Shared Folders\Sources\AWORKS' -IPv4Subnet $IPv4Subnet -IPV6Prefix $IPV6Prefix -AddressFamily $AddressFamily $CommonParameter"
			foreach ($CloneVMX in $AAGLIST)
            {
                if ($NMM.IsPresent)
                    {
				    status "Installing Networker $nmm_ver an NMM $nmm_ver on all Nodes"
					status $CloneVMX
					write-verbose "Install NWClient"
					invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    write-verbose "Install NMM"
					invoke-vmxpowershell -config $CloneVMX -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $nmm_ver -Guestuser $Adminuser -Guestpassword $Adminpassword
                    write-verbose "Finishing Always On"
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finish-aag.ps1 -interactive -nowait
					} # end !NMM
				else 
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finish-aag.ps1 -interactive -nowait
                    }# end else nmm
				}
           # 

			status "Done"			
	
			
		}# end cloneok
	} # End Switchblock AAG

switch ($PsCmdlet.ParameterSetName)
{
	"Exchange"{
        # we need ipv4
        if ($AddressFamily -notmatch 'ipv4')
            { 
            $EXAddressFamiliy = 'IPv4IPv6'
            }
        else
        {
        $EXAddressFamiliy = $AddressFamily
        }
        if ($DAG.IsPresent)
            {
            Write-Warning "Running Exchange Avalanche Install"

            if ($DAGNOIP.IsPresent)
			    {
				$DAGIP = ([System.Net.IPAddress])::None
			    }
			else
                {
                $DAGIP = "$IPv4subnet.110"
                }
        }
		foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
			###################################################
			# Setup Exchange Node
			# Init
			$Nodeip = "$IPv4Subnet.11$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$EXLIST += $CloneVMX
		    $SourceScriptDir = "$Builddir\$Script_dir\$EX_Version\"
		    # $Exprereqdir = "$Sourcedir\EXPREREQ\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
            $AddonFeatures = "$AddonFeatures, RSAT-DNS-SERVER, Desktop-Experience, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation" 
			###################################################
	    	
            Write-Verbose $IPv4Subnet
            Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "IPv6Prefix = $IPV6Prefix"
            Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
            Write-Verbose "Addressfamily = $AddressFamily"
            Write-Verbose "EXAddressFamiliy = $EXAddressFamiliy"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }
		    test-dcrunning
		    status $Commentline
		    workorder "Creating Exchange Host $Nodename with IP $Nodeip in Domain $BuildDomain"
		    $CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Exchange -Size $Exchangesize -Sourcedir $Sourcedir "
		    ###################################################
		    If ($CloneOK)
            {
            $EXnew = $True
			write-verbose "Copy Configuration files, please be patient"
			copy-tovmx -Sourcedir $NodeScriptDir
			copy-tovmx -Sourcedir $SourceScriptDir
			# copy-tovmx -Sourcedir $Exprereqdir
			write-verbose "Waiting System Ready"
			test-user -whois Administrator
			write-Verbose "Starting Customization"
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			write-verbose "Setup Database Drives"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script prepare-disks.ps1
			write-verbose "Setup Exchange Prereqs"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-exchangeprereqs.ps1 -interactive
			write-verbose "Setting Power Scheme"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script powerconf.ps1 -interactive
			write-verbose "Installing Exchange, this may take up to 60 Minutes ...."
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $ex_cu"
            }
            }
        if ($EXnew)
        {
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
            $CloneVMX = (get-vmx $Nodename).config
            # 
			test-user -whois Administrator
            status "Waiting for Pass 4 (Exchange Installed) for $Nodename"
            #$EXSetupStart = Get-Date
			    While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\exchange.pass) -ne "The file exists.")
			    {
				    sleep $Sleep
				    #runtime $EXSetupStart "Exchange"
			    } #end while
			    Write-Host
                    do {
                        $ToolState = Get-VMXToolsState -config $CloneVMX
                         Write-Verbose $ToolState.State
                        }
                    until ($ToolState.state -match "running")
            write-Verbose "Performing Exchange Post Install Tasks:"
    		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-exchange.ps1 -interactive
     
    
    #  -nowait
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent) 
                    {
				    write-verbose "Creating DAG"
				    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
                    write-verbose "Creating Accounts and Mailboxes:"
	                do
				        {
					    ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; C:\$Script_dir\User.ps1 -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter") 
					    if ($BugTest) { debug $Cmdresult }
				        }
				    until ($VMrunErrorCondition -notcontains $cmdresult)
                    } #end creatuser
            }# end if last server
       }      
		
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
            $CloneVMX = (get-vmx $Nodename).config				
			write-verbose "Setting Local Security Policies"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				write-verbose "Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				write-verbose "Install NMM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $nmm_ver
			    write-verbose "Performin NMM Post Install Tasks"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange
	

##### Hyper-V Block #####	
	"HyperV" {
        $Firstnode = 1 #for later use
        $Clusternum = 1 # for later use
        $FirstVMX =  "$Builddir\HVNODE$Firstnode\HVNODE$Firstnode.vmx"
		$HVLIST = @()
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Hyper-V, Hyper-V-Tools, Hyper-V-PowerShell, WindowsStorageManagementService"
		if ($ScaleIO.IsPresent)
            {
            If ($HyperVNodes -lt 3)
                {
                Write-Warning "Need 3 nodes for ScaleIO, incrementing to 3"
                $HyperVNodes = 3
                }
            if (!$Cluster.IsPresent)
                {
                Write-Warning "We want a Cluster for Automated SCALEIO Deployment, adjusting"
                [switch]$Cluster = $true
                }   
            If (!$Disks){$Disks = 3} 
            $cloneparm = " -AddDisks -disks $Disks"
            if ("XXL" -notmatch $Size)
                { 
                Write-Warning "we adjust size to XL Machine to make ScaleIO RUN"
                $Size = "XL"              
                }
            If ($Computersize -le "2" -and !$Scaleiowarn )
                {
                write-warning "Your Computer is at low Memory For ScaleIO Scenario"
                write-warning "Insufficient memory might cause MDM Setup to fail"
                write-warning "machines with < 16GB might not be able to run the Scenario"
                write-warning "Please make sure to close all desktop Apps"
                pause
                $Scaleiowarn = $true
                }
            
            }
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"}

        foreach ($HVNODE in ($Firstnode..$HyperVNodes))
		{
			if ($HVNODE -eq $HyperVNodes -and $SCVMM.IsPresent) 
            { 
            if ("XL" -notmatch $Size)
                { 
                $Size = "TXL"              
                }
            }
  
			###################################################
			# Hyper-V  Node Setup
			# Init
			$Nodeip = "$IPv4Subnet.15$HVNode"
			$Nodename = "HVNODE$HVNode"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$SourceScriptDir = "$Builddir\$Script_dir\HyperV\"
            $SQLScriptDir = "$Builddir\$Script_dir\sql\"
            Write-Verbose $IPv4Subnet
            write-verbose $Nodeip
            Write-Verbose $Nodename
            Write-Verbose $AddonFeatures
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }
			###################################################
			# Clone BAse Machine
			status $Commentline
			status "Creating Hyper-V Node  $Nodename"
			# status "Hyper-V Development is still not finished and untested, be careful"
			test-dcrunning
			$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $HVNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir $cloneparm"
			###################################################
			
            If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $NodeScriptDir
                copy-tovmx -Sourcedir $SourceScriptDir
                if ($SCVMM.IsPresent)
                    {
                    copy-tovmx -Sourcedir $SQLScriptDir
                    }
                If ($ScaleIO.IsPresent)
                    {
                    Write-Verbose "Copying DiskSpeed"
                    $VMX | Copy-VMXDirHost2Guest -Sourcepath "$Sourcedir\diskspd\amd64fre\diskspd.exe" -targetpath "c:\Diskspd" -Verbose -recurse -Guestuser "Administrator" -Guestpassword $Adminpassword
				    }
                write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
				test-user Administrator
				write-verbose "Setting up Virtual Machine"
				# invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createvm.ps1 -interactive
                if ($ScaleIO.IsPresent)
                    {
                    switch ($HVNODE){
                1
                    {
                    Write-Output "Installing MDM"
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive
                    }
                2
                    {
                    if (!$singlemdm.IsPresent)
                        {
                        Write-Output "Installing MDM"
                        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive
                        }
                    else
                        {
                        Write-Output "Installing single MDM"
                        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive 
                        }
                    
                    }
                3
                    {
                    if (!$singlemdm.IsPresent)
                        {                                        
                        Write-Output " Installing TB"
                        Invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role TB -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive 
                        }
                    else
                        {
                        Write-Output " Installing single MDM"
                        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive 
                        }

                    }
                default
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer" -interactive 
                    }
                }
                    }
                
                          
	            if ($NMM.IsPresent)
		            {
			        write-verbose "Install NWClient"
			        invoke-vmxpowershell -config $CloneVMX -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver -Guestuser $Adminuser -Guestpassword $Adminpassword
			        
                    write-verbose "Install NMM"
                    $NMM_Parameter = "-nmm_ver $nmm_ver"
                    If ($SCVMM.IsPresent)
                        {
                        $NMM_Parameter = "$NMM_Parameter -scvmm"
                        }
			        invoke-vmxpowershell -config $CloneVMX -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $NMM_Parameter -Guestuser $Adminuser -Guestpassword $Adminpassword
		            }# End Nmm		
            invoke-postsection -wait
            } # end Clone OK

		} # end HV foreach
		########### leaving NMM Section ###################
		if ($Cluster.IsPresent)
		{
			write-host
			write-verbose "Forming Hyper-V Cluster"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'HVNODE' -IPAddress '$IPv4Subnet.150' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		}
	    if ($ScaleIO.IsPresent)
            {
            write-verbose "configuring mdm"
		    # invoke-vmxpowershell -config $FirstVMX -ScriptPath $Targetscriptdir -Script configure-mdm.ps1 -interactive -Parameter $CommonParameter -Guestuser $Adminuser -Guestpassword $Adminpassword
        
            if ($singlemdm.IsPresent)
                    {
                    Write-Warning "Configuring MDM"
                    invoke-vmxpowershell -config $FirstVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-mdm.ps1 -Parameter "-singlemdm" -interactive 
                    }
            if ($clusteredmdm.IsPresent)
                    {
                    Write-Warning "Configuring MDM"
                    invoke-vmxpowershell -config $FirstVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-mdm.ps1 -Parameter "-CSVnum 3" -interactive 
                    }
            }
		if ($SCVMM.IsPresent)
		    {
			write-verbose "Building SCVMM Setup Configruration"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script set-vmmconfig.ps1 -interactive
			write-verbose "Installing SQL Binaries"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath" -interactive
			write-verbose "Installing SCVMM PREREQS"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $Targetscriptdir -Script install-vmmprereq.ps1 -interactive
            checkpoint-progress -step vmmprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			write-verbose "Installing SCVMM"
            if ($ConfigureVMM.IsPresent)
                {
                Write-Warning "Setup of VMM and Update Rollups in progress, could take up to 20 Minutes"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $Targetscriptdir -Script install-vmm.ps1 -interactive
			    Write-Verbose "Configuring VMM"
                if ($Cluster.IsPresent)
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-vmm.ps1 -Parameter "-Cluster" -interactive
                    }
                    else
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-vmm.ps1 -interactive
                    }
                }
            else
                {
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $Targetscriptdir -Script install-vmm.ps1 -interactive -nowait
		        }
            } #end SCVMM
	} # End Switchblock hyperv
###### new SOFS Block
	"SOFS" {
        $AddonFeatures = "File-Services, RSAT-File-Services, RSAT-ADDS, RSAT-ADDS-TOOLS, Failover-Clustering, RSAT-Clustering, WVR"
		foreach ($Node in ($SOFSSTART..$SOFSNODES))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.21$Node"
			$Nodename = "SOFSNode$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$SourceScriptDir = "$Builddir\$Script_dir\SOFS\"
            $Size = "XL"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $Size
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }

			test-dcrunning
			
			
			# Clone Base Machine
			status $Commentline
			status "Creating SOFS Node Host $Nodename with IP $Nodeip"
			$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir "
			
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $NodeScriptDir
				copy-tovmx -Sourcedir $SourceScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
				invoke-postsection -wait

			}# end Cloneok
			
		} # end foreach
		# if ($Cluster)
		# {
			write-host
			write-verbose "Forming SOFS Cluster"
            do {
                
                }
            until ((Get-VMXToolsState -config $Cluster).State -eq "running")

			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'SOFS' -IPAddress '$IPv4Subnet.210' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script new-sofsserver.ps1 -Parameter "-SOFSNAME 'SOFSServer'  $CommonParameter" -interactive

		# }

	} # End Switchblock SOFS



###### end SOFS Block

	"Sharepoint" {
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
            $Node = 1
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Net-Framework-Features"
            $AddonFeatures = "$AddonFeatures, Web-Server, Web-WebServer, Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-App-Dev"
            $AddonFeatures = "$AddonFeatures, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor"
            $AddonFeatures = "$AddonFeatures, Web-Http-Tracing, Web-Security, Web-Basic-Auth, Web-Windows-Auth, Web-Filtering, Web-Digest-Auth, Web-Performance, Web-Stat-Compression"
            $AddonFeatures = "$AddonFeatures, Web-Dyn-Compression, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, Application-Server, AS-Web-Support, AS-TCP-Port-Sharing"
            $AddonFeatures = "$AddonFeatures, AS-WAS-Support, AS-HTTP-Activation, AS-TCP-Activation, AS-Named-Pipes, AS-Net-Framework, WAS, WAS-Process-Model, WAS-NET-Environment"
            $AddonFeatures = "$AddonFeatures, WAS-Config-APIs, Web-Lgcy-Scripting, Windows-Identity-Foundation, Server-Media-Foundation, Xps-Viewer"
            $Prefix= $SPPrefix
            $SPSize = "TXL"
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.14$Node"
			$Nodename = "$Prefix"+"Node$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$SourceScriptDir = "$Builddir\$Script_dir\$Prefix\"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $AddonFeatures
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }

			test-dcrunning
			# Clone Base Machine
			status $Commentline
			status "Creating Blank Node Host $Nodename with IP $Nodeip"
		    $CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $SPSize -Sourcedir $Sourcedir $cloneparm"
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
			    copy-tovmx -Sourcedir $NodeScriptDir
				copy-tovmx -Sourcedir $SourceScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script powerconf.ps1 -interactive
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-spprereqs.ps1 -interactive
                checkpoint-progress -step spprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
                Write-Verbose "Installing Sharepoint"
                If ($AlwaysOn.IsPresent)
                    {
                    Write-Warning "installing sharepoint customized, could take an hour"
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    }
                else
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-sp.ps1 -interactive
                    }
                if ($NMM.IsPresent)
                    {
				    status "Installing Networker $nmm_ver an NMM $nmm_ver on all Nodes"
					status $CloneVMX
					write-verbose "Install NWClient"
					invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    write-verbose "Install NMM"
					invoke-vmxpowershell -config $CloneVMX -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $nmm_ver -Guestuser $Adminuser -Guestpassword $Adminpassword
					}
				invoke-postsection
			}# end Cloneok


	} # End Switchblock Sharepoint
	"Blanknodes" {
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"}

		foreach ($Node in ($Blankstart..$BlankNodes))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.18$Node"
			$Nodename = "Node$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			# $SourceScriptDir = "$Builddir\$Script_dir\Exchange\"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }

			test-dcrunning
			
			
			# Clone Base Machine
			status $Commentline
			status "Creating Blank Node Host $Nodename with IP $Nodeip"
			if ($VTbit)
			{
				$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir $cloneparm"
			}
			else
			{
				$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir $cloneparm"
			}
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $NodeScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                if ($NW.IsPresent)
                    {
                    write-verbose "Install NWClient"
		            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    }
				invoke-postsection
			}# end Cloneok
			
		} # end foreach

    	if ($Cluster.IsPresent)
		    {
			write-host
			write-verbose "Forming Blanknode Cluster"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'NODE' -IPAddress '$IPv4Subnet.180' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		    }

	} # End Switchblock Blanknode
	
	"Spaces" {
		
		foreach ($Node in (1..$SpaceNodes))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.17$Node"
			$Nodename = "Spaces$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$SourceScriptDir = "$Builddir\$Script_dir\Spaces"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }

			test-dcrunning
			if ($SpaceNodes -gt 1) {$AddonFeatures = "Failover-Clustering, RSAT-Clustering"}
			status $Commentline
			status "Creating Storage Spaces Node Host $Nodename with IP $Nodeip"
			$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -AddOnfeatures $AddonFeature"
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $NodeScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
				invoke-postsection -wait
			}# end Cloneok
			
		} # end foreach
		
		if ($SpaceNodes -gt 1)
		{
			write-host
			write-verbose "Forming Storage Spaces Cluster"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'Spaces' -IPAddress '$IPv4Subnet.170' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		}
		
		
	} # End Switchblock Spaces	
	"SQL" {
		$Node = 1 # chnge when supporting Nodes Parameter and AAG
		###################################################
		# Setup of a Blank Node
		# Init
		$Nodeip = "$IPv4Subnet.13$Node"
		$Nodename = "SQLNODE$Node"
		$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
		$SourceScriptDir = "$Builddir\$Script_dir\SQL\"
		###################################################
		# we need a DC, so check it is running
        Write-Verbose $IPv4Subnet
        write-verbose $Nodename
        write-verbose $Nodeip
        $AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features") 
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
             { 
             Write-verbose "Now Pausing"
             pause
             }
        if ($Cluster.IsPresent) {$AddonFeatures = ("$AddonFeatures", "Failover-Clustering")}
# -AddOnfeatures $AddonFeatures
		test-dcrunning
		# Clone Base Machine
		status $Commentline
		status "Creating $SQLVER Node $Nodename with IP $Nodeip"
		$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -sql"
		###################################################
		If ($CloneOK)
		{
			write-verbose "Copy Configuration files, please be patient"
			copy-tovmx -Sourcedir $NodeScriptDir
			write-verbose "Copy Setup files, please be patient"
			copy-tovmx -Sourcedir $SourceScriptDir
			write-verbose "Waiting System Ready"
			test-user -whois Administrator
			write-Verbose "Starting Customization"
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
			invoke-postsection -wait
            write-verbose "Configure Disks"
            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script prepare-disks.ps1
            write-verbose "Installing SQL Binaries"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER $CommonParameter" -interactive
            <#			
            $SQLSetupStart = Get-Date
			While ($FileOK = (&$vmrun -gu $builddomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\sql.pass) -ne "The file exists.")
			{
				runtime $SQLSetupStart "$SQLVER"
			}
			write-host
			test-user -whois administrator
            #>
            Write-Verbose "Setting SQL Server Roles on $($CloneVMX.vmxname)"
            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script set-sqlroles.ps1 -interactive

			if ($NMM.IsPresent)
			{
				write-verbose "Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				write-verbose "Install NMM"
                
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $nmm_ver
			}# End NoNmm
			Write-Verbose "Importing Database"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script import-database.ps1 -interactive

			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finish_sql.ps1 -interactive -nowait

			#invoke-postsection
		}# end Cloneok
	} #end Switchblock SQL

"Panorama"
{
	###################################################
	# Panorama Setup
	###################################################
	$Nodeip = "$IPv4Subnet.15"
	$Nodename = "Panorama"
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features,Web-Mgmt-Console, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI" 
	###################################################
	status $Commentline
	status "Creating Panorama Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        { 
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }

	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -bridge -Gateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		$SourceScriptDir = "$Builddir\$Script_dir\Panorama\"
		write-verbose "Copy Configuration files, please be patient"
		copy-tovmx -Sourcedir $NodeScriptDir
		copy-tovmx -Sourcedir $SourceScriptDir
		write-verbose "Waiting System Ready"
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        write-verbose "Building Panorama Server"
        invoke-postsection -wait
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script panorama.ps1 -interactive -parameter " $CommonParameter"
	}
} #Panorama End




    "Isilon" {
		<#
		foreach ($Node in (1..$isi_nodes))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodename = "isi_Node$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
            $MasterVMX = "$Builddir\$isimaster\$isimaster.vmx"
			# $SourceScriptDir = "$Builddir\$Script_dir\Exchange\"
			###################################################
			# we need a DC, so check it is running
			# test-dcrunning
		    # Clone Base Machine
			status $Commentline
			status "Creating isilon Node $Nodename"
		
				$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $MyVMnet -Isilon  -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir "
			}
			###################################################
			If ($CloneOK){
			
			}# end Cloneok
			#>
        Write-Verbose "Calling Isilon Installer"
        Invoke-Expression -Verbose "$Builddir\install-isi.ps1 -Nodes $isi_nodes -Disks 4 -Disksize 36GB -MasterPath $Builddir\$ISIMaster -vmnet $VMnet -verbose"
        status "Isilon Setup done"
        workorder "In cluster Setup, please spevcify the following Values already propagated in ad:"
        Progress "Assign internal Addresses from .41 to .56 according to your Subnet"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Cluster Name  ...........: "
        Status "isi2go"
        Workorder -NoNewline -ForegroundColor DarkCyan  "Interface int-a"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Netmask int-a............: "
        Status "255.255.255.0"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Internal Low IP .........: "
        Status "your vmnet1 .41"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Intenal High IP .........: "
        Status "your vmnet1 .56"      
        Workorder -NoNewline -ForegroundColor DarkCyan  "Interface ext-1"        
        Write-Host -NoNewline -ForegroundColor DarkCyan "Netmask ext-1............: "
        Status "255.255.255.0"
        Write-Host -NoNewline -ForegroundColor DarkCyan "External Low IP .........: "
        Status "$IPv4Subnet.41"
        Write-Host -NoNewline -ForegroundColor DarkCyan "External High IP ........: "
        Status "$IPv4Subnet.56"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Default Gateway..........: "
        Status "$IPv4Subnet.$Gatewayhost"
        Workorder "Configure Smartconnect"
        Write-Host -NoNewline -ForegroundColor DarkCyan "smartconnect Zone Name...: "
        Status "onefs.$BuildDomain.local"
        Write-Host -NoNewline -ForegroundColor DarkCyan "smartconnect Service IP .: "
        Status "$IPv4Subnet.40"
        Workorder -NoNewline -ForegroundColor DarkCyan  "Configure DNS Settings"
        Write-Host -NoNewline -ForegroundColor DarkCyan "DNS Server...............: "
        Status "$IPv4Subnet.10"
        Write-Host -NoNewline -ForegroundColor DarkCyan "Search Domain............: "
        Status "$BuildDomain.local"
        ######### Setting Master back to Default Master
		# $MasterVMX = $masterconfig.FullName
        ###############################################
        } # end isilon

}


if ($NW.IsPresent -or $NWServer.IsPresent)
{
	###################################################
	# Networker Setup
	###################################################
	$Nodeip = "$IPv4Subnet.$Gatewayhost"
	$Nodename = $NWNODE
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features" 
	###################################################
	status $Commentline
	status "Creating Networker Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose "Node has ip: $Nodeip"
    if ($nw_ver -ge "nw85")
        {
        $Size = "L"
        }

    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        { 
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }

	test-dcrunning
    If ($IsGateway.IsPresent) { $SetGateway = "-Gateway"}
	$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 9 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -NW $SetGateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		$SourceScriptDir = "$Builddir\$Script_dir\NW\"
		write-verbose "Copy Configuration files, please be patient"
		copy-tovmx -Sourcedir $NodeScriptDir
		copy-tovmx -Sourcedir $SourceScriptDir
		write-verbose "Waiting System Ready"
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		# Setup Networker
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
		write-verbose "Building Networker Server"
		############ java
		write-verbose "installing JAVA"
		$Parm = "/s"
		$Execute = "\\vmware-host\Shared Folders\Sources\$LatestJava"
		do
		{
			($cmdresult = &$vmrun -gu Administrator -gp Password123! runPrograminGuest  $CloneVMX -activeWindow  $Execute $Parm) 2>&1 | Out-Null
			write-log "$origin $cmdresult"
		}
		until ($VMrunErrorCondition -notcontains $cmdresult)
		write-log "$origin $cmdresult"
		###################adobe
		write-verbose "installing Acrobat Reader"
		$Parm = "/sPB /rs"
		$Execute = "\\vmware-host\Shared Folders\Sources\$LatestReader"
		do
		{
			($cmdresult = &$vmrun -gu Administrator -gp Password123! runPrograminGuest  $CloneVMX -activeWindow  $Execute $Parm) 2>&1 | Out-Null
			write-log "$origin $cmdresult"
		}
		until ($VMrunErrorCondition -notcontains $cmdresult)
		write-log "$origin $cmdresult"
		###################
		
		write-verbose "installing Networker Server"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwserver.ps1 -Parameter $nw_ver -interactive
		if (!$IsGateway.IsPresent)
            {
            checkpoint-progress -step networker -reboot
            }
        write-verbose "Waiting for NSR Media Daemon to start"
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "nsrd.exe") { write-host -NoNewline "." }
		write-verbose "Creating Networker users"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script nsruserlist.ps1 -interactive
		status "Creating AFT Device"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script create-nsrdevice.ps1 -interactive -Parameter "-AFTD AFTD1"
		# write-verbose "Creating Networker Clients, Groups and Saveset resources"
		# invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script create-nsrres.ps1 -interactive
        if ($IsGateway.IsPresent){
                write-verbose "Opening Firewall on Networker Server for your Client"
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script firewall.ps1 -interactive
        		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script add-rras.ps1 -interactive -Parameter "-IPv4Subnet $IPv4Subnet"
                checkpoint-progress -step rras -reboot

        }
        invoke-postsection -wait
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-nmc.ps1 -interactive
		progress "Please finish NMC Setup by Double-Clicking Networker Management Console from Desktop on $NWNODE.$builddomain.local"
	    
	}
} #Networker End

$endtime = Get-Date
$Runtime = ($endtime - $Starttime).TotalMinutes
status "Finished Creation of $mySelf in $Runtime Minutes "
status "Deployed VM´s in Scenario $Scenarioname"
get-vmx | where scenario -match $Scenarioname | ft vmxname,state,activationpreference

return
