# gen_pdf.ps1 - convert 17 SVG engineering drawings to individual + combined PDF via Edge headless
$ErrorActionPreference = 'Stop'
$dir   = "C:\Users\zgzgd\Documents\DSH\精英联赛_设计包\工程图"
$pdfDir = "$dir\PDF"
New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$utf8nobom = New-Object System.Text.UTF8Encoding($false)

$parts = @(
  @('P01_底板.svg','底板'), @('P02_支架.svg','支架'), @('P03_导轨支架.svg','导轨支架'),
  @('P04_主动轴.svg','主动轴'), @('P05_从动轴.svg','从动轴'), @('P06_主动齿轮.svg','主动齿轮'),
  @('P07_从动齿轮.svg','从动齿轮'), @('P08_曲柄盘.svg','曲柄盘'), @('P09_曲柄销.svg','曲柄销'),
  @('P10_连杆.svg','连杆'), @('P11_滑块.svg','滑块'), @('P12_导轨.svg','导轨'),
  @('P13_电机.svg','电机'), @('P14_工件台.svg','工件台'), @('P15_工件.svg','工件'),
  @('P16_螺栓.svg','螺栓'), @('P17_螺母.svg','螺母')
)

function Convert-SvgToPdf([string]$htmlPath, [string]$pdfPath) {
    if (Test-Path $pdfPath) { Remove-Item $pdfPath -Force }
    & $edge --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=4000 "--print-to-pdf=$pdfPath" ("file:///" + ($htmlPath -replace '\\','/')) 2>&1 | Out-Null
    Start-Sleep -Milliseconds 600
    return (Test-Path $pdfPath)
}

$okCount = 0
foreach ($p in $parts) {
    $svgFile = $p[0]; $name = $p[1]
    $svgPath = Join-Path $dir $svgFile
    if (-not (Test-Path $svgPath)) { Write-Output "MISSING $svgFile"; continue }
    $svg = [System.IO.File]::ReadAllText($svgPath, $utf8nobom)
    $html = "<!DOCTYPE html><html><head><meta charset='utf-8'><style>@page{size:297mm 210mm;margin:0}html,body{margin:0;padding:0}svg{display:block}</style></head><body>$svg</body></html>"
    $tmp = Join-Path $env:TEMP ("dsh_" + [System.IO.Path]::GetFileNameWithoutExtension($svgFile) + ".html")
    [System.IO.File]::WriteAllText($tmp, $html, $utf8nobom)
    $outPdf = Join-Path $pdfDir ([System.IO.Path]::GetFileNameWithoutExtension($svgFile) + ".pdf")
    if (Convert-SvgToPdf $tmp $outPdf) { $okCount++; Write-Output "OK  $outPdf" } else { Write-Output "FAIL $outPdf" }
}
Write-Output "individual done: $okCount / $($parts.Count)"

# --- combined PDF (cover + 17 drawings, one per A4-landscape page) ---
$cover = @"
<div style='width:297mm;height:210mm;page-break-after:always;font-family:Microsoft YaHei,SimHei,sans-serif;box-sizing:border-box;padding:20mm 24mm;position:relative'>
  <div style='border:2px solid #000;height:100%;padding:10mm 12mm;box-sizing:border-box'>
    <div style='text-align:center;margin-top:26mm'>
      <div style='font-size:22mm;font-weight:bold'>零件工程图集</div>
      <div style='font-size:11mm;margin-top:10mm'>齿轮传动曲柄滑块往复机构</div>
      <div style='font-size:7mm;margin-top:14mm;color:#333'>共 17 张 · A4 横置 · 三视图 + 完整尺寸标注</div>
      <div style='font-size:6mm;margin-top:30mm;color:#555'>智能制造工程专业 · 精英联赛参赛作品</div>
      <div style='font-size:6mm;margin-top:6mm;color:#555'>SolidWorks 2024 SP5 · 2026-11</div>
    </div>
  </div>
</div>
"@
$body = $cover
foreach ($p in $parts) {
    $svg = [System.IO.File]::ReadAllText((Join-Path $dir $p[0]), $utf8nobom)
    $body += "<div style='page-break-after:always'>$svg</div>`n"
}
$combHtml = "<!DOCTYPE html><html><head><meta charset='utf-8'><style>@page{size:297mm 210mm;margin:0}html,body{margin:0;padding:0}svg{display:block}div{page-break-after:always}</style></head><body>$body</body></html>"
$tmpComb = Join-Path $env:TEMP "dsh_drawings_all.html"
[System.IO.File]::WriteAllText($tmpComb, $combHtml, $utf8nobom)
$combPdf = Join-Path $pdfDir "零件工程图集.pdf"
if (Convert-SvgToPdf $tmpComb $combPdf) {
    $f = Get-Item $combPdf
    Write-Output "COMBINED OK: $combPdf ($($f.Length) bytes)"
} else {
    Write-Output "COMBINED FAIL"
}
