' sw_diag53.vbs - nested-extrude + no-cut part construction tests
Option Explicit
On Error Resume Next

Dim fso, lf, swApp
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag53.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
End Sub

Set swApp = CreateObject("SldWorks.Application")
L "attached rev=" & swApp.RevisionNumber

Dim md, sk, ft, res
Dim feats, fi, planeNames(3), cnt

Sub GetPlanes()
  Dim f2
  Set f2 = md.FirstFeature
  cnt = 0
  Set fi = f2
  Do While Not fi Is Nothing
    If fi.GetTypeName2 = "RefPlane" Then
      planeNames(cnt) = fi.Name
      cnt = cnt + 1
      If cnt = 3 Then Exit Do
    End If
    Set fi = fi.GetNextFeature
  Loop
End Sub
Sub NewPart(tag)
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  If md Is Nothing Then L tag & " newdoc FAILED" Else L tag & " newdoc ok"
  GetPlanes
End Sub
Sub PlaneSel(pn)
  md.ClearSelection2 True
  res = md.Extension.SelectByID2(pn, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
End Sub
Sub SelSk(tag)
  Dim f2, lastF, typ
  Set f2 = md.FirstFeature
  Set lastF = Nothing
  Set fi = f2
  Do While Not fi Is Nothing
    typ = fi.GetTypeName2
    If typ = "ProfileFeature" Then Set lastF = fi
    Set fi = fi.GetNextFeature
  Loop
  If lastF Is Nothing Then
    L tag & " selsk none"
  Else
    res = md.Extension.SelectByID2(lastF.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selsk " & lastF.Name & " res=" & res
  End If
End Sub
Sub Extr(flip, d, tag)
  md.SketchManager.InsertSketch True
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag & " Nothing" Else L "OK " & tag & " " & ft.Name
End Sub
Sub Line2(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub
Sub Arc2(x1, y1, x2, y2, dirn)
  md.SketchManager.CreateArc 0, 0, 0, x1, y1, 0, x2, y2, 0, dirn
End Sub
Sub CountSegs(tag)
  Dim segs, n
  segs = md.SketchManager.ActiveSketch.GetSketchSegments
  If IsArray(segs) Then
    n = UBound(segs) + 1
    L tag & " segs=" & n
  Else
    L tag & " segs not array"
  End If
End Sub
Sub SaveStl(fn, tag)
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L "save " & tag & " res=" & res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".STL", 0, 2)
  L "stl " & tag & " res=" & res
End Sub

' ---- Case A: annulus extrude (outer CCW circle + inner CW circle)
L "=== A annulus ==="
NewPart "A"
PlaneSel planeNames(0)
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.02
Arc2 0.01, 0, 0, -0.01, -1
Arc2 0, -0.01, -0.01, 0, -1
Arc2 -0.01, 0, 0, 0.01, -1
Arc2 0, 0.01, 0.01, 0, -1
CountSegs "A"
Extr False, 0.01, "A-annulus"
SaveStl "sw_diag53_A", "A"

' ---- Case B: D-shaft single loop extrude (arc bottom + chord at y=0.002)
L "=== B dshaft ==="
NewPart "B"
PlaneSel planeNames(0)
Arc2 -0.0049, 0.002, 0.0049, 0.002, 1
Line2 0.0049, 0.002, -0.0049, 0.002
CountSegs "B"
Extr False, 0.02, "B-dshaft"
SaveStl "sw_diag53_B", "B"

' ---- Case C: nested extrude (outer CCW circle r20 + inner D-loop)
L "=== C nested-D ==="
NewPart "C"
PlaneSel planeNames(0)
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.02
Arc2 -0.0049, 0.002, 0.0049, 0.002, 1
Line2 0.0049, 0.002, -0.0049, 0.002
CountSegs "C"
Extr False, 0.008, "C-nested"
SaveStl "sw_diag53_C", "C"

' ---- Case D: full gear1 (hub annulus + filler rect + 20 teeth), no cuts
L "=== D gear1 ==="
NewPart "D"
Dim pi, al, m, zz, rp, rb, ra, rf, invp, ua2, inva2, htp
Dim i2, j2, u2, r2, a2, x2, y2, phi, psLaK, psRaK1, psLbK, psRbK1, thf, cs, sn
pi = 4 * Atn(1)
zz = 20
m = 0.002
al = 20 * pi / 180
rp = m * zz / 2
rb = rp * Cos(al)
ra = rp + m
rf = rp - 1.25 * m
invp = Tan(al) - al
ua2 = Sqr((ra / rb) * (ra / rb) - 1)
inva2 = ua2 - Atn(ua2)
htp = pi / (2 * zz)
L "gear rb=" & rb & " ra=" & ra & " rf=" & rf & " ua=" & ua2
' hub annulus: outer r8 CCW + inner r5.1 CW, d24
PlaneSel planeNames(0)
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Arc2 0.0051, 0, 0, -0.0051, -1
Arc2 0, -0.0051, -0.0051, 0, -1
Arc2 -0.0051, 0, 0, 0.0051, -1
Arc2 0, 0.0051, 0.0051, 0, -1
CountSegs "D-hub"
Extr False, 0.024, "D-hub"
' filler rect rotated by thf, d24
thf = 94.5 * pi / 180
cs = Cos(thf) : sn = Sin(thf)
PlaneSel planeNames(0)
Line2 0.0052 * cs - 0.002 * sn, 0.0052 * sn + 0.002 * cs, 0.0052 * cs - 0.0052 * sn, 0.0052 * sn + 0.0052 * cs
Line2 0.0052 * cs - 0.0052 * sn, 0.0052 * sn + 0.0052 * cs, -0.0052 * cs - 0.0052 * sn, -0.0052 * sn + 0.0052 * cs
Line2 -0.0052 * cs - 0.0052 * sn, -0.0052 * sn + 0.0052 * cs, -0.0052 * cs - 0.002 * sn, -0.0052 * sn + 0.002 * cs
Line2 -0.0052 * cs - 0.002 * sn, -0.0052 * sn + 0.002 * cs, 0.0052 * cs - 0.002 * sn, 0.0052 * sn + 0.002 * cs
CountSegs "D-filler"
Extr False, 0.024, "D-filler"
' 20 teeth
For i2 = 0 To 19
  phi = 2 * pi * i2 / zz
  psLaK = phi + htp + invp - inva2
  psRaK1 = phi + 2 * pi / zz + htp + invp - inva2
  psLbK = phi + 3 * pi / (2 * zz) - invp
  psRbK1 = phi + 2 * pi / zz + 3 * pi / (2 * zz) - invp
  PlaneSel planeNames(0)
  ' tip arc psLaK -> psRaK1 CCW 4-seg
  Dim t
  t = (psRaK1 - psLaK) / 4
  Line2 ra * Cos(psLaK), ra * Sin(psLaK), ra * Cos(psLaK + t), ra * Sin(psLaK + t)
  Line2 ra * Cos(psLaK + t), ra * Sin(psLaK + t), ra * Cos(psLaK + 2 * t), ra * Sin(psLaK + 2 * t)
  Line2 ra * Cos(psLaK + 2 * t), ra * Sin(psLaK + 2 * t), ra * Cos(psLaK + 3 * t), ra * Sin(psLaK + 3 * t)
  Line2 ra * Cos(psLaK + 3 * t), ra * Sin(psLaK + 3 * t), ra * Cos(psRaK1), ra * Sin(psRaK1)
  ' right flank down: u=ua..0
  Dim up, rp2, ap, pp
  For j2 = 0 To 7
    u2 = ua2 * (1 - CDbl(j2) / 8)
    r2 = rb * Sqr(1 + u2 * u2)
    a2 = psRbK1 - (u2 - Atn(u2))
    If j2 = 0 Then
      Line2 ra * Cos(psRaK1), ra * Sin(psRaK1), r2 * Cos(a2), r2 * Sin(a2)
    Else
      up = ua2 * (1 - CDbl(j2 - 1) / 8)
      rp2 = rb * Sqr(1 + up * up)
      ap = psRbK1 - (up - Atn(up))
      Line2 rp2 * Cos(ap), rp2 * Sin(ap), r2 * Cos(a2), r2 * Sin(a2)
    End If
  Next
  ' radial in to r=0.007
  Line2 rf * Cos(psRbK1), rf * Sin(psRbK1), 0.007 * Cos(psRbK1), 0.007 * Sin(psRbK1)
  ' inner arc r=0.007 from psRbK1 to psLbK (2 seg)
  t = (psLbK - psRbK1) / 2
  Line2 0.007 * Cos(psRbK1), 0.007 * Sin(psRbK1), 0.007 * Cos(psRbK1 + t), 0.007 * Sin(psRbK1 + t)
  Line2 0.007 * Cos(psRbK1 + t), 0.007 * Sin(psRbK1 + t), 0.007 * Cos(psLbK), 0.007 * Sin(psLbK)
  ' radial out
  Line2 0.007 * Cos(psLbK), 0.007 * Sin(psLbK), rf * Cos(psLbK), rf * Sin(psLbK)
  ' left flank up: u=0..ua
  For j2 = 0 To 7
    u2 = ua2 * CDbl(j2) / 8
    r2 = rb * Sqr(1 + u2 * u2)
    a2 = psLbK + (u2 - Atn(u2))
    If j2 = 0 Then
      Line2 rf * Cos(psLbK), rf * Sin(psLbK), r2 * Cos(a2), r2 * Sin(a2)
    Else
      up = ua2 * CDbl(j2 - 1) / 8
      rp2 = rb * Sqr(1 + up * up)
      ap = psLbK + (up - Atn(up))
      Line2 rp2 * Cos(ap), rp2 * Sin(ap), r2 * Cos(a2), r2 * Sin(a2)
    End If
  Next
  SelSk "D-tooth" & i2
  Extr False, 0.018, "D-tooth" & i2
Next
SaveStl "sw_diag53_D", "D"
swApp.CloseAllDocuments True
L "DONE diag53"
lf.Close
