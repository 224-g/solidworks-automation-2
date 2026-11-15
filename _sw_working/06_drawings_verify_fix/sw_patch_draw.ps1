$p = 'C:\Users\zgzgd\Documents\DSH\sw_drawings.ps1'
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
$c = $c.Replace('($y+$gap) -1 0', '($y+$gap) (-1) 0')
$c = $c.Replace('$y1 0 -1', '$y1 0 (-1)')
$c = $c.Replace(" -7 '", " (-7) '")
$c = $c.Replace(" -10 '", " (-10) '")
$c = $c.Replace(" -14 '", " (-14) '")
$c = $c.Replace(" -15 '", " (-15) '")
$c = $c.Replace(" -17 '", " (-17) '")
$c = $c.Replace(' $ox = 105; $oy = 105', ' $ox = 30; $oy = 120')
$c = $c.Replace(' $sx = 260; $sy = 105', ' $sx = 260; $sy = 120')
$bom = New-Object System.Text.UTF8Encoding($true)
[IO.File]::WriteAllText($p, $c, $bom)
Write-Output 'patched ok'
