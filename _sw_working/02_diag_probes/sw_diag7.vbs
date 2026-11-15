' sw_diag7.vbs - (1) which world quadrants register on the pl(1) sketch + sketch transform
'                (2) replicate build bracket flow with err capture
Option Explicit
Dim swApp, fso, lf
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag7.log", 2, True)
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")

Sub L(s)
  lf.WriteLine Time & " " & s
  lf.Flush
End Sub

Dim md, sk, pl(2), i, f, segs, f2, res, t, ad, j

On Error Resume Next

' ========== PART 1: pl(1) quadrant probe ==========
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
L "P1 planes: " & pl(0) & " / " & pl(1) & " / " & pl(2)
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(1), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "P1 select pl(1) res=" & res
res = sk.InsertSketch(True)
L "P1 insertsketch res=" & res
Set t = sk.ActiveSketch.Transform2
ad = t.ArrayData
L "P1 sketch transform: " & Join(ad, ",")
sk.CreateCircleByRadius 0.05, 0, 0.05, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P1 c1(+x,+z) segs=" & UBound(segs)
sk.CreateCircleByRadius 0.05, 0, -0.05, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P1 c2(+x,-z) segs=" & UBound(segs)
sk.CreateCircleByRadius -0.05, 0, 0.05, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P1 c3(-x,+z) segs=" & UBound(segs)
sk.CreateCircleByRadius -0.05, 0, -0.05, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P1 c4(-x,-z) segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

' ========== PART 2: pl(0) quadrant probe ==========
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "P2 select pl(0) res=" & res
res = sk.InsertSketch(True)
L "P2 insertsketch res=" & res
sk.CreateCircleByRadius 0.05, 0.05, 0, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P2 c1(+x,+y) segs=" & UBound(segs)
sk.CreateCircleByRadius 0.05, -0.05, 0, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P2 c2(+x,-y) segs=" & UBound(segs)
sk.CreateCircleByRadius -0.05, 0.05, 0, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P2 c3(-x,+y) segs=" & UBound(segs)
sk.CreateCircleByRadius -0.05, -0.05, 0, 0.01
segs = sk.ActiveSketch.GetSketchSegments : L "P2 c4(-x,-y) segs=" & UBound(segs)
swApp.CloseDoc md.GetTitle

' ========== PART 3: build-style bracket with CloseSketch loop + SelLastSketch ==========
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
Set sk = md.SketchManager
i = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" And i <= 2 Then pl(i) = f.Name : i = i + 1
  Set f = f.GetNextFeature
Loop
md.ClearSelection2 True
res = md.Extension.SelectByID2(pl(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "P3 select res=" & res
res = sk.InsertSketch(True)
L "P3 insertsketch res=" & res
sk.CreateLine -0.045, 0, 0, 0.045, 0, 0
sk.CreateLine 0.045, 0, 0, 0.045, 0.015, 0
sk.CreateLine 0.045, 0.015, 0, 0.010, 0.015, 0
sk.CreateLine 0.010, 0.015, 0, 0.010, 0.090, 0
sk.CreateLine 0.010, 0.090, 0, -0.010, 0.090, 0
sk.CreateLine -0.010, 0.090, 0, -0.010, 0.015, 0
sk.CreateLine -0.010, 0.015, 0, -0.045, 0.015, 0
sk.CreateLine -0.045, 0.015, 0, -0.045, 0, 0
segs = sk.ActiveSketch.GetSketchSegments : L "P3 segs after 8 lines=" & UBound(segs)
' build CloseSketch: 4x InsertSketch
res = sk.InsertSketch(True) : L "P3 close1 res=" & res & " err=" & Err.Number
If Not res Then
  For i = 1 To 3
    WScript.Sleep 300
    res = sk.InsertSketch(True) : L "P3 close" & (i+1) & " res=" & res & " err=" & Err.Number
    If res Then Exit For
  Next
End If
' build SelLastSketch: walk features, select last ProfileFeature
Dim lastF
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "ProfileFeature" Then Set lastF = f
  Set f = f.GetNextFeature
Loop
L "P3 lastF isNothing=" & (lastF Is Nothing) & " name=" & lastF.Name
md.ClearSelection2 True
res = md.Extension.SelectByID2(lastF.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
L "P3 select sketch res=" & res & " err=" & Err.Number
Set f2 = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, 0.012, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
L "P3 extrude isNothing=" & (f2 Is Nothing) & " err=" & Err.Number
If Not f2 Is Nothing Then
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag7_testpart.SLDPRT", 0, 0)
  L "P3 save res=" & res
End If
swApp.CloseDoc md.GetTitle

L "DONE"
lf.Close
