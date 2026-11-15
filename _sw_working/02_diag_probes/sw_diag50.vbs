' sw_diag50.vbs - settle: STL center, CCW-tip-inside gap cut, plate hole placement
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag50.log", True)

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub NewP(tag)
  On Error Resume Next
  swApp.CloseAllDocuments True
  WScript.Sleep 300
  swApp.NewDocument "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0
  WScript.Sleep 400
  L "new", tag
End Sub

Sub PlaneSel()
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  md.Extension.SelectByID2 "", "PLANE", 0, 0, 0, False, 0, Nothing, 0
  md.SketchManager.InsertSketch False
End Sub

Sub SelSk(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim f : Set f = md.FirstFeature
  Dim last : Set last = Nothing
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then Set last = f
    Set f = f.GetNextFeature
  Loop
  Dim r
  If last Is Nothing Then
    L tag & " selsk", "NOT-FOUND"
  Else
    r = md.Extension.SelectByID2(last.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selsk", last.Name & " res=" & r
  End If
End Sub

Sub Extr(flip, d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  SelSk tag
  Dim ft : Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag, "extrude Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub FaceSketch(x, y, z, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim selok : selok = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag & " facesk", "sel=" & selok
End Sub

Sub CutTA(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag, "cut Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub GapCCWinside(rTip, tag)
  ' CCW gap with tip at rTip (inside the ring OD), all lines
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = rTip : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, ang2, xp(8), yp(8)
  sk.CreateLine rf * Cos(psLb), rf * Sin(psLb), 0, rb * Cos(psLb), rb * Sin(psLb), 0
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  For i = 0 To 3
    ang = psLa - (psLa - psRa) * i / 4
    ang2 = psLa - (psLa - psRa) * (i + 1) / 4
    sk.CreateLine ra * Cos(ang), ra * Sin(ang), 0, ra * Cos(ang2), ra * Sin(ang2), 0
  Next
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  sk.CreateLine rb * Cos(psRb), rb * Sin(psRb), 0, rf * Cos(psRb), rf * Sin(psRb), 0
  For i = 0 To 3
    ang = psRb + (psLb - psRb) * i / 4
    ang2 = psRb + (psLb - psRb) * (i + 1) / 4
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
End Sub

Sub SaveSTL(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & nm & ".SLDPRT", 0, 2)
  L "save " & tag, "res=" & res
  Dim res2 : res2 = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & nm & ".STL", 0, 2)
  L "stl " & tag, "res=" & res2
  md.CloseDoc CStr(md.GetTitle)
End Sub

On Error Resume Next
Dim t : t = Timer
Do While swApp Is Nothing And Timer - t < 120
  Set swApp = GetObject("", "SldWorks.Application")
  If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
  If swApp Is Nothing Then WScript.Sleep 2000
Loop
If swApp Is Nothing Then
  L "FATAL", "no SW"
  lf.Close : WScript.Quit
End If
L "attached", "rev=" & swApp.RevisionNumber
swApp.Visible = True

' A: plain gear, no cuts - STL center check
NewP "A"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "A-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "A-ring"
SaveSTL "sw_diag50_A", "A"

' B: gear + CCW gap tip-inside 0.0415
NewP "B"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "B-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "B-ring"
FaceSketch 0, 0.02, 0.018, "B"
GapCCWinside 0.0415, "B"
CutTA "B-gap"
SaveSTL "sw_diag50_B", "B"

' C: plate + 4 holes (multi-contour one sketch) - hole placement check
NewP "C"
PlaneSel
Dim sk3 : Set sk3 = swApp.ActiveDoc.SketchManager
sk3.CreateLine 0, -0.095, 0, 0.432, -0.095, 0
sk3.CreateLine 0.432, -0.095, 0, 0.432, 0.235, 0
sk3.CreateLine 0.432, 0.235, 0, 0, 0.235, 0
sk3.CreateLine 0, 0.235, 0, 0, -0.095, 0
Extr False, 0.012, "C-plate"
FaceSketch 0.1, 0.03, 0.012, "C"
Dim sk4 : Set sk4 = swApp.ActiveDoc.SketchManager
sk4.CreateCircleByRadius 0.02, -0.042, 0, 0.0032
sk4.CreateCircleByRadius 0.412, -0.042, 0, 0.0032
sk4.CreateCircleByRadius 0.02, 0.088, 0, 0.0032
sk4.CreateCircleByRadius 0.412, 0.088, 0, 0.0032
CutTA "C-holes"
SaveSTL "sw_diag50_C", "C"

L "DONE", "diag50"
lf.Close
