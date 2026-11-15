' sw_diag22.vbs - full gear1 (z=20) with offset-free stacking + 20 gap cuts
Option Explicit
Dim fso, lf, swApp, md, PI
PI = 4 * Atn(1)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag22.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub MkSketch
  On Error Resume Next
  Dim sk
  Set sk = md.SketchManager
  sk.InsertSketch False
End Sub
Sub EndSketch
  On Error Resume Next
  md.SketchManager.InsertSketch True
End Sub
Sub Extrude(tag, flip, depth)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L tag & " EXTRUDE NOTHING" Else L tag & " EXTRUDE OK " & feat.Name
End Sub
Sub CutThroughAll(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " CUT NOTHING" Else L tag & " CUT OK " & feat.Name
End Sub
Sub CutBlind(tag, depth)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 0, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " CUT NOTHING" Else L tag & " CUT OK " & feat.Name
End Sub
Sub DRegionCut(tag, rr, dd, thf, arcDir)
  On Error Resume Next
  Dim sk, s, x1, y1, x2, y2
  s = Sqr(rr * rr - dd * dd)
  x1 = dd * Cos(thf) - s * Sin(thf)
  y1 = dd * Sin(thf) + s * Cos(thf)
  x2 = dd * Cos(thf) + s * Sin(thf)
  y2 = dd * Sin(thf) - s * Cos(thf)
  Set sk = md.SketchManager
  sk.InsertSketch False
  sk.CreateLine x1, y1, 0, x2, y2, 0
  sk.CreateArc 0, 0, 0, x2, y2, 0, x1, y1, 0, arcDir
  sk.InsertSketch True
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " CUT NOTHING" Else L tag & " CUT OK " & feat.Name
End Sub
Sub GapCut(k)
  On Error Resume Next
  Dim sk, i, j, rr, ang, pts(26)
  Dim m, zz, rp, rb, ra, rf, invp, ua, inva, htp, phi
  Dim psRb, psRa, psLa, psLb
  m = 0.002 : zz = 20
  rp = m * zz / 2 : rb = rp * Cos(20 * PI / 180) : ra = rp + m : rf = rp - 1.25 * m
  invp = Tan(20 * PI / 180) - 20 * PI / 180
  ua = Sqr((ra / rb) ^ 2 - 1) : inva = ua - Atn(ua)
  htp = PI / (2 * zz)
  phi = 2 * PI * k / zz
  psRb = phi + htp + invp
  psRa = phi + htp + invp - inva
  psLa = phi + 3 * PI / (2 * zz) - invp + inva
  psLb = phi + 3 * PI / (2 * zz) - invp
  Set sk = md.SketchManager
  sk.InsertSketch False
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  For i = 0 To 8
    Dim uu
    uu = ua * i / 8
    rr = rb * Sqr(1 + uu * uu)
    ang = psRb - (uu - Atn(uu))
    pts(3 * i) = rr * Cos(ang) : pts(3 * i + 1) = rr * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  sk.CreateArc 0, 0, 0, ra * Cos(psRa), ra * Sin(psRa), 0, ra * Cos(psLa), ra * Sin(psLa), 0, 1
  For i = 0 To 8
    Dim u2
    u2 = ua * (8 - i) / 8
    rr = rb * Sqr(1 + u2 * u2)
    ang = psLb + (u2 - Atn(u2))
    pts(3 * i) = rr * Cos(ang) : pts(3 * i + 1) = rr * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  sk.CreateArc 0, 0, 0, rf * Cos(psLb), rf * Sin(psLb), 0, rf * Cos(psRb), rf * Sin(psRb), 0, -1
  sk.InsertSketch True
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L "gap" & k & " CUT NOTHING" Else L "gap" & k & " CUT OK " & feat.Name
End Sub
Sub CountFeatures
  On Error Resume Next
  Dim f, n
  Set f = md.FirstFeature
  n = 0
  Do While Not f Is Nothing
    If f.GetTypeName2 = "Extrusion" Or f.GetTypeName2 = "Cut" Then n = n + 1
    Set f = f.GetNextFeature
  Loop
  L "solid features=" & n
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 600
MkSketch
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
EndSketch
Extrude "hub", False, 0.024
MkSketch
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
EndSketch
Extrude "ring", False, 0.018
MkSketch
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
EndSketch
CutBlind "backannulus", 0.006
DRegionCut "dhole", 0.0051, 0.002, 94.5 * PI / 180, -1
Dim k
For k = 0 To 19
  GapCut k
Next
CountFeatures
Dim sv
sv = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag22_gear1.SLDPRT", 0, 2)
L "save res=" & sv
swApp.CloseDoc ""
L "DONE"
lf.Close
WScript.Quit
