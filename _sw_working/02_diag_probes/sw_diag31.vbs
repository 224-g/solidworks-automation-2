' sw_diag31.vbs - cut vs selection matrix with working extrude pattern
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag31.log", True, True)
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
Function LastSketchName()
  On Error Resume Next
  Dim ff, skf
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then LastSketchName = ff.Name
    Set ff = ff.GetNextFeature
  Loop
End Function
Sub Block()
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.020
  md.SketchManager.InsertSketch True
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L "block NOTHING" Else L "block OK"
End Sub
Sub HoleSk()
  On Error Resume Next
  PlaneSel
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  md.SketchManager.InsertSketch True
End Sub
Sub Cut(tag, mode)
  On Error Resume Next
  If mode = "A" Then
    ' leave plane selected
  ElseIf mode = "B" Then
    md.Extension.SelectByID2 LastSketchName(), "SKETCH", 0, 0, 0, True, 0, Nothing, 0
  ElseIf mode = "C" Then
    md.Extension.SelectByID2 LastSketchName(), "SKETCH", 0, 0, 0, False, 0, Nothing, 0
  ElseIf mode = "D" Then
    md.ClearSelection2 True
  End If
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True

Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : HoleSk : Cut "A plane-sel", "A"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : HoleSk : Cut "B plane+sketch-append", "B"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : HoleSk : Cut "C sketch-only", "C"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : HoleSk : Cut "D cleared", "D"
L "DONE"
lf.Close
WScript.Quit
