Write-Warning "you reached emergency update mode, patching to new labbuildr Distro Version"
$Filecopy = Copy-Item ./labbuildr/build-lab.ps1 -Force -Destination ./build-lab.ps1
./build-lab.ps1 -update -Force
