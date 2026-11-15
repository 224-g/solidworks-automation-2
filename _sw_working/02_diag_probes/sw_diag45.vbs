' sw_diag45.vbs - bisect which entity/count breaks cuts; real segment counts via ActiveSketch
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag45.log", True)

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

Sub CountS(tag)
  On Error Resume Next
  Dim sk2 : Set sk2 = swApp.ActiveDoc.SketchManager.ActiveSketch
  If sk2 Is Nothing Then
    L tag, "ACTIVESKETCH-NOTHING"
    Exit Sub
  End If
  Dim segs : segs = sk2.GetSketchSegments
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

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & nm & ".SLDPRT", 0, 2)
  L "save " & tag, "res=" & res
  md.CloseDoc CStr(md.GetTitle)
End Sub

Sub PolyCut(tag, n)
  ' regular n-gon at r=0.02 (between annulus 8..42), closed
  On Error Resume Next
  Dim PI : PI = 4 * Atn(1)
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i
  For i = 0 To n - 1
    sk.CreateLine 0.02 * Cos(2 * PI * i / n), 0.02 * Sin(2 * PI * i / n), 0, 0.02 * Cos(2 * PI * (i + 1) / n), 0.02 * Sin(2 * PI * (i + 1) / n), 0
  Next
End Sub

Sub ArcCut(tag)
  ' circle at (0,0.03) r=0.004 drawn as TWO half-arcs
  On Error Resume Next
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  sk.CreateArc 0, 0.03, 0, 0.004, 0.03, 0, -0.004, 0.03, 0, 1
  sk.CreateArc 0, 0.03, 0, -0.004, 0.03, 0, 0.004, 0.03, 0, 1
End Sub

Sub SplineCut(tag)
  ' closed lobe: 1 spline (4 pts) + 1 line, inside annulus
  On Error Resume Next
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim pts(11)
  pts(0) = 0.02 : pts(1) = 0.024 : pts(2) = 0
  pts(3) = 0.026 : pts(4) = 0.026 : pts(5) = 0
  pts(6) = 0.024 : pts(7) = 0.03 : pts(8) = 0
  pts(9) = 0.02 : pts(10) = 0.032 : pts(11) = 0
  sk.CreateSpline2 pts, True
  sk.CreateLine 0.02, 0.032, 0, 0.02, 0.024, 0
End Sub

Sub GapLinesCut(tag)
  ' z40 k0 gap, ALL LINES (same math as diag39 GapLines): 2 radial + 8+8 flank segs + 4 tip + 4 root = 26 lines
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua, PI
  PI = 4 * Atn(1)
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, ang2, xp(8), yp(8)
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  For i = 0 To 3
    ang = psRa + (psLa - psRa) * i / 4
    ang2 = psRa + (psLa - psRa) * (i + 1) / 4
    sk.CreateLine ra * Cos(ang), ra * Sin(ang), 0, ra * Cos(ang2), ra * Sin(ang2), 0
  Next
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  For i = 0 To 3
    ang = psLb + (psRb - psLb) * i / 4
    ang2 = psLb + (psRb - psLb) * (i + 1) / 4
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
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

' A: 6-gon
NewP "A"
GearBody "A"
FaceSketch 0, 0.02, 0.018, "A"
PolyCut "A", 6
CountS "A"
CutTA "A-hexagon"
SaveAs "sw_diag45_A", "A"

' B: 12-gon
NewP "B"
GearBody "B"
FaceSketch 0, 0.02, 0.018, "B"
PolyCut "B", 12
CountS "B"
CutTA "B-12gon"
SaveAs "sw_diag45_B", "B"

' C: two half-arcs circle
NewP "C"
GearBody "C"
FaceSketch 0, 0.02, 0.018, "C"
ArcCut "C"
CountS "C"
CutTA "C-arcs"
SaveAs "sw_diag45_C", "C"

' D: spline+line lobe
NewP "D"
GearBody "D"
FaceSketch 0, 0.02, 0.018, "D"
SplineCut "D"
CountS "D"
CutTA "D-spline"
SaveAs "sw_diag45_D", "D"

' E: all-lines gap (26 lines)
NewP "E"
GearBody "E"
FaceSketch 0, 0.02, 0.018, "E"
GapLinesCut "E"
CountS "E"
CutTA "E-gaplines"
SaveAs "sw_diag45_E", "E"

L "DONE", "diag45"
lf.Close
