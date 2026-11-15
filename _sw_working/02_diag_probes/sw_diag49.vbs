' sw_diag49.vbs - inspect diag46-C saved file + face-lookup probes after one gap cut
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag49.log", True)

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub DumpTree(tag, cap)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim f : Set f = md.FirstFeature
  Dim n : n = 0
  Do While Not f Is Nothing
    n = n + 1
    L tag & " " & n, f.Name & " : " & f.GetTypeName2
    If n >= cap Then Exit Do
    Set f = f.GetNextFeature
  Loop
End Sub

Sub ProbeFace(x, y, z, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim r : r = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  L tag & " faceprobe", "sel=" & r
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

Sub Gap0(tag)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
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

' Part 1: open the diag46-C part (the one CCW gap cut that succeeded) and dump its tree
Dim md46 : Set md46 = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag46_C.SLDPRT", 1)
L "open46", "isNothing=" & (md46 Is Nothing)
If Not md46 Is Nothing Then
  DumpTree "C46", 10
  Dim stlRes : stlRes = md46.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag46_C.STL", 0, 2)
  L "C46 stl", "res=" & stlRes
  swApp.CloseDoc CStr(md46.GetTitle)
End If

' Part 2: fresh gear2 z40, cut gap0, then probe face lookups
NewP "D"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "D-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "D-ring"
FaceSketch 0, 0.02, 0.018, "D"
Gap0 "D"
CutTA "D-gap0"
' probes after the cut
ProbeFace 0, 0.02, 0.018, "D-90deg"
ProbeFace 0.02, 0, 0.018, "D-0deg"
ProbeFace -0.02, 0, 0.018, "D-180deg"
ProbeFace 0, 0.005, 0.024, "D-hubfront"
' second gap via the 0-deg point
FaceSketch 0.02, 0, 0.018, "D2"
Gap0 "D2"
CutTA "D-gap1"
DumpTree "Dfinal", 12
L "DONE", "diag49"
lf.Close
