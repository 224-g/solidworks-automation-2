' sw_diag24.vbs - which FeatureCut* method works late-bound?
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag24.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub NewDoc1()
  On Error Resume Next
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  WScript.Sleep 500
End Sub
Sub Block()
  On Error Resume Next
  Dim pf
  Set pf = md.FirstFeature
  Dim pn
  Do While Not pf Is Nothing
    If pf.GetTypeName2 = "RefPlane" Then pn = pf.Name : Exit Do
    Set pf = pf.GetNextFeature
  Loop
  md.ClearSelection2 True
  md.Extension.SelectByID2 pn, "PLANE", 0, 0, 0, False, 0, Nothing, 0
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.020
  md.SketchManager.InsertSketch True
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  L "block " & IIf(feat Is Nothing, "NOTHING", feat.Name)
End Sub
Sub HoleSketch()
  On Error Resume Next
  Dim pf, pn
  Set pf = md.FirstFeature
  Do While Not pf Is Nothing
    If pf.GetTypeName2 = "RefPlane" Then pn = pf.Name : Exit Do
    Set pf = pf.GetNextFeature
  Loop
  md.ClearSelection2 True
  md.Extension.SelectByID2 pn, "PLANE", 0, 0, 0, False, 0, Nothing, 0
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  md.SketchManager.InsertSketch True
  Dim ff, skf
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
    Set ff = ff.GetNextFeature
  Loop
  md.Extension.SelectByID2 skf.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0
End Sub
Sub TryCut(tag)
  On Error Resume Next
  Dim feat
  If tag = "A-FeatureCut" Then
    Set feat = md.FeatureManager.FeatureCut(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False)
  ElseIf tag = "B-FeatureCut3" Then
    Set feat = md.FeatureManager.FeatureCut3(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True)
  ElseIf tag = "C-FeatureCut4" Then
    Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False, False)
  End If
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
NewDoc1 : Block : HoleSketch : TryCut "A-FeatureCut"
NewDoc1 : Block : HoleSketch : TryCut "B-FeatureCut3"
NewDoc1 : Block : HoleSketch : TryCut "C-FeatureCut4"
L "DONE"
lf.Close
WScript.Quit
