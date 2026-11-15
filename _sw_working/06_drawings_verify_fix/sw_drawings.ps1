# sw_drawings.ps1 - generate 17 engineering drawings (SVG) - PS 5.1 compatible
$ErrorActionPreference = 'Stop'
$outDir = 'C:\Users\zgzgd\Documents\DSH\精英联赛_设计包\工程图'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$script:body = New-Object System.Collections.Generic.List[string]
function Add($s) { $script:body.Add($s) }
function Ln($x1,$y1,$x2,$y2,$w=0.35,$dash='') {
  $a=[math]::Round($x1,2); $b=[math]::Round($y1,2); $c=[math]::Round($x2,2); $d=[math]::Round($y2,2)
  Add("<line x1='$a' y1='$b' x2='$c' y2='$d' stroke='black' stroke-width='$w'$dash />")
}
function Cir($cx,$cy,$r,$w=0.35,$dash='') {
  $a=[math]::Round($cx,2); $b=[math]::Round($cy,2); $c=[math]::Round($r,2)
  Add("<circle cx='$a' cy='$b' r='$c' fill='none' stroke='black' stroke-width='$w'$dash />")
}
function Rec($x,$y,$w,$h,$lw=0.35) {
  $a=[math]::Round($x,2); $b=[math]::Round($y,2); $c=[math]::Round($w,2); $d=[math]::Round($h,2)
  Add("<rect x='$a' y='$b' width='$c' height='$d' fill='none' stroke='black' stroke-width='$lw' />")
}
function Txt($x,$y,$s,$size=3.5,$anchor='middle',$rot=0) {
  $a=[math]::Round($x,2); $b=[math]::Round($y,2)
  if ($rot -ne 0) { $tr = " transform='rotate($rot $a $b)'" } else { $tr = '' }
  Add("<text x='$a' y='$b' font-size='$size' text-anchor='$anchor' font-family='SimHei, Microsoft YaHei, sans-serif'$tr>$s</text>")
}
function Arrow($x,$y,$dx,$dy,$sz=1.6) {
  $px = -$dy; $py = $dx
  $hx1 = $x - $dx*$sz + $px*$sz*0.45; $hy1 = $y - $dy*$sz + $py*$sz*0.45
  $hx2 = $x - $dx*$sz - $px*$sz*0.45; $hy2 = $y - $dy*$sz - $py*$sz*0.45
  $xr=[math]::Round($x,2); $yr=[math]::Round($y,2)
  $hx1r=[math]::Round($hx1,2); $hy1r=[math]::Round($hy1,2); $hx2r=[math]::Round($hx2,2); $hy2r=[math]::Round($hy2,2)
  Add("<polygon points='$xr,$yr $hx1r,$hy1r $hx2r,$hy2r' fill='black' />")
}
function DimH($x1,$x2,$y,$gap,$label,$size=3) {
  Ln $x1 $y $x1 ($y+$gap) 0.18
  Ln $x2 $y $x2 ($y+$gap) 0.18
  Ln $x1 ($y+$gap) $x2 ($y+$gap) 0.25
  Arrow $x1 ($y+$gap) (-1) 0
  Arrow $x2 ($y+$gap) 1 0
  Txt (($x1+$x2)/2) ($y+$gap-1) $label $size
}
function DimV($y1,$y2,$x,$gap,$label,$size=3) {
  Ln $x $y1 ($x+$gap) $y1 0.18
  Ln $x $y2 ($x+$gap) $y2 0.18
  Ln ($x+$gap) $y1 ($x+$gap) $y2 0.25
  Arrow ($x+$gap) $y1 0 (-1)
  Arrow ($x+$gap) $y2 0 1
  Txt ($x+$gap+0.5) (($y1+$y2)/2) $label $size 'start'
}
function Title($name,$mat,$qty,$scale,$pno) {
  $tx = 157; $ty = 178
  Add("<rect x='$tx' y='$ty' width='140' height='32' fill='white' stroke='black' stroke-width='0.5' />")
  Ln $tx ($ty+10) ($tx+140) ($ty+10) 0.35
  Ln ($tx+60) ($ty+10) ($tx+60) ($ty+32) 0.35
  Ln ($tx+110) ($ty+10) ($tx+110) ($ty+32) 0.35
  Ln $tx ($ty+21) ($tx+140) ($ty+21) 0.35
  Txt ($tx+30) ($ty+7) $name 4.5
  Txt ($tx+85) ($ty+17.5) $mat 3
  Txt ($tx+130) ($ty+17.5) $qty 3
  Txt ($tx+145) ($ty+17.5) $scale 3 'end'
  Txt ($tx+10) ($ty+27) $pno 3 'start'
  Txt ($tx+85) ($ty+27) '智能制造工程' 3
  Txt ($tx+125) ($ty+27) '2026-11' 3
  Txt ($tx+30) ($ty+17.5) '材料' 2.5
}
function SaveSvg($path) {
  $hdr = "<svg xmlns='http://www.w3.org/2000/svg' width='297mm' height='210mm' viewBox='0 0 297 210'><rect x='0' y='0' width='297' height='210' fill='white' stroke='black' stroke-width='1' />"
  $all = $hdr + ($script:body -join "`n") + '</svg>'
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, $all, $enc)
  $script:body.Clear()
}
function P($x,$y,$ox,$oy,$s) { @(([math]::Round($ox+$x*$s,2)), ([math]::Round($oy-$y*$s,2))) }

# involute tooth path
function ToothPath($z,$m,$j) {
  $al = 20*[math]::PI/180; $rp = $m*$z/2; $rb = $rp*[math]::Cos($al); $ra = $rp+$m; $rf = $rp-1.25*$m
  $invp = [math]::Tan($al)-$al; $ua = [math]::Sqrt(($ra/$rb)*($ra/$rb)-1); $inva = $ua-[math]::Atan($ua); $htp = [math]::PI/(2*$z)
  $psLbPrev = ($j-1)*2*[math]::PI/$z + 3*[math]::PI/(2*$z) - $invp
  $psRbJ = $j*2*[math]::PI/$z + $htp + $invp
  $psRaJ = $psRbJ - $inva; $psLaPrev = $psLbPrev + $inva
  $pts = New-Object System.Collections.Generic.List[object]
  for ($i=0; $i -le 6; $i++) { $a = $psLbPrev + ($psRbJ-$psLbPrev)*$i/6; $pts.Add(@(($rf*[math]::Cos($a)), ($rf*[math]::Sin($a)))) }
  $pts.Add(@(($rb*[math]::Cos($psRbJ)), ($rb*[math]::Sin($psRbJ))))
  for ($i=1; $i -le 8; $i++) { $u=$ua*$i/8; $r=$rb*[math]::Sqrt(1+$u*$u); $a=$psRbJ-($u-[math]::Atan($u)); $pts.Add(@(($r*[math]::Cos($a)), ($r*[math]::Sin($a)))) }
  for ($i=1; $i -le 4; $i++) { $a = $psRaJ + ($psLaPrev-$psRaJ)*$i/4; $pts.Add(@(($ra*[math]::Cos($a)), ($ra*[math]::Sin($a)))) }
  for ($i=7; $i -ge 0; $i--) { $u=$ua*$i/8; $r=$rb*[math]::Sqrt(1+$u*$u); $a=$psLbPrev+($u-[math]::Atan($u)); $pts.Add(@(($r*[math]::Cos($a)), ($r*[math]::Sin($a)))) }
  return ,$pts
}
function GearFace($cx,$cy,$s,$z,$m,$da,$d,$df) {
  Cir $cx $cy ($da/2*$s) 0.35
  Cir $cx $cy ($d/2*$s) 0.2 ' stroke-dasharray="6 2 1 2"'
  Cir $cx $cy ($df/2*$s) 0.2
  $dpath = ''
  for ($j=0; $j -lt $z; $j++) {
    $pts = ToothPath $z $m $j
    $first = $true
    foreach ($pt in $pts) {
      $px = [math]::Round($cx + $pt[0]*$s,2); $py = [math]::Round($cy - $pt[1]*$s,2)
      if ($first) { $dpath += "M $px $py"; $first=$false } else { $dpath += " L $px $py" }
    }
    $dpath += ' Z '
  }
  Add("<path d='$dpath' fill='none' stroke='black' stroke-width='0.2' />")
}
function GearTable($x,$y,$s,$rows) {
  $h = $rows.Count*5
  Add("<rect x='$x' y='$y' width='46' height='$h' fill='white' stroke='black' stroke-width='0.35' />")
  Txt ($x+23) ($y-1.5) '齿轮参数' 3.2
  for ($i=0; $i -lt $rows.Count; $i++) {
    Ln $x ($y+$i*5) ($x+46) ($y+$i*5) 0.25
    Txt ($x+11) ($y+$i*5+3.5) $rows[$i][0] 2.8 'middle'
    Txt ($x+34) ($y+$i*5+3.5) $rows[$i][1] 2.8 'middle'
  }
  Ln $x ($y+$rows.Count*5) ($x+46) ($y+$rows.Count*5) 0.25
}
function FlatChord($mx,$my,$r,$d,$thdeg,$s) {
  $th = $thdeg*[math]::PI/180
  $nx = [math]::Cos($th); $ny = [math]::Sin($th)
  $px = [math]::Sin($th); $py = -[math]::Cos($th)
  $hh = [math]::Sqrt($r*$r-$d*$d)
  @(
    @(($mx + ($d*$nx + $hh*$px)*$s), ($my - ($d*$ny + $hh*$py)*$s)),
    @(($mx + ($d*$nx - $hh*$px)*$s), ($my - ($d*$ny - $hh*$py)*$s))
  )
}
function Cent($cx,$cy,$r) {
  Ln ($cx-$r) $cy ($cx+$r) $cy 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln $cx ($cy-$r) $cx ($cy+$r) 0.15 ' stroke-dasharray="5 2 1 2"'
}

# ================= PART DRAWINGS =================
function D01 {
  $s = 0.5; $ox = 30; $oy = 105
  Rec $ox ($oy-235*$s) (432*$s) (330*$s) 0.5
  foreach ($h in @(@(20,-42),@(412,-42),@(20,88),@(412,88))) {
    $c = P $h[0] $h[1] $ox $oy $s
    Cir $c[0] $c[1] (6.4*$s/2) 0.35
    Cent $c[0] $c[1] (4.5*$s)
  }
  DimH $ox ($ox+432*$s) ($oy-235*$s) 8 '432'
  DimV ($oy-235*$s) $oy ($ox+432*$s) 8 '330'
  DimH ($ox+20*$s) ($ox+412*$s) ($oy-235*$s) 16 '4×Ø6.4' 2.8
  DimV ($oy+88*$s) ($oy-42*$s) $ox 14 '53  130  53' 2.6
  DimV ($oy+88*$s) ($oy+42*$s) $ox (-14) '183' 2.6
  $sx = 260; $sy = 120
  Rec $sx ($sy-235*$s) (12*$s) (330*$s) 0.5
  DimH $sx ($sx+12*$s) ($sy-235*$s) 7 '12' 2.8
  Title '底板' 'Q235-A' '1' '1:2' 'P01'
  SaveSvg "$outDir\P01_底板.svg"
}
function D02 {
  $s = 1; $ox = 60; $oy = 115
  $pts = @(@((-45),0),@(45,0),@(45,15),@(10,15),@(10,90),@((-10),90),@((-10),15),@((-45),15))
  $d = ''
  $first = $true
  foreach ($p in $pts) { $c = P $p[0] $p[1] $ox $oy $s; if ($first) { $d += "M $($c[0]) $($c[1])"; $first=$false } else { $d += " L $($c[0]) $($c[1])" } }
  Add("<path d='$d Z' fill='none' stroke='black' stroke-width='0.5' />")
  $c = P 0 65 $ox $oy $s
  Cir $c[0] $c[1] (10.2*$s/2) 0.35
  Cent $c[0] $c[1] (7*$s)
  DimH ($ox-45) ($ox+45) $oy 7 '90'
  DimV $oy ($oy-15*$s) ($ox+45) 7 '15'
  DimV ($oy-15*$s) ($oy-90*$s) ($ox-45) (-7) '75'
  DimH ($ox-10) ($ox+10) ($oy-90*$s) 8 '20'
  DimV $oy ($oy-65*$s) ($ox-45) (-15) '65'
  DimV ($oy-65*$s) ($oy-90*$s) ($ox-45) (-15) 'Ø10.2'
  $sx = 230; $sy = 70
  Rec $sx ($sy-90*$s) (12*$s) (90*$s) 0.5
  DimH $sx ($sx+12*$s) ($sy-90*$s) 7 '12'
  Title '支架' 'Q235-A' '2' '1:1' 'P02'
  SaveSvg "$outDir\P02_支架.svg"
}
function D03 {
  $s = 1; $ox = 90; $oy = 100
  Rec ($ox-40) ($oy-32) 80 32 0.5
  DimH ($ox-40) ($ox+40) ($oy-32) 7 '80'
  DimV ($oy-32) $oy ($ox+40) 7 '32'
  $sx = 230; $sy = 100
  Rec $sx ($sy-32) 12 32 0.5
  DimH $sx ($sx+12) ($sy-32) 7 '12'
  Title '导轨支架' 'Q235-A' '1' '1:1' 'P03'
  SaveSvg "$outDir\P03_导轨支架.svg"
}
function D04 {
  $s = 2; $ox = 70; $oy = 90
  Cir $ox $oy (5*$s) 0.5
  $ch = FlatChord $ox $oy 5 2 94.5 $s
  Ln $ch[0][0] $ch[0][1] $ch[1][0] $ch[1][1] 0.5
  Cent $ox $oy (7*$s)
  Txt ($ox+9*$s) ($oy-4*$s) 'Ø10' 3 'start'
  Txt ($ox+9*$s) ($oy+3*$s) '扁2(距中心)' 2.6 'start'
  $sx = 210; $sy = 90
  Rec ($sx-56) ($sy-5) 56 10 0.5
  Ln ($sx-56) $sy ($sx-56+56) $sy 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-56) $sx ($sy+5) 7 '56'
  DimV ($sy-5) ($sy+5) ($sx+2) 7 'Ø10'
  Title '主动轴' '45钢' '1' '1:1' 'P04'
  SaveSvg "$outDir\P04_主动轴.svg"
}
function D05 {
  $s = 2; $ox = 70; $oy = 90
  Cir $ox $oy (5*$s) 0.5
  $ch = FlatChord $ox $oy 5 2 83.25 $s
  Ln $ch[0][0] $ch[0][1] $ch[1][0] $ch[1][1] 0.5
  Cent $ox $oy (7*$s)
  Txt ($ox+9*$s) ($oy-4*$s) 'Ø10' 3 'start'
  Txt ($ox+9*$s) ($oy+3*$s) '扁2(距中心)' 2.6 'start'
  $sx = 210; $sy = 90
  Rec ($sx-48) ($sy-5) 48 10 0.5
  Ln ($sx-48) $sy ($sx-48+48) $sy 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-48) $sx ($sy+5) 7 '48'
  DimV ($sy-5) ($sy+5) ($sx+2) 7 'Ø10'
  Title '从动轴' '45钢' '1' '1:1' 'P05'
  SaveSvg "$outDir\P05_从动轴.svg"
}
function D06 {
  $s = 1.6; $ox = 75; $oy = 105
  GearFace $ox $oy $s 20 2 44 40 35
  Cir $ox $oy (8*$s) 0.4
  Cir $ox $oy (5.1*$s) 0.35
  $ch = FlatChord $ox $oy 5.1 2 94.5 $s
  Ln $ch[0][0] $ch[0][1] $ch[1][0] $ch[1][1] 0.35
  DimV ($oy-22*$s) $oy ($ox+22*$s) 7 'Ø44'
  DimV ($oy-20*$s) $oy ($ox-22*$s) (-10) 'Ø40' 2.8
  DimV ($oy-17.5*$s) $oy ($ox-22*$s) (-17) 'Ø35' 2.8
  DimV ($oy-8*$s) $oy ($ox-22*$s) (-10) 'Ø16' 2.8
  Txt ($ox+10*$s) ($oy+14*$s) 'Ø10.2' 2.8 'start'
  $sx = 210; $sy = 105
  Rec ($sx-24) ($sy-22) 24 44 0.5
  Ln ($sx-6) ($sy-22) ($sx-6) ($sy+22) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-18) ($sy-22) ($sx-18) ($sy+22) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-24) ($sy-8) ($sx-6) ($sy-8) 0.35
  Ln ($sx-24) ($sy+8) ($sx-6) ($sy+8) 0.35
  Ln ($sx-18) ($sy-8) ($sx-18) ($sy+8) 0.35
  Ln $sx ($sy-8) $sx ($sy+8) 0.35
  Ln ($sx-24) ($sy-5.1) $sx ($sy-5.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-24) ($sy+5.1) $sx ($sy+5.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-24) $sx ($sy+22) 7 '24'
  DimH ($sx-6) $sx ($sy-22) (-7) '6'
  DimH ($sx-18) ($sx-6) ($sy-22) (-7) '12'
  DimH ($sx-24) ($sx-18) ($sy-22) (-7) '6'
  GearTable 160 30 1 @(@('m','2'),@('z','20'),@('α','20°'),@('d','40'),@('da','44'),@('df','35'),@('b','12'))
  Title '主动齿轮' '45钢' '1' '1:1' 'P06'
  SaveSvg "$outDir\P06_主动齿轮.svg"
}
function D07 {
  $s = 1.6; $ox = 95; $oy = 95
  GearFace $ox $oy $s 40 2 84 80 75
  Cir $ox $oy (8*$s) 0.4
  Cir $ox $oy (5.1*$s) 0.35
  $ch = FlatChord $ox $oy 5.1 2 83.25 $s
  Ln $ch[0][0] $ch[0][1] $ch[1][0] $ch[1][1] 0.35
  DimV ($oy-42*$s) $oy ($ox+42*$s) 7 'Ø84'
  DimV ($oy-40*$s) $oy ($ox-42*$s) (-10) 'Ø80' 2.8
  DimV ($oy-37.5*$s) $oy ($ox-42*$s) (-17) 'Ø75' 2.8
  DimV ($oy-8*$s) $oy ($ox-42*$s) (-10) 'Ø16' 2.8
  Txt ($ox+10*$s) ($oy+14*$s) 'Ø10.2' 2.8 'start'
  $sx = 220; $sy = 95
  Rec ($sx-24) ($sy-42) 24 84 0.5
  Ln ($sx-6) ($sy-42) ($sx-6) ($sy+42) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-18) ($sy-42) ($sx-18) ($sy+42) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-24) ($sy-8) ($sx-6) ($sy-8) 0.35
  Ln ($sx-24) ($sy+8) ($sx-6) ($sy+8) 0.35
  Ln ($sx-18) ($sy-8) ($sx-18) ($sy+8) 0.35
  Ln $sx ($sy-8) $sx ($sy+8) 0.35
  Ln ($sx-24) ($sy-5.1) $sx ($sy-5.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-24) ($sy+5.1) $sx ($sy+5.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-24) $sx ($sy+42) 7 '24'
  DimH ($sx-6) $sx ($sy-42) (-7) '6'
  DimH ($sx-18) ($sx-6) ($sy-42) (-7) '12'
  DimH ($sx-24) ($sx-18) ($sy-42) (-7) '6'
  GearTable 32 30 1 @(@('m','2'),@('z','40'),@('α','20°'),@('d','80'),@('da','84'),@('df','75'),@('b','12'))
  Title '从动齿轮' '45钢' '1' '1:1' 'P07'
  SaveSvg "$outDir\P07_从动齿轮.svg"
}
function D08 {
  $s = 1.2; $ox = 105; $oy = 95
  Cir $ox $oy (50*$s) 0.5
  Cir $ox $oy (5.1*$s) 0.35
  $ch = FlatChord $ox $oy 5.1 2 83.25 $s
  Ln $ch[0][0] $ch[0][1] $ch[1][0] $ch[1][1] 0.35
  $hp = P 35 0 $ox $oy $s
  Cir $hp[0] $hp[1] (8.2*$s/2) 0.35
  Cent $hp[0] $hp[1] (5*$s)
  Cent $ox $oy (55*$s)
  DimV ($oy-50*$s) $oy ($ox+50*$s) 7 'Ø100'
  DimH $ox $hp[0] ($oy-50*$s) (-7) '35' 2.8
  Txt ($ox-55*$s) ($oy+50*$s+6) 'Ø10.2' 2.8 'middle'
  Txt ($hp[0]+5) ($hp[1]+5) 'Ø8.2' 2.8 'start'
  $sx = 235; $sy = 95
  Rec ($sx-100) ($sy-4) 100 8 0.5
  DimH ($sx-100) $sx ($sy+4) 7 '8'
  Title '曲柄盘' '45钢' '1' '1:1' 'P08'
  SaveSvg "$outDir\P08_曲柄盘.svg"
}
function D09 {
  $s = 4; $ox = 110; $oy = 90
  Rec ($ox-4*$s) ($oy-8*$s) (8*$s) (16*$s) 0.5
  DimH ($ox-4*$s) ($ox+4*$s) ($oy+8*$s) 7 'Ø8'
  DimV ($oy-8*$s) ($oy+8*$s) ($ox+4*$s) 7 '16'
  Txt ($ox+20) ($oy-20) '两端倒角C0.5' 3 'start'
  Title '曲柄销' '45钢' '1' '2:1' 'P09'
  SaveSvg "$outDir\P09_曲柄销.svg"
}
function D10 {
  $s = 1; $ox = 85; $oy = 100
  Cir $ox $oy (11*$s) 0.5
  $c2 = P 85 0 $ox $oy $s
  Cir $c2[0] $c2[1] (11*$s) 0.5
  Ln ($ox-7.55) ($oy-8) ($c2[0]+7.55) ($oy-8) 0.5
  Ln ($ox-7.55) ($oy+8) ($c2[0]+7.55) ($oy+8) 0.5
  Cir $ox $oy (4.1*$s) 0.35
  Cir $c2[0] $c2[1] (4.1*$s) 0.35
  Ln ($ox-12*$s) $oy ($c2[0]+12*$s) $oy 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH $ox $c2[0] ($oy+11*$s) 8 '85'
  DimV ($oy-11*$s) ($oy+11*$s) ($ox-11*$s) (-7) '2×Ø22' 2.8
  DimV ($oy-4.1*$s) ($oy+4.1*$s) ($ox-11*$s) (-14) '2×Ø8.2' 2.8
  DimV ($oy-8) ($oy+8) ($c2[0]+11*$s) 7 '16'
  $sx = 230; $sy = 100
  Rec ($sx-8) ($sy-11) 8 22 0.5
  Rec ($sx-8) ($sy-4.1) 8 8.2 0.2
  Ln ($sx-8) ($sy-4.1) $sx ($sy-4.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-8) ($sy+4.1) $sx ($sy+4.1) 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-8) $sx ($sy+11) 7 '8'
  DimV ($sy-11) ($sy+11) ($sx+2) 7 'Ø22'
  Title '连杆' '45钢' '1' '1:1' 'P10'
  SaveSvg "$outDir\P10_连杆.svg"
}
function D11 {
  $s = 1; $ox = 90; $oy = 100
  Rec ($ox-33) ($oy-28) 66 56 0.5
  $c = P 0 -1 $ox $oy $s
  Cir $c[0] $c[1] (8.2*$s/2) 0.35
  Cent $c[0] $c[1] (5*$s)
  DimH ($ox-33) ($ox+33) ($oy-28) 7 '66'
  DimV ($oy-28) ($oy+28) ($ox+33) 7 '56'
  DimV ($oy-28) $c[1] ($ox-33) (-7) '27' 2.8
  Txt ($c[0]+4) ($c[1]-4) 'Ø8.2' 2.8 'start'
  $sx = 220; $sy = 100
  Rec ($sx-24) ($sy-28) 24 56 0.5
  Ln ($sx-24) $sy ($sx-24+24) $sy 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-24) $sx ($sy+28) 7 '24'
  Title '滑块' '45钢' '1' '1:1' 'P11'
  SaveSvg "$outDir\P11_滑块.svg"
}
function D12 {
  $s = 1; $ox = 90; $oy = 100
  Rec ($ox-45) ($oy-33) 90 66 0.5
  Rec ($ox-40) ($oy-29) 80 58 0.35
  DimH ($ox-45) ($ox+45) ($oy-33) 7 '90'
  DimV ($oy-33) ($oy+33) ($ox+45) 7 '66'
  DimV ($oy-29) ($oy+29) ($ox-40) (-7) '58' 2.8
  DimH ($ox-40) ($ox+40) ($oy+33) 8 '80'
  $sx = 230; $sy = 100
  Rec ($sx-48) ($sy-33) 48 66 0.5
  Ln ($sx-24) ($sy-33) ($sx-24) ($sy+33) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-48) ($sy-29) ($sx-24) ($sy-29) 0.2
  Ln ($sx-48) ($sy+29) ($sx-24) ($sy+29) 0.2
  DimH ($sx-48) $sx ($sy+33) 7 '48'
  DimH ($sx-48) ($sx-24) ($sy-33) (-7) '24'
  Txt ($sx-36) ($sy-42) '通道深24' 2.8 'middle'
  Title '导轨' '45钢' '1' '1:1' 'P12'
  SaveSvg "$outDir\P12_导轨.svg"
}
function D13 {
  $s = 1; $ox = 90; $oy = 95
  Rec ($ox-45) ($oy-45) 90 90 0.5
  Cir $ox $oy (28*$s) 0.4
  Rec ($ox-45) ($oy+27) 90 38 0.4
  Cent $ox $oy (32*$s)
  DimH ($ox-45) ($ox+45) ($oy-45) 7 '90'
  DimV ($oy-28*$s) ($oy+28*$s) ($ox+45) 7 'Ø56'
  DimV ($oy+27) ($oy+65) ($ox-45) (-7) '37' 2.8
  DimH ($ox-45) ($ox+45) ($oy+65) 7 '90'
  $sx = 225; $sy = 95
  Rec ($sx-101) ($sy-45) 101 90 0.5
  Ln ($sx-95) ($sy-45) ($sx-95) ($sy+45) 0.2
  Ln ($sx-95) ($sy-28) ($sx-95+6) ($sy-28) 0.2
  Ln ($sx-95) ($sy+28) ($sx-95+6) ($sy+28) 0.2
  Rec ($sx-81) ($sy-27) 20 90 0.4
  DimH ($sx-101) $sx ($sy+45) 7 '101'
  DimH ($sx-95) $sx ($sy-45) (-7) '95'
  DimH ($sx-101) ($sx-95) ($sy-45) (-14) '6'
  DimH ($sx-81) $sx ($sy+45) 12 '20'
  Txt ($sx-50) ($sy+60) '电机(简化外形)' 3
  Title '电机' '外购件' '1' '1:1' 'P13'
  SaveSvg "$outDir\P13_电机.svg"
}
function D14 {
  $s = 1; $ox = 90; $oy = 100
  Rec $ox ($oy-50) 70 50 0.5
  $c = P 35 25 $ox $oy $s
  Cir $c[0] $c[1] (31*$s/2) 0.35
  Cent $c[0] $c[1] (17*$s)
  DimH $ox ($ox+70) ($oy-50) 7 '70'
  DimV ($oy-50) $oy ($ox+70) 7 '50'
  DimH $ox $c[0] ($oy-50) (-7) '35' 2.8
  DimV ($oy-50) $c[1] ($ox-4) (-7) '25' 2.8
  Txt ($c[0]+16) ($c[1]-16) 'Ø31' 2.8 'start'
  $sx = 220; $sy = 100
  Rec ($sx-20) ($sy-50) 20 50 0.5
  Ln ($sx-18) ($sy-46.5) ($sx-18) ($sy-3.5) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-20) ($sy-46.5) ($sx-18) ($sy-46.5) 0.2
  DimH ($sx-20) $sx ($sy+50) 7 '20'
  DimV ($sy-48) ($sy-2) ($sx-20) (-7) '沉孔Ø31深2' 2.8
  Title '工件台' '45钢' '1' '1:1' 'P14'
  SaveSvg "$outDir\P14_工件台.svg"
}
function D15 {
  $s = 1; $ox = 90; $oy = 100
  Rec ($ox-15) ($oy-50) 30 50 0.5
  DimH ($ox-15) ($ox+15) ($oy-50) 7 'Ø30'
  DimV ($oy-50) $oy ($ox+15) 7 '50'
  $sx = 220; $sy = 100
  Cir $sx $sy (15*$s) 0.5
  Cent $sx $sy (18*$s)
  DimV ($sy-15) ($sy+15) ($sx+18) 7 'Ø30'
  Title '工件' '45钢' '1' '1:1' 'P15'
  SaveSvg "$outDir\P15_工件.svg"
}
function D16 {
  $s = 2; $ox = 100; $oy = 100
  Rec ($ox-6.5*$s) ($oy-5*$s) (13*$s) (5*$s) 0.5
  Rec ($ox-3*$s) $oy (6*$s) (16*$s) 0.5
  Ln ($ox-3*$s) $oy ($ox-3*$s) ($oy+16*$s) 0.5
  Ln ($ox+3*$s) $oy ($ox+3*$s) ($oy+16*$s) 0.5
  Ln ($ox-3*$s) ($oy+16*$s) ($ox-2.5*$s) ($oy+16.5*$s) 0.35
  Ln ($ox+3*$s) ($oy+16*$s) ($ox+2.5*$s) ($oy+16.5*$s) 0.35
  Ln $ox ($oy-5*$s) $ox ($oy+17*$s) 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($ox-6.5*$s) ($ox+6.5*$s) ($oy-5*$s) 7 '13'
  DimV ($oy-5*$s) $oy ($ox+6.5*$s) 7 '5'
  DimH ($ox-3*$s) ($ox+3*$s) ($oy+16*$s) 7 'M6'
  DimV $oy ($oy+16*$s) ($ox+3*$s+2) 7 '16'
  DimV ($oy-5*$s) ($oy+16*$s) ($ox-6.5*$s-6) (-7) '21'
  Txt ($ox+20) ($oy-14) '螺纹M6×16 粗牙' 3 'start'
  Title '螺栓' '8.8级' '4' '2:1' 'P16'
  SaveSvg "$outDir\P16_螺栓.svg"
}
function D17 {
  $s = 4; $ox = 100; $oy = 90
  Cir $ox $oy (6.5*$s) 0.5
  Cir $ox $oy (3.2*$s) 0.35
  DimV ($oy-6.5*$s) ($oy+6.5*$s) ($ox+6.5*$s) 7 'Ø13'
  DimV ($oy-3.2*$s) ($oy+3.2*$s) ($ox-6.5*$s) (-7) 'Ø6.4' 2.8
  Txt ($ox+10) ($oy+8) 'M6' 3 'start'
  $sx = 220; $sy = 90
  Rec ($sx-4*$s) ($sy-6.5*$s) (4*$s) (13*$s) 0.5
  Ln ($sx-4*$s) ($sy-3.2*$s) $sx ($sy-3.2*$s) 0.15 ' stroke-dasharray="5 2 1 2"'
  Ln ($sx-4*$s) ($sy+3.2*$s) $sx ($sy+3.2*$s) 0.15 ' stroke-dasharray="5 2 1 2"'
  DimH ($sx-4*$s) $sx ($sy+6.5*$s) 7 '4'
  DimV ($sy-6.5*$s) ($sy+6.5*$s) ($sx+4*$s) 7 'Ø13'
  Title '螺母' '8级' '4' '2:1' 'P17'
  SaveSvg "$outDir\P17_螺母.svg"
}

D01; D02; D03; D04; D05; D06; D07; D08; D09; D10; D11; D12; D13; D14; D15; D16; D17

$items = Get-ChildItem $outDir -Filter *.svg | Sort-Object Name
$rows = ($items | ForEach-Object { "<tr><td><a href='$($_.Name)'>$($_.Name)</a></td><td>打开查看（可用浏览器打印为 PDF）</td></tr>" }) -join "`n"
$html = "<!DOCTYPE html><html lang='zh'><head><meta charset='utf-8'><title>精英联赛 零件工程图索引</title>" +
"<style>body{font-family:'Microsoft YaHei';margin:20px}table{border-collapse:collapse}td,th{border:1px solid #333;padding:6px 12px}a{color:#06c}</style></head>" +
"<body><h2>齿轮传动曲柄滑块机构 — 17 个零件工程图</h2>" +
"<p>点击文件名打开 SVG 工程图（浏览器直接查看，Ctrl+P 可打印/另存为 PDF）。</p>" +
"<table><tr><th>文件</th><th>说明</th></tr>" + $rows + "</table></body></html>"
$enc = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText("$outDir\index.html", $html, $enc)
Write-Output "DONE: $($items.Count) svg + index.html in $outDir"
