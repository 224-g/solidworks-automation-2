' sw_diag12.vbs - ground truth: which plane does each sketch land on
' logs 3D endpoints of segments drawn on each selected plane
Option Explicit
Dim fso, lf, swApp, md, sk
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag12.log", True, True)
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

' list ALL RefPlanes
Dim f, allP(20), np
np = 0
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" Then
    If np <= 20 Then
      Set allP(np) = f
      L "plane[" & np & "] name=" & f.Name
    End If
    np = np + 1
  End If
  Set f = f.GetNextFeature
Loop
L "total planes=" & np

Sub DumpSegs(tag)
  On Error Resume Next
  Dim sks, arr, i, seg, p1, p2
  Set sks = sk.ActiveSketch
  L tag & " activeSketch type=" & TypeName(sks)
  If sks Is Nothing Then Exit Sub
  arr = sks.GetSketchSegments
  L tag & " segs type=" & TypeName(arr)
  If Not IsArray(arr) Then Exit Sub
  L tag & " segs count=" & (UBound(arr) + 1)
  For i = 0 To UBound(arr)
    Set seg = arr(i)
    p1 = seg.GetStartPoint2
    p2 = seg.GetEndPoint2
    L tag & " seg" & i & " " & Round(CDbl(p1(0)),4) & "," & Round(CDbl(p1(1)),4) & "," & Round(CDbl(p1(2)),4) & " -> " & Round(CDbl(p2(0)),4) & "," & Round(CDbl(p2(1)),4) & "," & Round(CDbl(p2(2)),4)
  Next
End Sub

Sub CaseOn(tag, pf, insArg)
  On Error Resume Next
  Dim b
  md.ClearSelection2 True
  b = pf.Select2(False, 1)
  L tag & " Select2 b=" & b
  sk.InsertSketch insArg
  L tag & " InsertSketch(" & insArg & ")"
  sk.CreateLine 0, 0, 0, 0, 0.05, 0
  L tag & " Yline drawn"
  sk.CreateLine 0, 0, 0, 0, 0, 0.05
  L tag & " Zline drawn"
  DumpSegs tag
  sk.InsertSketch True
  L tag & " closed"
End Sub

CaseOn "P0FRONT", allP(0), False
CaseOn "P1TOP", allP(1), False
CaseOn "P2RIGHT", allP(2), False
If np > 3 Then CaseOn "P3EXTRA", allP(3), False
If np > 4 Then CaseOn "P4EXTRA", allP(4), False

L "DONE"
lf.Close
md.SaveAs3 "C:\Users\zgzgd\Documents\DSH\sw_diag12_junk.SLDPRT", 0, 2
WScript.Quit
