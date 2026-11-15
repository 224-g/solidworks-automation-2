' sw_diag27.vbs - template / method / revolve matrix
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag27.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub PlaneSel()
  On Error Resume Next
  Dim pf, pn
  Set pf = md.FirstFeature
  Do While Not pf Is Nothing
    If pf.GetTypeName2 = "RefPlane" Then pn = pf.Name : Exit Do
    Set pf = pf.GetNextFeature
  Loop
  md.ClearSelection2 True
  md.Extension.SelectByID2 pn, "PLANE", 0, 0, 0, False, 0, Nothing, 0
End Sub
Sub Boss()
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.020
  md.SketchManager.InsertSketch True
  md.ClearSelection2 True
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L "boss NOTHING" Else L "boss " & feat.Name
End Sub
Sub HoleSketch(mode)
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  If mode = "B" Then
    md.SketchManager.CreateCircle 0.005, 0, 0, 0.008, 0, 0
  Else
    md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  End If
  If mode = "C" Then
    md.SketchManager.AddToDB = False
  End If
  md.SketchManager.InsertSketch True
  md.ClearSelection2 True
End Sub
Sub HoleSketchDB()
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.AddToDB = True
  md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  md.SketchManager.AddToDB = False
  md.SketchManager.InsertSketch True
  md.ClearSelection2 True
End Sub
Sub Cut27(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub
Sub Cut27bd(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(False, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub
Sub Cut5(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut5(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub
Sub RevolveTest()
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCenterLine 0, 0, 0, 0, 0.030, 0
  md.SketchManager.CreateLine 0.005, 0, 0, 0.010, 0, 0
  md.SketchManager.CreateLine 0.010, 0, 0, 0.010, 0.020, 0
  md.SketchManager.CreateLine 0.010, 0.020, 0, 0.005, 0.020, 0
  md.SketchManager.CreateLine 0.005, 0.020, 0, 0.005, 0, 0
  md.SketchManager.InsertSketch True
  md.ClearSelection2 True
  Dim feat
  Set feat = md.FeatureManager.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 6.283185307, 0, False, False, 0, 0, 0, 0, 0, True, True, True)
  If feat Is Nothing Then L "revolve NOTHING" Else L "revolve " & feat.Name
End Sub
Sub NewDocG()
  On Error Resume Next
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  WScript.Sleep 400
End Sub
Sub NewDocD()
  On Error Resume Next
  Set md = swApp.NewDocument("", 0, 0, 0)
  WScript.Sleep 400
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True

NewDocD : Boss : HoleSketch "A" : Cut27 "A default-template"
NewDocG : Boss : HoleSketch "B" : Cut27 "B CreateCircle"
NewDocG : Boss : HoleSketchDB : Cut27 "C AddToDB"
NewDocG : Boss : HoleSketch "A" : Cut27bd "D Sd=False"
NewDocG : Boss : HoleSketch "A" : Cut5 "E FeatureCut5"
NewDocG : RevolveTest
L "DONE"
lf.Close
WScript.Quit
