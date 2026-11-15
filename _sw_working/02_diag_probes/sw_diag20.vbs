' sw_diag20.vbs - isolate Mark=1 plane selection vs marked sketch selection
Option Explicit
Dim fso, lf, swApp, md, planeFeat
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag20.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub NewPart
  On Error Resume Next
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  WScript.Sleep 600
End Sub
Sub GetFrontPlane
  On Error Resume Next
  Dim f
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    If f.GetTypeName2 = "RefPlane" Then
      Set planeFeat = f
      Exit Do
    End If
    Set f = f.GetNextFeature
  Loop
End Sub
Sub DoVariant(tag, planeMark, sketchMark)
  On Error Resume Next
  Dim sk, circ, sres, feat, ff, skf
  GetFrontPlane
  If planeMark >= 0 Then
    Dim pr
    pr = planeFeat.Select2(False, planeMark)
    L tag & " planeSelect2(" & planeMark & ") res=" & pr
  End If
  Set sk = md.SketchManager
  sk.InsertSketch False
  Set circ = sk.CreateCircleByRadius(0, 0, 0, 0.008)
  sk.InsertSketch True
  If sketchMark >= 0 Then
    Set skf = Nothing
    Set ff = md.FirstFeature
    Do While Not ff Is Nothing
      If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
      Set ff = ff.GetNextFeature
    Loop
    If skf Is Nothing Then
      L tag & " NOSKETCHFOUND"
    Else
      Dim sr2
      sr2 = skf.Select2(False, sketchMark)
      L tag & " sketchSelect2(" & sketchMark & ") res=" & sr2 & " name=" & skf.Name
    End If
  End If
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.006, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then
    L tag & " EXTRUDE NOTHING"
  Else
    L tag & " EXTRUDE OK name=" & feat.Name
  End If
  swApp.CloseDoc ""
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
NewPart : DoVariant "V6-planeMark0-sketchNone", 0, -1
NewPart : DoVariant "V7-planeMark1-sketchNone", 1, -1
NewPart : DoVariant "V8-planeMark0-sketchMark0", 0, 0
NewPart : DoVariant "V9-planeMark0-sketchMark1", 0, 1
NewPart : DoVariant "V10-planeNone-sketchMark0", -1, 0
L "DONE"
lf.Close
WScript.Quit
