$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
New-Item -ItemType file  "$Builddir\$ScriptName.log" -ErrorAction SilentlyContinue
$Domain = (get-addomain).name.tolower()
$DomainController = (get-addomain).InfrastructureMaster.tolower()
$DAGNAME = $Domain+"dag"
$Dag = Get-ChildItem -Path C:\Scripts -Filter client*dag.txt

foreach  ($file in $DAG) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
$content | foreach {$_ -replace "BRS2GODAG", "$DAGNAME"}  | Set-Content $file.FullName
}
$groups = Get-ChildItem -Path C:\Scripts -Filter group*.txt
foreach  ($file in $groups) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $file.FullName | out-host
}

$Clients = Get-ChildItem -Path C:\Scripts -Filter client*.txt
foreach  ($file in $Clients) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "BRSDC", "$DomainController"} | Set-Content $file.FullName
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $file.FullName | out-host
}
