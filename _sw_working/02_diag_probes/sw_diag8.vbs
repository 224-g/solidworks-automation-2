' sw_diag8.vbs - identify which plane sketches actually land on; test InsertSketch(False)
Option Explicit
Dim swApp, fso, lf
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag8.log", 2, True)
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")

Sub L(s)
  lf.WriteLine Time & " " & s
  lf.Flush
End Sub

Dim md, sk, pl(2), i, f, segs, res
On Error Resume Next

' ===== DOC 1: select pl(1) top, NO InsertSketch, auto-sketch, draw Y-line + Z-line =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "D1 sel pl(1) res=" & res
sk.CreateLine 0, 0, 0, 0, 0.05, 0   ' pure Y-direction
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after Y-line segs=" & UBound(segs)
sk.CreateLine 0, 0, 0, 0, 0, 0.05   ' pure Z-direction
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after Z-line segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

' ===== DOC 2: select pl(1) + InsertSketch(False) + same 2 lines =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "D2 sel pl(1) res=" & res
res = sk.InsertSketch(False)
L "D2 insertsketch(False) res=" & res & " err=" & Err.Number
sk.CreateLine 0, 0, 0, 0, 0.05, 0
segs = sk.ActiveSketch.GetSketchSegments : L "D2 after Y-line segs=" & UBound(segs)
sk.CreateLine 0, 0, 0, 0, 0, 0.05
segs = sk.ActiveSketch.GetSketchSegments : L "D2 after Z-line segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

' ===== DOC 3: select pl(1) with coords (0.2,0,0.2) + InsertSketch(False) =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(1), "PLANE", 0.2, 0, 0.2, False, 0, Nothing, 0)
L "D3 sel pl(1)@(0.2,0,0.2) res=" & res
res = sk.InsertSketch(False)
L "D3 insertsketch(False) res=" & res & " err=" & Err.Number
sk.CreateLine 0, 0, 0, 0, 0.05, 0
segs = sk.ActiveSketch.GetSketchSegments : L "D3 after Y-line segs=" & UBound(segs)
sk.CreateLine 0, 0, 0, 0, 0, 0.05
segs = sk.ActiveSketch.GetSketchSegments : L "D3 after Z-line segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

' ===== DOC 4: select pl(0) front with coords on front plane + InsertSketch(False) =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(0), "PLANE", 0.2, 0.2, 0, False, 0, Nothing, 0)
L "D4 sel pl(0)@(0.2,0.2,0) res=" & res
res = sk.InsertSketch(False)
L "D4 insertsketch(False) res=" & res & " err=" & Err.Number
sk.CreateLine 0, 0, 0, 0, 0.05, 0
segs = sk.ActiveSketch.GetSketchSegments : L "D4 after Y-line segs=" & UBound(segs)
sk.CreateLine 0, 0, 0, 0, 0, 0.05
segs = sk.ActiveSketch.GetSketchSegments : L "D4 after Z-line segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

L "DONE"
lf.Close
