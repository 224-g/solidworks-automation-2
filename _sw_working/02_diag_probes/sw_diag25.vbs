' sw_diag25.vbs - cut variants with exact VT types
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag25.log", True, True)
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
  Dim pf, pn
  Set pf = md.FirstFeature
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
  If feat Is Nothing Then L "block NOTHING" Else L "block " & feat.Name
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
Sub CutA()
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True)
  If feat Is Nothing Then L "A FeatureCut20 NOTHING" Else L "A FeatureCut20 " & feat.Name
End Sub
Sub CutB()
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut3(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, 0, False)
  If feat Is Nothing Then L "B FeatureCut3-26 NOTHING" Else L "B FeatureCut3-26 " & feat.Name
End Sub
Sub CutC()
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, CLng(1), CLng(0), CDbl(0.001), CDbl(0), False, False, False, False, CDbl(0), CDbl(0), False, False, False, False, False, True, True, False, False, False, CLng(0), CDbl(0), False, False)
  If feat Is Nothing Then L "C Cut4-typed NOTHING" Else L "C Cut4-typed " & feat.Name
End Sub
Sub CutD()
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, CLng(0), CLng(0), CDbl(0.010), CDbl(0), False, False, False, False, CDbl(0), CDbl(0), False, False, False, False, False, True, True, False, False, False, CLng(0), CDbl(0), False, False)
  If feat Is Nothing Then L "D Cut4-blind10 NOTHING" Else L "D Cut4-blind10 " & feat.Name
End Sub
Sub CutE()
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, False, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False, False)
  If feat Is Nothing Then L "E Cut4-scope NOTHING" Else L "E Cut4-scope " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
NewDoc1 : Block : HoleSketch : CutA
NewDoc1 : Block : HoleSketch : CutB
NewDoc1 : Block : HoleSketch : CutC
NewDoc1 : Block : HoleSketch : CutD
NewDoc1 : Block : HoleSketch : CutE
L "DONE"
lf.Close
WScript.Quit

