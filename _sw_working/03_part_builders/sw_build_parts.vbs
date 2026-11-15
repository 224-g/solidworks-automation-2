' sw_build_parts.vbs - rebuild #5 - all proven patterns
' extrudes: PlaneSel + bare InsertSketch False + draw + bare InsertSketch True + SelSk + FeatureExtrusion2 (23 args)
' face cuts: FaceSketch + draw + bare InsertSketch True + FeatureCut4 (27 args, through-all, Flip=True) directly
' face extrudes: FaceSketch + circle + InsertSketch True + SelSk + FeatureExtrusion2
' gear: hubback d6 + ring d12 (face z6) + hubfront d6 (face z18) + z gap cuts on ring face (0,0.02,0.018)
'       + D-hole: rect cut (rotated thf) + circle cut, face points (0,0.005,0.024) and (-0.006,0,0.024)
' sole blind cut: anvil counterbore CutBl
Option Explicit
Dim swApp, lf, FSO, gPartTpl, N_PLATE, N_BRACKET, N_TOWER, N_SHAFT1, N_SHAFT2, N_GEAR1, N_GEAR2
Dim N_CRANK, N_PIN, N_ROD, N_SLIDER, N_RAIL, N_MOTOR, N_ANVIL, N_WORK, N_BOLT, N_NUT
Dim gDir, gShotDir

Set FSO = CreateObject("Scripting.FileSystemObject")
gDir = "C:\Users\zgzgd\Documents\DSH\sw_parts5"
If Not FSO.FolderExists(gDir) Then FSO.CreateFolder gDir
gShotDir = "C:\Users\zgzgd\Documents\DSH\sw_shots5"
If Not FSO.FolderExists(gShotDir) Then FSO.CreateFolder gShotDir

N_PLATE = ChrW(&H5E95) & ChrW(&H677F)
N_BRACKET = ChrW(&H652F) & ChrW(&H67B6)
N_TOWER = ChrW(&H5BFC) & ChrW(&H8F68) & ChrW(&H652F) & ChrW(&H67B6)
N_SHAFT1 = ChrW(&H4E3B) & ChrW(&H52A8) & ChrW(&H8F74)
N_SHAFT2 = ChrW(&H4ECE) & ChrW(&H52A8) & ChrW(&H8F74)
N_GEAR1 = ChrW(&H4E3B) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E)
N_GEAR2 = ChrW(&H4ECE) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E)
N_CRANK = ChrW(&H66F2) & ChrW(&H67C4) & ChrW(&H76D8)
N_PIN = ChrW(&H66F2) & ChrW(&H67C4) & ChrW(&H9500)
N_ROD = ChrW(&H8FDE) & ChrW(&H6746)
N_SLIDER = ChrW(&H6ED1) & ChrW(&H5757)
N_RAIL = ChrW(&H5BFC) & ChrW(&H8F68)
N_MOTOR = ChrW(&H7535) & ChrW(&H673A)
N_ANVIL = ChrW(&H5DE5) & ChrW(&H4EF6) & ChrW(&H53F0)
N_WORK = ChrW(&H5DE5) & ChrW(&H4EF6)
N_BOLT = ChrW(&H87BA) & ChrW(&H6813)
N_NUT = ChrW(&H87BA) & ChrW(&H6BCD)

gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub Ck(ft, tag)
  On Error Resume Next
  If ft Is Nothing Then L "ERR " & tag, "type=Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub NewPart(tag)
  On Error Resume Next
  swApp.CloseAllDocuments True
  WScript.Sleep 200
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

Sub FaceSketch(x, y, z, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim selok : selok = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag & " facesk", "sel=" & selok
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
  Ck ft, tag
End Sub

Sub CutTA(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  Ck ft, tag
End Sub

Sub CutBl(d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  Ck ft, tag
End Sub

Sub Line(x1, y1, x2, y2)
  On Error Resume Next
  swApp.ActiveDoc.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub

Sub RectF(x1, y1, x2, y2)
  On Error Resume Next
  Line x1, y1, x2, y1
  Line x2, y1, x2, y2
  Line x2, y2, x1, y2
  Line x1, y2, x1, y1
End Sub

Sub CircleF(x, y, r)
  On Error Resume Next
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub

Sub GapCut(k, z)
  ' generic involute gap, m=2mm, alpha=20deg, gap index k of z teeth
  ' ALL-LINES polyline, CCW traversal (proven diag46-C; splines/arcs fail in this session)
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
  Dim i, u, r, ang, ang2, xp(8), yp(8)
  ' 1: radial rf->rb at psLb (start at root-left)
  Line rf * Cos(psLb), rf * Sin(psLb), rb * Cos(psLb), rb * Sin(psLb)
  ' 2: left flank rb->ra, 8 lines (ang increasing)
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    Line xp(i), yp(i), xp(i + 1), yp(i + 1)
  Next
  ' 3: tip psLa -> psRa, 4 lines (ang decreasing)
  For i = 0 To 3
    ang = psLa - (psLa - psRa) * i / 4
    ang2 = psLa - (psLa - psRa) * (i + 1) / 4
    Line ra * Cos(ang), ra * Sin(ang), ra * Cos(ang2), ra * Sin(ang2)
  Next
  ' 4: right flank ra->rb, 8 lines
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    xp(i) = r * Cos(ang) : yp(i) = r * Sin(ang)
  Next
  For i = 0 To 7
    Line xp(i), yp(i), xp(i + 1), yp(i + 1)
  Next
  ' 5: radial rb->rf at psRb
  Line rb * Cos(psRb), rb * Sin(psRb), rf * Cos(psRb), rf * Sin(psRb)
  ' 6: root psRb -> psLb, 4 lines (ang increasing, closes loop)
  For i = 0 To 3
    ang = psRb + (psLb - psRb) * i / 4
    ang2 = psRb + (psLb - psRb) * (i + 1) / 4
    Line rf * Cos(ang), rf * Sin(ang), rf * Cos(ang2), rf * Sin(ang2)
  Next
End Sub

Sub DHoleRect(thf)
  ' rect x -0.0051..0.0051, y -0.0051..0.002 rotated by thf
  On Error Resume Next
  Dim c, s, x1, y1, x2, y2, x3, y3, x4, y4
  c = Cos(thf) : s = Sin(thf)
  x1 = -0.0051 * c + 0.0051 * s : y1 = -0.0051 * s - 0.0051 * c
  x2 = 0.0051 * c + 0.0051 * s : y2 = 0.0051 * s - 0.0051 * c
  x3 = 0.0051 * c - 0.002 * s : y3 = 0.0051 * s + 0.002 * c
  x4 = -0.0051 * c - 0.002 * s : y4 = -0.0051 * s + 0.002 * c
  Line x1, y1, x2, y2
  Line x2, y2, x3, y3
  Line x3, y3, x4, y4
  Line x4, y4, x1, y1
End Sub

Sub SavePart(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim res : res = md.SaveAs3(gDir & "\" & nm & ".SLDPRT", 0, 2)
  If res <> 0 Then L "save3", nm & " res=" & res & " err=" & Err.Number Else L "save3", nm & " res=0"
  Err.Clear
  md.ShowNamedView2 "*Isometric", 7
  WScript.Sleep 300
  md.SaveBMP gShotDir & "\" & tag & ".bmp", 0, 0
  L "bmp", tag
  md.CloseDoc CStr(md.GetTitle)
  WScript.Sleep 200
End Sub

' ==================== PARTS ====================

Sub BuildPlate()
  On Error Resume Next
  NewPart "plate"
  PlaneSel
  RectF 0, -0.095, 0.432, 0.235
  Extr False, 0.012, "plate-extr"
  FaceSketch 0.1, 0.03, 0.012, "plate"
  CircleF 0.02, -0.042, 0.0032
  CircleF 0.412, -0.042, 0.0032
  CircleF 0.02, 0.088, 0.0032
  CircleF 0.412, 0.088, 0.0032
  CutTA "plate-holes"
  SavePart N_PLATE, "plate"
End Sub

Sub BuildBracket()
  On Error Resume Next
  NewPart "bracket"
  PlaneSel
  Line -0.045, 0, 0.045, 0
  Line 0.045, 0, 0.045, 0.015
  Line 0.045, 0.015, 0.01, 0.015
  Line 0.01, 0.015, 0.01, 0.09
  Line 0.01, 0.09, -0.01, 0.09
  Line -0.01, 0.09, -0.01, 0.015
  Line -0.01, 0.015, -0.045, 0.015
  Line -0.045, 0.015, -0.045, 0
  Extr False, 0.012, "bracket-extr"
  FaceSketch 0, 0.065, 0.012, "bracket"
  CircleF 0, 0.065, 0.0051
  CutTA "bracket-hole"
  SavePart N_BRACKET, "bracket"
End Sub

Sub BuildTower()
  On Error Resume Next
  NewPart "tower"
  PlaneSel
  RectF -0.04, 0, 0.04, 0.032
  Extr False, 0.012, "tower-extr"
  SavePart N_TOWER, "tower"
End Sub

Sub BuildShaft(l, nm, tag)
  On Error Resume Next
  NewPart tag
  PlaneSel
  CircleF 0, 0, 0.005
  Extr False, l, tag & "-body"
  FaceSketch 0.004, 0, l, tag
  RectF -0.01, 0.002, 0.01, 0.01
  CutTA tag & "-flat"
  SavePart nm, tag
End Sub

Sub BuildGear(z, thf, nm, tag)
  On Error Resume Next
  NewPart tag
  ' hub FULL DEPTH d24 (plane sketch, z0..24)
  Dim ringR : ringR = 0.002 * z / 2 + 0.002
  PlaneSel
  CircleF 0, 0, 0.008
  Extr False, 0.024, tag & "-hub"
  ' ring d18 z0..18 (plane sketch, NOT face extrude - diag39-proven)
  PlaneSel
  CircleF 0, 0, ringR
  Extr False, 0.018, tag & "-ring"
  ' gaps on ring front annulus z18
  Dim k
  For k = 0 To z - 1
    FaceSketch 0, 0.02, 0.018, tag
    GapCut k, z
    CutTA tag & "-gap" & k
  Next
  ' D-hole rect cut on hub front face z24
  FaceSketch 0, 0.005, 0.024, tag
  DHoleRect thf
  CutTA tag & "-dhrect"
  ' D-hole circle cut (same face point)
  FaceSketch 0, 0.005, 0.024, tag
  CircleF 0, 0, 0.0051
  CutTA tag & "-dhcirc"
  SavePart nm, tag
End Sub

Sub BuildCrank()
  On Error Resume Next
  NewPart "crank"
  PlaneSel
  CircleF 0, 0, 0.05
  Extr False, 0.008, "crank-extr"
  FaceSketch 0.004, 0, 0.008, "crank"
  CircleF 0, 0, 0.0051
  CircleF 0.035, 0, 0.0041
  CutTA "crank-holes"
  SavePart N_CRANK, "crank"
End Sub

Sub BuildPin()
  On Error Resume Next
  NewPart "pin"
  PlaneSel
  CircleF 0, 0, 0.004
  Extr False, 0.016, "pin-extr"
  SavePart N_PIN, "pin"
End Sub

Sub BuildRod()
  On Error Resume Next
  NewPart "rod"
  PlaneSel
  RectF 0, -0.008, 0.085, 0.008
  Extr False, 0.008, "rod-bar"
  PlaneSel
  CircleF 0, 0, 0.011
  Extr False, 0.008, "rod-eye1"
  PlaneSel
  CircleF 0.085, 0, 0.011
  Extr False, 0.008, "rod-eye2"
  FaceSketch 0, 0.009, 0.008, "rod"
  CircleF 0, 0, 0.0041
  CircleF 0.085, 0, 0.0041
  CutTA "rod-holes"
  SavePart N_ROD, "rod"
End Sub

Sub BuildSlider()
  On Error Resume Next
  NewPart "slider"
  PlaneSel
  RectF -0.033, -0.028, 0.033, 0.028
  Extr False, 0.024, "slider-extr"
  FaceSketch 0, 0, 0.024, "slider"
  CircleF 0, 0, 0.0041
  CutTA "slider-hole"
  SavePart N_SLIDER, "slider"
End Sub

Sub BuildRail()
  On Error Resume Next
  NewPart "rail"
  PlaneSel
  RectF -0.045, -0.033, 0.045, 0.033
  Extr False, 0.048, "rail-extr"
  FaceSketch 0, 0, 0.048, "rail"
  RectF -0.04, -0.029, 0.04, 0.029
  CutTA "rail-channel"
  SavePart N_RAIL, "rail"
End Sub

Sub BuildMotor()
  On Error Resume Next
  NewPart "motor"
  PlaneSel
  RectF -0.045, -0.045, 0.045, 0.045
  Extr True, 0.006, "motor-flange"
  PlaneSel
  CircleF 0, 0, 0.028
  Extr True, 0.095, "motor-body"
  PlaneSel
  RectF -0.045, -0.065, 0.045, -0.027
  Extr True, 0.02, "motor-foot"
  SavePart N_MOTOR, "motor"
End Sub

Sub BuildAnvil()
  On Error Resume Next
  NewPart "anvil"
  PlaneSel
  RectF 0, 0, 0.07, 0.05
  Extr True, 0.02, "anvil-extr"
  FaceSketch 0.035, 0.025, 0, "anvil"
  CircleF 0.035, 0.025, 0.0155
  CutBl 0.002, "anvil-cb"
  SavePart N_ANVIL, "anvil"
End Sub

Sub BuildWork()
  On Error Resume Next
  NewPart "work"
  PlaneSel
  CircleF 0, 0, 0.015
  Extr False, 0.05, "work-extr"
  SavePart N_WORK, "work"
End Sub

Sub BuildBolt()
  On Error Resume Next
  NewPart "bolt"
  PlaneSel
  CircleF 0, 0, 0.0065
  Extr True, 0.005, "bolt-head"
  PlaneSel
  CircleF 0, 0, 0.003
  Extr True, 0.021, "bolt-shank"
  SavePart N_BOLT, "bolt"
End Sub

Sub BuildNut()
  On Error Resume Next
  NewPart "nut"
  PlaneSel
  CircleF 0, 0, 0.0065
  Extr True, 0.004, "nut-extr"
  FaceSketch 0.002, 0, 0, "nut"
  CircleF 0, 0, 0.0032
  CutTA "nut-hole"
  SavePart N_NUT, "nut"
End Sub

' ==================== MAIN ====================
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_build_parts.log", True)
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

BuildPlate
BuildBracket
BuildTower
BuildShaft 0.056, N_SHAFT1, "shaft1"
BuildShaft 0.048, N_SHAFT2, "shaft2"
BuildGear 20, 94.5 * 4 * Atn(1) / 180, N_GEAR1, "gear1"
BuildGear 40, 83.25 * 4 * Atn(1) / 180, N_GEAR2, "gear2"
BuildCrank
BuildPin
BuildRod
BuildSlider
BuildRail
BuildMotor
BuildAnvil
BuildWork
BuildBolt
BuildNut

L "DONE", "all parts"
lf.Close
