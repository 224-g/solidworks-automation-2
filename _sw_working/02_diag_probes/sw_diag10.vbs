' sw_diag10.vbs - plane check via feature-tree sketch + segment endpoints
' pure ASCII, logs to sw_diag10.log (UTF-16)
Option Explicit
Dim fso, lf, swApp, md, sk
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag10.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & " " & Err.Description & "]"
  Err.Clear
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
If swApp Is Nothing Then
  lf.WriteLine "NO SW"
  lf.Close
  WScript.Quit
End If
L "SW attached"

Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
L "NewDoc"
Set sk = md.SketchManager
L "got sk"

Dim f, pl0, pl1, cnt
pl0 = "" : pl1 = "" : cnt = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" Then
    cnt = cnt + 1
    If cnt = 1 Then pl0 = f.Name
    If cnt = 2 Then pl1 = f.Name
  End If
  Set f = f.GetNextFeature
Loop
L "planes pl0=" & pl0 & " pl1=" & pl1

Sub InspectSketch(tag)
  ' find LAST sketch feature in tree, get segments + first endpoint
  Dim ff, skf, i
  Set skf = Nothing
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
    Set ff = ff.GetNextFeature
  Loop
  If skf Is Nothing Then
    L tag & " NOSKETCHFEATURE"
    Exit Sub
  End If
  Dim sk2, n
  Set sk2 = skf.GetSpecificFeature2
  L tag & " specfeature type=" & TypeName(sk2) & " name=" & skf.Name
  n = sk2.GetSketchSegmentCount
  L tag & " segcount=" & n
  If n > 0 Then
    Dim seg, pts
    Set seg = sk2.GetSketchSegments(0)
    pts = seg.GetStartPoint2
    L tag & " seg0 start=(" & pts(0) & "," & pts(1) & "," & pts(2) & ")"
    pts = seg.GetEndPoint2
    L tag & " seg0 end=(" & pts(0) & "," & pts(1) & "," & pts(2) & ")"
  End If
End Sub

Sub OpenAndClose(planeName, px, py, pz)
  Dim b
  md.ClearSelection2 True
  b = md.Extension.SelectByID2(planeName, "PLANE", px, py, pz, False, 0, Nothing, 0)
  L " sel b=" & b
  sk.InsertSketch False
  L " bare InsertSketch False"
End Sub

' T1: pl1(top) Z-line -> expect seg=1 end z=0.05 if plane=top; 0 segments if front
md.ClearSelection2 True
Dim b
b = md.Extension.SelectByID2(pl1, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "T1 sel pl1 b=" & b
sk.InsertSketch False
L "T1 bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0, 0.05
L "T1 after Zline"
sk.InsertSketch True
L "T1 after bare close"
InspectSketch "T1"

' T2: pl1(top) Y-line
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl1, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "T2 sel pl1 b=" & b
sk.InsertSketch False
L "T2 bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0.05, 0
L "T2 after Yline"
sk.InsertSketch True
L "T2 after bare close"
InspectSketch "T2"

' T3: pl0(front) Y-line (sanity - should be seg=1 end y=0.05)
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl0, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "T3 sel pl0 b=" & b
sk.InsertSketch False
L "T3 bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0.05, 0
L "T3 after Yline"
sk.InsertSketch True
L "T3 after bare close"
InspectSketch "T3"

L "DONE"
lf.Close
md.SaveAs3 "C:\Users\zgzgd\Documents\DSH\sw_diag10_junk.SLDPRT", 0, 2
WScript.Quit
