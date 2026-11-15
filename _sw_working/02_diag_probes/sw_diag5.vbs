' sw_diag5.vbs - isolate bracket extrude / plate extrude / gear revolve failures
' top-level only + On Error Resume Next so every HRESULT is captured
Option Explicit
Dim swApp, fso, lf
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag5.log", 2, True)
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
lf.WriteLine Time & " swApp=" & (Not swApp Is Nothing) & " err=" & Err.Number

Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  lf.Flush
End Sub

Dim md, sk, pl(2), i, f, segs, res

' ================= CASE A: bracket polyline =================
On Error Resume Next
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
L "A NewDoc"
Set sk = md.SketchManager
L "A got sk"
i = 0
Set f = md.FirstFeature
L "A got firstfeature"
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
L "A planes " & pl(0) & "/" & pl(1)
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "A sel plane res=" & res
res = sk.InsertSketch(True)
L "A insertsketch res=" & res
sk.AddToDB = True
sk.CreateLine -0.045, 0, 0, 0.045, 0, 0 : L "A ln1"
sk.CreateLine 0.045, 0, 0, 0.045, 0.015, 0 : L "A ln2"
sk.CreateLine 0.045, 0.015, 0, 0.010, 0.015, 0 : L "A ln3"
sk.CreateLine 0.010, 0.015, 0, 0.010, 0.090, 0 : L "A ln4"
sk.CreateLine 0.010, 0.090, 0, -0.010, 0.090, 0 : L "A ln5"
sk.CreateLine -0.010, 0.090, 0, -0.010, 0.015, 0 : L "A ln6"
sk.CreateLine -0.010, 0.015, 0, -0.045, 0.015, 0 : L "A ln7"
sk.CreateLine -0.045, 0.015, 0, -0.045, 0, 0 : L "A ln8"
sk.AddToDB = False
segs = sk.ActiveSketch.GetSketchSegments
L "A segs ubound=" & UBound(segs)
res = sk.InsertSketch(True)
L "A close res=" & res
' dump tree
Set f = md.FirstFeature
Do While Not f Is Nothing
  L "A feat: " & f.Name & " type=" & f.GetTypeName2
  Set f = f.GetNextFeature
Loop
Dim f2
Set f2 = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "A extrude isNothing=" & (f2 Is Nothing)
swApp.CloseDoc md.GetTitle

' ================= CASE B: plate RectT =================
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
L "B NewDoc"
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
md.Extension.SelectByID2 pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0
res = sk.InsertSketch(True)
L "B insertsketch res=" & res
sk.AddToDB = True
sk.CreateLine 0, 0, -0.095, 0.432, 0, -0.095 : L "B ln1"
sk.CreateLine 0.432, 0, -0.095, 0.432, 0, 0.140 : L "B ln2"
sk.CreateLine 0.432, 0, 0.140, 0, 0, 0.140 : L "B ln3"
sk.CreateLine 0, 0, 0.140, 0, 0, -0.095 : L "B ln4"
sk.AddToDB = False
segs = sk.ActiveSketch.GetSketchSegments
L "B segs ubound=" & UBound(segs)
res = sk.InsertSketch(True)
L "B close res=" & res
Set f2 = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "B extrude isNothing=" & (f2 Is Nothing)
swApp.CloseDoc md.GetTitle

' ================= CASE C: gear revolve =================
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
L "C NewDoc"
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
md.Extension.SelectByID2 pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0
res = sk.InsertSketch(True)
L "C insertsketch res=" & res
sk.AddToDB = True
sk.CreateCenterLine 0, 0, 0, 0, 0, 0.024 : L "C cl"
sk.CreateLine 0, 0, 0, 0.008, 0, 0 : L "C ln1"
sk.CreateLine 0.008, 0, 0, 0.008, 0, 0.006 : L "C ln2"
sk.CreateLine 0.008, 0, 0.006, 0.022, 0, 0.006 : L "C ln3"
sk.CreateLine 0.022, 0, 0.006, 0.022, 0, 0.018 : L "C ln4"
sk.CreateLine 0.022, 0, 0.018, 0.008, 0, 0.018 : L "C ln5"
sk.CreateLine 0.008, 0, 0.018, 0.008, 0, 0.024 : L "C ln6"
sk.CreateLine 0.008, 0, 0.024, 0, 0, 0.024 : L "C ln7"
sk.AddToDB = False
segs = sk.ActiveSketch.GetSketchSegments
L "C segs ubound=" & UBound(segs)
res = sk.InsertSketch(True)
L "C close res=" & res
Set f2 = md.FeatureManager.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 6.2831853, 0, False, False, 0, 0, 0, 0, 0, True, True, True)
L "C revolve isNothing=" & (f2 Is Nothing)
swApp.CloseDoc md.GetTitle

lf.WriteLine Time & " DONE"
lf.Close
