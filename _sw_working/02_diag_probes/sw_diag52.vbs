' sw_diag52.vbs - cut-semantics discovery on fresh SW: notch/void trick
Option Explicit
On Error Resume Next

Dim fso, lf, swApp
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag52.log", True, True)
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
Sub FaceSel(x, y, z)
  md.ClearSelection2 True
  res = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  L "facesel res=" & res
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
Sub Cut(flip, tag)
  md.SketchManager.InsertSketch True
  Set ft = md.FeatureManager.FeatureCut4(True, flip, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag & " Nothing" Else L "OK " & tag & " " & ft.Name
End Sub
Sub SaveStl(fn, tag)
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L "save " & tag & " res=" & res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".STL", 0, 2)
  L "stl " & tag & " res=" & res
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
Sub Pline(n, r0, a0, r1, a1)
  Dim i, t, r, a, x, y
  For i = 0 To n - 1
    t = CDbl(i) / CDbl(n)
    r = r0 + (r1 - r0) * t
    a = a0 + (a1 - a0) * t
    x = r * Cos(a)
    y = r * Sin(a)
    md.SketchManager.CreateLine x, y, 0, x, y, 0
  Next
End Sub
Sub Line2(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub

' ---- Case O: STL the diag39-D part from THIS session (rect-cut semantics)
L "=== O diag39-D ==="
swApp.CloseAllDocuments True
Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag39_parts\sw_diag39_D.SLDPRT", 1)
If md Is Nothing Then L "O opendoc FAILED" Else L "O opendoc ok"
res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag52_O.STL", 0, 2)
L "O stl res=" & res

' ---- Case 2: block + outer rect CCW + inner circle CW (void) hole
L "=== 2 void-hole ==="
NewPart "2"
PlaneSel planeNames(0)
md.SketchManager.CreateLine -0.02, -0.015, 0, 0.02, -0.015, 0
md.SketchManager.CreateLine 0.02, -0.015, 0, 0.02, 0.015, 0
md.SketchManager.CreateLine 0.02, 0.015, 0, -0.02, 0.015, 0
md.SketchManager.CreateLine -0.02, 0.015, 0, -0.02, -0.015, 0
Extr False, 0.012, "2-block"
' hole: outer rect CCW + inner circle CW, on the front face
FaceSel 0, 0, 0.012
md.SketchManager.CreateLine -0.02, -0.015, 0, 0.02, -0.015, 0
md.SketchManager.CreateLine 0.02, -0.015, 0, 0.02, 0.015, 0
md.SketchManager.CreateLine 0.02, 0.015, 0, -0.02, 0.015, 0
md.SketchManager.CreateLine -0.02, 0.015, 0, -0.02, -0.015, 0
' inner circle drawn CW: 4 arcs
md.SketchManager.CreateArc 0, 0, 0, 0.005, 0, 0, 0, 0.005, 0, -1
md.SketchManager.CreateArc 0, 0, 0, 0, 0.005, 0, -0.005, 0, 0, -1
md.SketchManager.CreateArc 0, 0, 0, -0.005, 0, 0, 0, -0.005, 0, -1
md.SketchManager.CreateArc 0, 0, 0, 0, -0.005, 0, 0.005, 0, 0, -1
CountSegs "2-hole"
Cut True, "2-hole"
SaveStl "sw_diag52_C2", "2"

' ---- Case 3: gear + ONE notch cut (disc minus wedge as single loop)
L "=== 3 notch ==="
NewPart "3"
PlaneSel planeNames(0)
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "3-hub"
PlaneSel planeNames(0)
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "3-ring"
' notch loop: outer circle long way psRa->psLa+2pi (CCW), left flank down, root arc psLb->psRb (CW), right flank up
Dim psRa, psLa, psRb, psLb, ra, rf, rb, ua2, i2, u2, r2, a2, x2, y2
psRa = 0.0186803 : psLa = 0.1383993 : psRb = 0.0541743 : psLb = 0.1029053
ra = 0.042 : rf = 0.0375 : rb = 0.0375877 : ua2 = 0.4983
FaceSel 0, 0.02, 0.018
' outer circle from psRa to psLa+2pi in 48 segs
For i2 = 1 To 48
  a2 = psRa + (psLa + 6.2831853 - psRa) * CDbl(i2) / 48.0
  If i2 = 1 Then
    Line2 ra * Cos(psRa), ra * Sin(psRa), ra * Cos(a2), ra * Sin(a2)
  Else
    Line2 ra * Cos(psRa + (psLa + 6.2831853 - psRa) * CDbl(i2 - 1) / 48.0), ra * Sin(psRa + (psLa + 6.2831853 - psRa) * CDbl(i2 - 1) / 48.0), ra * Cos(a2), ra * Sin(a2)
  End If
Next
' left flank ua->0
For i2 = 0 To 7
  u2 = ua2 * (1.0 - CDbl(i2) / 8.0)
  r2 = rb * Sqr(1.0 + u2 * u2)
  a2 = psLb + (u2 - Atn(u2))
  If i2 = 0 Then
    Line2 ra * Cos(psLa), ra * Sin(psLa), r2 * Cos(a2), r2 * Sin(a2)
  Else
    Dim u3, r3, a3
    u3 = ua2 * (1.0 - CDbl(i2 - 1) / 8.0)
    r3 = rb * Sqr(1.0 + u3 * u3)
    a3 = psLb + (u3 - Atn(u3))
    Line2 r3 * Cos(a3), r3 * Sin(a3), r2 * Cos(a2), r2 * Sin(a2)
  End If
Next
' root arc psLb -> psRb in 4 segs (angle decreasing)
For i2 = 1 To 4
  a2 = psLb + (psRb - psLb) * CDbl(i2) / 4.0
  If i2 = 1 Then
    Line2 rf * Cos(psLb), rf * Sin(psLb), rf * Cos(a2), rf * Sin(a2)
  Else
    Line2 rf * Cos(psLb + (psRb - psLb) * CDbl(i2 - 1) / 4.0), rf * Sin(psLb + (psRb - psLb) * CDbl(i2 - 1) / 4.0), rf * Cos(a2), rf * Sin(a2)
  End If
Next
' right flank 0->ua
For i2 = 0 To 7
  u2 = ua2 * CDbl(i2) / 8.0
  r2 = rb * Sqr(1.0 + u2 * u2)
  a2 = psRb - (u2 - Atn(u2))
  If i2 = 0 Then
    Line2 rf * Cos(psRb), rf * Sin(psRb), r2 * Cos(a2), r2 * Sin(a2)
  Else
    u3 = ua2 * CDbl(i2 - 1) / 8.0
    r3 = rb * Sqr(1.0 + u3 * u3)
    a3 = psRb - (u3 - Atn(u3))
    Line2 r3 * Cos(a3), r3 * Sin(a3), r2 * Cos(a2), r2 * Sin(a2)
  End If
Next
' close: right flank top back to (ra, psRa)
Line2 ra * Cos(psRa), ra * Sin(psRa), ra * Cos(psRa), ra * Sin(psRa)
CountSegs "3-notch"
Cut True, "3-notch"
SaveStl "sw_diag52_C3", "3"
swApp.CloseAllDocuments True
L "DONE diag52"
lf.Close
