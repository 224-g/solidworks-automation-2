' sw_diag46.vbs - find the missing line in the all-lines gap + variants: 8-seg arcs, reversed, deep radials
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag46.log", True)

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

Sub GapA(tag)
  ' all-lines gap with per-group counts (26 lines expected)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, ang2, xp(8), yp(8)
  sk.CreateLine rf * Cos(psRb), rf * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
  CountS tag & " G1"
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  CountS tag & " G2"
  For i = 0 To 3
    ang = psRa + (psLa - psRa) * i / 4
    ang2 = psRa + (psLa - psRa) * (i + 1) / 4
    sk.CreateLine ra * Cos(ang), ra * Sin(ang), 0, ra * Cos(ang2), ra * Sin(ang2), 0
  Next
  CountS tag & " G3"
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    sk.CreateLine xp(i), yp(i), 0, xp(i + 1), yp(i + 1), 0
  Next
  CountS tag & " G4"
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rf * Cos(psLb), rf * Sin(psLb), 0
  CountS tag & " G5"
  For i = 0 To 3
    ang = psLb + (psRb - psLb) * i / 4
    ang2 = psLb + (psRb - psLb) * (i + 1) / 4
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
  CountS tag & " G6"
End Sub

Sub GapB(tag)
  ' 8-seg tip/root arc polylines, radials at rf
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua
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
  For i = 0 To 7
    ang = psRa + (psLa - psRa) * i / 8
    ang2 = psRa + (psLa - psRa) * (i + 1) / 8
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
  For i = 0 To 7
    ang = psLb + (psRb - psLb) * i / 8
    ang2 = psLb + (psRb - psLb) * (i + 1) / 8
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
  CountS tag
End Sub

Sub GapC(tag)
  ' REVERSED direction loop (CW), radials rf->rb at psLb side first
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
    ang = psRb - (psRb - psLb) * i / 4
    ang2 = psRb - (psRb - psLb) * (i + 1) / 4
    sk.CreateLine rf * Cos(ang), rf * Sin(ang), 0, rf * Cos(ang2), rf * Sin(ang2), 0
  Next
  CountS tag
End Sub

Sub GapD(tag)
  ' deep radials to r=0.033 (overhang beyond rf into tooth space)
  On Error Resume Next
  Dim rb, ra, rf, psRb, psRa, psLb, psLa, ua, rdeep
  rb = 0.0375877 : ra = 0.042 : rf = 0.0375
  rdeep = 0.033
  psRb = 0.0541743 : psLb = 0.1029053
  psRa = 0.0186803 : psLa = 0.1383993
  ua = 0.49830
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, ang2, xp(8), yp(8)
  sk.CreateLine rdeep * Cos(psRb), rdeep * Sin(psRb), 0, rb * Cos(psRb), rb * Sin(psRb), 0
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
  sk.CreateLine rb * Cos(psLb), rb * Sin(psLb), 0, rdeep * Cos(psLb), rdeep * Sin(psLb), 0
  For i = 0 To 3
    ang = psLb + (psRb - psLb) * i / 4
    ang2 = psLb + (psRb - psLb) * (i + 1) / 4
    sk.CreateLine rdeep * Cos(ang), rdeep * Sin(ang), 0, rdeep * Cos(ang2), rdeep * Sin(ang2), 0
  Next
  CountS tag
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
GapA "A"
CutTA "A-gap4"
SaveAs "sw_diag46_A", "A"

NewP "B"
GearBody "B"
FaceSketch 0, 0.02, 0.018, "B"
GapB "B"
CutTA "B-gap8"
SaveAs "sw_diag46_B", "B"

NewP "C"
GearBody "C"
FaceSketch 0, 0.02, 0.018, "C"
GapC "C"
CutTA "C-gaprev"
SaveAs "sw_diag46_C", "C"

NewP "D"
GearBody "D"
FaceSketch 0, 0.02, 0.018, "D"
GapD "D"
CutTA "D-gapdeep"
SaveAs "sw_diag46_D", "D"

L "DONE", "diag46"
lf.Close
