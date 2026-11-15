' sw_diag47.vbs - CCW gap with splines+arcs (the real involute, reversed orientation) vs CW control
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag47.log", True)

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

Sub GapCCW(tag)
  ' CCW involute gap with splines + arcs (reversed orientation of the diag39 Gap0)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, pts(26)
  ' 1: radial rf@psLb -> rb@psLb
  sk.CreateLine rf * Cos(psLb), rf * Sin(psLb), 0, rb * Cos(psLb), rb * Sin(psLb), 0
  CountS tag & " S1"
  ' 2: left flank rb@psLb -> ra@psLa (ang increasing)
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  CountS tag & " S2"
  ' 3: tip arc psLa -> psRa CW (dir -1)
  sk.CreateArc 0, 0, 0, ra * Cos(psLa), ra * Sin(psLa), 0, ra * Cos(psRa), ra * Sin(psRa), 0, -1
  CountS tag & " S3"
  ' 4: right flank ra@psRa -> rb@psRb (u decreasing)
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  CountS tag & " S4"
  ' 5: radial rb@psRb -> rf@psRb
  sk.CreateLine rb * Cos(psRb), rb * Sin(psRb), 0, rf * Cos(psRb), rf * Sin(psRb), 0
  CountS tag & " S5"
  ' 6: root arc psRb -> psLb CCW (dir +1)
  sk.CreateArc 0, 0, 0, rf * Cos(psRb), rf * Sin(psRb), 0, rf * Cos(psLb), rf * Sin(psLb), 0, 1
  CountS tag & " S6"
End Sub

Sub GapCW(tag)
  ' the diag39 Gap0 (CW), splines + arcs — control
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, pts(26)
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  sk.CreateArc 0, 0, 0, ra * Cos(psRa), ra * Sin(psRa), 0, ra * Cos(psLa), ra * Sin(psLa), 0, 1
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  sk.CreateArc 0, 0, 0, rf * Cos(psLb), rf * Sin(psLb), 0, rf * Cos(psRb), rf * Sin(psRb), 0, -1
  CountS tag
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

NewP "A"
GearBody "A"
FaceSketch 0, 0.02, 0.018, "A"
GapCCW "A"
CutTA "A-gapccw"
SaveAs "sw_diag47_A", "A"

NewP "B"
GearBody "B"
FaceSketch 0, 0.02, 0.018, "B"
GapCW "B"
CutTA "B-gapcw"
SaveAs "sw_diag47_B", "B"

NewP "C"
GearBody "C"
FaceSketch 0, 0.02, 0.018, "C"
GapCCW "C"
CutTA "C-gapccw"
FaceSketch 0, 0.005, 0.024, "C"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0051
CutTA "C-dhcirc"
SaveAs "sw_diag47_C", "C"

L "DONE", "diag47"
lf.Close
