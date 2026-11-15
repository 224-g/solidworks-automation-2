' sw_diag28.vbs - tree verification after failed extrude
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag28.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub DumpTree(tag)
  On Error Resume Next
  Dim f, n
  n = 0
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    n = n + 1
    If n <= 40 Then L tag & " [" & n & "] " & f.GetTypeName2 & " :: " & f.Name
    Set f = f.GetNextFeature
  Loop
  L tag & " total=" & n
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached rev=" & swApp.RevisionNumber
swApp.CloseAllDocuments True

Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
L "doc title=" & md.GetTitle
L "ro1=" & md.IsOpenedReadOnly
L "ro2=" & md.ReadOnlyState

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
md.ClearSelection2 True
DumpTree "after-sketch"

Dim feat
Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
If feat Is Nothing Then L "extrude1 NOTHING" Else L "extrude1 OK " & feat.Name
DumpTree "after-extrude1"

Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.010, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
If feat Is Nothing Then L "extrude2 NOTHING" Else L "extrude2 OK " & feat.Name
DumpTree "after-extrude2"

L "activedoc title=" & swApp.ActiveDoc.GetTitle
L "DONE"
lf.Close
WScript.Quit
