' sw_diag26.vbs - cut selection/state variants
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag26.log", True, True)
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
Sub SkName()
  On Error Resume Next
  Dim ff, skf
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
    Set ff = ff.GetNextFeature
  Loop
  md.Extension.SelectByID2 skf.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0
End Sub
Sub Block(shape)
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  If shape = "C" Then
    md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.020
  Else
    md.SketchManager.CreateLine -0.020, -0.020, 0, 0.020, -0.020, 0
    md.SketchManager.CreateLine 0.020, -0.020, 0, 0.020, 0.020, 0
    md.SketchManager.CreateLine 0.020, 0.020, 0, -0.020, 0.020, 0
    md.SketchManager.CreateLine -0.020, 0.020, 0, -0.020, -0.020, 0
  End If
  md.SketchManager.InsertSketch True
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L "block NOTHING" Else L "block " & feat.Name
End Sub
Sub Hole(shape)
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  If shape = "B" Then
    ' leave sketch OPEN
  Else
    md.SketchManager.InsertSketch True
  End If
  If shape = "C" Then
    SkName
  ElseIf shape = "D" Then
    md.ClearSelection2 True
  End If
End Sub
Sub Cut27(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub
Sub CutFull(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub
Sub CutRect(tag)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True

' A: closed sketch, select by name, circle body, hole circle
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "C" : Hole "A" : SkName : Cut27 "A closed+named"
' B: open sketch, no close
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "C" : Hole "B" : Cut27 "B open+nosel"
' C: open + named
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "C" : Hole "C" : Cut27 "C open+named"
' D: closed + no selection at all
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "C" : Hole "D" : Cut27 "D closed+nosel"
' E: rect body + hole cut
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "R" : Hole "D" : CutRect "E rectbody"
' F: cut the full boss circle itself (through-all)
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
Block "C" : Hole "D" : CutFull "F fullcircle"
L "DONE"
lf.Close
WScript.Quit
