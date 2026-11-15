' sw_diag33.vbs - isolate: 2nd-cut face-select failure; DRegion cut; annulus-face cut; gap cut
Option Explicit
Dim fso, lf, swApp, md, planeName
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag33.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub PlaneSel()
  On Error Resume Next
  Dim pf
  Set pf = md.FirstFeature
  Do While Not pf Is Nothing
    If pf.GetTypeName2 = "RefPlane" Then planeName = pf.Name : Exit Do
    Set pf = pf.GetNextFeature
  Loop
  md.ClearSelection2 True
  md.Extension.SelectByID2 planeName, "PLANE", 0, 0, 0, False, 0, Nothing, 0
End Sub
Sub SelSk()
  On Error Resume Next
  Dim ff, skf
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
    Set ff = ff.GetNextFeature
  Loop
  If Not skf Is Nothing Then md.Extension.SelectByID2 skf.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0
End Sub
Function SegCount()
  On Error Resume Next
  Dim v
  v = md.SketchManager.ActiveSketch.GetSketchSegments
  If IsArray(v) Then SegCount = UBound(v) + 1 Else SegCount = -1
End Function
Sub ExtrT(tag, flip, d)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If feat Is Nothing Then L "ERR extr " & tag Else L "OK extr " & tag
End Sub
Sub CutT(tag, flip, t1, d1)
  On Error Resume Next
  Dim feat
  Set feat = md.FeatureManager.FeatureCut4(True, flip, False, t1, 0, d1, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If feat Is Nothing Then L "ERR cut " & tag Else L "OK cut " & tag
End Sub
Sub FaceSk(x, y, z)
  On Error Resume Next
  md.ClearSelection2 True
  Dim sr
  sr = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L "facesk sel=" & sr
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True

' A: plate: two holes, second-hole select test with sleep
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
PlaneSel : md.SketchManager.InsertSketch False
md.SketchManager.CreateLine 0, -0.095, 0, 0.432, -0.095, 0
md.SketchManager.CreateLine 0.432, -0.095, 0, 0.432, 0.235, 0
md.SketchManager.CreateLine 0.432, 0.235, 0, 0, 0.235, 0
md.SketchManager.CreateLine 0, 0.235, 0, 0, -0.095, 0
md.SketchManager.InsertSketch True : SelSk
ExtrT "A-plate", False, 0.012
WScript.Sleep 400
FaceSk 0.1, 0.03, 0.012 : md.SketchManager.CreateCircleByRadius 0.020, -0.042, 0, 0.0032
L "A h1 segs=" & SegCount()
md.SketchManager.InsertSketch True : CutT "A-h1", True, 1, 0.001
WScript.Sleep 800
FaceSk 0.1, 0.03, 0.012 : md.SketchManager.CreateCircleByRadius 0.412, -0.042, 0, 0.0032
L "A h2 segs=" & SegCount()
md.SketchManager.InsertSketch True : CutT "A-h2", True, 1, 0.001

' B: shaft: circle block + DRegion cap cut
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
PlaneSel : md.SketchManager.InsertSketch False
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.005
md.SketchManager.InsertSketch True : SelSk
ExtrT "B-shaft", False, 0.056
WScript.Sleep 400
FaceSk 0.004, 0, 0.056
Dim s, x1, y1, x2, y2, thf
thf = 1.5707963267949
s = Sqr(0.005 * 0.005 - 0.002 * 0.002)
x1 = 0.002 * Cos(thf) - s * Sin(thf)
y1 = 0.002 * Sin(thf) + s * Cos(thf)
x2 = 0.002 * Cos(thf) + s * Sin(thf)
y2 = 0.002 * Sin(thf) - s * Cos(thf)
md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
md.SketchManager.CreateArc 0, 0, 0, x2, y2, 0, x1, y1, 0, 1
L "B flat segs=" & SegCount()
md.SketchManager.InsertSketch True : CutT "B-flat", True, 1, 0.001

' C: gear: hub+ring, backcut on ring z0 face
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
PlaneSel : md.SketchManager.InsertSketch False
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
md.SketchManager.InsertSketch True : SelSk
ExtrT "C-hub", False, 0.024
WScript.Sleep 400
PlaneSel : md.SketchManager.InsertSketch False
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
md.SketchManager.InsertSketch True : SelSk
ExtrT "C-ring", False, 0.018
WScript.Sleep 400
FaceSk 0, 0.02, 0 : md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
L "C backcut segs=" & SegCount()
md.SketchManager.InsertSketch True : CutT "C-backcut", True, 0, 0.006
WScript.Sleep 400
FaceSk 0, 0.005, 0.024 : md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0041
L "C dhole segs=" & SegCount()
md.SketchManager.InsertSketch True : CutT "C-dhole", True, 1, 0.001
L "DONE"
lf.Close
WScript.Quit
