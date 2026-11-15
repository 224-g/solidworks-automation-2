' sw_diag17.vbs - minimal extrude with return + selection diagnostics
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag17.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub WalkTree
  On Error Resume Next
  Dim f, n
  Set f = md.FirstFeature
  n = 0
  Do While Not f Is Nothing
    n = n + 1
    L "FEAT " & n & " name=" & f.Name & " type=" & f.GetTypeName2
    Set f = f.GetNextFeature
  Loop
  L "total features=" & n
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 600
L "NewDoc"
Dim planeFeat, f, found
Set f = md.FirstFeature
found = False
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" Then
    Set planeFeat = f
    found = True
    Exit Do
  End If
  Set f = f.GetNextFeature
Loop
L "found front plane=" & found
Dim selRes
If found Then
  selRes = planeFeat.Select2(False, 1)
  L "Select2 res=" & selRes & " selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
End If
Dim sk
Set sk = md.SketchManager
sk.InsertSketch False
L "InsertSketch done selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
Dim circ
Set circ = sk.CreateCircleByRadius(0, 0, 0, 0.008)
L "circle created"
sk.InsertSketch True
L "closed sketch selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
Dim sres
sres = md.Extension.SelectByID2("", "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
L "SelectByID2 SKETCH res=" & sres & " selcount=" & md.SelectionManager.GetSelectedObjectCount2(-1)
Dim feat
Set feat = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.006, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "extrude type=" & TypeName(feat)
If feat Is Nothing Then L "extrude returned NOTHING" Else L "extrude name=" & feat.Name
WalkTree
Dim saveRes
saveRes = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag17_testpart.SLDPRT", 0, 2)
L "save res=" & saveRes
L "DONE"
lf.Close
WScript.Quit
