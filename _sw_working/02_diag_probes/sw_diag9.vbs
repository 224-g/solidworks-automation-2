' sw_diag9.vbs - test BARE-STATEMENT InsertSketch after plane selection
' pure ASCII, logs to sw_diag9.log (UTF-16)
Option Explicit
Dim fso, lf, swApp, md, sk, errNum
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag9.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
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
L "SW attached rev=" & swApp.RevisionNumber

Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
L "NewDoc"
Set sk = md.SketchManager
L "got sk type=" & TypeName(sk)

' plane names from feature tree
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

Dim b, segs, i, lineSeg
' count segments helper as inline code
Sub CountSegs(tag)
  Dim sks, n, j
  Set sks = sk.ActiveSketch
  If sks Is Nothing Then
    L tag & " noseg (no active sketch)"
    Exit Sub
  End If
  n = sks.GetSketchSegmentCount
  L tag & " segcount=" & n & " (sks name=" & sks.Name & ")"
End Sub

' V1: pl0 + bare InsertSketch False + Y-line
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl0, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "V1 sel pl0 b=" & b
sk.InsertSketch False
L "V1 after bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0.05, 0
L "V1 after Yline"
CountSegs "V1 Yline"
' close: bare InsertSketch True
sk.InsertSketch True
L "V1 after bare close"

' V2: pl1 + bare InsertSketch False + Y-line
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl1, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "V2 sel pl1 b=" & b
sk.InsertSketch False
L "V2 after bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0.05, 0
L "V2 after Yline"
CountSegs "V2 Yline"
sk.InsertSketch True
L "V2 after bare close"

' V3: pl1 + bare InsertSketch False + Z-line
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl1, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "V3 sel pl1 b=" & b
sk.InsertSketch False
L "V3 after bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0, 0.05
L "V3 after Zline"
CountSegs "V3 Zline"
sk.InsertSketch True
L "V3 after bare close"

' V4: pl1@(0.2,0,0.2) + bare InsertSketch False + Z-line
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl1, "PLANE", 0.2, 0, 0.2, False, 0, Nothing, 0)
L "V4 sel pl1@pt b=" & b
sk.InsertSketch False
L "V4 after bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0, 0.05
L "V4 after Zline"
CountSegs "V4 Zline"
sk.InsertSketch True
L "V4 after bare close"

' V5: no selection + bare InsertSketch False + Y-line
md.ClearSelection2 True
L "V5 cleared sel"
sk.InsertSketch False
L "V5 after bare InsertSketch False"
sk.CreateLine 0, 0, 0, 0, 0.05, 0
L "V5 after Yline"
CountSegs "V5 Yline"
sk.InsertSketch True
L "V5 after bare close"

' V6: pl1 + bare InsertSketch True + Z-line (UpdateEditRebuild=True?)
md.ClearSelection2 True
b = md.Extension.SelectByID2(pl1, "PLANE", 0, 0, 0, False, 0, Nothing, 0)
L "V6 sel pl1 b=" & b
sk.InsertSketch True
L "V6 after bare InsertSketch True"
sk.CreateLine 0, 0, 0, 0, 0, 0.05
L "V6 after Zline"
CountSegs "V6 Zline"
sk.InsertSketch True
L "V6 after bare close"

L "DONE"
lf.Close
' save junk doc anyway so user can inspect
md.SaveAs3 "C:\Users\zgzgd\Documents\DSH\sw_diag9_junk.SLDPRT", 0, 2
WScript.Quit
