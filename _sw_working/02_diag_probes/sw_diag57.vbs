' sw_diag57.vbs - feature-tree walk of saved diag55 gear
Option Explicit
On Error Resume Next
Dim swApp, md, LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag57.log", 8, True)
Set lf = LOG
Sub L(tag, msg)
  lf.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Sub Main()
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber
  Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag55_G.SLDPRT", 1)
  If md Is Nothing Then
    L "open", "FAILED"
    Exit Sub
  End If
  L "open", "ok title=" & md.GetTitle
  Dim f, i
  Set f = md.FirstFeature
  i = 0
  Do While Not f Is Nothing
    i = i + 1
    If i > 60 Then
      L "walk", "cap reached"
      Exit Do
    End If
    L "f" & i, f.GetTypeName2 & " : " & f.Name
    Set f = f.GetNextFeature
  Loop
  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag57"
End Sub

Call Main
