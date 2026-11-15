' sw_diag23.vbs - how to create a SECOND sketch
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag23.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub ListSketches(tag)
  On Error Resume Next
  Dim f
  Set f = md.FirstFeature
  Dim names, n
  names = "" : n = 0
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then
      names = names & f.Name & " "
      n = n + 1
    End If
    Set f = f.GetNextFeature
  Loop
  L tag & " sketches(" & n & "): " & names
End Sub
Sub ActName(tag)
  On Error Resume Next
  Dim a
  Set a = md.SketchManager.ActiveSketch
  If a Is Nothing Then L tag & " active=NOTHING" Else L tag & " active=" & a.Name
End Sub
Sub Extrude(tag, depth)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L tag & " EXTRUDE NOTHING" Else L tag & " EXTRUDE OK " & feat.Name
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 600
' feature 1
md.SketchManager.InsertSketch False
ListSketches "after IS-F sketch1"
ActName "act1"
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
md.SketchManager.InsertSketch True
ListSketches "after IS-T sketch1"
Extrude "feat1", 0.006
ListSketches "after extrude1"
' try A: InsertSketch True for sketch 2
md.SketchManager.InsertSketch True
ListSketches "A: after IS-T sketch2"
ActName "A act"
md.SketchManager.CreateCircleByRadius 0.02, 0, 0, 0.005
md.SketchManager.InsertSketch True
ListSketches "A: after close2"
Extrude "A feat2", 0.006
ListSketches "A: after extrude2"
L "DONE"
lf.Close
WScript.Quit
