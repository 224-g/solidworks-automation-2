' sw_diag6.vbs - per-line segment counts on TOP plane, with/without AddToDB
Option Explicit
Dim swApp, fso, lf
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag6b.log", 2, True)
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")

Sub L(s)
  lf.WriteLine Time & " " & s
  lf.Flush
End Sub

Dim md, sk, pl(2), i, f, segs, f2

' ===== DOC 1: NO AddToDB =====
On Error Resume Next
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.Extension.SelectByID2 pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0
sk.InsertSketch True
L "D1 no-addb. l1..."
sk.CreateLine 0, 0, -0.095, 0.432, 0, -0.095
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after l1 segs=" & UBound(segs)
sk.CreateLine 0.432, 0, -0.095, 0.432, 0, 0.140
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after l2 segs=" & UBound(segs)
sk.CreateLine 0.432, 0, 0.140, 0, 0, 0.140
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after l3 segs=" & UBound(segs)
sk.CreateLine 0, 0, 0.140, 0, 0, -0.095
segs = sk.ActiveSketch.GetSketchSegments : L "D1 after l4 segs=" & UBound(segs)
sk.InsertSketch True
Set f2 = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "D1 extrude isNothing=" & (f2 Is Nothing)
swApp.CloseDoc md.GetTitle

' ===== DOC 2: WITH AddToDB =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.Extension.SelectByID2 pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0
sk.InsertSketch True
sk.AddToDB = True
L "D2 addb. l1..."
sk.CreateLine 0, 0, -0.095, 0.432, 0, -0.095
sk.CreateLine 0.432, 0, -0.095, 0.432, 0, 0.140
sk.CreateLine 0.432, 0, 0.140, 0, 0, 0.140
sk.CreateLine 0, 0, 0.140, 0, 0, -0.095
sk.AddToDB = False
segs = sk.ActiveSketch.GetSketchSegments : L "D2 after all segs=" & UBound(segs)
sk.InsertSketch True
Set f2 = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "D2 extrude isNothing=" & (f2 Is Nothing)
swApp.CloseDoc md.GetTitle

' ===== DOC 3: negative coord line only =====
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.Extension.SelectByID2 pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0
sk.InsertSketch True
sk.AddToDB = True
sk.CreateLine 0, 0, -0.095, 0.432, 0, -0.095
sk.AddToDB = False
segs = sk.ActiveSketch.GetSketchSegments : L "D3 single neg line segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

L "DONE"
lf.Close

