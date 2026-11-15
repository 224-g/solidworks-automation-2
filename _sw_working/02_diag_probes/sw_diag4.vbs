Option Explicit
On Error Resume Next
Dim swApp, FSO, f, md, sk, planeName, feat, res, cl, l1, arc
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag4.log", True, False)
f.WriteLine "=== diag4 start " & Time
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
md.Extension.SelectByID2 planeName, "PLANE", 0, 0, 0, False, 0, Nothing, 0
md.InsertSketch2 True

f.WriteLine "A Set-based 6 args (mirror sw-build5):"
sk.AddToDB = True
Err.Clear
Set l1 = sk.CreateLine(0, 0, 0, 0.082, 0, 0)
f.WriteLine "  SetCreateLine6 err=" & Err.Number & " [" & Err.Description & "] l1=" & (Not (l1 Is Nothing))
Err.Clear
Set cl = sk.CreateCenterLine(0, 0, 0, 0.082, 0, 0)
f.WriteLine "  SetCenterLine6 err=" & Err.Number & " [" & Err.Description & "] cl=" & (Not (cl Is Nothing))
sk.AddToDB = False

f.WriteLine "B Set-based CreateArc 10 args:"
Err.Clear
Set arc = sk.CreateArc(0, 0, 0, 0, 0.0045, 0, 0, -0.0045, 0, -1)
f.WriteLine "  SetArc10 err=" & Err.Number & " [" & Err.Description & "] arc=" & (Not (arc Is Nothing))

f.WriteLine "C value-assign 6 args again:"
Err.Clear
res = sk.CreateLine(0.01, 0.01, 0, 0.05, 0.01, 0)
f.WriteLine "  valLine6 err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "D Set-based 7 args (old chain flag):"
Err.Clear
Set l1 = sk.CreateLine(0, 0.01, 0, 0.05, 0.01, 0, False)
f.WriteLine "  SetLine7 err=" & Err.Number & " [" & Err.Description & "]"

md.SketchManager.InsertSketch True
f.WriteLine "=== diag4 done " & Time
f.Close
