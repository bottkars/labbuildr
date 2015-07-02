############ massmailer Script   
# Karsten Bott  
# Karsten.Bott@emc.com  
# 24.05.2013
# modified 05.04.2015 for labbuildr  
# twitter @hyperv_guy  
####################  
# Adjust Parameter to your needs or start with-parameter  
param (  
[string[]]$Databases,
[string[]]$Distributiongroups,  
[string]$Sourcepath = "\\vmware-host\shared folders\sources\Attachements",  
[uint64]$MaxmessageSize = 9MB,  
[string]$From,  
[string]$Smtpserver = "mailhost"  
)  
$body = "
Please add some text files for 
Random Creation of
Emailbodies
" 

if (!$From)
    {
    $From = "Administrator@$Env:USERDNSDOMAIN"
    }
if (!$Databases)
    {
    $Databases =  (Get-MailboxDatabase | where Recovery -eq $false ).name
    }
$Dots = [char]58  
$Time = Get-Date   
Write-Host -BackgroundColor DarkRed Start Sending Bulk Emails  
Write-Host -ForegroundColor Yellow please Press '"ctrl-c"' to quit  
Write-Host -ForegroundColor Yellow "reading Users from Mailbox Databases . . ."  
foreach ( $Database in $Databases )  
{  
if (!(get-Mailboxdatabase $Database -warningAction SilentlyContinue -ErrorAction SilentlyContinue ))  
    {
    Write-Host -BackgroundColor DarkRed Database $Database not found
    }  
else
    {  
    $Receipients += ((Get-Mailbox -Database $Database ) | select PrimarySMTPAddress)
    $Receipients = $Receipients -notmatch "DiscoverySearch"  
    }  
}  
If ($Distributiongroups)  
    {
    foreach ($Distributiongroup in $Distributiongroups)  
        {  
        $Receipients += (Get-DistributionGroup $Distributiongroup) | select PrimarySMTPAddress  
        }  
    }  
  
if ($Receipients)  
{  
    [uint64]$MBsent = 0MB  
    $Attachextensions = @(".pdf",".ppt",".docx" )  
    Write-Host -ForegroundColor Yellow reading Files from $Sourcepath . . .  
    $Dir = get-childitem $Sourcepath -recurse  
    $AttachList = $Dir | where {$_.extension -in $Attachextensions }  
    $Bodylist = $Dir | where {$_.extension -eq ( ".txt" ) }  
    $AttachCount = $AttachList.Count  
    $BodyCount = $BodyList.Count  
    $MessageCount = 0  
    while ($true) 
        {  
        foreach ( $Receipient in $Receipients ) {  
        $ReceipientSMTP = $Receipient.PrimarySmtpAddress.local+"@"+$Receipient.PrimarySmtpAddress.Domain  
        do
            {  
            $randattach = (Get-Random -Minimum 0 -Maximum ($attachCount-1))  
            }   
        until ($AttachList[$randattach].Length -le $MaxmessageSize)  

        if ($Bodylist)
            {
            $randbody = (Get-Random -Minimum 0 -Maximum ($bodyCount-1))  
            [string]$Body = Get-Content -Path $BodyList[$randbody].FullName -TotalCount 20 
            } 
        $Myfile = $AttachList[$randattach].FullName  
        $Subject = $AttachList[$randattach].BaseName  
        $MessageCount ++   
        $MBsent +=  $AttachList[$randattach].Length  
        $Timenow = Get-Date  
        $Difftime = $Timenow - $Time  
        $StrgTime = ("{0:D2}" -f $Difftime.Hours).ToString()+$Dots+("{0:D2}" -f $Difftime.Minutes).ToString()+$Dots+("{0:D2}" -f $Difftime.Seconds).ToString()  
        $Average = $MBsent / 1MB / $Difftime.TotalSeconds  
        write-host "`r".padright(1," ") -nonewline  
        Write-Host -ForegroundColor Yellow Running for $StrgTime at ("{0:N2}" -f $Average)"MBs, Sending Message"("{0:D2}" -f $MessageCount)to -NoNewline  
        Write-Host -BackgroundColor DarkRed ("{0,25}" -f $ReceipientSMTP) -NoNewline  
        Write-Host -ForegroundColor Yellow ", Total of"("{0:N2}" -f ($MBsent / 1MB )) "MB sent" -NoNewline  
        Send-MailMessage -From $From -Subject $Subject -To $ReceipientSMTP -Attachments $myfile -Body $Body  -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue  
        }  
    }  
}  
else   
    {
    Write-Host -BackgroundColor DarkRed "No receipients found exiting now !" 
    }  
