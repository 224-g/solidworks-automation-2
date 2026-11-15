$ErrorActionPreference = "Continue"
$log = "C:\Users\zgzgd\Documents\DSH\sw_model_log.txt"
function Log($m){ "$m" | Out-File $log -Append -Encoding utf8 }
"===== FULL MODEL START $(Get-Date -Format o) =====" | Out-File $log -Encoding utf8

$PI = [math]::PI

# ---------- 1. Connect ----------
try {
    $sw = New-Object -ComObject SldWorks.Application
    Log "1. COM OK"
} catch { Log "FATAL COM: $($_.Exception.Message)"; exit 1 }
try { $sw.Visible = $true; Log "   Visible" } catch { Log "   Visible err: $($_.Exception.Message)" }

# ---------- 2. New document (GB part template) ----------
$tpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"
if (-not (Test-Path $tpl)) { $tpl = $null }
try {
    if ($tpl) { $part = $sw.NewDocument($tpl, 0, 0, 0) }
    else { $part = $sw.NewPart() }
    Log "2. NewDocument OK"
} catch { Log "FATAL NewDocument: $($_.Exception.Message)"; exit 1 }
Start-Sleep -Seconds 3
try { $part = $sw.ActiveDoc; Log "   ActiveDoc: $($part.GetTitle())" }
catch { Log "FATAL ActiveDoc: $($_.Exception.Message)"; exit 1 }

# ---------- 3. Select front plane ----------
$selOk = $false
foreach ($pname in @("前视基准面","Front Plane")) {
    try {
        $r = $part.Extension.SelectByID2($pname, "PLANE", 0, 0, 0, $false, 0, $null, 0)
        if ($r) { Log "3. Selected plane '$pname'"; $selOk = $true; break }
    } catch { Log "   select '$pname' err: $($_.Exception.Message)" }
}
if (-not $selOk) { Log "FATAL: no front plane"; exit 1 }

# ---------- 4. Sketch: revolve profile (outer body + inner bore) ----------
$sm = $part.SketchManager
try { $sm.InsertSketch($true); Log "4. Sketch started" } catch { Log "FATAL sketch: $($_.Exception.Message)"; exit 1 }

# centerline along X axis (revolve axis)
try { $sm.CreateCenterLine(-0.005, 0, 0, 0.12, 0, 0) | Out-Null; Log "   centerline ok" } catch { Log "   centerline err: $($_.Exception.Message)" }

# Outer profile (radius = y, meters)
# (0,40)->(12,40)->(12,31)->(90.65,31)->(90.65,37)->(110.65,37)->(110.65,0)->(0,0)
$outerPts = @(
    @(0.0, 0.040), @(0.012, 0.040), @(0.012, 0.031), @(0.09065, 0.031),
    @(0.09065, 0.037), @(0.11065, 0.037), @(0.11065, 0.0), @(0.0, 0.0)
)
# Inner bore phi52 (radius 0.026)
$innerPts = @(
    @(0.0, 0.026), @(0.11065, 0.026), @(0.11065, 0.0), @(0.0, 0.0)
)
try {
    for ($i=0; $i -lt $outerPts.Count-1; $i++) {
        $a=$outerPts[$i]; $b=$outerPts[$i+1]
        $sm.CreateLine($a[0], $a[1], 0, $b[0], $b[1], 0) | Out-Null
    }
    $sm.CreateLine($outerPts[-1][0], $outerPts[-1][1], 0, $outerPts[0][0], $outerPts[0][1], 0) | Out-Null
    Log "   outer profile ok"
} catch { Log "   outer profile err: $($_.Exception.Message)" }
try {
    for ($i=0; $i -lt $innerPts.Count-1; $i++) {
        $a=$innerPts[$i]; $b=$innerPts[$i+1]
        $sm.CreateLine($a[0], $a[1], 0, $b[0], $b[1], 0) | Out-Null
    }
    $sm.CreateLine($innerPts[-1][0], $innerPts[-1][1], 0, $innerPts[0][0], $innerPts[0][1], 0) | Out-Null
    Log "   inner bore profile ok"
} catch { Log "   inner profile err: $($_.Exception.Message)" }

try { $sm.InsertSketch($true); Log "4b. Sketch closed" } catch { Log "   close sketch err: $($_.Exception.Message)" }

# ---------- 5. Revolve 360 ----------
try {
    $feat = $part.FeatureManager.FeatureRevolve2(2*$PI, $false, 0, 0, $true, $false, $true, 0, 0)
    if ($feat) { Log "5. REVOLVE OK: $($feat.Name)" } else { Log "5. REVOLVE returned null" }
} catch { Log "FATAL revolve: $($_.Exception.Message)" }

# ---------- 6. Rebuild & save ----------
try { $part.ForceRebuild3($true); Log "6. rebuild ok" } catch { Log "   rebuild err: $($_.Exception.Message)" }
try {
    $savePath = "C:\Users\zgzgd\Documents\DSH\气缸体.SLDPRT"
    $part.SaveAs3($savePath, 0, 2)
    Log "7. SAVED: $savePath"
} catch { Log "FATAL save: $($_.Exception.Message)"; exit 1 }

Log "===== FULL MODEL SUCCESS $(Get-Date -Format o) ====="
