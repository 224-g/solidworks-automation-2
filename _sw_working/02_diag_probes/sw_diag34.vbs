' sw_diag34.vbs - face dumps + overhang-cut tests
Option Explicit
Dim fso, lf, swApp, md, planeName
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag34.log", True, True)
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
Sub DumpFaces(tag)
  On Error Resume Next
  Dim bodies, body, fc, cnt
  bodies = md.GetBodies2(0, True)
  If Not IsArray(bodies) Then
    L tag & " NOBODIES"
    Exit Sub
  End If
  cnt = 0
  For Each body In bodies
    Set fc = body.GetFirstFace
    Do While Not fc Is Nothing
      cnt = cnt + 1
      Dim ar, bx
      ar = fc.GetArea
      bx = fc.GetBox
      If IsArray(bx) Then
        L tag & " face" & cnt & " area=" & Round(ar, 6) & " box=(" & Round(bx(0),3) & "," & Round(bx(1),3) & "," & Round(bx(2),3) & ")-(" & Round(bx(3),3) & "," & Round(bx(4),3) & "," & Round(bx(5),3) & ")"
      Else
        L tag & " face" & cnt & " area=" & Round(ar, 6) & " nobox"
      End If
      Set fc = fc.GetNextFace
    Loop
  Next
  L tag & " faces=" & cnt
End Sub
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

' A: plate with h1 cut, dump faces, retry h2 lookup
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
md.SketchManager.InsertSketch True : CutT "A-h1", True, 1, 0.001
WScript.Sleep 400
DumpFaces "A-after-h1"
WScript.Sleep 400
FaceSk 0.1, 0.03, 0.012 : md.SketchManager.CreateCircleByRadius 0.412, -0.042, 0, 0.0032
md.SketchManager.InsertSketch True : CutT "A-h2", True, 1, 0.001
WScript.Sleep 400
DumpFaces "A-after-h2"

' B: shaft with overhang-rect flat
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0) : WScript.Sleep 400
PlaneSel : md.SketchManager.InsertSketch False
md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.005
md.SketchManager.InsertSketch True : SelSk
ExtrT "B-shaft", False, 0.056
WScript.Sleep 400
FaceSk 0.004, 0, 0.056
md.SketchManager.CreateLine -0.010, 0.002, 0, 0.010, 0.002, 0
md.SketchManager.CreateLine 0.010, 0.002, 0, 0.010, 0.010, 0
md.SketchManager.CreateLine 0.010, 0.010, 0, -0.010, 0.010, 0
md.SketchManager.CreateLine -0.010, 0.010, 0, -0.010, 0.002, 0
md.SketchManager.InsertSketch True : CutT "B-flat-rect", True, 1, 0.001
WScript.Sleep 400
DumpFaces "B-after-rectflat"

' C: gear: hub+ring, backcut r=0.030 overhang + dhole circle
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
FaceSk 0, 0.02, 0 : md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.030
md.SketchManager.InsertSketch True : CutT "C-backcut-overhang", True, 0, 0.006
WScript.Sleep 400
FaceSk 0, 0.005, 0.024 : md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0041
md.SketchManager.InsertSketch True : CutT "C-dhole", True, 1, 0.001
WScript.Sleep 400
DumpFaces "C-final"
L "DONE"
lf.Close
WScript.Quit
