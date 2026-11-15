' sw_diag40.vbs - inspect saved gears: feature-tree counts + part box
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag40.log", True)

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub Inspect(path, tag)
  On Error Resume Next
  Dim md
  Set md = swApp.OpenDoc(path, 1)
  If md Is Nothing Then
    L tag & " open", "FAILED"
    Exit Sub
  End If
  WScript.Sleep 300
  Dim feat, extCnt, cutCnt, skCnt, totCnt, typ
  Set feat = md.FirstFeature
  extCnt = 0
  cutCnt = 0
  skCnt = 0
  totCnt = 0
  Do While Not feat Is Nothing
    typ = feat.GetTypeName2
    If typ = "Extrusion" Then extCnt = extCnt + 1
    If typ = "Cut" Then cutCnt = cutCnt + 1
    If typ = "ProfileFeature" Then skCnt = skCnt + 1
    totCnt = totCnt + 1
    If typ = "Extrusion" Or typ = "Cut" Then
      L tag & " feat", totCnt & ":" & typ & ":" & feat.Name
    End If
    Set feat = feat.GetNextFeature
    If totCnt > 300 Then Set feat = Nothing
  Loop
  Dim box
  box = md.Extension.GetPartBox(True)
  L tag & " counts", "ext=" & extCnt & " cut=" & cutCnt & " sk=" & skCnt
  L tag & " box", Join(box, ",")
  md.CloseDoc CStr(md.GetTitle)
End Sub

On Error Resume Next
Dim t
t = Timer
Do While swApp Is Nothing And Timer - t < 120
  Set swApp = GetObject("", "SldWorks.Application")
  If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
  If swApp Is Nothing Then WScript.Sleep 2000
Loop
If swApp Is Nothing Then
  L "FATAL", "no SW"
  lf.Close
  WScript.Quit
End If
L "attached", "rev=" & swApp.RevisionNumber

Inspect "C:\Users\zgzgd\Documents\DSH\sw_parts5\" & ChrW(&H4E3B) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E) & ".SLDPRT", "gear1"
Inspect "C:\Users\zgzgd\Documents\DSH\sw_parts5\" & ChrW(&H4ECE) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E) & ".SLDPRT", "gear2"

L "DONE", "diag40"
lf.Close
