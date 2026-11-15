' sw_diag21.vbs - gear stacking extrudes with StartOffset + offset cut, no selection
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag21.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub MkCircle(px, py, pr)
  On Error Resume Next
  Dim sk, c
  Set sk = md.SketchManager
  sk.InsertSketch False
  Set c = sk.CreateCircleByRadius(px, py, 0, pr)
  sk.InsertSketch True
End Sub
Sub ExtrudeNoSel(tag, flip, t1, depth, off)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, flip, False, t1, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, off, False)
  If feat Is Nothing Then
    L tag & " EXTRUDE NOTHING"
  Else
    L tag & " EXTRUDE OK name=" & feat.Name
  End If
End Sub
Sub CutNoSel(tag, flip, t1, depth, off)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, flip, False, t1, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, False, False, False, 0, off, False, False)
  If feat Is Nothing Then
    L tag & " CUT NOTHING"
  Else
    L tag & " CUT OK name=" & feat.Name
  End If
End Sub
Sub CountFeatures
  On Error Resume Next
  Dim f, n
  Set f = md.FirstFeature
  n = 0
  Do While Not f Is Nothing
    If f.GetTypeName2 = "Extrusion" Or f.GetTypeName2 = "Cut" Then n = n + 1
    Set f = f.GetNextFeature
  Loop
  L "solid features=" & n
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 600
MkCircle 0, 0, 0.008
ExtrudeNoSel "hub1", False, 0, 0.008, 0
MkCircle 0, 0, 0.042
ExtrudeNoSel "ring", False, 0, 0.012, 0.006
MkCircle 0, 0, 0.008
ExtrudeNoSel "hub2", False, 0, 0.008, 0.016
MkCircle 0.035, 0.025, 0.0155
CutNoSel "anvil-cb", False, 0, 0.002, 0.018
CountFeatures
Dim sv
sv = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag21_stack.SLDPRT", 0, 2)
L "save res=" & sv
swApp.CloseDoc ""
L "DONE"
lf.Close
WScript.Quit
