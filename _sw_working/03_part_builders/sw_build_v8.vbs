' sw_build_v8.vbs - ALL 17 parts, no-cut extrusion, NAMED plane selection
' gear teeth = 4-seg chord-approximated involute boss loops (proven diag66-1/diag67-B)
' proven patterns: named-plane PlaneSel; hub = circle+D-loop; ring = 2 circles;
' each tooth = SEPARATE sketch (never same sketch as ring circles); SaveBMP 3-arg
Option Explicit
On Error Resume Next
Dim swApp, md, ft
Dim LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_build_v8.log", 8, True)
Set lf = LOG
Sub L(tag, msg)
  lf.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Const PI = 3.14159265358979
Dim gPartTpl, gOut, gShots
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"
gOut = "C:\Users\zgzgd\Documents\DSH\sw_parts8\"
gShots = "C:\Users\zgzgd\Documents\DSH\sw_shots8\"
Dim gFso
Set gFso = CreateObject("Scripting.FileSystemObject")
If Not gFso.FolderExists(gOut) Then gFso.CreateFolder gOut
If Not gFso.FolderExists(gShots) Then gFso.CreateFolder gShots

' ---------- core helpers ----------
Dim gPlaneN(2)

Sub NewPart(tag)
  On Error Resume Next
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 500
  If md Is Nothing Then L tag, "newdoc FAILED" : Exit Sub
  Dim f, n
  n = 0
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    If f.GetTypeName2 = "RefPlane" And n < 3 Then
      gPlaneN(n) = f.Name
      n = n + 1
    End If
    Set f = f.GetNextFeature
  Loop
  L tag, "newdoc ok planes0=" & gPlaneN(0)
End Sub

Sub PlaneSel(tag)
  On Error Resume Next
  md.ClearSelection2 True
  Dim b : b = md.Extension.SelectByID2(gPlaneN(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  If b = False Then L tag, "PLANESEL FALSE"
End Sub

Sub FaceSel(tag, x, y, z)
  On Error Resume Next
  md.ClearSelection2 True
  Dim b : b = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  If b = False Then L tag, "FACESEL FALSE"
End Sub

Sub SelSk(tag)
  On Error Resume Next
  Dim f
  Set f = md.FirstFeature
  Dim last, lastN
  Set last = Nothing
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then
      Set last = f
      lastN = f.Name
    End If
    Set f = f.GetNextFeature
  Loop
  If last Is Nothing Then
    L tag, "selsk NONE"
    Exit Sub
  End If
  Dim b : b = md.Extension.SelectByID2(lastN, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  If b = False Then L tag, "SELSK FALSE name=" & lastN
End Sub

Sub Extr(tag, flip, d)
  On Error Resume Next
  md.SketchManager.InsertSketch True
  SelSk tag
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L tag, "EXTR FAILED"
  Else
    L tag, "OK " & ft.Name
  End If
End Sub

Sub Line(x1, y1, x2, y2)
  Err.Clear
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
  If Err.Number <> 0 Then L "line", "ERR " & Err.Number
End Sub

Sub Circ(x, y, r)
  Err.Clear
  md.SketchManager.CreateCircleByRadius x, y, 0, r
  If Err.Number <> 0 Then L "circ", "ERR " & Err.Number
End Sub

Sub Arc2(x1, y1, x2, y2, dirn)
  Err.Clear
  md.SketchManager.CreateArc 0, 0, 0, x1, y1, 0, x2, y2, 0, dirn
  If Err.Number <> 0 Then L "arc", "ERR " & Err.Number
End Sub

' D-loop at distance d along thf on circle radius r: arc CCW (long way) + chord
Sub DLoop(r, d, thf)
  Dim s : s = Sqr(r * r - d * d)
  Dim x1, y1, x2, y2
  x1 = d * Cos(thf) - s * Sin(thf)
  y1 = d * Sin(thf) + s * Cos(thf)
  x2 = d * Cos(thf) + s * Sin(thf)
  y2 = d * Sin(thf) - s * Cos(thf)
  Arc2 x1, y1, x2, y2, 1
  Line x2, y2, x1, y1
End Sub

' 4-seg chord tooth boss: root arc at rf CCW + chord to tip + tip arc at ra CW + chord back
' (fix: root at rf so the tooth spans the full root-to-tip height and merges into the web)
Sub ToothLoop(z, j)
  Dim m : m = 0.002
  Dim al : al = 20 * PI / 180
  Dim rp : rp = m * z / 2
  Dim rb : rb = rp * Cos(al)
  Dim ra : ra = rp + m
  Dim rf : rf = rp - 1.25 * m
  Dim invp : invp = Tan(al) - al
  Dim ua : ua = Sqr((ra / rb) * (ra / rb) - 1)
  Dim inva : inva = ua - Atn(ua)
  Dim htp : htp = PI / (2 * z)
  Dim psLbPrev : psLbPrev = (j - 1) * 2 * PI / z + 3 * PI / (2 * z) - invp
  Dim psRbJ : psRbJ = j * 2 * PI / z + htp + invp
  Dim psRaJ : psRaJ = psRbJ - inva
  Dim psLaPrev : psLaPrev = psLbPrev + inva
  Arc2 rf * Cos(psLbPrev), rf * Sin(psLbPrev), rf * Cos(psRbJ), rf * Sin(psRbJ), 1
  Line rf * Cos(psRbJ), rf * Sin(psRbJ), ra * Cos(psRaJ), ra * Sin(psRaJ)
  Arc2 ra * Cos(psRaJ), ra * Sin(psRaJ), ra * Cos(psLaPrev), ra * Sin(psLaPrev), -1
  Line ra * Cos(psLaPrev), ra * Sin(psLaPrev), rf * Cos(psLbPrev), rf * Sin(psLbPrev)
End Sub

Sub SavePart(name)
  On Error Resume Next
  Dim res
  res = md.SaveAs3(gOut & name & ".SLDPRT", 0, 2)
  L name, "save res=" & res
  md.ShowNamedView2 "*Isometric", 7
  WScript.Sleep 400
  Dim res2
  res2 = md.SaveBMP(gShots & name & ".bmp", 1280, 960)
  L name, "bmp res=" & res2
End Sub

' ---------- parts ----------
Sub BuildPlate()
  NewPart "plate"
  PlaneSel "plate"
  Line 0, -0.095, 0.432, -0.095
  Line 0.432, -0.095, 0.432, 0.235
  Line 0.432, 0.235, 0, 0.235
  Line 0, 0.235, 0, -0.095
  Circ 0.02, -0.042, 0.0032
  Circ 0.412, -0.042, 0.0032
  Circ 0.02, 0.088, 0.0032
  Circ 0.412, 0.088, 0.0032
  Extr "plate", False, 0.012
  SavePart "plate"
End Sub

Sub BuildBracket()
  NewPart "bracket"
  PlaneSel "bracket"
  Line -0.045, 0, 0.045, 0
  Line 0.045, 0, 0.045, 0.015
  Line 0.045, 0.015, 0.01, 0.015
  Line 0.01, 0.015, 0.01, 0.09
  Line 0.01, 0.09, -0.01, 0.09
  Line -0.01, 0.09, -0.01, 0.015
  Line -0.01, 0.015, -0.045, 0.015
  Line -0.045, 0.015, -0.045, 0
  Circ 0, 0.065, 0.0051
  Extr "bracket", False, 0.012
  SavePart "bracket"
End Sub

Sub BuildTower()
  NewPart "tower"
  PlaneSel "tower"
  Line -0.04, 0, 0.04, 0
  Line 0.04, 0, 0.04, 0.032
  Line 0.04, 0.032, -0.04, 0.032
  Line -0.04, 0.032, -0.04, 0
  Extr "tower", False, 0.012
  SavePart "tower"
End Sub

Sub BuildShaft(tag, name, thf, dlen)
  NewPart tag
  PlaneSel tag
  DLoop 0.005, 0.002, thf
  Extr tag, False, dlen
  SavePart name
End Sub

Sub BuildGear(tag, name, z, thf)
  NewPart tag
  ' hub annulus: OD circle + D-hole loop
  PlaneSel tag & "-hub"
  Circ 0, 0, 0.008
  DLoop 0.0051, 0.002, thf
  Extr tag & "-hub", False, 0.024
  ' ring annulus: rf outer + r8 inner (web disc up to the root circle; teeth provide rf..ra)
  Dim ra : ra = 0.002 * z / 2 + 0.002
  Dim rf : rf = 0.002 * z / 2 - 0.0025
  PlaneSel tag & "-ring"
  Circ 0, 0, rf
  Circ 0, 0, 0.008
  Extr tag & "-ring", False, 0.018
  ' teeth bosses - each in its OWN sketch
  Dim k
  For k = 0 To z - 1
    PlaneSel tag & "-tooth" & k
    ToothLoop z, k
    Extr tag & "-tooth" & k, False, 0.018
    If ft Is Nothing Then
      PlaneSel tag & "-tooth" & k & "-r"
      ToothLoop z, k
      Extr tag & "-tooth" & k & "-r", False, 0.018
    End If
  Next
  SavePart name
End Sub

Sub BuildCrank()
  NewPart "crank"
  PlaneSel "crank"
  Circ 0, 0, 0.05
  DLoop 0.0051, 0.002, 83.25 * PI / 180
  Circ 0.035, 0, 0.0041
  Extr "crank", False, 0.008
  SavePart "crank"
End Sub

Sub BuildPin()
  NewPart "pin"
  PlaneSel "pin"
  Circ 0, 0, 0.004
  Extr "pin", False, 0.016
  SavePart "pin"
End Sub

Sub BuildRod()
  NewPart "rod"
  PlaneSel "rod-bar"
  Line 0, -0.008, 0.085, -0.008
  Line 0.085, -0.008, 0.085, 0.008
  Line 0.085, 0.008, 0, 0.008
  Line 0, 0.008, 0, -0.008
  Circ 0, 0, 0.0041
  Circ 0.085, 0, 0.0041
  Extr "rod-bar", False, 0.008
  PlaneSel "rod-eye1"
  Circ 0, 0, 0.011
  Circ 0, 0, 0.0041
  Extr "rod-eye1", False, 0.008
  PlaneSel "rod-eye2"
  Circ 0.085, 0, 0.011
  Circ 0.085, 0, 0.0041
  Extr "rod-eye2", False, 0.008
  SavePart "rod"
End Sub

Sub BuildSlider()
  NewPart "slider"
  PlaneSel "slider"
  Line -0.033, -0.028, 0.033, -0.028
  Line 0.033, -0.028, 0.033, 0.028
  Line 0.033, 0.028, -0.033, 0.028
  Line -0.033, 0.028, -0.033, -0.028
  Circ 0, -0.001, 0.0041
  Extr "slider", False, 0.024
  SavePart "slider"
End Sub

Sub BuildRail()
  NewPart "rail"
  PlaneSel "rail-front"
  Line -0.045, -0.033, 0.045, -0.033
  Line 0.045, -0.033, 0.045, 0.033
  Line 0.045, 0.033, -0.045, 0.033
  Line -0.045, 0.033, -0.045, -0.033
  Line -0.04, -0.029, 0.04, -0.029
  Line 0.04, -0.029, 0.04, 0.029
  Line 0.04, 0.029, -0.04, 0.029
  Line -0.04, 0.029, -0.04, -0.029
  Extr "rail-front", False, 0.024
  FaceSel "rail-back", 0, 0, 0.024
  Line -0.045, -0.033, 0.045, -0.033
  Line 0.045, -0.033, 0.045, 0.033
  Line 0.045, 0.033, -0.045, 0.033
  Line -0.045, 0.033, -0.045, -0.033
  Extr "rail-back", False, 0.024
  SavePart "rail"
End Sub

Sub BuildMotor()
  NewPart "motor"
  PlaneSel "motor-flange"
  Line -0.045, -0.045, 0.045, -0.045
  Line 0.045, -0.045, 0.045, 0.045
  Line 0.045, 0.045, -0.045, 0.045
  Line -0.045, 0.045, -0.045, -0.045
  Extr "motor-flange", True, 0.006
  PlaneSel "motor-body"
  Circ 0, 0, 0.028
  Extr "motor-body", True, 0.095
  PlaneSel "motor-foot"
  Line -0.045, -0.065, 0.045, -0.065
  Line 0.045, -0.065, 0.045, -0.027
  Line 0.045, -0.027, -0.045, -0.027
  Line -0.045, -0.027, -0.045, -0.065
  Extr "motor-foot", True, 0.020
  SavePart "motor"
End Sub

Sub BuildAnvil()
  NewPart "anvil"
  PlaneSel "anvil-body"
  Line 0, 0, 0.07, 0
  Line 0.07, 0, 0.07, 0.05
  Line 0.07, 0.05, 0, 0.05
  Line 0, 0.05, 0, 0
  Circ 0.035, 0.025, 0.0155
  Extr "anvil-body", True, 0.018
  PlaneSel "anvil-plug"
  Circ 0.035, 0.025, 0.0155
  Extr "anvil-plug", True, 0.002
  SavePart "anvil"
End Sub

Sub BuildWork()
  NewPart "work"
  PlaneSel "work"
  Circ 0, 0, 0.015
  Extr "work", False, 0.05
  SavePart "work"
End Sub

Sub BuildBolt()
  NewPart "bolt"
  PlaneSel "bolt-head"
  Circ 0, 0, 0.0065
  Extr "bolt-head", True, 0.005
  PlaneSel "bolt-shank"
  Circ 0, 0, 0.003
  Extr "bolt-shank", True, 0.021
  SavePart "bolt"
End Sub

Sub BuildNut()
  NewPart "nut"
  PlaneSel "nut"
  Circ 0, 0, 0.0065
  Circ 0, 0, 0.0032
  Extr "nut", True, 0.004
  SavePart "nut"
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber

  BuildPlate
  BuildBracket
  BuildTower
  BuildShaft "shaft1", "shaft1", 94.5 * PI / 180, 0.056
  BuildShaft "shaft2", "shaft2", 83.25 * PI / 180, 0.048
  BuildGear "gear1", "gear1", 20, 94.5 * PI / 180
  BuildGear "gear2", "gear2", 40, 83.25 * PI / 180
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

  L "done", "all 17 parts"
End Sub

Call Main
