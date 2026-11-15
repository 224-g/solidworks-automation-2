' sw_diag39.vbs - isolate gap failure: face choice, coincidence, splines; D-hole same-point retest
Option Explicit
Dim swApp, lf, gPartTpl, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag39.log", True)
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub NewP(tag)
  On Error Resume Next
  swApp.NewDocument gPartTpl, 0, 0, 0
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
  If last Is Nothing Then
    L tag & " selsk", "NOT-FOUND"
  Else
    Dim r : r = md.Extension.SelectByID2(last.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selsk", last.Name & " res=" & r
  End If
End Sub

Sub Extr(flip, d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  SelSk tag
  Dim ft : Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, ft.Name
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
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim dir : dir = "C:\Users\zgzgd\Documents\DSH\sw_diag39_parts"
  If Not FSO.FolderExists(dir) Then FSO.CreateFolder dir
  Dim res : res = md.SaveAs3(dir & "\" & nm & ".SLDPRT", 0, 2)
  L "save " & tag, "res=" & res
  md.CloseDoc CStr(md.GetTitle)
End Sub

Sub Rect(x1, y1, x2, y2)
  On Error Resume Next
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  sk.CreateLine x1, y1, 0, x2, y1, 0
  sk.CreateLine x2, y1, 0, x2, y2, 0
  sk.CreateLine x2, y2, 0, x1, y2, 0
  sk.CreateLine x1, y2, 0, x1, y1, 0
End Sub

Sub Gap0(rTip)
  ' z40 k=0: lines + 2 splines + 2 small arcs, tip arc at rTip
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
  sk.CreateArc 0, 0, 0, rTip * Cos(psRa), rTip * Sin(psRa), 0, rTip * Cos(psLa), rTip * Sin(psLa), 0, 1
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  sk.CreateArc 0, 0, 0, rf * Cos(psLb), rf * Sin(psLb), 0, rf * Cos(psRb), rf * Sin(psRb), 0, -1
End Sub

Sub GapLines(rTip)
  ' z40 k=0: ALL LINES approximation (7 segs per flank, 4 segs root arc, 4 segs tip arc at rTip)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, xp(8), yp(8)
  ' A radial rf->rb at psRb
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  ' B right flank 7 segs
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  ' C tip arc 4 segs at rTip from psRa to psLa
  For i = 0 To 3
    ang = psRa + (psLa - psRa) * i / 4
    Dim ang2 : ang2 = psRa + (psLa - psRa) * (i + 1) / 4
    sk.CreateLine rTip * Cos(ang), rTip * Sin(ang), 0, rTip * Cos(ang2), rTip * Sin(ang2), 0
  Next
  ' D left flank 7 segs ua->0
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  ' E radial rb->rf at psLb
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  ' F root arc 4 segs at rf from psLb to psRb
  For i = 0 To 3
    ang = psLb + (psRb - psLb) * i / 4
    ang2 = psLb + (psRb - psLb) * (i + 1) / 4
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
End Sub

Sub GearBase(tag)
  ' hub + ring (r=0.042 d18) + face-sketch hubfront (stacking-order proven in diag38-D style, plane extrudes fine here)
  PlaneSel
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
  Extr False, 0.024, tag & "-hub"
  PlaneSel
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
  Extr False, 0.018, tag & "-ring"
End Sub

' ============ MAIN ============
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
swApp.CloseAllDocuments True
WScript.Sleep 300

' ---- A: gap on RING FRONT face (annulus), tip arc coincident 0.042 ----
NewP "A"
GearBase "A"
FaceSketch 0, 0.02, 0.018, "A"
Gap0 0.042
CutTA "A-gap-ringface"
SaveAs "sw_diag39_A", "A"

' ---- B: gap on ring front face, tip arc INSIDE 0.0415 ----
NewP "B"
GearBase "B"
FaceSketch 0, 0.02, 0.018, "B"
Gap0 0.0415
CutTA "B-gap-inside"
SaveAs "sw_diag39_B", "B"

' ---- C: all-lines gap on ring front face, tip 0.0415 ----
NewP "C"
GearBase "C"
FaceSketch 0, 0.02, 0.018, "C"
GapLines 0.0415
CutTA "C-gap-lines"
SaveAs "sw_diag39_C", "C"

' ---- D: D-hole two features, SAME face point both times ----
NewP "D"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "D-hub"
FaceSketch 0, 0.005, 0.024, "D"
Rect -0.0051, -0.0051, 0.0051, 0.002
CutTA "D-flatpart"
FaceSketch 0, 0.005, 0.024, "D"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0051
CutTA "D-circlepart"
SaveAs "sw_diag39_D", "D"

L "DONE", "diag39"
lf.Close
