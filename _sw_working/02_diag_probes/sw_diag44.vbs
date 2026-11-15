' sw_diag44.vbs - minimal cut matrix on the ring annulus face + per-call err capture in gap drawing
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag44.log", True)

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

Sub CountSegs(tag)
  On Error Resume Next
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim segs : segs = sk.GetSketchSegments
  If IsEmpty(segs) Or (Not IsArray(segs)) Then
    L tag, "segs=EMPTY"
  Else
    L tag, "segs=" & (UBound(segs) + 1)
  End If
End Sub

Sub GearBody(tag)
  On Error Resume Next
  PlaneSel
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
  Extr False, 0.024, tag & "-hub"
  PlaneSel
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
  Extr False, 0.018, tag & "-ring"
End Sub

Sub GapFull(tag)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, pts(26)
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  Err.Clear : L tag & " A-line", "err=" & Err.Number
  CountSegs tag & " A"
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  Err.Clear : L tag & " B-spline", "err=" & Err.Number
  CountSegs tag & " B"
  sk.CreateArc 0, 0, 0, ra * Cos(psRa), ra * Sin(psRa), 0, ra * Cos(psLa), ra * Sin(psLa), 0, 1
  Err.Clear : L tag & " C-arc", "err=" & Err.Number
  CountSegs tag & " C"
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  Err.Clear : L tag & " D-spline", "err=" & Err.Number
  CountSegs tag & " D"
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  Err.Clear : L tag & " E-line", "err=" & Err.Number
  CountSegs tag & " E"
  sk.CreateArc 0, 0, 0, rf * Cos(psLb), rf * Sin(psLb), 0, rf * Cos(psRb), rf * Sin(psRb), 0, -1
  Err.Clear : L tag & " F-arc", "err=" & Err.Number
  CountSegs tag & " F"
End Sub

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & nm & ".SLDPRT", 0, 2)
  L "save " & tag, "res=" & res
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

' A: plain circle cut on ring annulus face
NewP "A"
GearBody "A"
FaceSketch 0, 0.02, 0.018, "A"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0.03, 0, 0.004
CountSegs "A"
CutTA "A-circle-annulus"
SaveAs "sw_diag44_A", "A"

' B: plain 4-line diamond cut on ring annulus face
NewP "B"
GearBody "B"
FaceSketch 0, 0.02, 0.018, "B"
Dim sk : Set sk = swApp.ActiveDoc.SketchManager
sk.CreateLine 0.016, 0.032, 0, 0.024, 0.032, 0
sk.CreateLine 0.024, 0.032, 0, 0.02, 0.024, 0
sk.CreateLine 0.02, 0.024, 0, 0.012, 0.024, 0
sk.CreateLine 0.012, 0.024, 0, 0.016, 0.032, 0
CountSegs "B"
CutTA "B-diamond-annulus"
SaveAs "sw_diag44_B", "B"

' C: full gap with per-call err capture
NewP "C"
GearBody "C"
FaceSketch 0, 0.02, 0.018, "C"
GapFull "C"
CutTA "C-gapfull"
SaveAs "sw_diag44_C", "C"

L "DONE", "diag44"
lf.Close
