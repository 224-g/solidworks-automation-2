' sw_diag32.vbs - cut variants: NormalCut / both-through / face sketch
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag32.log", True, True)
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
Sub CutV(tag, ncut, t2v, onFace, flipv, blindv)
  On Error Resume Next
  Dim t1, d1
  If onFace Then
    md.ClearSelection2 True
    md.Extension.SelectByID2 "", "FACE", 0, 0.010, 0, False, 0, Nothing, 0
  Else
    PlaneSel
  End If
  md.SketchManager.InsertSketch False
  md.SketchManager.CreateCircleByRadius 0.005, 0, 0, 0.003
  md.SketchManager.InsertSketch True
  If blindv > 0 Then
    t1 = 0 : d1 = blindv
  Else
    t1 = 1 : d1 = 0.001
  End If
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, flipv, False, t1, t2v, d1, 0, False, False, False, False, 0, 0, False, False, False, False, ncut, False, False, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L tag & " NOTHING" Else L tag & " OK " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True

Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : CutV "A plane-ta norm=F", False, 1, False, False, 0
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : CutV "B plane-ta norm=T", True, 1, False, False, 0
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : CutV "C plane-both-ta", False, 1, False, False, 0
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : CutV "D face-flip-ta", False, 1, True, True, 0
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
Block : CutV "E face-flip-blind5", False, 0, True, True, 0.005
L "DONE"
lf.Close
WScript.Quit
