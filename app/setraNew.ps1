$ServerListFile = ".\Resources\serverstestlist.txt"   
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue  
$thresholdSpace = 20
[int]$ProccessNumToFetch = 10
$SystemInfo = @{}

Function Format-Date {
	param ([string]$UpTime)
	$LastBootUpTime = ([WMI] '').ConvertToDateTime($info.LastBootUpTime)
	$Time = (Get-Date) - $LastBootUpTime
	Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
}

ForEach($computername in $ServerList)  
{
    #Get processor Load details
	$AVGProc = Get-WmiObject -computername $computername -Class win32_processor | Select-Object -ExpandProperty LoadPercentage

    # Disk Informations for a particular computer
    $DiskInfo= Get-WMIObject -ComputerName $computername Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and ($_.freespace/$_.Size)*100 -lt $thresholdspace } | Select-Object SystemName, DriveType, VolumeName, Name, @{n="Size";e={"{0:n2}" -f ($_.size/1gb)}}, @{n="FreeSpace";e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n="PercentFree";e={"{0:n2}" -f ($_.freespace/$_.size*100)}}
    
    # System Informations for a particular Computer
    $info = Get-WmiObject -Class Win32_OperatingSystem -computername $computername | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory, caption, LastBootUpTime

    # Fetch the top 10 processes
    $TopProcesses = Get-Process -ComputerName $computername | Sort WS -Descending | Select ProcessName, Id, WS -First $ProccessNumToFetch

    # Fetch the services that are stopped
    $Services = Get-WmiObject -Class Win32_Service -ComputerName $computername | Where {($_.StartMode -eq "Auto") -and ($_.State -eq "Stopped")} | Select-Object -Property Name, State, StartMode

    $dump = @{
        CPULoad = $AVGProc;
        drives = $DiskInfo;
        processes = $TopProcesses;
        services = $Services;
        sysName = $info.caption;
        sysUptime = Format-Date -UpTime $info.LastBootUpTime;
        sysTotalRAM = [Math]::Round($info.TotalVisibleMemorySize/1MB, 2);
        sysFreeRAM = [Math]::Round($info.FreePhysicalMemory/1MB, 2);
        sysUsedRAM = [Math]::Round($SystemInfo.sysTotalRAM - $SystemInfo.sysFreeRAM, 2);
        sysRAMPercent = [Math]::Round(($info.FreePhysicalMemory/$info.TotalVisibleMemorySize) * 100, 2); 
    }
    $SystemInfo.$computername = $dump
}

# foreach($system in $SystemInfo.keys){
#     Write-Host $SystemInfo.$system.services
# }
$HTMLHeader = "<HTML>
    <head>
        <TITLE> Server Health Report </TITLE>
        <meta charset=`"utf-8`">
        <meta name=`"viewport`" content=`"width=device-width, initial-scale=1`">
        <!--Font Awesome Icons-->
        <link rel=`"stylesheet`" href=`"https://use.fontawesome.com/releases/v5.5.0/css/all.css`" integrity=`"sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU`" crossorigin=`"anonymous`" />
        <!--Bootstrap-->
        <link rel=`"stylesheet`" href=`"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css`" integrity=`"sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO`" crossorigin=`"anonymous`" />
        <!--Overlay Scrollbars-->
        <link rel=`"stylesheet`" href=`"https://cdnjs.cloudflare.com/ajax/libs/overlayscrollbars/1.6.1/css/OverlayScrollbars.min.css`" />
        <style>
            $(Get-Content -Path './Resources/Styles/style.min.css')
        </style>
    </head>"

$HTMLBody = & ({
    "`n<BODY>
            <div class=`"wrapper`">
        "
        & ([ScriptBlock]::Create($(Get-Content -Path './Resources/Templates/sidebar.template.html' | Out-String)))

        foreach($server in $ServerList){
            
            & ([ScriptBlock]::Create($(Get-Content -Path './Resources/Templates/report-content.template.html' | Out-String)))
        }
})

$HTMLEnd = & ([ScriptBlock]::Create($(Get-Content -Path 'scripts.txt' | Out-String)))

$HTMLHeader + $HTMLBody + $HTMLEnd | Out-File ".\Output\testNew.html" -Encoding utf8

$fromaddress = "autoemail-donotreply@setra.com" 
$toaddress ="shivam25gupta96@gmail.com" 
$Subject = "Sever Applications Status Report" 
$body = "Please check the attachment!"
$attachment = "./app/Output/testNew.html"
$smtpserver = "smtp.gmail.com"
$SMTPPort = "587"
$Username = "shivam25gupta96@gmail.com"
$Password = "csdoyktbzcdmjlac"

#################################### 
 
$message = new-object System.Net.Mail.MailMessage 
$message.From = $fromaddress 
$message.To.Add($toaddress) 
# $message.CC.Add($CCaddress) 
$message.IsBodyHtml = $false 
$message.Subject = $Subject 
$attach = new-object Net.Mail.Attachment($attachment)
$message.Attachments.Add($attach) 
$message.body = $body 
# $message.body = $HTMLmessage

$smtp = new-object System.Net.Mail.SmtpClient($smtpserver, $SMTPPort) 
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
$smtp.Send($message)

Write-Verbose "$(Get-Date): Script completed!"