$ServerListFile = ".\serverstestlist.txt"   
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue  
$serverLoads = @()  
ForEach($computername in $ServerList)  
{ 
	$AVGProc = Get-WmiObject -computername $computername -Class win32_processor | Select-Object -ExpandProperty LoadPercentage
	
	$serverLoads += [PSCustomObject] @{  
			ServerName = $computername;
			CPULoad = $AVGProc;
	}
}
# $Outputreport = "<HTML><TITLE> Server Health Report </TITLE> 
# 					<BODY background-color:peachpuff> 
# 					<font color =""#99000"" face=""Microsoft Tai le""> 
# 					<H2> Server CPU Usage Report </H2></font> 
# 					<Table border=1 cellpadding=0 cellspacing=0> 
# 					<TR bgcolor=gray align=center> 
# 					<TD><B>Server Name</B></TD> 
# 					<TD><B>Avrg.CPU Utilization</B></TD> 
# 					" 
						
# Foreach($Entry in $serverLoads)      
# {  
# 	if(($Entry.CPULoad) -ge "30" -and ($Entry.CPULoad) -le "70")  
# 	{  
# 	$Outputreport += "<TR bgcolor=gray>"  
# 	}
# 	elseif($($Entry.CPULoad) -ge "70")  
# 	{  
# 	$Outputreport += "<TR bgcolor=red>"  
# 	}
# 	else 
# 	{ 
# 	$Outputreport += "<TR>"  
# 	} 
# 	$Outputreport += "<TD>$($Entry.Servername)</TD><TD align=center>$($Entry.CPULoad)</TD></TR>"  
# } 
# $Outputreport += "</Table></BODY></HTML>" 




# PowerShell Systems Report
# Example usage: .\SystemsReport.ps1 .\list.txt
# Remember that list.txt is the file containing a list of Server names to run this against

#region Variables and Arguments
#$list = $args[0] #This accepts the argument you add to your scheduled task for the list of servers. i.e. list.txt
# $list = ".\serverstestlist.txt"
# $computers = get-content $list #grab the names of the servers/computers to check from the list.txt file.


# Set free disk space threshold below in percent (default at 10%)

$thresholdspace = 20
[int]$EventNum = 3
[int]$ProccessNumToFetch = 10
$ListOfAttachments = @()
$Report = @()
$CurrentTime = Get-Date
#endregion

Function Create-PieChart() {
	param([string]$FileName)
		
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
	
	#Create our chart object 
	$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
	$Chart.Width = 300
	$Chart.Height = 290 
	$Chart.Left = 10
	$Chart.Top = 10

	#Create a chartarea to draw on and add this to the chart 
	$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$Chart.ChartAreas.Add($ChartArea) 
	[void]$Chart.Series.Add("Data") 

	#Add a datapoint for each value specified in the arguments (args) 
    foreach ($value in $args[0]) {
		Write-Host "Now processing chart value: " + $value
		$datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $value)
	    $datapoint.AxisLabel = "Value" + "(" + $value + " GB)"
	    $Chart.Series["Data"].Points.Add($datapoint)
	}

	$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
	$Chart.Series["Data"]["PieLabelStyle"] = "Outside" 
	$Chart.Series["Data"]["PieLineColor"] = "Black" 
	$Chart.Series["Data"]["PieDrawingStyle"] = "Concave" 
	($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

	#Set the title of the Chart to the current date and time 
	$Title = new-object System.Windows.Forms.DataVisualization.Charting.Title 
	$Chart.Titles.Add($Title) 
	$Chart.Titles[0].Text = "RAM Usage Chart (Used/Free)"

	#Save the chart to a file
	$Chart.SaveImage($FileName + ".png","png")
}

Function Get-HostUptime {
	param ([string]$ComputerName)
	$Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
	$LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
	$Time = (Get-Date) - $LastBootUpTime
	Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
}

# Assemble the HTML Header and CSS for our Report
$HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>My Systems Report</title>
<style type="text/css">
<!--
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

    #report { width: 835px; }

    table{
	border-collapse: collapse;
	border: none;
	font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
	color: black;
	margin-bottom: 10px;
}

    table td{
	font-size: 12px;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

    table th {
	font-size: 12px;
	font-weight: bold;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

h2{ clear: both; font-size: 130%; }

h3{
	clear: both;
	font-size: 115%;
	margin-left: 20px;
	margin-top: 30px;
}

p{ margin-left: 20px; font-size: 12px; }

table.list{ float: left; }

    table.list td:nth-child(1){
	font-weight: bold;
	border-right: 1px grey solid;
	text-align: right;
}

table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
div.column { width: 320px; float: left; }
div.first{ padding-right: 20px; border-right: 1px  grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
-->
</style>
</head>
<body>

"@

foreach ($computer in $ServerList) {

	$DiskInfo= Get-WMIObject -ComputerName $computer Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and ($_.freespace/$_.Size)*100 -lt $thresholdspace } | Select-Object SystemName, DriveType, VolumeName, Name, @{n='Size (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, @{n='FreeSpace (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='PercentFree';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} | ConvertTo-HTML -fragment
	
	#region System Info
	$SystemInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $computer | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory, caption
	$OS = $SystemInfo.caption
	$TotalRAM = $SystemInfo.TotalVisibleMemorySize/1MB
	$FreeRAM = $SystemInfo.FreePhysicalMemory/1MB
	$UsedRAM = $TotalRAM - $FreeRAM
	$RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
	$TotalRAM = [Math]::Round($TotalRAM, 2)
	$FreeRAM = [Math]::Round($FreeRAM, 2)
	$UsedRAM = [Math]::Round($UsedRAM, 2)
	$RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
	#endregion
	
	$TopProcesses = Get-Process -ComputerName $computer | Sort WS -Descending | Select ProcessName, Id, WS -First $ProccessNumToFetch | ConvertTo-Html -Fragment
	
	#region Services Report
	$ServicesReport = @()
	$Services = Get-WmiObject -Class Win32_Service -ComputerName $computer | Where {($_.StartMode -eq "Auto") -and ($_.State -eq "Stopped")}

	foreach ($Service in $Services) {
		$row = New-Object -Type PSObject -Property @{
	   		Name = $Service.Name
			Status = $Service.State
			StartMode = $Service.StartMode
		}
		$ServicesReport += $row
	}
	
	$ServicesReport = $ServicesReport | ConvertTo-Html -Fragment
	#endregion
		
	#region Event Logs Report
	# $SystemEventsReport = @()
	# $SystemEvents = Get-EventLog -ComputerName $computer -LogName System -EntryType Error,Warning -Newest $EventNum
	# foreach ($event in $SystemEvents) {
	# 	$row = New-Object -Type PSObject -Property @{
	# 		TimeGenerated = $event.TimeGenerated
	# 		EntryType = $event.EntryType
	# 		Source = $event.Source
	# 		Message = $event.Message
	# 	}
	# 	$SystemEventsReport += $row
	# }
			
	# $SystemEventsReport = $SystemEventsReport | ConvertTo-Html -Fragment
	
	# $ApplicationEventsReport = @()
	# $ApplicationEvents = Get-EventLog -ComputerName $computer -LogName Application -EntryType Error,Warning -Newest $EventNum
	# foreach ($event in $ApplicationEvents) {
	# 	$row = New-Object -Type PSObject -Property @{
	# 		TimeGenerated = $event.TimeGenerated
	# 		EntryType = $event.EntryType
	# 		Source = $event.Source
	# 		Message = $event.Message
	# 	}
	# 	$ApplicationEventsReport += $row
	# }
	
	# $ApplicationEventsReport = $ApplicationEventsReport | ConvertTo-Html -Fragment
	# #endregion
	
	# # Create the chart using our Chart Function
	# Create-PieChart -FileName ((Get-Location).Path + "\chart-$computer") $FreeRAM, $UsedRAM
	# $ListOfAttachments += "chart-$computer.png"
	# #region Uptime
	# # Fetch the Uptime of the current system using our Get-HostUptime Function.
	# $SystemUptime = Get-HostUptime -ComputerName $computer
	# #endregion

	# Create HTML Report for the current System being looped through
	$CurrentSystemHTML = @"
	<hr noshade size=3 width="100%">
	<div id="report">
	<p><h2>$computer Report</p></h2>
	<h3>System Info</h3>
	<table class="list">
	<tr>
	<td>System Uptime</td>
	<td>$SystemUptime</td>
	</tr>
	<tr>
	<td>OS</td>
	<td>$OS</td>
	</tr>
	<tr>
	<td>Total RAM (GB)</td>
	<td>$TotalRAM</td>
	</tr>
	<tr>
	<td>Free RAM (GB)</td>
	<td>$FreeRAM</td>
	</tr>  
	
"@
	
if($RAMPercentFree -ge "80")
{
$CurrentSystemHTML+= @"
<tr bgcolor=red >
"@
}
else
{
$CurrentSystemHTML+= @"
<tr>
"@
}
$CurrentSystemHTML+= @"

<td>Percent free RAM</td>
	<td>$RAMPercentFree</td>
	</tr>
	</table>
	
	<IMG SRC="chart-$computer.png" ALT="$computer Chart">
		
	<h3>Disk Info</h3>
	<p>Drive(s) listed below have less than $thresholdspace % free space. Drives above this threshold will not be listed.</p>
	<table class="normal">$DiskInfo</table>
	<br></br>
	
	<div class="first column">
	<h3>System Processes - Top $ProccessNumToFetch Highest Memory Usage</h3>
	<p>The following $ProccessNumToFetch processes are those consuming the highest amount of Working Set (WS) Memory (bytes) on $computer</p>
	<table class="normal">$TopProcesses</table>
	</div>
	<div class="second column">
	
	<h3>System Services - Automatic Startup but not Running</h3>
	<p>The following services are those which are set to Automatic startup type, yet are currently not running on $computer</p>
	<table class="normal">
	$ServicesReport
	</table>
	</div>
	
"@
	# Add the current System HTML Report into the final HTML Report body
	$HTMLMiddle += $CurrentSystemHTML
	
	}

# Assemble the closing HTML for our report.
$HTMLEnd = @"
</div>
</body>
</html>
"@

# Services check give in Excel
$strPath = "E:\PROJECTS\Server Processes\ServersServices1.xlsx"
#$computers = get-content $list
$ser = @()
# Create an Object Excel.Application using Com interface
$objExcel = New-Object -ComObject Excel.Application

# Disable the 'visible' property so the document won't open in excel
$objExcel.Visible = $false
$WorkBook = $objExcel.Workbooks.Open($strPath)
$WorkSheet = $WorkBook.sheets.item("Sheet1")
$Ro =  ($WorkSheet.UsedRange.Rows).count
$Co = ($WorkSheet.UsedRange.Columns).Count
$g=0
$c
for ($a=2; $a -le $Co; $a++)
{
$com = $computers[$g]
for ($b=2; $worksheet.cells.Item($b, $a).value2 -ne $c; $b++)
{
$k ='NULL'
$ServicesOutputs = ''
$k = $worksheet.cells.Item($b, $a).value2
$ServicesOutputs = get-service -name $k -ComputerName $com | Select-Object machinename, status, name, DisplayName
$ser += $ServicesOutputs
}
$g++
}
$objexcel.quit()
New-Object PSObject -Property @{Service = $ser }
$Outputreports = "<HTML><TITLE> Server Health Report </TITLE> 
                     <BODY background-color:peachpuff> 
                     <font color =""#99000"" face=""Microsoft Tai le""> 
                     <H2> Services Report </H2></font> 
                     <Table border=1 cellpadding=0 cellspacing=0> 
                     <TR bgcolor=gray align=center> 
                       <TD><B>Server Name</B></TD> 
                       <TD><B>Status</B></TD><TD><B>Name</B></TD><TD><B>DisplayName</B></TD>
                       "
					   foreach($Entrys in $ser)
					   {If ($Entrys.status -eq "Stopped")
					   {$Outputreports += "<TR bgcolor=red>"  
					   }
					   else 
						{ 
						$Outputreports += "<TR>"  
						}
						$Outputreports += "<TD>$($Entrys.machinename)</TD><TD>$($Entrys.status)</TD><TD align=center>$($Entrys.name)</TD><TD align=center>$($Entrys.DisplayName)</TD></TR>"  
					   }
					 $Outputreports += "</Table></BODY></HTML>" 

# Assemble the final report from all our HTML sections
$HTMLmessage = $Outputreport + $HTMLHeader + $HTMLMiddle + $HTMLEnd + $Outputreports 
# Save the report out to a file in the current path
$HTMLmessage | Out-File .\testFinal.html

#Email functionality code
$fromaddress = "autoemail-donotreply@external.emdmillipore.com" 
#$toaddress ="Aishwarya.Rajagopal@external.emdmillipore.com, prince.kumar-singh@external.emdmillipore.com, ashit.swain@external.emdmillipore.com, ramu.sannappanavar@external.emdmillipore.com, devesh.a.sharma@external.emdmillipore.com, akash.biswas@external.emdmillipore.com, mohamed-mydeen.sandu-abdul-kader@external.emdmillipore.com" 
$toaddress = "veeresh.a.sreeram@external.emdmillipore.com" 
$CCaddress = "veeresh.a.sreeram@external.emdmillipore.com" 
$Subject = "Millipore Applications Server CPU Status Report" 
#$body = "Please check the attachment!"
$attachment = ".\testFinal.html" 
$smtpserver = "smtpgw.merck.de"

#################################### 
 
# $message = new-object System.Net.Mail.MailMessage 
# $message.From = $fromaddress 
# $message.To.Add($toaddress) 
# $message.CC.Add($CCaddress) 
# $message.IsBodyHtml = $True 
# $message.Subject = $Subject 
# $attach = new-object Net.Mail.Attachment($attachment)
# $message.Attachments.Add($attach) 
# #$message.body = $body 
# $message.body = $HTMLmessage
# $smtp = new-object Net.Mail.SmtpClient($smtpserver) 
# $smtp.Send($message)

Write-Verbose "$(Get-Date): Script completed!"