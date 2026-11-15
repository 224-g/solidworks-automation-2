Option Explicit
On Error Resume Next
Dim swApp, FSO, f, md, sk
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_test_line.log", True, False)
f.WriteLine "=== line test start " & Time
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
f.WriteLine "swApp ok=" & (Not swApp Is Nothing)
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
f.WriteLine "doc ok=" & (Not md Is Nothing)
Set sk = md.SketchManager

' --- step 1: open sketch on front plane
Err.Clear
md.Extension.SelectByID2 "前视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
f.WriteLine "SelectPlane err=" & Err.Number & " " & Err.Description
Err.Clear
sk.InsertSketch True
f.WriteLine "InsertSketch err=" & Err.Number & " " & Err.Description
Err.Clear
sk.AddToDB = True
f.WriteLine "AddToDB err=" & Err.Number & " " & Err.Description

' --- step 2: CreateLine
Err.Clear
sk.CreateLine -0.040, 0, 0, 0.040, 0, 0, False
f.WriteLine "CreateLine err=" & Err.Number & " " & Err.Description

' --- step 3: CreateCenterLine
Err.Clear
sk.CreateCenterLine 0, 0, 0, 0, 0, 0.024, True
f.WriteLine "CreateCenterLine err=" & Err.Number & " " & Err.Description

' --- step 4: circle
Err.Clear
sk.CreateCircleByRadius 0, 0.010, 0, 0.005
f.WriteLine "Circle err=" & Err.Number & " " & Err.Description

' --- step 5: arc
Err.Clear
sk.CreateArc 0, 0, 0, 0.004, 0.002, 0, -0.004, 0.002, 0, 1
f.WriteLine "CreateArc err=" & Err.Number & " " & Err.Description

sk.AddToDB = False
Err.Clear
sk.InsertSketch True
f.WriteLine "CloseSketch err=" & Err.Number & " " & Err.Description

' --- step 6: extrude test
Err.Clear
Dim fl
Set fl = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, _
  False, False, False, False, 0, 0, False, False, False, False, _
  True, True, True, 0, 0, False)
If fl Is Nothing Then
  f.WriteLine "Extrude NULL err=" & Err.Number & " " & Err.Description
Else
  f.WriteLine "Extrude OK"
End If
md.SaveAsSilent "C:\Users\zgzgd\Documents\DSH\sw_test_part.SLDPRT", 0
f.WriteLine "save err=" & Err.Number & " " & Err.Description
f.WriteLine "=== line test done " & Time
f.Close
