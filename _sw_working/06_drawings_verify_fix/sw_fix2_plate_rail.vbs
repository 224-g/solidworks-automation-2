' sw_fix2_plate_rail.vbs - rebuild plate (flipped y) + rail (3-box U-channel)
Option Explicit
On Error Resume Next
Dim swApp, md, ft
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_fix2.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Const gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"
Const gOut = "C:\Users\zgzgd\Documents\DSH\sw_parts8\"
Const gShots = "C:\Users\zgzgd\Documents\DSH\sw_shots8\"
Dim gPlaneN(2)

Sub NewPart(tag)
  On Error Resume Next
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 500
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
  L tag, "newdoc ok"
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
  Dim lastN
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then lastN = f.Name
    Set f = f.GetNextFeature
  Loop
  If lastN = "" Then
    L tag, "selsk NONE"
    Exit Sub
  End If
  Dim b : b = md.Extension.SelectByID2(lastN, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  If b = False Then L tag, "SELSK FALSE"
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
End Sub

Sub Circ(x, y, r)
  Err.Clear
  md.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub

Sub SavePart(name)
  On Error Resume Next
  Dim res : res = md.SaveAs3(gOut & name & ".SLDPRT", 0, 2)
  L name, "save res=" & res
  md.ShowNamedView2 "*Isometric", 7
  WScript.Sleep 400
  Dim res2 : res2 = md.SaveBMP(gShots & name & ".bmp", 1280, 960)
  L name, "bmp res=" & res2
End Sub

Sub BuildPlate()
  NewPart "plate"
  PlaneSel "plate"
  ' FLIPPED y-range: local y -235..95 so R_x(-90) at assembly maps to global z -95..235
  Line 0, -0.235, 0.432, -0.235
  Line 0.432, -0.235, 0.432, 0.095
  Line 0.432, 0.095, 0, 0.095
  Line 0, 0.095, 0, -0.235
  Circ 0.02, 0.042, 0.0032
  Circ 0.412, 0.042, 0.0032
  Circ 0.02, -0.088, 0.0032
  Circ 0.412, -0.088, 0.0032
  Extr "plate", False, 0.012
  SavePart "plate"
End Sub

Sub BuildRail()
  NewPart "rail"
  ' U-channel from 3 boxes: side walls (z 0..24) + back wall (z 24..48); open ends in x
  PlaneSel "rail-wall1"
  Line -0.045, 0.029, 0.045, 0.029
  Line 0.045, 0.029, 0.045, 0.033
  Line 0.045, 0.033, -0.045, 0.033
  Line -0.045, 0.033, -0.045, 0.029
  Extr "rail-wall1", False, 0.024
  PlaneSel "rail-wall2"
  Line -0.045, -0.033, 0.045, -0.033
  Line 0.045, -0.033, 0.045, -0.029
  Line 0.045, -0.029, -0.045, -0.029
  Line -0.045, -0.029, -0.045, -0.033
  Extr "rail-wall2", False, 0.024
  FaceSel "rail-back", 0.0425, 0.031, 0.024
  Line -0.045, -0.033, 0.045, -0.033
  Line 0.045, -0.033, 0.045, 0.033
  Line 0.045, 0.033, -0.045, 0.033
  Line -0.045, 0.033, -0.045, -0.033
  Extr "rail-back", False, 0.024
  SavePart "rail"
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "rev=" & swApp.RevisionNumber
  BuildPlate
  BuildRail
  L "done", "plate+rail fixed"
End Sub

Call Main
