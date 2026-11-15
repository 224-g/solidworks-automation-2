' sw_diag11.vbs - test feature.Select2 plane selection + robust inspect
' pure ASCII, logs to sw_diag11.log (UTF-16)
Option Explicit
Dim fso, lf, swApp, md, sk
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag11.log", True, True)
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

' collect plane feature OBJECTS
Dim f, fPl(2), pName(2), cnt, pIdx
cnt = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" Then
    If cnt <= 2 Then
      Set fPl(cnt) = f
      pName(cnt) = f.Name
    End If
    cnt = cnt + 1
  End If
  Set f = f.GetNextFeature
Loop
L "planes 0=" & pName(0) & " 1=" & pName(1) & " 2=" & pName(2)

Sub SelCount(tag)
  On Error Resume Next
  Dim sm, n
  Set sm = md.SelectionManager
  n = sm.GetSelectedObjectCount2(-1)
  L tag & " selcount=" & n
End Sub

Sub InspectSketch(tag)
  On Error Resume Next
  Dim ff, skf
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
  Dim sk2, n, seg, pts
  Set sk2 = skf.GetSpecificFeature2
  L tag & " spec=" & TypeName(sk2)
  If sk2 Is Nothing Then Exit Sub
  n = sk2.GetSketchSegmentCount
  L tag & " segcount=" & n
  If n > 0 Then
    Set seg = sk2.GetSketchSegments(0)
    pts = seg.GetStartPoint2
    L tag & " seg0 start=(" & Round(CDbl(pts(0)),4) & "," & Round(CDbl(pts(1)),4) & "," & Round(CDbl(pts(2)),4) & ")"
    pts = seg.GetEndPoint2
    L tag & " seg0 end=(" & Round(CDbl(pts(0)),4) & "," & Round(CDbl(pts(1)),4) & "," & Round(CDbl(pts(2)),4) & ")"
  End If
End Sub

Sub DoCase(tag, pf, kind, lx1, ly1, lz1, lx2, ly2, lz2)
  On Error Resume Next
  Dim b, selName, selPt
  md.ClearSelection2 True
  If kind = 0 Then
    ' feature.Select2
    b = pf.Select2(False, 1)
    L tag & " Select2 b=" & b
  ElseIf kind = 1 Then
    ' SelectByID2 by name + coords on plane
    selName = pf.Name
    b = md.Extension.SelectByID2(selName, "PLANE", 0, 0, 0, False, 1, Nothing, 0)
    L tag & " SelByID2(0,0,0) b=" & b
  Else
    ' SelectByID2 by name + off-origin coords (0.2,0,0.2)
    selName = pf.Name
    b = md.Extension.SelectByID2(selName, "PLANE", 0.2, 0, 0.2, False, 1, Nothing, 0)
    L tag & " SelByID2(pt) b=" & b
  End If
  SelCount tag
  sk.InsertSketch False
  L tag & " bare InsertSketch False"
  SelCount tag & " afterIns"
  sk.CreateLine lx1, ly1, lz1, lx2, ly2, lz2
  L tag & " after line"
  sk.InsertSketch True
  L tag & " after bare close"
  InspectSketch tag
End Sub

' A: top plane via feature.Select2, Z-line (should survive if plane=top)
DoCase "A", fPl(1), 0, 0, 0, 0, 0, 0, 0.05
' B: top plane via SelectByID2 name+coords, Z-line
DoCase "B", fPl(1), 2, 0, 0, 0, 0, 0, 0.05
' C: front plane via feature.Select2, Y-line (sanity)
DoCase "C", fPl(0), 0, 0, 0, 0, 0, 0.05, 0
' D: right plane via feature.Select2, Z-line (survives if plane=right(Y-Z))
DoCase "D", fPl(2), 0, 0, 0, 0, 0, 0, 0.05
' E: right plane via feature.Select2, Y-line
DoCase "E", fPl(2), 0, 0, 0, 0, 0, 0.05, 0

L "DONE"
lf.Close
md.SaveAs3 "C:\Users\zgzgd\Documents\DSH\sw_diag11_junk.SLDPRT", 0, 2
WScript.Quit
