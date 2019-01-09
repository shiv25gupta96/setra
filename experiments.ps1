$ServerList

$t1 = Get-Content -Path 'app/body.html' | Out-String
$text = [ScriptBlock]::create($t1)

$styles = {
    "<html>"
    $i
"</html>"
}


write (& $text)