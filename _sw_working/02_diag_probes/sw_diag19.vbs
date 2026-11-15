' sw_diag19.vbs - extrude variant matrix: sketch open/closed, selection modes
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag19.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub NewPart
  On Error Resume Next
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  WScript.Sleep 600
End Sub
Sub DoVariant(tag, closeMode, selMode)
  On Error Resume Next
  Dim sk, circ, sres, feat
  Set sk = md.SketchManager
  sk.InsertSketch False
  Set circ = sk.CreateCircleByRadius(0, 0, 0, 0.008)
  If closeMode = 1 Then sk.InsertSketch True
  If closeMode = 2 Then sk.InsertSketch False
  If selMode = 1 Then
    sres = md.Extension.SelectByID2("", "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selByEmpty res=" & sres & " selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
  End If
  If selMode = 2 Then
    sres = md.Extension.SelectByID2(ChrW(&H8349)&ChrW(&H56FE)&"1", "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selByName res=" & sres & " selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
  End If
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.006, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then
    L tag & " EXTRUDE NOTHING"
  Else
    L tag & " EXTRUDE OK name=" & feat.Name
  End If
  Dim f, cnt
  Set f = md.FirstFeature
  cnt = 0
  Do While Not f Is Nothing
    If f.GetTypeName2 = "Extrusion" Then cnt = cnt + 1
    Set f = f.GetNextFeature
  Loop
  L tag & " extrusion features=" & cnt
  swApp.CloseDoc ""
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
NewPart : DoVariant "V1-open-nosel", 0, 0
NewPart : DoVariant "V2-closed-nosel", 1, 0
NewPart : DoVariant "V3-closed-selEmpty", 1, 1
NewPart : DoVariant "V4-closed-selName", 1, 2
NewPart : DoVariant "V5-open-selName", 0, 2
L "DONE"
lf.Close
WScript.Quit
