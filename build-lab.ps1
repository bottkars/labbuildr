<#
.Synopsis
   labbuildr allows you to create Virtual Machines with VMware Workstation from Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM, SCaleIO, OneFS
.DESCRIPTION
   labbuildr is a Self Installing Lab tool for Building VMware Virtual Machines on VMware Workstation
      
      Copyright 2016 Karsten Bott

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
   https://github.com/bottkars/labbuildr/wiki
.EXAMPLE
    build-lab.ps1 -createshortcut
    Creates a Desktop Shortcut for labbuildr
.EXAMPLE
    PS F:\labbuildr .\build-lab.ps1 -HyperV -ScaleIO -clusteredmdm -Disks 3 -defaults -SCVMM -ConfigureVMM -Sourcedir G:\Sources
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
    Build  a Sharepoint Foundation with integrated SQL Server
#>
[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <#
    run build-lab version    #>
	[Parameter(ParameterSetName = "version",Mandatory = $false, HelpMessage = "this will display the current version")][switch]$version,
    <# 
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will update labbuildr from latest git commit")][switch]$Update,
    <#
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "select a branch to update from")][ValidateSet('master','testing','develop')]$branch,
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
    E15 Scenario: Installs a Standalone or DAG Exchange 2013 Installation.
    IP-Addresses: .110 - .119
    #>
	[Parameter(ParameterSetName = "E15",Mandatory = $true)][switch][alias('ex15')]$Exchange2013,
    <# 
    Exchange16 Scenario: Installs a Standalone or DAG Exchange 2016 Installation.
    IP-Addresses: .120 - .129
    #>
	[Parameter(ParameterSetName = "E16",Mandatory = $true)][switch][alias('ex16')]$Exchange2016,
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
    IP-Addresses: .18
    #>
    [Parameter(ParameterSetName = "Panorama")][switch][alias('pn')]$Panorama,
    <#
    Selects the EMC ViPR SRM Binary Install
    IP-Addresses: .17
    #>
	[Parameter(ParameterSetName = "SRM", Mandatory = $true)][switch][alias('srm')]$ViPRSRM,
    [Parameter(ParameterSetName = "SRM")]
    [ValidateSet('3.7.1.0','3.7.0.0','3.6.0.3')]
    $SRM_VER='3.7.1.0',
    <#
    Selects the Microsoft System Center Binary Install
    IP-Addresses: .18
    #>
	[Parameter(ParameterSetName = "SCOM", Mandatory = $true)][switch][alias('SC_OM')]$SCOM,


    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [ValidateSet('SC2012_R2','SCTP3','SCTP4')]$SC_Version = "SC2012_R2",

    <#
    Selects the Blank Nodes Scenario
    IP-Addresses: .180 - .189
    #>
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bn')]$Blanknode,
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bnhv')]$BlankHV,
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('S2D')]$SpacesDirect,
	[Parameter(ParameterSetName = "Blanknodes")][string][alias('CLN')]$ClusterName,
    <#
    Selects the SOFS Scenario
    IP-Addresses: .210 - .219
    #>
    [Parameter(ParameterSetName = "SOFS")][switch]$SOFS,
    #### scenario options #####
    <#
    Determines if Exchange should be installed in a DAG
    #>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAG,
    <# Specify the Number of Exchange Nodes#>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 10)][int][alias('exn')]$EXNodes,
    <# Specify the Starting exchange Node#>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 9)][int][alias('exs')]$EXStartNode = "1",
    <#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'Preview1'
    Default is latest
    CU Location is [Driveletter]:\sources\e2016[cuver], e.g. c:\sources\e2016Preview1
    #>
	[Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [ValidateSet('Preview1','final')]$e16_cu,
<#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'cu1','cu2','cu3','cu4','sp1','cu6','cu7'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [ValidateSet('cu1', 'cu2', 'cu3', 'sp1','cu5','cu6','cu7','cu8','cu9','cu10','CU11')][alias('ex_cu')]$e15_cu,
    <# schould we prestage users ? #>	
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$nouser,
    <# Install a DAG without Management IP Address ? #>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAGNOIP,
    <# Specify Number of Spaces Hosts #>
    [Parameter(ParameterSetName = "Spaces", Mandatory = $false)][ValidateRange(1, 2)][int]$SpaceNodes = "1",
    <# Specify Number of Hyper-V Hosts #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 9)][int][alias('hvnodes')]$HyperVNodes = "1",
	<# ScaleIO on hyper-v #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch][alias('sc')]$ScaleIO,
	<# ScaleIO on hyper-v #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][string]
    [ValidateSet('2.0-5014.0','1.30-426.0','1.31-258.2','1.31-1277.3','1.31-2333.2','1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5')]
    [alias('siover')]$ScaleIOVer,
    <# single mode with mdm only on first node ( no secondary, no tb ) #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$singlemdm,
    # <# Cluster modemdm automatically#>
    # [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$clusteredmdm,
    <# SCVMM on last Node ? #>	
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$SCVMM,
    <# Configure VMM ?#>
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
	[ValidateSet('SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014')]$SQLVER,
    
    ######################### common Parameters start here in Order
    <# reads the Default Config from defaults.xml
    <config>
    <nmm_ver>nmm82</nmm_ver>
    <nw_ver>nw82</nw_ver>
    <master>2012R2UEFIMASTER</master>
    <sqlver>SQL2014</sqlver>
    <e15_cu>cu6</e15_cu>
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
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
   	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[switch]$defaults,

    <#do we want Tools Update? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Switch]$Toolsupdate,

    
    <# Wich version of OS Master should be installed
    '2012R2FallUpdate','2012R2U1MASTER','2012R2MASTER','2012R2UMASTER','2012MASTER','2012R2UEFIMASTER','vNextevalMaster','RELEASE_SERVER'
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateSet('2016TP4','2016TP3','2012R2FallUpdate','2012R2UEFIMASTER')]$Master,
    <#do we want a special path to the Masters ? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ })]$Masterpath,
    <# Do we want Additional Disks / of additional 100GB Disks for ScaleIO. The disk will be made ready for ScaleIO usage in Guest OS#>	
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 6)][int][alias('ScaleioDisks')]$Disks,
      <#
    Enable the default gateway 
    .103 will be set as default gateway, NWserver will have 2 Nics, NIC2 Pointing to NAT serving as Gateway
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [switch][alias('gw')]$Gateway,
<# select vmnet, number from 1 to 19#>                                        	
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet,

 #   [Parameter(Mandatory = $false, HelpMessage = "Enter a valid VMware network Number vmnet between 1 and 19 ")]
<# This stores the defaul config in defaults.xml#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$savedefaults,

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
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL', 'TXL', 'XXL', 'XXXL')]$Size = "M",
	
<# Specify your own Domain name#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,15}[a-zA-Z0-9]+$")][string]$BuildDomain,
	
<# Turn this one on if you would like to install a Hypervisor inside a VM #>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$VTbit,
		
####networker 	
    <# install Networker Modules for Microsoft #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	#[ValidateSet('nmm8221','nmm822','nmm8211','nmm8212','nmm8214','nmm8216','nmm8217','nmm8218','nmm822','nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3013', 'nmm82','nmm85','nmm85.BR1','nmm85.BR2','nmm85.BR3','nmm85.BR4','nmm90.DA','nmm9001','nmm9002')]
    [ValidateSet('nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm821')]
    $nmm_ver,
	
<# Indicates to install Networker Server with Scenario #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NW,
    <#
Version Of Networker Server / Client to be installed
    'nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nwunknown'
mus be extracted to [sourcesdir]\[nw_ver], ex. c:\sources\nw82
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [ValidateSet('nw90.DA','nw9001','nw9002','nw9003','nw9004',
    'nw8223','nw8222','nw8221','nw822',
    'nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821',
    'nw8206','nw8205','nw8204','nw8203','nw8202','nw82',
    'nw8137','nw8136','nw8135','nw8134','nw8133','nw8132','nw8131','nw813',
    'nw8127','nw8126','nw8125','nw8124','nw8123','nw8122','nw8121','nw812',
    'nw8119','nw8118','nw8117','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',
    'nw8105','nw8104','nw8103','nw8102','nw81',
    'nw81044','nw8043','nw8042','nw8041',
    'nw8036','nw8035','nw81034','nw8033','nw8032','nw8031',
    'nw8026','nw8025','nw81024','nw8023','nw8022','nw8021',
    'nw8016','nw8015','nw81014','nw8013','nw8012',
    'nw8007','nw8006','nw8005','nw81004','nw8003','nw8002','nw80',
    'nwunknown')]
    $nw_ver,

### network Parameters ######

<# Disable Domainchecks for running DC
This should be used in Distributed scenario´s
 #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [switch]$NoDomainCheck,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Validatepattern(‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’)]$MySubnet,

<# Specify your IP Addressfamilie/s
Valid values 'IPv4','IPv6','IPv4IPv6'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily, 

<# Specify your IPv6 ULA Prefix, consider https://www.sixxs.net/tools/grh/ula/  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateScript({$_ -match [IPAddress]$_ })]$IPV6Prefix,

<# Specify your IPv6 ULA Prefix Length, #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [String]$Sourcedir,
	#[Validatescript({Test-Path -Path $_ })][String]$Sourcedir,

    <#
     run build-lab -update -force to force an update
    #>
    [Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will force update labbuildr")]
    [switch]$force,


    <# Turn on Logging to Console#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[switch]$ConsoleLog
) # end Param

#requires -version 3.0
#requires -module vmxtoolkit
#requires -module labtools 
###################################################
### VMware Master Script
###################################################
[string]$Myself = $MyInvocation.MyCommand
#$AddressFamily = 'IPv4'
$IPv4PrefixLength = '24'
$myself = $Myself.TrimEnd(".ps1")
$Starttime = Get-Date
$Builddir = $PSScriptRoot
try
    {
    $Current_labbuildr_branch = Get-Content  ($Builddir + "\labbuildr.branch") -ErrorAction Stop
    }
catch
    {
    Write-Host -ForegroundColor Gray " ==> no prevoius branch"
    If (!$PSCmdlet.MyInvocation.BoundParameters['branch'].IsPresent)
        {
        $Current_labbuildr_branch = "master"
        }
    else
        {
        $Current_labbuildr_branch = $branch
        }
    }
If (!$PSCmdlet.MyInvocation.BoundParameters["branch"].IsPresent)
     {
     $PSCmdlet.MyInvocation.BoundParameters["branch"].IsPresent
     # $branch = $Current_labbuildr_branch
     }
Write-Verbose "Branch = $branch"
Write-Verbose "Current Branch = $Current_labbuildr_branch"
if ([String]::IsNullOrEmpty($PSCmdlet.MyInvocation.BoundParameters['branch']))
    {
    $branch = $Current_labbuildr_branch
    }
Write-Verbose "Branch = $branch"
Write-Verbose "Current Branch = $Current_labbuildr_branch"

try
    {
    $verlabbuildr = New-Object System.Version (Get-Content  ($Builddir + "\labbuildr4.version") -ErrorAction Stop).Replace("-",".")
    }
catch
    {
    $verlabbuildr = "00.0000"
    }
try
    {
    $vervmxtoolkit = New-Object System.Version (Get-Content  ($Builddir + "\vmxtoolkit.version") -ErrorAction Stop).Replace("-",".")
    }
catch
    {
    $vervmxtoolkit = "00.0000"
    }
try
    {
    [datetime]$Latest_labbuildr_git = Get-Content  ($Builddir + "\labbuildr-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labbuildr_scripts_git = Get-Content  ($Builddir + "\labbuildr-scripts-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_scripts_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labtools_git = Get-Content  ($Builddir + "\labtools-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labtools_git = "07/11/2015"
    }


try
    {
    [datetime]$Latest_vmxtoolkit_git = Get-Content  ($Builddir + "\vmxtoolkit-$branch.gitver") -ErrorAction Stop
    }
catch
    {
    [datetime]$Latest_vmxtoolkit_git = "07/11/2015"
    }

try
    {
    [datetime]$Latest_SIOToolKit_git = Get-Content  ($Builddir + "\SIOToolKit-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_SIOToolKit_git = "07/11/2015"
    }

################## Statics
$LogFile = "$Builddir\$(Get-Content env:computername).log"
$WAIKVER = "WAIK"
$domainsuffix = ".local"
$AAGDB = "AWORKS"
$major = "2016"
$Edition = "Spring"
$Default_vmnet = "vmnet2"
$Default_BuildDomain = "labbuildr"
$Default_Subnet = "192.168.2.0"
$Default_IPv6Prefix = "FD00::"
$Default_IPv6PrefixLength = '8'
$Default_AddressFamily = "IPv4"
$latest_ScaleIOVer = '2.0-5014.0'
$ScaleIO_OS = "Windows"
$ScaleIO_Path = "ScaleIO_$($ScaleIO_OS)_SW_Download"
$latest_nmm = 'nmm9004'
$latest_nw = 'nw9004'
$latest_e16_cu = 'final'
$latest_e15_cu = 'cu11'
$latest_sqlver  = 'SQL2014SP1slip'
$latest_master = '2012R2FallUpdate'
$latest_sql_2012 = 'SQL2012SP2'
$SIOToolKit_Branch = "master"
$NW85_requiredJava = "jre-7u61-windows-x64"
$latest_java8uri = "http://javadl.sun.com/webapps/download/AutoDL?BundleId=107944"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$Dots = [char]58
[string]$Commentline = "#######################################################################################################################"
$WAIKVER = "WAIK"
$DCNODE = "DCNODE"
$NWNODE = "NWSERVER"
$SPver = "SP2013SP1fndtn"
$SPPrefix = "SP2013"
$Sleep = 10
[string]$Sources = "Sources"
$Sourcedirdefault = "c:\$Sources"
$Scripts = "Scripts"
$Sourceslink = "https://my.syncplicity.com/share/wmju8cvjzfcg04i/sources"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "11" 
$Host_ScriptDir = "$Builddir\$Scripts\"
$IN_Guest_UNC_Scriptroot = "\\vmware-host\Shared Folders\$Scripts"
$IN_Guest_UNC_Sourcepath = "\\vmware-host\Shared Folders\Sources"
$IN_Guest_UNC_NodeScriptDir = "$IN_Guest_UNC_Scriptroot\Node"
$IN_Guest_LogDir = "C:\Scripts"
#$IN_Guest_UNC_NodeScriptDir = "$IN_Guest_UNC_Scriptroot\Node"
##################
### VMrun Error Condition help to tune the Bug wher the VMRUN Command can not communicate with the Host !
$VMrunErrorCondition = @("Waiting for Command execution Available", "Error", "Unable to connect to host.", "Error: The operation is not supported for the specified parameters", "Unable to connect to host. Error: The operation is not supported for the specified parameters", "Error: vmrun was unable to start. Please make sure that vmrun is installed correctly and that you have enough resources available on your system.", "Error: The specified guest user must be logged in interactively to perform this operation")
$Host.UI.RawUI.WindowTitle = "$Buildname"
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
			($cmdresult = &$vmrun -gu $Adminuser -gp $Adminpassword copyfilefromhosttoguest $CloneVMX $Sourcedir$file $IN_Guest_UNC_Scriptroot$file) 2>&1 | Out-Null
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
####
function update-fromGit
{
	param (
            [string]$Repo,
            [string]$RepoLocation,
            [string]$branch,
            [datetime]$latest_local_Git,
            [string]$Destination,
            [switch]$delete
            )
        $branch =  $branch.ToLower()
        $Isnew = $false
        Write-Verbose "Using update-fromgit function for $repo"
        $Uri = "https://api.github.com/repos/$RepoLocation/$repo/commits/$branch"
        $Zip = ("https://github.com/$RepoLocation/$repo/archive/$branch.zip").ToLower()
        try
            {
            $request = Invoke-WebRequest -UseBasicParsing -Uri $Uri -Method Head -ErrorAction Stop
            }
        Catch
            {
            Write-Warning "Error connecting to git"
            if ($_.Exception.Response.StatusCode -match "Forbidden")
                {
                Write-Host -ForegroundColor Gray " ==> Status inidicates that Connection Limit is exceeded"
                }
            exit
            }
        [datetime]$latest_OnGit = $request.Headers.'Last-Modified'
                Write-Verbose "We have $repo version $latest_local_Git, $latest_OnGit is online !"
                $latest_local_Git -lt $latest_OnGit
                if ($latest_local_Git -lt $latest_OnGit -or $force.IsPresent )
                    {
                    $Updatepath = "$Builddir\Update"
					if (!(Get-Item -Path $Updatepath -ErrorAction SilentlyContinue))
					        {
						    $newDir = New-Item -ItemType Directory -Path "$Updatepath" | out-null
                            }
                    Write-Host -ForegroundColor Gray "We found a newer Version for $repo on Git Dated $($request.Headers.'Last-Modified')"
                    if ($delete.IsPresent)
                        {
                        Write-Verbose "Cleaning $Destination"
                        Remove-Item -Path $Destination -Recurse -ErrorAction SilentlyContinue
                        }
                    Get-LABHttpFile -SourceURL $Zip -TarGetFile "$Builddir\update\$repo-$branch.zip" -ignoresize
                    Expand-LABZip -zipfilename "$Builddir\update\$repo-$branch.zip" -destination $Destination -Folder $repo-$branch
                    $Isnew = $true
                    $request.Headers.'Last-Modified' | Set-Content ($Builddir+"\$repo-$branch.gitver") 
                    }
                else 
                    {
                    Status "No update required for $repo on $branch, already newest version "                    
                    }
if ($Isnew) {return $true}
}
#####
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
        Write-verbose "Starting Download of $DownLoadUrl"
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
    Write-Host -ForegroundColor Gray " ==> No download needed, file exists" 
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
    if ($Toolsupdate.IsPresent)
        {
        Write-Host -ForegroundColor Gray " ==> Preparing VMware Tools Upgrade by injecting tools CD ( update will start before next reboot of VM )"
        Start-Process 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe' -ArgumentList  "installTools $CloneVMX" -NoNewWindow
        }
    Write-Host -ForegroundColor Magenta "Configuring Node and Features and Joining Domain $BuildDomain"
	do
        {
        Write-Verbose "Joining Domain $BuildDomain"
        Write-Verbose "Calling $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-node.ps1 -Parameter -nodeip $Nodeip -nodename $Nodename -Domain $BuildDomain -domainsuffix $domainsuffix -IPv4subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix $AddGateway -AddOnfeatures '$AddonFeatures' $CommonParameter"
        $domainadd = invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-node.ps1 -Parameter "-nodeip $Nodeip -nodename $Nodename -Domain $BuildDomain -domainsuffix $domainsuffix -IPv4subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix $AddGateway -AddOnfeatures '$AddonFeatures' $CommonParameter" -nowait -interactive # $CommonParameter
        }
    until ($domainadd -match "success")

    Write-Host -ForegroundColor Gray "Waiting for Phase Domain Joined"
    do {
        $ToolState = Get-VMXToolsState -config $CloneVMX
        Write-Verbose $ToolState.State
        }
    until ($ToolState.state -match "running")
    Write-Verbose "Paranoia, checking shared folders second time"
    $Folderstate = Set-VMXSharedFolderState -VMXName $nodename -config $CloneVMX -enabled
    Write-Verbose "Please Check inside VM for Network Warnings"
	While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\3.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
    Write-Host "Done"
    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-labshortcut.ps1 -interactive # -Parameter $CommonParameter
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
	# copy-vmxguesttohost -Guestpath "$Scripts\domain.txt" -Hostpath "$Builddir\domain.txt" -Guest $DCNODE
	$holdomain = Get-Content "$Builddir\$Scripts\$DCNODE\domain.txt"
	status $holdomain
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Subnet.........: "
	#copy-vmxguesttohost -Guestpath "C:\$Scripts\ip.txt" -Hostpath "$Builddir\ip.txt" -Guest $DCNODE
	$DomainIP = Get-Content "$Builddir\$Scripts\$DCNODE\ip.txt"
	$IPv4subnet = convert-iptosubnet $DomainIP
	status $ipv4Subnet

	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Default Gateway: "
	#copy-vmxguesttohost -Guestpath "C:\$Scripts\Gateway.txt" -Hostpath "$Builddir\Gateway.txt" -Guest $DCNODE
	$DomainGateway = Get-Content "$Builddir\$Scripts\$DCNODE\Gateway.txt"
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
				debug "Please Download and extraxt $Version to $Sourcedir\$Version"
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
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\Node" -Script set-step.ps1 -nowait -interactive -Parameter " -step $step $AddParameter" # $CommonParameter
	write-Host
    if (!$Nowait.IsPresent)
        {
	    write-verbose "Waiting for Checkpoint $step"
        do {
            $ToolState = Get-VMXToolsState -config $CloneVMX
            Write-Verbose $ToolState.State
            }
        until ($ToolState.state -match "running")
	    While ($FileOK = (&$vmrun -gu $Adminuser -gp $Adminpassword fileExistsInGuest $CloneVMX "$IN_Guest_LogDir\$step.pass") -ne "The file exists.") { Write-Host -NoNewline "."; write-log "$FileOK $Origin"; sleep $Sleep }
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
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_NodeScriptDir" -Script powerconf.ps1 -interactive # $CommonParameter
	write-verbose "Configuring UAC"
    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_NodeScriptDir" -Script set-uac.ps1 -interactive # $CommonParameter
    if ($LabDefaults.Puppet)
        {
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\Node" -Script install-puppetagent.ps1 -Parameter "-Puppetmaster $Puppetmaster" -interactive # $CommonParameter
        }
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
    "update" 
        {
        $ReloadProfile = $False
        $Repo = "labbuildr"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_git
        $Destination = "$Builddir"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination
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
            }
        else 
            {
            Write-Host "No Deletions required"
            }



        ####
        $Repo = "labbuildr-scripts"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_scripts_git
        $Destination = "$Builddir\$Scripts"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete
        ####
        $Repo = "labtools"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labtools_git
        $Destination = "$Builddir\$Repo"
        if ($Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete)
            {
            $ReloadProfile = $True
            }
        ####
        $Repo = "VMXToolKit"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_vmxtoolkit_git
        $Destination = "$Builddir\VMXToolKit"
        if ($Hasupdate = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete)
            {
            $ReloadProfile = $True
            }
        ####
        $Repo = "SIOToolKit"
        $RepoLocation = "emccode"
        $Latest_local_git = $Latest_SIOToolkit_git
        $Destination = "$Builddir\SIOToolKit"
        $Hasupdate = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination
        $Branch | Set-Content -Path "$Builddir\labbuildr.branch" -Force # -Verbose

        if ($ReloadProfile)
            {
            Remove-Item .\Update -Recurse -Confirm:$false
			status "Update Done"
            status "press any key for reloading Modules"
            pause
            ./profile.ps1
            }
        else
            {
            ./build-lab.ps1
            }

    return 
    #$ReloadProfile
    }# end Updatefromgit
			
    "Shortcut"
        {
				status "Creating Desktop Shortcut for $Buildname"
				createshortcut
                return
    }# end shortcut
    "Version"
        {
				Write-Host -ForegroundColor Magenta -NoNewline "labbuildr version $major-$Edition on branch : " 
                Write-Host -ForegroundColor Cyan "$Current_labbuildr_branch"

                if ($Latest_labbuildr_git)
                    {
                    Status "labbuildr Git Release $Latest_labbuildr_git"
                    }
                if ($Latest_vmxtoolkit_git)
                    {
                    Status "vmxtoolkit Git Release $Latest_vmxtoolkit_git"
                    }
                if ($Latest_labbuildr_scripts_git)
                    {
                    Status "scripts Git Release $Latest_labbuildr_scripts_git"
                    }
                if ($Latest_labtools_git)
                    {
                    Status "labtools Git Release $Latest_labtools_git"
                    }

                Write-Host -ForegroundColor Gray '   Copyright 2016 Karsten Bott

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
#################### default Parameter Section Start
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
        $LabDefaults = Get-LABDefaults
        }
       if (!($LabDefaults))
                {
                try
                    {
                    $LabDefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                    }
                catch
                    {
                Write-Warning "no  defaults or example defaults found, exiting now"
                exit
                    }
        Write-Host -ForegroundColor Magenta "Using generic defaults from labbuildr"
        }
        $DefaultGateway = $LabDefaults.DefaultGateway
        if (!$nmm_ver)
            {
            try
                {
                $nmm_ver = $LabDefaults.nmm_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==> defaulting NMM version to $latest_nmm"
                 $nmm_ver = $latest_nmm
                }
            } 
        $nmm_scvmm_ver = $nmm_ver -replace "nmm","scvmm"
        if (!$nw_ver)
            {
            try
                {
                $nw_ver = $LabDefaults.nw_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==> defaulting nw version to $latest_nw"
                 $nw_ver = $latest_nw
                }
            } 
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = $LabDefaults.Masterpath
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
       
        if (!$Sourcedir)
            {
            try
                {
                $Sourcedir = $LabDefaults.Sourcedir
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Host -ForegroundColor Gray " ==> No sources specified, trying default"
                $Sourcedir = $Sourcedirdefault
                }
            }

        if (!$Master) 
            {
            try
                {
                $master = $LabDefaults.master
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Master specified, trying default"
                $Master = $latest_master
                }
            }
        if (!$SQLVER)
            {   
            try
                {
                $sqlver = $LabDefaults.sqlver
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No sqlver specified, trying default"
                $sqlver = $latest_sqlver
                }
            }
        if (!$e15_cu) 
            {
            try
                {
                $e15_cu = $LabDefaults.e15_cu
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2013 CU Specified, setting $latest_e15_cu"
                $e15_cu = $latest_e15_cu
                }
            }
        if (!$e16_cu) 
            {
            try
                {
                $e16_cu = $LabDefaults.e16_cu
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2016 CU Specified, setting $latest_e16_cu"
                $e16_cu = $latest_e16_cu
                }
            }
        if (!$ScaleIOVer) 
            {
            try
                {
                $ScaleIOVer = $LabDefaults.ScaleIOVer
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No ScaleIOVer specified, trying default"
                $ScaleIOVer = $latest_ScaleIOVer
                }
            }
        if (!$vmnet) 
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
        if (!$BuildDomain) 
            {
            try
                {
                $BuildDomain = $LabDefaults.BuildDomain
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No BuildDomain specified, trying default"
                $BuildDomain = $Default_BuildDomain
                }
            } 
        if  (!$MySubnet) 
            {
            try
                {
                $MySubnet = $LabDefaults.mysubnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No mysubnet specified, trying default"
                $MySubnet = $Default_Subnet
                }
            }
       if (!$vmnet) 
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
       if (!$AddressFamily) 
            {
            try
                {
                $AddressFamily = $LabDefaults.AddressFamily
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No AddressFamily specified, trying default"
                $AddressFamily = $Default_AddressFamily
                }
            }
       if (!$IPv6Prefix) 
            {
            try
                {
                $IPv6Prefix = $LabDefaults.IPv6Prefix
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No IPv6Prefix specified, trying default"
                $IPv6Prefix = $Default_IPv6Prefix
                }
            }
       if (!$IPv6PrefixLength) 
            {
            try
                {
                $IPv6PrefixLength = $LabDefaults.IPv6PrefixLength
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No IPv6PrefixLength specified, trying default"
                $IPv6PrefixLength = $Default_IPv6PrefixLength
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("Gateway")))
            {
            if ($LabDefaults.Gateway -eq "true")
                {
                $Gateway = $true
                [switch]$NW = $True
                $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NoDomainCheck")))
            {
            if ($LabDefaults.NoDomainCheck -eq "true")
                {
                [switch]$NoDomainCheck = $true
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NMM")))
            {
            if ($LabDefaults.NMM -eq "true")
                {
                $nmm = $true
                $nw = $true
                }
            }
        
    }
if (!$MySubnet) {$MySubnet = "192.168.2.0"}
$IPv4Subnet = convert-iptosubnet $MySubnet
if (!$BuildDomain) { $BuildDomain = $Default_BuildDomain }
if (!$ScaleIOVer) {$ScaleIOVer = $latest_ScaleIOVer}
if (!$SQLVER) {$SQLVER = $latest_sqlver}
if (!$e15_cu) {$e15_cu = $latest_e15_cu}
if (!$e16_cu) {$e16_cu = $latest_e16_cu}
if (!$Master) {$Master = $latest_master}
if (!$nmm_ver) {$nmm_ver= $latest_nmm}
if (!$nw_ver) {$nw_ver= $latest_nw}
if (!$vmnet) {$vmnet = $Default_vmnet}
if (!$IPv6PrefixLength){$IPv6PrefixLength = $Default_IPv6PrefixLength}
if (!$LabDefaults.DNS1)
    {
    $DNS1 = "$IPv4Subnet.10"
    } 
else 
    {
    $DNS1 = $LabDefaults.DNS1
    }
write-verbose "After defaults !!!! "
Write-Verbose "Sourcedir : $Sourcedir"
Write-Verbose "NWVER : $nw_ver"
Write-Verbose "Gateway : $($Gateway.IsPresent)"
Write-Verbose "NMM : $($nmm.IsPresent)"
Write-Verbose "MySubnet : $MySubnet"
Write-Verbose "ScaleIOVer : $ScaleIOVer"
Write-Verbose "Masterpath : $Masterpath"
Write-Verbose "Master : $Master"
Write-Verbose "Defaults before Safe:"
If ($DefaultGateway -match "$IPv4Subnet.$Gatewayhost")
    {
    $gateway = $true
    }
If ($Gateway.IsPresent)
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
$config += ("<e15_cu>$e15_cu</e15_cu>")
$config += ("<e16_cu>$e16_cu</e16_cu>")
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
$config += ("<DNS1>$($DNS1)</DNS1>")
$config += ("<NMM>$($NMM.IsPresent)</NMM>")
$config += ("<Masterpath>$Masterpath</Masterpath>")
$config += ("<NoDomainCheck>$NoDomainCheck</NoDomainCheck>")
$config += ("<Puppet>$($LabDefaults.Puppet)</Puppet>")
$config += ("<PuppetMaster>$($LabDefaults.PuppetMaster)</PuppetMaster>")
$config += ("<Hostkey>$($LabDefaults.HostKey)</Hostkey>")
$config += ("</config>")
$config | Set-Content $defaultsfile
}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent -and $savedefaults.IsPresent )
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
    try
        {
        Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null 
        }
        catch
        [System.Management.Automation.DriveNotFoundException] 
        {
        Write-Warning "Drive not found, make sure to have your Source Stick connected"
        exit
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
        Write-Warning "no sources directory found named $Sourcedir"
        exit
        }


     }
if (!$Master)
    {
    Write-Warning "No Master was specified. See get-help .\labbuildr.ps1 -Parameter Master !!"
    Write-Host -ForegroundColor Gray " ==> Load masters from $UpdateUri"
    break
    } # end Master
    Try
    {
    $MyMaster = get-vmx -path "$Masterpath\$Master"
    }
    catch [Exception] 
    {
    Write-Warning "Could not find $Masterpath\$Master"
    Write-Host -ForegroundColor Gray " ==> Please download a Master from https://github.com/bottkars/labbuildr/wiki/Master"
    Write-Host -ForegroundColor Gray " ==> And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
if (!$MyMaster)
    {
    Write-Warning "Could not find $Masterpath\$Master"
    Write-Host -ForegroundColor Gray " ==> Please download a Master from https://github.com/bottkars/labbuildr/wiki/Master"
    Write-Host -ForegroundColor Gray " ==> And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
else
    {
   $MasterVMX = $mymaster.config		
   Write-Verbose "We got master $MasterVMX"
   }
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
# get-vmwareversion
####### Building required Software Versions Tabs
$NW_Sourcedir = Join-Path $Sourcedir "Networker"
$Sourcever = @()
# $Sourcever = @("$nw_ver","$nmm_ver","E2013$e15_cu","$WAIKVER","$SQL2012R2")
if (!($DConly.IsPresent))
{
	if ($Exchange2013.IsPresent) 
        {
        $EX_Version = "E2013"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
    if ($Exchange2016.IsPresent) 
        {
        $EX_Version = "E2016"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
	#  if (($NMM.IsPresent) -and ($Blanknode -eq $false)) { $Sourcever += $nmm_ver }
	# if ($NW.IsPresent) { $Sourcever += $nw_ver }
	# if ($NWServer.IsPresent -or $NW.IsPresent -or $NMM.IsPresent ) 
    #    { 
    #    $Sourcever += $nw_ver 
    #    }
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
status "Version $($major).$Edition"
#status "# running Labuildr Build $verlabbuildr"
# status "# and vmxtoolkit   Build $vervmxtoolkit"

workorder "Building Proposed Workorder"
If ($DAG.IsPresent)
    {
    if (!$EXNodes)
        {
        $EXNodes = 2 
        Write-Host -ForegroundColor Gray " ==> No -EXnodes specified, defaulting to $EXNodes Nodes for DAG Deployment"
        }
    }
if ($Blanknode.IsPresent)
{
	workorder "We are going to Install $BlankNodes Blank Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"

    workorder "The Gateway will be $DefaultGateway"
	if ($VTbit) { write-verbose "Virtualization will be enabled in the Nodes" }
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered" }
}
if ($SOFS.IsPresent)
{
	workorder "We are going to Install $SOFSNODES SOFS Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
    if ($DefaultGateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}
if ($HyperV.IsPresent)
{
	
	
}#end Hyperv.ispresent
if ($ScaleIO.IsPresent)
{
    If ($HyperVNodes -lt 3)
                {
                Write-Host -ForegroundColor Gray " ==> Need 3 nodes for ScaleIO, incrementing to 3"
                $HyperVNodes = 3
                }	
workorder "We are going to Install ScaleIO on $HyperVNodes Hyper-V  Nodes"
    if ($DefaultGateway.IsPresent){ workorder "The Gateway will be $DefaultGateway"}
	# if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}
if ($AlwaysOn.IsPresent -or $PsCmdlet.ParameterSetName -match "AAG" -or $SPdbtype -eq "AlwaysOn")
{
	workorder "We are going to Install an SQL Always On Cluster with $AAGNodes Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet"
	$AlwaysOn = $true
    # if ($NoNMM -eq $false) {status "Networker Modules will be installed on each Node"}
}
#if ($NWServer.IsPresent -or $NW.IsPresent)
##### exchange downloads section
if ($Exchange2013.IsPresent)
{
    if (!$e15_cu)
        {
        $e15_cu = $Latest_e15_cu
        }

    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2013 -e15_cu $e15_cu -Destination $Sourcedir -unzip))
        {
        Write-Host -ForegroundColor Gray " ==> We could not receive Exchange 2013 $e15_cu"
        return
        }

    $EX_Version = "E2013"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  "$Destination\$FileName"))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { Write-Host -ForegroundColor Gray " ==> Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==> Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName" | out-null
                }
            }

        
        }
    
	    if ($DAG.IsPresent)
	        {
		    Write-Host -ForegroundColor Yellow "We will form a $EX_Version $EXNodes-Node DAG"
	        }

}
#########

##### exchange 2016 downloads section
if ($Exchange2016.IsPresent)
{
    if (!$e16_cu)
        {
        $e16_cu = $Latest_e16_cu
        }

    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2016 -e16_cu $e16_cu -Destination $Sourcedir -unzip))
        {
        Write-Warning "We could not receive Exchange 2016 $e16_cu"
        return
        }

    $EX_Version = "E2016"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  "$Destination\$FileName"))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { Write-Host -ForegroundColor Gray " ==> Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==> Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName" | out-null
                }
            }

        
        }
    
	    if ($DAG.IsPresent)
	        {
		    Write-Host -ForegroundColor Yellow "We will form a $EXNodes-Node DAG"
	        }

}
#########

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
                Write-Warning "Error Downloading file $Url, Please check connectivity"
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
                Write-Warning "Error Downloading file $Url, Please check connectivity"
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
                Write-Warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            Write-Verbose "Extracting $FileName"
            Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/extract:$Sourcedir\$SPver /quiet /passive" -Wait
            }
    workorder "We are going to Install Sharepoint 2013 in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet and SQL"
    }# end SPPREREQ
if ($ConfigureVMM.IsPresent)
    {
    [switch]$SCVMM = $true
    }

############## scvmm  download section
if ($SCVMM.IsPresent)
  {
    Write-Host -ForegroundColor Gray " ==> Entering SCVMM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "prereq"
    if ($SC_Version -match "2012")
        {
        $SQLVER = "SQL2012SP2"
        }
    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCVMM -Destination $Sourcedir -unzip))
        {
        Write-Warning "We could not receive scvmm"
        return
        }

    }# end SCOMPREREQ


############## SCOM  download section
if ($SCOM.IsPresent)
  {
    Write-Host -ForegroundColor Gray " ==> Entering SCOM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "prereq"
    if ($SC_Version -match "2012")
        {
        $SQLVER = "SQL2012SP2"
        }

    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCOM -Destination $Sourcedir -unzip))
        {
        Write-Warning "We could not receive scom"
        return
        }

    }# end SCOMPREREQ
############## SCVMM download section
#######



#################
if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
    {
    $AAGURL = "https://community.emc.com/servlet/JiveServlet/download/38-111250/AWORKS.zip"
    $URL = $AAGURL
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $FileName in $Sourcedir"
    if (!(test-path  "$Sourcedir\Aworks\AdventureWorks2012.bak"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            Write-Warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        #New-Item -ItemType Directory -Path "$Sourcedir\Aworks" -Force
        Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
        }

    if (!($SQL_OK = receive-labsql -SQLVER $SQLVER -Destination $Sourcedir -Product_Dir "SQL" -extract))
        {
        break
        }

}
if ($Panorama.IsPresent)
    {
    $Targetir = "$Sourcedir/panorama"
    if (Test-Path "$Sourcedir/panorama/Syncplicity Panorama.msi")
        {
        Write-Verbose "Syncplicity found"
        }
    else
        {
        Write-Host -ForegroundColor Gray " ==> We need to get Panorama trying Automated Download"
        $url = "https://download.syncplicity.com/panorama-connector/Syncplicity Panorama.msi"
        if ($url)
            {
            $FileName = Split-Path -Leaf -Path $Url
            get-prereq -DownLoadUrl $url -destination "$Sourcedir/panorama/$FileName"
            }
        }
     }

############## networker dowwnload section

if ($NWServer.IsPresent -or $NMM.IsPresent -or $NW.IsPresent)
    {
    if ((Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/networker.msi") -or (Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/lgtoclnt-*.exe"))
        {
        Write-Host "Networker $nw_ver found"
        }
    else #if ($nw_ver -lt "nw84")
        {
        Write-Host -ForegroundColor Gray " ==> We need to get $NW_ver, trying Automated Download"
        $NW_download_ok  =  receive-LABNetworker -nw_ver $nw_ver -arch win_x64 -Destination $NW_Sourcedir -unzip # $CommonParameter
        if ($NW_download_ok)
            {
            Write-Host -ForegroundColor Magenta "Received $nw_ver"
            }
        else
            {
            Write-Warning "We can only autodownload Cumulative Updates from ftp, please get $nw_ver from support.emc.com"
            break
            }

      } #end elseif
}
if ($NMM.IsPresent)
    {

    if ((Test-Path "$NW_Sourcedir/$nmm_ver/win_x64/networkr/NetWorker Module for Microsoft.msi") -or (Test-Path "$NW_Sourcedir/$nmm_ver/win_x64/networkr/NWVSS.exe"))
        {
        Write-Verbose "Networker NMM $nmm_ver found"
        }
    else
        {
        Write-Host -ForegroundColor Gray " ==> We need to get $NMM_ver, trying Automated Download"
        $Nmm_download_ok  =  receive-LABnmm -nmm_ver $nmm_ver -Destination $NW_Sourcedir -unzip # $CommonParameterReceive-LABnmm -
      }
    }
####SACELIO Downloader #####
if ($ScaleIO.IsPresent)
    {
    $Java8_required = $true
    ##
    # ScaleIO_1.32_Complete_Windows_SW_Download\ScaleIO_1.32_Windows_Download #
    Write-Verbose "Now Checking for ScaleIO $ScaleIOVer"
    $ScaleIO_Major = $ScaleIOVer[0]
    $ScaleIORoot = join-path $Sourcedir "Scaleio\"
    $ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*mdm-$ScaleIOVer.msi" -ErrorAction SilentlyContinue ).Directory.FullName

    try
        {
        Test-Path $ScaleIOPath | Out-Null
        }
    catch
        {
        Write-Host -ForegroundColor Gray " ==> we did not find ScaleIO $ScaleIOVer, we will check local zip/try to download latest version!"
        Receive-LABScaleIO -Destination $Sourcedir -arch Windows -unzip -Confirm:$false -force
        }
        #### will be moved to receive-labopenssl
        if ($ScaleIO_Major -ge 2)
            {
            Write-Host -ForegroundColor Magenta "Checking for OpenSSL"
            if (!(test-path "$Sourcedir\Win64OpenSSL_Light-1_0_1s.exe"))
                {
                Start-BitsTransfer -Destination $Sourcedir -Source https://slproweb.com/download/Win64OpenSSL_Light-1_0_1s.exe -Description "OpenSSL for ScaleIO"
                }
            }
        Write-Verbose "Checking Diskspeed"
        $URL = "https://gallery.technet.microsoft.com/DiskSpd-a-robust-storage-6cd2f223/file/132882/1/Diskspd-v2.0.15.zip"
        $FileName = Split-Path -Leaf -Path $Url
        $Zipfilename = Join-Path $Sourcedir $FileName
        $Destinationdir = Join-Path "$Sourcedir" "diskspd"

        # $Directory = Split-Path 
        if (!(test-path  (join-path "$Sourcedir" "\diskspd\amd64fre\diskspd.exe")))
        {
        ## Test if we already have the ZIP

        if (!(test-path  "$Zipfilename"))
            {
            Write-Verbose "Trying Download DiskSpeed"
            if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir"))
                { 
                    Write-Warning "Error Downloading file $Url, Please check connectivity"
                        exit
                }
            }
        Extract-Zip -zipfilename $Zipfilename -destination $Destination

    }# end DiskSpeed
} #end ScaleIO
##### puppet stuff
############
if ($LabDefaults.Puppet)
    {
    If ($LabDefaults.Puppetmaster -match "Enterprise")
    {
        $Puppetmaster  = "PuppetENMaster1"
    }
else
    {
    $Puppetmaster  = "PuppetMaster1"
    }
Write-Verbose "Pupppetmaster will be $Puppetmaster"
}
##end Autodownloaders
##########################################
if ($nw.IsPresent -and !$NoDomainCheck.IsPresent) { workorder "Networker $nw_ver Node will be installed" }
write-verbose "Checking Environment"
if ($NW.IsPresent -or $NWServer.IsPresent)
{
    if (!$Scenarioname) 
        {
        $Scenarioname = "nwserver"
        $Scenario = 8
        }
	if (!($Acroread = Get-ChildItem -Path $Sourcedir -Filter 'a*rdr*.exe'))
	    {
		status "Adobe reader not found ...."
	    }
	else
	    {
		$Acroread = $Acroread | Sort-Object -Property Name -Descending
		$Latest_Acroread = $Acroread[0].Name
		write-verbose "Found Adobe $Latest_Acroread"
	    }
    try
        {
        $Acroread_Patch = Get-ChildItem -Path $Sourcedir -Filter 'a*rdr*.msp'
	    }
    catch
        {
        Write-Host -ForegroundColor Gray " ==> no reader Patch found"
        }

        $Acroread_Patch = $Acroread_Patch | Sort-Object -Property Name -Descending
		$Latest_AcroreadPatch = $Acroread_Patch[0].Name
		write-verbose "Found Adobe $Latest_Acroread"

	##### 
    $Java7_required = $True
    #####
If ($nw_ver -gt "nw85.BR1")
            {
            $Java8_required = $true
            $Java7_required = $false
            if ($LatestJava7)
                {
                $LatestJava = $LatestJava7
                }
            
            if ($LatestJava8)
                {
                $LatestJava = $LatestJava8
                }
            }
}
#end $nw
if ($Java7_required)
    {
    Write-Verbose "Checking for Java 7"
    if (!($Java7 = Get-ChildItem -Path $Sourcedir -Filter 'jre-7*x64*'))
	    {
		Write-Warning "Java7 not found, please download from www.java.com"
	    break
        }
    else
        {
	    $Java7 = $Java7 | Sort-Object -Property Name -Descending
	    $LatestJava = $Java7[0].Name
        }
    }
If ($Java8_required)
    {
    Write-Verbose "Checking for Java 8"
    if (!($Java8 = Get-ChildItem -Path $Sourcedir -Filter 'jre-8*x64*'))
        {
	    Write-Host -ForegroundColor Gray " ==> Java8 not found, trying download"
        Write-Verbose "Asking for latest Java8"
        $LatestJava = (get-labJava64 -DownloadDir $Sourcedir).LatestJava8
        if (!$LatestJava)
            {
            break
            }
	    }
    else
        {
        $Java8 = $Java8 | Sort-Object -Property Name -Descending
	    $LatestJava = $Java8[0].Name
        Write-Verbose "Got $LatestJava"
        }
    }
if (!($SourceOK = test-source -SourceVer $Sourcever -SourceDir $Sourcedir))
{
	Write-Verbose "Sourcecomplete: $SourceOK"
	break
}
if ($DefaultGateway) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
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
	    $Checkdom = invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\$DCNODE" -Script checkdom.ps1 # $CommonParameter
	    $BuildDomain, $RunningIP, $VMnet, $MyGateway = test-domainsetup
	    $IPv4Subnet = convert-iptosubnet $RunningIP
	    workorder "We will Use Domain $BuildDomain and Subnet $IPv4Subnet.0 for on $VMnet the Running Workorder"
	    
        If ($MyGateway) 
            {
            workorder "We will configure Default Gateway at $MyGateway"
            $AddGateway  = "-DefaultGateway $MyGateway"
            Write-Verbose -Message "we will add a Gateway with $AddGateway"
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
	$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$DCNODE"
	###################################################
    
	Write-Verbose "IPv4Subnet :$IPv4Subnet"
    Write-Verbose "IPV6Prefix :$IPv6Prefix"
    Write-Verbose "IPv6Prefixlength : $IPv6PrefixLength"
    write-verbose "DCName : $DCName"
    Write-Verbose "Domainsuffix : $domainsuffix"
    Write-Verbose "Domain : $BuildDomain"
    Write-Verbose "AddressFamily : $AddressFamily"
    Write-Verbose "DefaultGateway : $DefaultGateway"
    Write-Verbose "DNS1 : $DNS1"
    If ($DefaultGateway.IsPresent)
        {
        Write-Verbose "Gateway : $DefaultGateway"
        }
	workorder "We will Build Domain $BuildDomain and Subnet $IPv4subnet.0  on $VMnet for the Running Workorder"
    if ($DefaultGateway){ workorder "The Gateway will be $DefaultGateway"}
	if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-Verbose "Press any key to Continue Cloning"
        Pause
        }
    Set-LABDNS1 -DNS1 "$IPv4Subnet.10"
	$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 0 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Size 'L' -Sourcedir $Sourcedir"
	
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
        Write-Host -ForegroundColor Gray " ==> Building DC for Domain $BuildDomain, this may take a while"
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script new-dc.ps1 -Parameter "-dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix  -AddressFamily $AddressFamily $AddGateway $CommonParameter" -interactive -nowait
   
        status "Preparing Domain"
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            write-verbose "verbose enabled, Please press any key within VM $Dcname"
            While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\2.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
            }
        else 
            {

		    While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\2.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
            Write-Host
		    }
		test-user -whois Administrator
        if ($Toolsupdate.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==> Preparing VMware Tools Upgrade by injecting tools CD ( update will start before next reboot of VM )"
            Start-Process 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe' -ArgumentList  "installTools $CloneVMX" -NoNewWindow
            }

		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-domain.ps1 -Parameter "-domain $BuildDomain -domainsuffix $domainsuffix $CommonParameter" -interactive -nowait
		status "Creating Domain $BuildDomain"
		While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\3.pass) -ne "The file exists.") { Write-Host -NoNewline "."; sleep $Sleep }
		write-host
		status  "Domain Setup Finished"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script dns.ps1 -Parameter "-IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix $CommonParameter"  -interactive
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script add-serviceuser.ps1 -interactive
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-labshortcut.ps1 -interactive # -Parameter $CommonParameter
        Write-Host -ForegroundColor Magenta " ==> Setting Password Policies"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir  -Script pwpolicy.ps1 -interactive
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script set-winrm.ps1 -interactive
        if ($NW.IsPresent)
            {
            Write-Host -ForegroundColor Magenta " ==> Install NWClient"
		    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
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
        $IN_Guest_UNC_ScenarioScriptDir = Join-Path $IN_Guest_UNC_Scriptroot "AAG"
        $In_Guest_UNC_SQLScriptDir = Join-Path $IN_Guest_UNC_Scriptroot "SQL"
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
            #$In_Guest_UNC_SQLScriptDir = "$Builddir\$Scripts\sql\"
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
			$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $AAGNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -sql"
			###################################################
			If ($CloneOK)
			{
				Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
				test-user -whois Administrator
				Write-Host -ForegroundColor Magenta " ==> Starting Customization"
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                invoke-postsection -wait
                Write-Host -ForegroundColor Magenta " ==> Setup Database Drives"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
				Write-Host -ForegroundColor Magenta " ==> Starting $SQLVER Setup on $Nodename"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -reboot" -interactive -nowait
                $SQLSetupStart = Get-Date
			}
			
		} ## end foreach AAGNODE
		If ($CloneOK)
		{
			####### Check for all SQl Setups Done .. ####
			Write-Host -ForegroundColor Magenta " ==> Checking SQL INSTALLED and Rebooted on All Machines"
			foreach ($AAGNode in $AAGLIST)
			{
				While ($FileOK = (&$vmrun -gu $builddomain\Administrator -gp Password123! fileExistsInGuest $AAGNode $IN_Guest_LogDir\sql.pass) -ne "The file exists.")
				{
				runtime $SQLSetupStart "$SQLVER $Nodename"
				}
            Write-Host -ForegroundColor Magenta " ==> Setting SQL Server Roles on $AAGNode"
            invoke-vmxpowershell -config $AAGNode -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\SQL" -Script set-sqlroles.ps1 -interactive
			} # end aaglist
			write-host
			Write-Host -ForegroundColor Magenta " ==> Forming AlwaysOn WFC Cluster"
	        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix 'AAGNODE' -IPAddress '$IPv4Subnet.160' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			Write-Host -ForegroundColor Magenta " ==> Enabling AAG"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script enable-aag.ps1 -interactive
			Write-Host -ForegroundColor Magenta " ==> Creating AAG"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-aag.ps1 -interactive -Parameter "-Nodeprefix 'AAGNODE' -AgName '$AAGName' -DatabaseList 'AdventureWorks2012' -BackupShare '\\vmware-host\Shared Folders\Sources\AWORKS' -IPv4Subnet $IPv4Subnet -IPV6Prefix $IPV6Prefix -AddressFamily $AddressFamily $CommonParameter"
			foreach ($CloneVMX in $AAGLIST)
            {
                if ($NMM.IsPresent)
                    {
				    status "Installing Networker $nmm_ver an NMM $nmm_ver on all Nodes"
					status $CloneVMX
					Write-Host -ForegroundColor Magenta " ==> Install NWClient"
					invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    Write-Host -ForegroundColor Magenta " ==> Install NMM"
					invoke-vmxpowershell -config $CloneVMX -ScriptPath "$IN_Guest_UNC_Scriptroot\SQL" -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver" -Guestuser $Adminuser -Guestpassword $Adminpassword
                    Write-Host -ForegroundColor Magenta " ==> Finishing Always On"
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-aag.ps1 -interactive -nowait
					} # end !NMM
				else 
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-aag.ps1 -interactive -nowait
                    }# end else nmm
				}
           # 
			status "Done"			
		}# end cloneok
	} # End Switchblock AAG
switch ($PsCmdlet.ParameterSetName)
{
	"E15"{
        $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\E2013"
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
            Write-Host -ForegroundColor Gray " ==> Running E15 Avalanche Install"

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
			# Setup E15 Node
			# Init
			$Nodeip = "$IPv4Subnet.11$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$EXLIST += $CloneVMX
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
		    workorder "Creating E15 Host $Nodename with IP $Nodeip in Domain $BuildDomain"
		    $CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -AddDisks -Disks 3 -Disksize 500GB -Size $Exchangesize -Sourcedir $Sourcedir "

		    ###################################################
		    If ($CloneOK)
            {
            $EXnew = $True
			Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
			test-user -whois Administrator
			Write-Host -ForegroundColor Magenta " ==> Starting Customization"
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			Write-Host -ForegroundColor Magenta " ==> Setup Database Drives"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
			Write-Host -ForegroundColor Magenta " ==> Setup E15 Prereqs"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchangeprereqs.ps1 -interactive
			Write-Host -ForegroundColor Magenta " ==> Setting Power Scheme"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
			Write-Host -ForegroundColor Magenta " ==> Installing E15, this may take up to 60 Minutes ...."
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $e15_cu"
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
            status "Waiting for Pass 4 (E15 Installed) for $Nodename"
            #$EXSetupStart = Get-Date
			    While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\exchange.pass) -ne "The file exists.")
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
            Write-Host -ForegroundColor Magenta " ==> Performing E15 Post Install Tasks:"
     		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive
    
    
    #  -nowait
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent) 
                    {
				    Write-Host -ForegroundColor Magenta " ==> Creating DAG"
				    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir  -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
                    Write-Host -ForegroundColor Magenta " ==> Creating Accounts and Mailboxes:"
	                do
				        {
					    ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter") 
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
			Write-Host -ForegroundColor Magenta " ==> Setting Local Security Policies"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				Write-Host -ForegroundColor Magenta " ==> Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				Write-Host -ForegroundColor Magenta " ==> Install NMM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			    Write-Host -ForegroundColor Magenta " ==> Performin NMM Post Install Tasks"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange
	
	"E16"{
        Write-Host -ForegroundColor Magenta " ==> Starting $EX_Version $e16_cu Setup"
        $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\E2016"

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
            Write-Host -ForegroundColor Gray " ==> Running e16 Avalanche Install"

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
			# Setup e16 Node
			# Init
			$Nodeip = "$IPv4Subnet.12$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$EXLIST += $CloneVMX
		    # $Exprereqdir = "$Sourcedir\EXPREREQ\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
            # $AddonFeatures = "$AddonFeatures, RSAT-DNS-SERVER, Desktop-Experience, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation" 
            $AddonFeatures = "$AddonFeatures, RSAT-DNS-Server, AS-HTTP-Activation, Desktop-Experience, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation"


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
            $Exchangesize = "XXL"
		    test-dcrunning
		    status $Commentline
		    workorder "Creating $EX_Version Host $Nodename with IP $Nodeip in Domain $BuildDomain"
		    $CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -AddDisks -Disks 3 -Disksize 500GB -Size $Exchangesize -Sourcedir $Sourcedir "
		    ###################################################
		    If ($CloneOK)
                {
                $EXnew = $True
			    Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
			    test-user -whois Administrator
			    Write-Host -ForegroundColor Magenta " ==> Starting Customization"
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			    Write-Host -ForegroundColor Magenta " ==> Setup Database Drives"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
			    Write-Host -ForegroundColor Magenta " ==> Setup e16 Prereqs"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchangeprereqs.ps1 -interactive
                checkpoint-progress -step exprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			    Write-Host -ForegroundColor Magenta " ==> Setting Power Scheme"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
			    Write-Host -ForegroundColor Magenta " ==> Installing e16, this may take up to 60 Minutes ...."
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $e16_cu"
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
            status "Waiting for Pass 4 (e16 Installed) for $Nodename"
            #$EXSetupStart = Get-Date
			    While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX "$IN_Guest_LogDir\exchange.pass") -ne "The file exists.")
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
            Write-Host -ForegroundColor Magenta " ==> Performing e16 Post Install Tasks:"
    		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive
     
    
    #  -nowait
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent) 
                    {
				    Write-Host -ForegroundColor Magenta " ==> Creating DAG"
				    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
                    Write-Host -ForegroundColor Magenta " ==> Creating Accounts and Mailboxes:"
	                do
				        {
						 #invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "'C:\Program Files\Microsoft\Exchange Server\V15\bin\'" -script "RemoteExchange.ps1;Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter"
				    
                        ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter") 
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
			Write-Host -ForegroundColor Magenta " ==> Setting Local Security Policies"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				Write-Host -ForegroundColor Magenta " ==> Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				Write-Host -ForegroundColor Magenta " ==> Install NMM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			    Write-Host -ForegroundColor Magenta " ==> Performin NMM Post Install Tasks"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange


##### Hyper-V Block #####	
	"HyperV" {
        $Firstnode = "1" #for later use
        $Clusternum = "1" # for later use
        #$LASTVMX = "HVNODE$HyperVNodes"
        $FirstVMX =  "HVNODE$Firstnode"
		$HVLIST = @()
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Hyper-V, Hyper-V-Tools, Hyper-V-PowerShell, WindowsStorageManagementService"
		if ($ScaleIO.IsPresent)
            {
            if (!$Cluster.IsPresent)
                {
                Write-Host -ForegroundColor Gray " ==> We want a Cluster for Automated SCALEIO Deployment, adjusting"
                [switch]$Cluster = $true
                }   
            If (!$Disks){$Disks = 1} 
            $cloneparm = " -AddDisks -disks $Disks"
            if ("XXL" -notmatch $Size)
                { 
                Write-Host -ForegroundColor Gray " ==> we adjust size to XL Machine to make ScaleIO RUN"
                $Size = "XL"              
                }
            If ($Computersize -le "2" -and !$Scaleiowarn )
                {
                Write-Host -ForegroundColor Gray " ==> Your Computer is at low Memory For ScaleIO Scenario"
                Write-Host -ForegroundColor Gray " ==> Insufficient memory might cause MDM Setup to fail"
                Write-Host -ForegroundColor Gray " ==> machines with < 16GB might not be able to run the Scenario"
                Write-Host -ForegroundColor Gray " ==> Please make sure to close all desktop Apps"
                pause
                $Scaleiowarn = $true
                }
            
            }
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"}
        If (!(get-vmx HVNODE))
            {
            $newdeploy = $true
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==> Node1 Already Deployed, no autoconfig is done"
            }

 
        foreach ($HVNODE in ($Firstnode..$HyperVNodes))
		{
			if ($HVNODE -eq $HyperVNodes -and $SCVMM.IsPresent) 
            {
            $LastNode = $True 
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
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\HyperV\"
            $In_Guest_UNC_SQLScriptDir = "$IN_Guest_UNC_Scriptroot\sql\"
            $In_Guest_UNC_SCVMMScriptDir = "$IN_Guest_UNC_Scriptroot\scvmm\"
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
			$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $HVNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir $cloneparm"
			
###################################################
			
            If ($CloneOK)
			    {
                Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
				test-user Administrator
				write-verbose "Setting up Hyper-V Configuration"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-hyperv.ps1 -interactive

				write-verbose "Setting up WINRM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script set-winrm.ps1 -interactive
                
                if ($ScaleIO.IsPresent)
                    {
                    $SIO_ProtectionDomainName = "PD_$BuildDomain"
                    $SIO_StoragePoolName = "SP_$BuildDomain"
                    $SIO_SystemName = "ScaleIO@$BuildDomain"
                    if ($singlemdm.IsPresent)
                        {
                        $mdmipa = "$IPv4Subnet.151"
                        $mdmipb = "$IPv4Subnet.151"
                        }
                    else
                        {
                        $mdmipa = "$IPv4Subnet.151"
                        $mdmipb = "$IPv4Subnet.152"
                        }
                    switch ($HVNODE)
                        {
                        1
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1 -interactive
                                }
                            Write-Host -ForegroundColor Gray " ==> Installing MDM as Manager"
                            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                            }
                        2
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1 -interactive
                                }

                            if (!$singlemdm.IsPresent)
                                {
                                Write-Host -ForegroundColor Gray " ==> Installing MDM as Manager"
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer  -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                                }
                            else
                                {
                                Write-Host -ForegroundColor Gray " == > Installing single MDM"
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer  -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 
                                }
                    
                            }
                        3
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1 -interactive
                                }

		                        <#do
		                            {
			                        ($cmdresult = &$vmrun -gu Administrator -gp Password123! runPrograminGuest  $CloneVMX -activeWindow  $Execute $Parm) 2>&1 | Out-Null
			                        write-log "$origin $cmdresult"
		                            }
		                        until ($VMrunErrorCondition -notcontains $cmdresult)
		                        write-log "$origin $cmdresult"
#>
                            if (!$singlemdm.IsPresent)
                                {
                                switch ($scaleio_major)
                                    {
                                    1
                                        {                        
                                        Write-Host -ForegroundColor Gray " ==>Installing TB"
                                        Invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role TB -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 
                                        }
                                    2
                                        {
                                        Write-Host -ForegroundColor Gray " ==> Installing MDM as TB"
                                        Invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role TB -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 
                                        }
                                    }
                                }
                            else
                                {
                                Write-Host -ForegroundColor Gray " ==>  Installing single MDM"
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 
                                }
                            Write-Host -ForegroundColor Magenta "generating SIO Config File"
                            Set-LABSIOConfig -mdm_ipa $mdmipa -mdm_ipb $mdmipb -gateway_ip "$IPv4Subnet.153" -system_name $SIO_SystemName -pool_name $SIO_StoragePoolName -pd_name $SIO_ProtectionDomainName

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
                            Invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role gateway -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 


                            }
                        default
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1 -interactive
                                }
                                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive 
                            }
                        }
                    }
                
                          
	            if ($NMM.IsPresent)
		            {
			        write-verbose "Install NWClient"
			        invoke-vmxpowershell -config $CloneVMX -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver -Guestuser $Adminuser -Guestpassword $Adminpassword
			        
                    write-verbose "Install NMM"
                    $NMM_Parameter = "-nmm_ver $nmm_ver"
                    If ($SCVMM.IsPresent -and $LastNode)
                        {
                        $NMM_Parameter = "$NMM_Parameter -scvmm"
                        }
			        invoke-vmxpowershell -config $CloneVMX -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter $NMM_Parameter -Guestuser $Adminuser -Guestpassword $Adminpassword
		            }# End Nmm		
            invoke-postsection -wait
            } # end Clone OK

		} # end HV foreach
		########### leaving NMM Section ###################
    If ($newdeploy)
        {
        Write-Host -ForegroundColor Green "Trying New Cluster Deployment !! "
        if ($Cluster.IsPresent)
		{
			write-host
			write-verbose "Forming Hyper-V Cluster"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix 'HVNODE' -IPAddress '$IPv4Subnet.150' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		}
	    if ($ScaleIO.IsPresent)
            {
            write-verbose "configuring mdm"
            if ($singlemdm.IsPresent)
                    {
                    Write-Host -ForegroundColor Gray " ==> Configuring Single MDM"
                    get-vmx $FirstVMX | invoke-vmxpowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-mdm.ps1 -Parameter "-singlemdm -CSVnum 2 -ScaleIO_Major $ScaleIO_Major"-interactive 
                    }
            else
                    {
                    Write-Host -ForegroundColor Gray " ==> Configuring Clustered MDM"
                    get-vmx $FirstVMX | invoke-vmxpowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-mdm.ps1 -Parameter "-CSVnum 3 -ScaleIO_Major $ScaleIO_Major" -interactive 
                    }
            }
		if ($SCVMM.IsPresent)
		    {
			#write-verbose "Building SCVMM Setup Configruration"
			#invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest -Script set-vmmconfig.ps1 -interactive
			write-verbose "Installing SQL Binaries"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath $CommonParameter" -interactive
			write-verbose "Installing SCVMM PREREQS"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script install-vmmprereq.ps1 -Parameter "-sc_version $SC_Version $CommonParameter"  -interactive
            checkpoint-progress -step vmmprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			write-verbose "Installing SCVMM"
            Write-Host -ForegroundColor Gray " ==> Setup of VMM and Update Rollups in progress, could take up to 20 Minutes"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script install-vmm.ps1 -Parameter "-sc_version $SC_Version $CommonParameter" -interactive
            
            
            if ($ConfigureVMM.IsPresent)
                {
			    Write-Verbose "Configuring VMM"
                if ($Cluster.IsPresent)
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script configure-vmm.ps1 -Parameter "-Cluster" -interactive
                    }
                    else
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script configure-vmm.ps1 -interactive
                    }
                }
            <#
            else
                {
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-vmm.ps1 -Parameter "-scvmm_ver $scvmm_ver $CommonParameter" -interactive -nowait
		        }
#>
            } #end SCVMM
        }#end newdeploy
	} # End Switchblock hyperv
###### new SOFS Block
	"SOFS" {
        $AddonFeatures = "File-Services, RSAT-File-Services, RSAT-ADDS, RSAT-ADDS-TOOLS, Failover-Clustering, RSAT-Clustering, WVR"
		foreach ($Node in ($SOFSSTART..$SOFSNODES))
		{
			###################################################
			# Setup of a SOFS Node
			# Init
			$Nodeip = "$IPv4Subnet.21$Node"
			$Nodename = "SOFSNode$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$Host_ScriptDir = "$Builddir\$Scripts\SOFS\"
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
			$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir "
			
			###################################################
			If ($CloneOK)
			{
				Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
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

			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix 'SOFS' -IPAddress '$IPv4Subnet.210' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script new-sofsserver.ps1 -Parameter "-SOFSNAME 'SOFSServer'  $CommonParameter" -interactive

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
			# Setup of a Sharepoint Node
			# Init
			$Nodeip = "$IPv4Subnet.14$Node"
			$Nodename = "$Prefix"+"Node$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$Prefix\"
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
			status "Creating Host $Nodename with IP $Nodeip"
		    $CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $SPSize -Sourcedir $Sourcedir $cloneparm"
			###################################################
			If ($CloneOK)
			{
				Write-Host -ForegroundColor Gray "Waiting for firstboot finished"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-spprereqs.ps1 -interactive
                checkpoint-progress -step spprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
                Write-Verbose "Installing Sharepoint"
                If ($AlwaysOn.IsPresent)
                    {
                    Write-Host -ForegroundColor Gray " ==> installing sharepoint customized, could take an hour"
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    }
                else
                    {
                    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sp.ps1 -interactive
                    }
                if ($NMM.IsPresent)
                    {
				    status "Installing Networker $nmm_ver an NMM $nmm_ver on all Nodes"
					status $CloneVMX
					write-verbose "Install NWClient"
					invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_Scriptroot -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    write-verbose "Install NMM"
					invoke-vmxpowershell -config $CloneVMX -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver" -Guestuser $Adminuser -Guestpassword $Adminpassword
					}
				invoke-postsection
			}# end Cloneok


	} # End Switchblock Sharepoint
	"Blanknodes" {
        if ($SpacesDirect.IsPresent )
            {
            If ($Master -lt "2016")
                {
                Write-Host -ForegroundColor Gray " ==> Master 2016TP3 or Later is required for Spaces Direct"
                exit
                }
            if ($Disks -lt 2)
                {
                $Disks = 2
                }
            if ($BlankNodes -lt 4)
                {
                $BlankNodes = 4
                }
            $Cluster = $true
            $BlankHV = $true
            }

        If ($BlankHV.IsPresent)
            {
            $VTbit = $True
            }

        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, RSAT-Clustering-AutomationServer, RSAT-Clustering-CmdInterface, WVR"}
        if ($BlankHV.IsPresent) {$AddonFeatures = "$AddonFeatures, Hyper-V, RSAT-Hyper-V-Tools, Multipath-IO"}
        $Blank_End = (($Blankstart+$BlankNodes)-1)

		foreach ($Node in ($Blankstart..$Blank_End))
        
		{
			###################################################
			# Setup of a Blank Node
			# Init
            $Node_range = 180
            $Node_byte = $Node_range+$node
            $Nodeip = "$IPv4Subnet.$Node_byte"
            $Nodeprefix = "Node"
            $NamePrefix = "GEN"
		    $Nodename = "$NamePrefix$NodePrefix$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
            $ClusterIP = "$IPv4Subnet.180"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "Disks: $Disks"
            Write-Verbose "Blanknodes: $BlankNodes"
            Write-Verbose "Cluster: $($Cluster.IsPresent)"
            Write-Verbose "Pre Clustername: $ClusterName"
            Write-Verbose "Pre ClusterIP: $ClusterIP"
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
				$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir -SharedDisk $cloneparm"
			}
			else
			{
				$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir $cloneparm"
			}
			###################################################
			If ($CloneOK)
			{
				Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                if ($NW.IsPresent)
                    {
                    write-verbose "Install NWClient"
		            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    }
				invoke-postsection
			}# end Cloneok
			
		} # end foreach

    	if ($Cluster.IsPresent)
		    {
			write-host
			write-verbose "Forming Blanknode Cluster"
            If ($ClusterName)
                {    
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -ClusterName $ClusterName -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }
            else
                {
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }			
		    
            }

	} # End Switchblock Blanknode
	
	"Spaces" {
		
		foreach ($Node in (1..$SpaceNodes))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.17$Node"
            $NodePrefix	= "Spaces"		
            $Nodename = "$NodePrefix$Node"
			$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $Disks
            Write-Verbose $ClusterName
           
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }

			test-dcrunning
			if ($SpaceNodes -gt 1) {$AddonFeatures = "Failover-Clustering, RSAT-Clustering"}
			status $Commentline
			status "Creating Storage Spaces Node Host $Nodename with IP $Nodeip"
			$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -AddOnfeatures $AddonFeature"
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $IN_Guest_UNC_NodeScriptDir
				Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
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
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_Scriptroot -Script create-cluster.ps1 -Parameter "-Nodeprefix 'Spaces' -IPAddress '$IPv4Subnet.170' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
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
		$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\SQL\"
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
		test-dcrunning
		status $Commentline
		status "Creating $SQLVER Node $Nodename with IP $Nodeip"
		$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -sql"
		###################################################
		If ($CloneOK)
		{
			Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
			test-user -whois Administrator
			write-Verbose "Starting Customization"
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
			invoke-postsection -wait
            write-verbose "Configure Disks"
            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
            write-verbose "Installing SQL Binaries"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER $CommonParameter" -interactive
            <#			
            $SQLSetupStart = Get-Date
			While ($FileOK = (&$vmrun -gu $builddomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Scripts\sql.pass) -ne "The file exists.")
			{
				runtime $SQLSetupStart "$SQLVER"
			}
			write-host
			test-user -whois administrator
            #>
            Write-Verbose "Setting SQL Server Roles on $($CloneVMX.vmxname)"
            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script set-sqlroles.ps1 -interactive

			if ($NMM.IsPresent)
			{
				write-verbose "Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				write-verbose "Install NMM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			}# End NoNmm
			Write-Verbose "Importing Database"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script import-database.ps1 -interactive

			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-sql.ps1 -interactive -nowait

			#invoke-postsection
		}# end Cloneok
	} #end Switchblock SQL

"Panorama"
{
	###################################################
	# Panorama Setup
	###################################################
	
    $Nodeip = "$IPv4Subnet.19"
	$NodePrefix = "Panorama"
    $Nodename = $NodePrefix
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
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
	$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -bridge -Gateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        write-verbose "Building Panorama Server"
        invoke-postsection -wait
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script panorama.ps1 -interactive -parameter " $CommonParameter"
	}
} #Panorama End

"SRM"
{
	###################################################
	# SRM Setup
	###################################################
	$Nodeip = "$IPv4Subnet.17"
	$NodePrefix = "ViPRSRM"
    $Nodename = $NodePrefix
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS" 
	###################################################
	status $Commentline
	status "Creating SRM Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        { 
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }

	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Gateway -size XXL -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        if ($NW.IsPresent)
            {
            write-verbose "Install NWClient"
		    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
            }
        invoke-postsection -wait
        write-verbose "Building SRM Server"
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-SRM.ps1 -interactive -parameter "-SRM_VER $SRM_VER $CommonParameter"
        Write-Host -ForegroundColor White "You cn now Connect to http://$($Nodeip):58080/APG/ with admin/changeme"
	
}
} #SRM End

"SCOM"
{
	###################################################
	# SCO Setup
	###################################################
	$Nodeip = "$IPv4Subnet.18"
	$Nodename = "SCOM"
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\SCOM"
    $In_Guest_UNC_SQLScriptDir = "$IN_Guest_UNC_Scriptroot\sql\"

	###################################################
	status $Commentline
	status "Creating $SC_Version Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        { 
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }

	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Gateway -size XXL -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		Write-Host -ForegroundColor Gray " ==> Waiting for firstboot finished"
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        if ($NW.IsPresent)
            {
            write-verbose "Install NWClient"
		    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
            }
        invoke-postsection -wait
        write-verbose "Installing SQL Binaries"
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath" -interactive

        write-verbose "Building SCOM Server"
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-Scom.ps1 -interactive -parameter "-SC_Version $SC_Version $CommonParameter"
#        Write-Host -ForegroundColor White "You cn now Connect to http://$($Nodeip):58080/APG/ with admin/changeme"
	
}
} #SRM End




    "Isilon" {
        Write-Verbose "Calling Isilon Installer"
        Invoke-Expression -Verbose "$Builddir\install-isi.ps1 -Nodes $isi_nodes -Disks 4 -Disksize 36GB -defaults "
        status "Isilon Setup done"
        } # end isilon
}
if (($NW.IsPresent -and !$NoDomainCheck.IsPresent) -or $NWServer.IsPresent)
{
	###################################################
	# Networker Setup
	###################################################
	$Nodeip = "$IPv4Subnet.$Gatewayhost"
	$Nodename = $NWNODE
	$CloneVMX = "$Builddir\$Nodename\$Nodename.vmx"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NWNODE" 
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
    If ($DefaultGateway -match $Nodeip){$SetGateway = "-Gateway"}
	$CloneOK = Invoke-expression "$Builddir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 9 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -NW $SetGateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	    {
		Write-Host -ForegroundColor Gray
		test-user -whois Administrator
		write-Verbose "Starting Customization"
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		# Setup Networker
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
		write-verbose "Building Networker Server"
		write-verbose "installing JAVA"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-program.ps1 -Parameter "-Program $LatestJava -ArgumentList '/s' $CommonParameter"-interactive
		write-verbose "installing Acrobat Reader"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-program.ps1 -Parameter "-Program $Latest_Acroread -ArgumentList '/sPB /rs' $CommonParameter"-interactive
		write-verbose "installing Networker Server"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nwserver.ps1 -Parameter "-nw_ver $nw_ver $CommonParameter"-interactive
		if (!$Gateway.IsPresent)
            {
            checkpoint-progress -step networker -reboot
            }
        write-verbose "Waiting for NSR Media Daemon to start"
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "nsrd.exe") { write-host -NoNewline "." }
		write-verbose "Creating Networker users"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script nsruserlist.ps1 -interactive
		status "Creating AFT Device"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-nsrdevice.ps1 -interactive -Parameter "-AFTD AFTD1"
        If ($DefaultGateway -match $Nodeip){
                write-verbose "Opening Firewall on Networker Server for your Client"
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script firewall.ps1 -interactive
        		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script add-rras.ps1 -interactive -Parameter "-IPv4Subnet $IPv4Subnet"
                checkpoint-progress -step rras -reboot

        }
        invoke-postsection -wait
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-nmc.ps1 -interactive
		progress "Please finish NMC Setup by Double-Clicking Networker Management Console from Desktop on $NWNODE.$builddomain.local"
	    
	}
} #Networker End
$endtime = Get-Date
$Runtime = ($endtime - $Starttime).TotalMinutes
status "Finished Creation of $mySelf in $Runtime Minutes "
status "Deployed VM´s in Scenario $Scenarioname"
get-vmx | where scenario -match $Scenarioname | ft vmxname,state,activationpreference
return
