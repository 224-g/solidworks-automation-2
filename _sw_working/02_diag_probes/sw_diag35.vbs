' sw_diag35.vbs - verify overhang cuts + multi-hole single-sketch cuts (NO face dumps!)
Option Explicit
Dim swApp, lf, gPartTpl
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag35.log", True)
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub L(tag, extra)
  On Error Resume Next
  Dim s : s = Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
  lf.WriteLine s
  lf.Close : Set lf = FSO.OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag35.log", 8)
End Sub

Function NewPart(tag)
  On Error Resume Next
  Set NewPart = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 400
  L "new " & tag, "(got doc)"
End Function

Sub Boss(r, d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim selok : selok = md.Extension.SelectByID2("", "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  Dim sk : Set sk = md.SketchManager
  sk.InsertSketch False
  sk.CreateCircleByRadius 0, 0, 0, r
  sk.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag & "-boss", "type=Nothing" Else L "OK " & tag & "-boss", "name=" & ft.Name
End Sub

Sub FaceSketch(x, y, z, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim selok : selok = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  Dim sk : Set sk = md.SketchManager
  sk.InsertSketch False
  L tag & " facesk", "sel=" & selok
End Sub

Sub CutTA(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim sk : Set sk = md.SketchManager
  sk.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag & "-cut", "type=Nothing" Else L "OK " & tag & "-cut", "name=" & ft.Name
End Sub

Sub CutBl(d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim sk : Set sk = md.SketchManager
  sk.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag & "-cut", "type=Nothing" Else L "OK " & tag & "-cut", "name=" & ft.Name
End Sub

Sub Line4(x1, y1, x2, y2, x3, y3, x4, y4)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim sk : Set sk = md.SketchManager
  sk.CreateLine x1, y1, 0, x2, y2, 0
  sk.CreateLine x2, y2, 0, x3, y3, 0
  sk.CreateLine x3, y3, 0, x4, y4, 0
  sk.CreateLine x4, y4, 0, x1, y1, 0
End Sub

Sub SaveAs(nm, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim dir : dir = "C:\Users\zgzgd\Documents\DSH\sw_diag35_parts"
  If Not FSO.FolderExists(dir) Then FSO.CreateFolder dir
  Dim p : p = dir & "\" & nm & ".SLDPRT"
  Dim res : res = md.SaveAs3(p, 0, 2)
  L "save " & tag, "res=" & res
End Sub

' ============ MAIN ============
On Error Resume Next
Dim t : t = Timer
Do While swApp Is Nothing And Timer - t < 120
  Set swApp = GetObject("", "SldWorks.Application")
  If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
  If swApp Is Nothing Then WScript.Sleep 2000
Loop
If swApp Is Nothing Then
  L "FATAL", "no SW"
  lf.Close : WScript.Quit
End If
L "attached", "rev=" & swApp.RevisionNumber
swApp.Visible = True

' ---- Case A: plate + ONE sketch 2 holes ----
NewPart "A"
Boss 0.02, 0.012, "A"        ' plate body 40x40x12 (circle d12 fine)
FaceSketch 0.1, 0.03, 0.012, "A"
Dim mdA : Set mdA = swApp.ActiveDoc
mdA.SketchManager.CreateCircleByRadius 0.1, 0.03, 0, 0.0032
mdA.SketchManager.CreateCircleByRadius 0.15, 0.03, 0, 0.0032
CutTA "A-2hole"
SaveAs "sw_diag35_A", "A"
mdA.CloseDoc CStr(mdA.GetTitle)

' ---- Case B: shaft + overhang-rect D-flat ----
NewPart "B"
Boss 0.005, 0.056, "B"       ' shaft O10 d56
FaceSketch 0.004, 0, 0.056, "B"
Line4 -0.010, 0.002, 0.010, 0.002, 0.010, 0.010, -0.010, 0.010
CutTA "B-flat"
SaveAs "sw_diag35_B", "B"
Dim mdB : Set mdB = swApp.ActiveDoc
mdB.CloseDoc CStr(mdB.GetTitle)

' ---- Case C: gear overhang backcut + hubback + dhole ----
NewPart "C"
Boss 0.008, 0.024, "C"       ' hub O16 d24
Dim mdC : Set mdC = swApp.ActiveDoc
mdC.ClearSelection2 True
mdC.Extension.SelectByID2 "", "PLANE", 0, 0, 0, False, 0, Nothing, 0
mdC.SketchManager.InsertSketch False
mdC.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
mdC.SketchManager.InsertSketch True
Dim ftR : Set ftR = mdC.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.018, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
If ftR Is Nothing Then L "ERR C-ring", "Nothing" Else L "OK C-ring", ftR.Name
FaceSketch 0, 0.02, 0, "C"
mdC.SketchManager.CreateCircleByRadius 0, 0, 0, 0.030
CutBl 0.006, "C-backcut"
mdC.ClearSelection2 True
mdC.Extension.SelectByID2 "", "PLANE", 0, 0, 0, False, 0, Nothing, 0
mdC.SketchManager.InsertSketch False
mdC.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
mdC.SketchManager.InsertSketch True
Dim ftHb : Set ftHb = mdC.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.006, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
If ftHb Is Nothing Then L "ERR C-hubback", "Nothing" Else L "OK C-hubback", ftHb.Name
FaceSketch 0, 0.005, 0.024, "C"
mdC.SketchManager.CreateCircleByRadius 0, 0.005, 0, 0.0041
CutTA "C-dhole"
SaveAs "sw_diag35_C", "C"
mdC.CloseDoc CStr(mdC.GetTitle)

L "DONE", "diag35"
lf.Close
