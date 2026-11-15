Option Explicit
On Error Resume Next
Dim swApp, FSO, f, md, sk, planeName, feat, res
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag2.log", True, False)
f.WriteLine "=== diag2 start " & Time
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
planeName = ""
Set feat = md.FirstFeature
Do While Not feat Is Nothing
  If feat.GetTypeName2 = "RefPlane" And planeName = "" Then planeName = feat.Name
  Set feat = feat.GetNextFeature
Loop
res = md.Extension.SelectByID2(planeName, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
sk.InsertSketch True

f.WriteLine "A no AddToDB 7 args:"
Err.Clear
res = sk.CreateLine(-0.04, 0, 0, 0.04, 0, 0, False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "B AddToDB 7 args:"
Err.Clear
sk.AddToDB = True
res = sk.CreateLine(-0.04, 0.005, 0, 0.04, 0.005, 0, False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "C 6 args:"
Err.Clear
res = sk.CreateLine(-0.04, 0.01, 0, 0.04, 0.01, 0)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "D 8 args:"
Err.Clear
res = sk.CreateLine(-0.04, 0.015, 0, 0.04, 0.015, 0, False, False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

sk.AddToDB = False
f.WriteLine "E CenterLine 6 args:"
Err.Clear
res = sk.CreateCenterLine(0, -0.02, 0, 0, 0.02, 0)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "F CenterLine 7 args:"
Err.Clear
res = sk.CreateCenterLine(0, -0.025, 0, 0, 0.025, 0, False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "G Arc 7 args:"
Err.Clear
res = sk.CreateArc(0, -0.03, 0, 0.03, -0.03, 0, -0.03, 0.03, 0, 1)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "H Arc 8 args:"
Err.Clear
res = sk.CreateArc(0, -0.035, 0, 0.03, -0.035, 0, -0.03, 0.035, 0, 1, False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

sk.InsertSketch True
f.WriteLine "=== diag2 done " & Time
f.Close
