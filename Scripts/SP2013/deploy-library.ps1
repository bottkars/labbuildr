if((Get-PSSnapin "Microsoft.SharePoint.PowerShell") -eq $null)
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}
 
#Script settings
 
$Url = "http://$Env:COMPUTERNAME"
 
$docLibraryName = "Documents"
$docLibraryUrlName = "Shared%20Documents"
 
$Attachementshare = "\\vmware-host\Shared Folders\Sources\Attachements"
 
#Open web and library
 
$web = Get-SPWeb $Url
 
$docLibrary = $web.Lists[$docLibraryName]
 
If ($files = Get-ChildItem -Path $Attachementshare -File -Recurse)
 
ForEach($file in $files)
{
 
    #Open file
    $fileStream = ([System.IO.FileInfo] (Get-Item $file.FullName)).OpenRead()
 
    #Add file
    $folder =  $web.getfolder($docLibraryUrlName)
 
    write-host "Copying file " $file.Name " to " $folder.ServerRelativeUrl "..."
    $spFile = $folder.Files.Add($folder.Url + "/" + $file.Name, [System.IO.Stream]$fileStream, $true)
    write-host "Success"
 
    #Close file stream
    $fileStream.Close();
}
#Dispose web
 
$web.Dispose()