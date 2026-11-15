' sw_diag41.vbs - dump EVERY feature type+name of saved gear1 + gear2
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag41.log", True)

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub DumpAll(path, tag)
  On Error Resume Next
  Dim md
  Set md = swApp.OpenDoc(path, 1)
  If md Is Nothing Then
    L tag & " open", "FAILED"
    Exit Sub
  End If
  WScript.Sleep 300
  Dim feat, totCnt, typ
  Set feat = md.FirstFeature
  totCnt = 0
  Do While Not feat Is Nothing
    totCnt = totCnt + 1
    typ = feat.GetTypeName2
    L tag, totCnt & ":" & typ & ":" & feat.Name
    Set feat = feat.GetNextFeature
    If totCnt > 120 Then Set feat = Nothing
  Loop
  L tag & " total", totCnt
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

DumpAll "C:\Users\zgzgd\Documents\DSH\sw_parts5\" & ChrW(&H4E3B) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E) & ".SLDPRT", "gear1"

L "DONE", "diag41"
lf.Close
