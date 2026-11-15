' sw_diag37.vbs - retest C/D with close-before-select extrude order (rebuild#4-proven)
Option Explicit
Dim swApp, lf, gPartTpl, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag37.log", True)
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Function NewPart(tag)
  On Error Resume Next
  Set NewPart = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 400
  L "new " & tag, "(got doc)"
End Function

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
    L tag & " selsk", "name=" & last.Name & " res=" & r
  End If
End Sub

Sub Extr(flip, d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  SelSk tag
  Dim ft : Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, "name=" & ft.Name
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
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, "name=" & ft.Name
End Sub

Sub CutBl(d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, "name=" & ft.Name
End Sub

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim dir : dir = "C:\Users\zgzgd\Documents\DSH\sw_diag37_parts"
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

Sub Gap0()
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua, pi
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

' ---- C: gear full flow + circle&rect D-hole ----
NewPart "C"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "C-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
Extr False, 0.018, "C-ring"
FaceSketch 0, 0.02, 0, "C"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.030
CutBl 0.006, "C-backcut"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.006, "C-hubback"
FaceSketch 0, 0.005, 0.024, "C"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0.005, 0, 0.0041
Rect -0.0051, -0.0051, 0.0051, 0.002
CutTA "C-dhole"
SaveAs "sw_diag37_C", "C"

' ---- D: gear + one involute gap ----
NewPart "D"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "D-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
Extr False, 0.018, "D-ring"
FaceSketch 0, 0.02, 0, "D"
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.030
CutBl 0.006, "D-backcut"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.006, "D-hubback"
FaceSketch 0, 0.005, 0.024, "D"
Gap0
CutTA "D-gap0"
SaveAs "sw_diag37_D", "D"

L "DONE", "diag37"
lf.Close
