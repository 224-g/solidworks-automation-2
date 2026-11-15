$ErrorActionPreference = "Continue"
$log = "C:\Users\zgzgd\Documents\DSH\sw_model_log.txt"
function Log($m){ $m | Out-File $log -Append -Encoding utf8 }
"===== START $(Get-Date -Format o) =====" | Out-File $log -Encoding utf8

try {
    $sw = New-Object -ComObject SldWorks.Application
    Log "1. COM OK"
    $sw.Visible = $true
    Log "2. Visible set"
} catch {
    Log "FATAL COM: $($_.Exception.Message)"; exit 1
}

try {
    $tpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"
    $part = $sw.NewDocument($tpl, 0, 0, 0)
    Log "3. NewDocument OK, type=$($part.GetType())"
} catch {
    Log "FATAL NewDocument: $($_.Exception.Message)"; exit 1
}

Start-Sleep -Seconds 3
try {
    $part = $sw.ActiveDoc
    Log "4. ActiveDoc: $($part.GetTitle())"
} catch {
    Log "FATAL ActiveDoc: $($_.Exception.Message)"; exit 1
}

# Try to select front plane (try both English and Chinese names)
$selOk = $false
foreach ($pname in @("前视基准面","Front Plane")) {
    try {
        $r = $part.Extension.SelectByID2($pname, "PLANE", 0, 0, 0, $false, 0, $null, 0)
        if ($r) { Log "5. Selected plane '$pname'"; $selOk = $true; break }
    } catch { Log "   select '$pname' err: $($_.Exception.Message)" }
}
if (-not $selOk) { Log "FATAL: no front plane found"; exit 1 }

try {
    $part.SketchManager.InsertSketch($true)
    Log "6. Sketch started"
} catch { Log "FATAL sketch: $($_.Exception.Message)"; exit 1 }

try {
    $part.SketchManager.CreateCircleByRadius(0, 0, 0, 0.02)  # r=0.02m = 20mm
    Log "7. Circle created (r20mm)"
} catch { Log "FATAL circle: $($_.Exception.Message)"; exit 1 }

try {
    $part.SketchManager.InsertSketch($true)
    Log "8. Sketch closed"
} catch { Log "FATAL close sketch: $($_.Exception.Message)"; exit 1 }

try {
    $feat = $part.FeatureManager.FeatureExtrusion2($true, $false, $false, 0, 0, 0.05, 0.01, $false, $false, $false, $false, 0, 0, $false, $false, $false, $false, $true, $true, $true, 0, 0, $false)
    Log "9. Extrude done"
} catch { Log "FATAL extrude: $($_.Exception.Message)"; exit 1 }

try {
    $savePath = "C:\Users\zgzgd\Documents\DSH\气缸体_test.SLDPRT"
    $errs = 0; $warns = 0
    $part.SaveAs3($savePath, 0, 2)
    Log "10. Saved to $savePath"
} catch { Log "FATAL save: $($_.Exception.Message)"; exit 1 }

Log "===== SUCCESS $(Get-Date -Format o) ====="
