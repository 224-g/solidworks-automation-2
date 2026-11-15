' sw_diag51.vbs - Flip semantics + diag39-A verification
Option Explicit
On Error Resume Next

Dim fso, lf, swApp
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag51.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
End Sub

Set swApp = CreateObject("SldWorks.Application")
L "attached rev=" & swApp.RevisionNumber

swApp.CloseAllDocuments True
Dim md, sk, ft, res
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
If md Is Nothing Then L "newdoc FAILED" Else L "newdoc ok"

Dim feats, f2, planeNames(3), cnt, fi
Set f2 = md.FirstFeature
cnt = 0
Set fi = f2
Do While Not fi Is Nothing
  If fi.GetTypeName2 = "RefPlane" Then
    planeNames(cnt) = fi.Name
    cnt = cnt + 1
    If cnt = 3 Then Exit Do
  End If
  Set fi = fi.GetNextFeature
Loop
L "planes: " & cnt

Sub PlaneSel(pn)
  md.ClearSelection2 True
  res = md.Extension.SelectByID2(pn, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
End Sub
Sub FaceSel(x, y, z)
  md.ClearSelection2 True
  res = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  L "facesel res=" & res
  md.SketchManager.InsertSketch False
End Sub
Sub Extr(flip, d, tag)
  md.SketchManager.InsertSketch True
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag & " Nothing" Else L "OK " & tag & " " & ft.Name
End Sub
Sub Cut(flip, tag)
  md.SketchManager.InsertSketch True
  Set ft = md.FeatureManager.FeatureCut4(True, flip, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag & " Nothing" Else L "OK " & tag & " " & ft.Name
End Sub
Sub Block(tag)
  PlaneSel planeNames(0)
  md.SketchManager.CreateLine -0.02, -0.015, 0, 0.02, -0.015, 0
  md.SketchManager.CreateLine 0.02, -0.015, 0, 0.02, 0.015, 0
  md.SketchManager.CreateLine 0.02, 0.015, 0, -0.02, 0.015, 0
  md.SketchManager.CreateLine -0.02, 0.015, 0, -0.02, -0.015, 0
  Extr False, 0.012, tag
End Sub
Sub HoleCut(flip, tag)
  FaceSel 0, 0, 0.012
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.005
  Cut flip, tag
End Sub
Sub SaveDoc(fn, tag)
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L "save " & tag & " res=" & res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".STL", 0, 2)
  L "stl " & tag & " res=" & res
End Sub

' case F1: block + circle hole, Flip=True
L "=== F1 flip=True ==="
Block "F1-block"
HoleCut True, "F1-hole"
SaveDoc "sw_diag51_F1", "F1"
swApp.CloseDoc md.GetTitle

' case F2: block + circle hole, Flip=False
L "=== F2 flip=False ==="
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set f2 = md.FirstFeature
cnt = 0
Set fi = f2
Do While Not fi Is Nothing
  If fi.GetTypeName2 = "RefPlane" Then
    planeNames(cnt) = fi.Name
    cnt = cnt + 1
    If cnt = 3 Then Exit Do
  End If
  Set fi = fi.GetNextFeature
Loop
Block "F2-block"
HoleCut False, "F2-hole"
SaveDoc "sw_diag51_F2", "F2"
swApp.CloseDoc md.GetTitle

' case O: verify the 18:50 diag39-A part
L "=== O diag39_A ==="
swApp.CloseAllDocuments True
Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag39_parts\sw_diag39_A.SLDPRT", 1)
If md Is Nothing Then L "opendoc FAILED" Else L "opendoc ok"
res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag51_O.STL", 0, 2)
L "stl O res=" & res
swApp.CloseAllDocuments True
L "DONE diag51"
lf.Close
