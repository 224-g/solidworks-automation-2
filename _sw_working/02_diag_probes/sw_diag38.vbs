' sw_diag38.vbs - decisive gear-path tests: coincidence, blind-overhang, real gap, face-sketch extrude position, 2-feature D-hole
Option Explicit
Dim swApp, lf, gPartTpl, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag38.log", True)
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

Sub CutBl(d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim dir : dir = "C:\Users\zgzgd\Documents\DSH\sw_diag38_parts"
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

Sub Gap0(raTip)
  ' gap k=0 z40, tip arc at raTip (pass 0.042 or overhang value)
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
  sk.CreateArc 0, 0, 0, raTip * Cos(psRa), raTip * Sin(psRa), 0, raTip * Cos(psLa), raTip * Sin(psLa), 0, 1
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

' ---- A: backcut circle EXACTLY ring OD (coincidence test, plain circle, blind) ----
NewP "A"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "A-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "A-ring"
FaceSketch 0, 0.02, 0, "A"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
CutBl 0.006, "A-backcut-exact"
SaveAs "sw_diag38_A", "A"

' ---- B: backcut circle r=0.043 (overhang, blind) ----
NewP "B"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "B-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "B-ring"
FaceSketch 0, 0.02, 0, "B"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.043
CutBl 0.006, "B-backcut-over"
SaveAs "sw_diag38_B", "B"

' ---- C: REAL gap with tip arc AT ring OD (0.042), through-all ----
NewP "C"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "C-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "C-ring"
FaceSketch 0, 0.005, 0.024, "C"
Gap0 0.042
CutTA "C-gap0"
SaveAs "sw_diag38_C", "C"

' ---- D: face-sketch EXTRUDE position (hubback d6 + ring on z=6 face) ----
NewP "D"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.006, "D-hubback"
FaceSketch 0, 0.005, 0.006, "D"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "D-ring"
FaceSketch 0, 0.042, 0.004, "D-discrim"
SaveAs "sw_diag38_D", "D"

' ---- E: D-hole via 2 separate features (rect then circle) ----
NewP "E"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "E-hub"
FaceSketch 0, 0.005, 0.024, "E"
Rect -0.0051, -0.0051, 0.0051, 0.002
CutTA "E-flatpart"
FaceSketch 0, 0.0065, 0.024, "E"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0051
CutTA "E-circlepart"
SaveAs "sw_diag38_E", "E"

' ---- F: blind overhang RECT backcut alternative ----
NewP "F"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "F-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "F-ring"
FaceSketch 0, 0.02, 0, "F"
Rect -0.043, -0.043, 0.043, 0.043
CutBl 0.006, "F-backcut-rect"
SaveAs "sw_diag38_F", "F"

L "DONE", "diag38"
lf.Close
