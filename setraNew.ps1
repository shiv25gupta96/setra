$ServerListFile = ".\serverstestlist.txt"   
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue  
$thresholdSpace = 20
[int]$ProccessNumToFetch = 10
$SystemInfo = @{}

ForEach($computername in $ServerList)  
{
    #Get processor Load details
	$AVGProc = Get-WmiObject -computername $computername -Class win32_processor | Select-Object -ExpandProperty LoadPercentage

    # Disk Informations for a particular computer
    $DiskInfo= Get-WMIObject -ComputerName $computername Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and ($_.freespace/$_.Size)*100 -lt $thresholdspace } | Select-Object SystemName, DriveType, VolumeName, Name, @{n="Size (GB)";e={"{0:n2}" -f ($_.size/1gb)}}, @{n="FreeSpace (GB)";e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n="PercentFree";e={"{0:n2}" -f ($_.freespace/$_.size*100)}}
    
    # System Informations for a particular Computer
    $info = Get-WmiObject -Class Win32_OperatingSystem -computername $computername | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory, caption

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
$HTMLHeader = '<HTML>
<head>
    <TITLE> Server Health Report </TITLE>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.5.0/css/all.css" integrity="sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU" crossorigin="anonymous" />
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" integrity="sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO" crossorigin="anonymous" />
    <link rel="stylesheet" href="//malihu.github.io/custom-scrollbar/jquery.mCustomScrollbar.min.css" />
    <style>
        .critical::after,.position-middle{position:absolute}.critical::after,.position-middle,.server-list ul>li span.badge{top:50%;transform:translateY(-50%)}@font-face{font-family:Roboto;font-style:normal;font-weight:300;src:local("Roboto Light"),local("Roboto-Light"),url(https://fonts.gstatic.com/s/roboto/v18/KFOlCnqEu92Fr1MmSU5fBBc9.ttf) format("truetype")}@font-face{font-family:Roboto;font-style:normal;font-weight:400;src:local("Roboto"),local("Roboto-Regular"),url(https://fonts.gstatic.com/s/roboto/v18/KFOmCnqEu92Fr1Mu4mxP.ttf) format("truetype")}@font-face{font-family:Roboto;font-style:normal;font-weight:500;src:local("Roboto Medium"),local("Roboto-Medium"),url(https://fonts.gstatic.com/s/roboto/v18/KFOlCnqEu92Fr1MmEU9fBBc9.ttf) format("truetype")}@font-face{font-family:"Roboto Slab";font-style:normal;font-weight:400;src:local("Roboto Slab Regular"),local("RobotoSlab-Regular"),url(https://fonts.gstatic.com/s/robotoslab/v7/BngMUXZYTXPIvIBgJJSb6ufN5qA.ttf) format("truetype")}.critical{background:rgba(255,0,0,.521)!important}.critical::after{content:"\f071";display:block;color:red;font-family:"Font Awesome 5 Free";font-size:1.5rem;right:13%;font-weight:900}a,a:focus,a:hover{color:inherit;text-decoration:none;transition:all .3s;margin-bottom:2px}.lgradient-orange{background:linear-gradient(60deg,#ffa726,#fb8c00);box-shadow:0 2px 3px -1px #ffa8268c}.lgradient-green{background:linear-gradient(60deg,#66bb6a,#43a047);box-shadow:0 2px 3px -1px #66bb6a8c}.lgradient-purple{background:linear-gradient(60deg,#ab47bc,#8e24aa);box-shadow:0 2px 3px -1px #ab47bc8c}.lgradient-blue{background:linear-gradient(60deg,#26c6da,#00acc1);box-shadow:0 2px 3px -1px #26c6da8c}.tcolor-orange{color:#fb8c00}.tcolor-green{color:#43a047}.tcolor-purple{color:#8e24aa}.tcolor-blue{color:#00acc1}.fixed-table-layout{table-layout:fixed}.resize-header{margin-left:0!important;margin-top:0!important;width:100%}.shrink-card{min-height:0!important}body{background-color:#eee;padding:0;margin:0;width:100%;height:100%;font-family:Roboto,Sans-Serif;overflow:hidden}.wrapper{display:flex;width:100%}.sidebar{position:fixed;min-width:340px;height:100vh;color:#d0d0d0;background-color:#2d2d2d;overflow:hidden;z-index:1000}.server-list ul>li,.sidebar a{position:relative}.sidebar .form-control{width:320px;margin:10px;background-color:#efefef}.sidebar hr{background-color:#ccc}.sidebar a{display:block;color:#fff;width:100%;padding:8px 10px;background-color:transparent;text-decoration:none}.server-list .server-header{position:relative;cursor:pointer;padding:8px 10px;margin-bottom:2px;font-size:.9rem;display:flex;align-items:center}.server-list .server-header small{font-size:.7em}.server-list ul>li.active>a,.server-list ul>li.active>a:focus,.server-list ul>li.active>a:hover{background-color:#4caf50}.server-list ul>li>a:focus,.server-list ul>li>a:hover{background-color:#404040}.server-list ul>li span.badge{display:inline-block;position:absolute;padding:3px 12px;right:30%}.report-content{position:relative;width:calc(100% - 340px);height:100%;margin-right:0;margin-left:340px;padding:0}.mCSB_container_wrapper{margin-bottom:12px;margin-right:12px}.mCSB_vertical_horizontal>.mCSB_scrollTools.mCSB_scrollTools_vertical{bottom:12px;width:12px}.mCSB_vertical_horizontal>.mCSB_scrollTools.mCSB_scrollTools_horizontal{right:12px;height:12px}.mCSB_scrollTools.mCSB_scrollTools_horizontal .mCSB_dragger .mCSB_dragger_bar{margin:4px auto}.mCSB_scrollTools.mCSB_scrollTools_horizontal .mCSB_draggerRail{margin:5px auto}.report-content .mCSB_container{padding:15px 20px!important}.report-content .mCSB_container>.row{margin:15px 0 0;flex-wrap:nowrap;justify-content:space-between}.report-content .card{width:470px;min-height:200px;max-height:200px;margin-top:10px;border-radius:4px;box-shadow:0 2px 5px 2px rgba(0,0,0,.15)}.report-content .column>.card:first-of-type{margin-bottom:30px}.report-content .column:first-of-type{padding-right:20px}.report-content .card>.card-header{color:#fff;border:none;border-radius:4px;margin-top:-10px;margin-right:10px;margin-left:10px;padding:0 1.25rem;height:48px;display:flex;justify-content:center;flex-direction:column}.report-content .card-header h5{margin:0}.report-content .card>.card-body{padding:8px 12px}.report-content .card>.card-footer{display:flex;position:relative;padding:.1rem 1rem;color:#555;font-size:13px}.report-content .card>.card-body .table{line-height:1.15rem;font-size:15px;margin-bottom:0}.report-content .table tr:first-of-type td,.report-content .table tr:first-of-type th{border:none}.report-content .table td,.report-content .table th{padding:5px 0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.system-info .table td,.system-info .table th{padding:3px 0}.system-info .table td:not(:first-child),.system-info .table th:not(:first-child){white-space:unset}.report-content .table td:not(:last-child),.report-content .table th:not(:last-child){padding-right:15px}.report-content .card>.card-body.row{position:relative;margin:0;justify-content:space-between;align-items:center}.drive-wrapper{overflow:hidden;flex-grow:1;display:flex;flex-direction:row;justify-content:space-evenly;flex-wrap:wrap}.disk-drive{flex:0 0 40%}.disk-drive p{font-size:12px;margin:0;text-align:center}.disk-info img{height:30px}.disk-drive .progress{box-sizing:border-box;margin-top:4px;border-radius:unset;display:flex;flex-direction:row-reverse;border:1px solid #555;box-shadow:unset}.disk-drive .progress .progress-bar{background:#fff;color:#555;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.left-arrow,.right-arrow{cursor:pointer}.report-content .system-processes,.report-content .system-services{min-height:416px;max-height:416px}
    </style>
</head>'

$HTMLBody = $("<BODY>
<div class=`"wrapper`">
    <div class=`"sidebar`">
        <form class=`"form-group`">
            <input type=`"text`" placeholder=`"Search`" class=`"form-control`"></input>
        </form>
        <hr />
        <div class=`"sidebar-body`">
            <div class=`"server-list content`">  
                <div class=`"server-header`" data-toggle=`"collapse`" data-target=`"#content-server`" aria-expanded=`"false`">
                    <small class=`"fas fa-plus mr-2`"></small>
                    <span>Content Servers</span>
                </div>
                <ul class=`"list-unstyled collapse components`" id=`"content-server`">"
                    foreach($server in $ServerList){
                        "<li>
                            <a href=`"#`" data-server-name=`"server-$server`">$server
                                <span class=`"badge badge-pill badge-light`">
                                    <strong>$($SystemInfo.$server.CPULoad)</strong><br>
                                    <small>CPU</small>
                                </span>
                            </a>
                        </li>"
                    }
               "</ul>
            </div>
        </div>
    </div>")

$HTMLEnd = "<!----------JQuery Script-->
<script src=`"https://code.jquery.com/jquery-3.3.1.slim.min.js`" integrity=`"sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo`" crossorigin=`"anonymous`"></script>

<!----------Custom Scrollbars -->
<script src=`"//malihu.github.io/custom-scrollbar/jquery.mCustomScrollbar.concat.min.js`"></script>

<!----------PopperJS Script-->

<!----------bootstrapJS Script-->
<script src=`"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js`" integrity=`"sha384-ChfqqxuZUCnJSK3+MXmPNIyE6ZbWh2IMqE241rYiqJxyMiZ6OW/JmZQ5stwEULTy`" crossorigin=`"anonymous`"></script>

<script>
    
    function defaults(){
        var defaultMenu = `$('.server-list .server-header').first();
        defaultMenu.attr(`"aria-expanded`", `"true`");
        var ul = defaultMenu.next(`"ul[id$='-server']`").toggleClass(`"show`");
        defaultMenu.children('small.fas').first().toggleClass('fa-minus').toggleClass(`"fa-plus`");
        ul.children(`"li`").first().addClass(`"active`");

        //console.log(`"#`" + ul.find(`"li:first-of-type a`").data(`"serverName`"));

        `$(`"`#`" + ul.find(`"li:first-of-type a`").data(`"serverName`")).removeClass(`"d-none`");

        `$(`".disk-info .left-arrow, .disk-info .right-arrow`").hide();

        `$(`".disk-info .drive-wrapper`").each(function(ind, elem){
            `$(elem).data(`"driveToBeShown`", 1);
            `$(elem).children().each(function(childInd, childElem){
                var rightArrow = (`$(elem).parents(`".disk-info`")).find(`".right-arrow`");
                console.log(`$(elem).parents(`".disk-info`").find(`".right-arrow`"));
                if(childInd > 1){
                    `$(childElem).addClass(`"d-none`");
                    rightArrow.show();
                }
            });
        });
        
    };
    
    `$(window).ready(function (ev){
        var sidebarBodyHeight = `$(`".sidebar`").height() - `$(`".sidebar form`").height() - 10 - 34;
        `$(`".sidebar .sidebar-body`").height(sidebarBodyHeight);
        `$(`".sidebar .sidebar-body`").mCustomScrollbar({
            theme: `"minimal`",
            scrollbarPosition: `"inside`"
        });
        `$(`".report-content`").mCustomScrollbar({
            theme: `"dark`",
            axis: `"yx`",
            callbacks: {
                onOverflowX: function(){
                    `$(`".report-content .mCSB_container`").width(`$(`".report-content .mCSB_container`").width() + 20);
                    console.dir(this);
                }
            }
        });
        
        defaults();
    })

    `$(`".server-list .server-header`").click(function(event){
        var fas=`$(event.currentTarget).children('small.fas');
        fas.toggleClass('fa-plus').toggleClass('fa-minus');
    });

    `$(`"ul[id`$='-server'] a`").click(function(ev){
        /* for removing critical, when you visit the critical server */
        // `$(ev.currentTarget).parent(`"li.critical`").parent(`"ul`").prev(`".server-header`").removeClass(`"critical`");
        // `$(ev.currentTarget).parent(`"li.critical`").removeClass(`"critical`");

        `$(`"ul[id`$='-server'] li.active`").removeClass(`"active`");
        `$(ev.currentTarget).parent(`"li`").addClass(`"active`");

        `$(`".report-content:not(.d-none)`").addClass(`"d-none`");
        `$(`"#`" + `$(ev.currentTarget).data(`"serverName`")).removeClass(`"d-none`");
    });
    `$(`".disk-info div.left-arrow, .disk-info div.right-arrow`").click(function(ev){
        var driveToBeShown = `$(ev.currentTarget).parent().children(`".drive-wrapper`").data(`"driveToBeShown`");
        var leftArrow=`$(ev.currentTarget).parent().children(`".left-arrow`");
        var rightArrow = `$(ev.currentTarget).parent().children(`".right-arrow`");
        var drives = `$(ev.currentTarget).parent().children(`".drive-wrapper`").children();
        if(`$(ev.currentTarget).is(rightArrow)){
            console.log(`"drive Start: `" + driveToBeShown +`", Clicked: Right`");
            leftArrow.show();
            driveToBeShown += 1;
            `$(drives[driveToBeShown-2]).addClass(`"d-none`");
            `$(drives[driveToBeShown]).removeClass(`"d-none`");
            if(driveToBeShown + 1 == drives.length){
                rightArrow.hide();
            }
            console.log(`"drive End: `" + driveToBeShown +`", Clicked: Right`");
        }
        if(`$(ev.currentTarget).is(leftArrow)){
            console.log(`"drive Start: `" + driveToBeShown +`", Clicked: Lefts`");
            rightArrow.show();
            `$(drives[driveToBeShown]).addClass(`"d-none`");
            `$(drives[driveToBeShown-2]).removeClass(`"d-none`");
            driveToBeShown -= 1;
            if(driveToBeShown == 1){
                leftArrow.hide();
            }
            console.log(`"drive End: `" + driveToBeShown +`", Clicked: Lefts`");
        }
        `$(ev.currentTarget).parent().children(`".drive-wrapper`").data(`"driveToBeShown`", driveToBeShown);
    })
    
    `$(`".card .card-header`").click(function(ev){
        `$(ev.currentTarget).nextAll().toggle();
        `$(ev.currentTarget).toggleClass(`"resize-header`");

        `$(ev.currentTarget).parent().toggleClass(`"shrink-card`");
    })

</script>
</BODY>
</HTML>"

$HTMLHeader + $HTMLBody + $HTMLEnd | Out-File ".\testNew.html"