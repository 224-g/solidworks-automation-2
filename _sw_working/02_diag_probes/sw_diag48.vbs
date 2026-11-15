' sw_diag48.vbs - ALL gaps in ONE sketch, one cut (multi-contour), gear1 z20 and gear2 z40
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag48.log", True)

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

Sub GapAll(k, z)
  ' one CCW all-lines involute gap contour (diag46-C recipe)
  On Error Resume Next
  Dim PI : PI = 4 * Atn(1)
  Dim m, al, rp, rb, ra, rf, invp, ua, inva, htp, phik
  Dim psRb, psRa, psLb, psLa
  m = 0.002 : al = 20 * PI / 180
  rp = m * z / 2 : rb = rp * Cos(al) : ra = rp + m : rf = rp - 1.25 * m
  invp = Tan(al) - al
  ua = Sqr((ra / rb) * (ra / rb) - 1)
  inva = ua - Atn(ua)
  htp = PI / (2 * z)
  phik = 2 * PI * k / z
  psRb = phik + htp + invp
  psRa = phik + htp + invp - inva
  psLb = phik + 3 * PI / (2 * z) - invp
  psLa = phik + 3 * PI / (2 * z) - invp + inva
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

' A: gear1 z20 - all 20 gaps in ONE sketch
NewP "A"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "A-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
Extr False, 0.018, "A-ring"
FaceSketch 0, 0.02, 0.018, "A"
Dim k
For k = 0 To 19
  GapAll k, 20
Next
CountS "A-allgaps"
CutTA "A-gapsall"
SaveAs "sw_diag48_A", "A"

' B: gear2 z40 - all 40 gaps in ONE sketch
NewP "B"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
Extr False, 0.024, "B-hub"
PlaneSel
swApp.ActiveDoc.SketchManager.CreateCircleByRadius 0, 0, 0, 0.042
Extr False, 0.018, "B-ring"
FaceSketch 0, 0.02, 0.018, "B"
For k = 0 To 39
  GapAll k, 40
Next
CountS "B-allgaps"
CutTA "B-gapsall"
SaveAs "sw_diag48_B", "B"

L "DONE", "diag48"
lf.Close
