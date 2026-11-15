$p = 'C:\Users\zgzgd\Documents\DSH\sw_drawings.ps1'
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
# FlatChord return: parenthesize elements
$c = $c.Replace('@(@($mx + ($d*$nx + $hh*$px)*$s, $my - ($d*$ny + $hh*$py)*$s),', '@(@(($mx + ($d*$nx + $hh*$px)*$s), ($my - ($d*$ny + $hh*$py)*$s)),')
$c = $c.Replace('@($mx + ($d*$nx - $hh*$px)*$s, $my - ($d*$ny - $hh*$py)*$s)', '@(($mx + ($d*$nx - $hh*$px)*$s), ($my - ($d*$ny - $hh*$py)*$s))')
# ToothPath point arrays
$c = $c.Replace('@($rf*[math]::Cos($a), $rf*[math]::Sin($a))', '@(($rf*[math]::Cos($a)), ($rf*[math]::Sin($a)))')
$c = $c.Replace('@($rb*[math]::Cos($psRbJ), $rb*[math]::Sin($psRbJ))', '@(($rb*[math]::Cos($psRbJ)), ($rb*[math]::Sin($psRbJ)))')
$c = $c.Replace('@($r*[math]::Cos($a), $r*[math]::Sin($a))', '@(($r*[math]::Cos($a)), ($r*[math]::Sin($a)))')
$c = $c.Replace('@($ra*[math]::Cos($a), $ra*[math]::Sin($a))', '@(($ra*[math]::Cos($a)), ($ra*[math]::Sin($a)))')
# P helper
$c = $c.Replace('@([math]::Round($ox+$x*$s,2), [math]::Round($oy-$y*$s,2))', '@(([math]::Round($ox+$x*$s,2)), ([math]::Round($oy-$y*$s,2)))')
# D02 pts negatives
$c = $c.Replace('@(-45,0)', '@((-45),0)').Replace('@(-10,90)', '@((-10),90)').Replace('@(-10,15)', '@((-10),15)').Replace('@(-45,15)', '@((-45),15)')
$bom = New-Object System.Text.UTF8Encoding($true)
[IO.File]::WriteAllText($p, $c, $bom)
Write-Output 'patched2 ok'
