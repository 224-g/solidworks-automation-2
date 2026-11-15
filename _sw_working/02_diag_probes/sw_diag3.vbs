Option Explicit
On Error Resume Next
Dim swApp, FSO, f, md, sk, planeName, feat, res, n
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag3.log", True, False)
f.WriteLine "=== diag3 start " & Time
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
sk.InsertSketch True

f.WriteLine "CreateLine count sweep:"
For n = 1 To 12
  Err.Clear
  Select Case n
    Case 1:  res = sk.CreateLine(CDbl(-0.04))
    Case 2:  res = sk.CreateLine(CDbl(-0.04), CDbl(0))
    Case 3:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0))
    Case 4:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04))
    Case 5:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0))
    Case 6:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0))
    Case 7:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False)
    Case 8:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False, False)
    Case 9:  res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False, False, False)
    Case 10: res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False, False, False, False)
    Case 11: res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False, False, False, False, False)
    Case 12: res = sk.CreateLine(CDbl(-0.04), CDbl(0), CDbl(0), CDbl(0.04), CDbl(0), CDbl(0), False, False, False, False, False, False)
  End Select
  f.WriteLine "  n=" & n & " err=" & Err.Number & " [" & Err.Description & "]"
Next

f.WriteLine "CreateCornerRectangle 5 args:"
Err.Clear
res = sk.CreateCornerRectangle(CDbl(-0.01), CDbl(-0.01), CDbl(0), CDbl(0.01), CDbl(0.01))
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "CreateLine3D... try CreateLine via md.SketchManager direct:"
Err.Clear
res = md.SketchManager.CreateLine(CDbl(-0.02), CDbl(0.02), CDbl(0), CDbl(0.02), CDbl(0.02), CDbl(0), False)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "CreateArc 10 args:"
Err.Clear
res = sk.CreateArc(CDbl(0), CDbl(-0.03), CDbl(0), CDbl(0.03), CDbl(-0.03), CDbl(0), CDbl(-0.03), CDbl(0.03), CDbl(0), 1)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

f.WriteLine "CreateCircleByRadius sanity:"
Err.Clear
res = sk.CreateCircleByRadius(0, 0.02, 0, 0.005)
f.WriteLine "  res=" & res & " err=" & Err.Number & " [" & Err.Description & "]"

sk.InsertSketch True
f.WriteLine "=== diag3 done " & Time
f.Close
