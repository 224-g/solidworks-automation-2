Option Explicit
On Error Resume Next
Dim swApp, FSO, f, md, sk, planeName, feat, i, res
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag.log", True, False)
f.WriteLine "=== diag start " & Time
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
f.WriteLine "swApp: " & (Not swApp Is Nothing)
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
f.WriteLine "doc: " & (Not md Is Nothing)
Set sk = md.SketchManager

' get first plane name dynamically (no Chinese literals)
planeName = ""
Set feat = md.FirstFeature
Do While Not feat Is Nothing
  If feat.GetTypeName2 = "RefPlane" And planeName = "" Then planeName = feat.Name
  Set feat = feat.GetNextFeature
Loop
f.WriteLine "planeName: [" & planeName & "]"

Err.Clear
res = md.Extension.SelectByID2(planeName, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
f.WriteLine "SelectByID2 res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"
Err.Clear
sk.InsertSketch True
f.WriteLine "InsertSketch err=" & Err.Number & " [" & Err.Description & "]"
Err.Clear
sk.AddToDB = True
f.WriteLine "AddToDB=True err=" & Err.Number
Err.Clear
sk.CreateLine -0.040, 0, 0, 0.040, 0, 0, False
f.WriteLine "CreateLine err=" & Err.Number & " [" & Err.Description & "]"
Err.Clear
sk.CreateCircleByRadius 0, 0.010, 0, 0.005
f.WriteLine "Circle err=" & Err.Number & " [" & Err.Description & "]"
sk.AddToDB = False
Err.Clear
sk.InsertSketch True
f.WriteLine "InsertSketch2 err=" & Err.Number & " [" & Err.Description & "]"
f.WriteLine "=== diag done " & Time
f.Close
