' sw_diag59.vbs - count bodies via SolidBodyFolder sub-features
Option Explicit
On Error Resume Next
Dim swApp, md, LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag59.log", 8, True)
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
  L "open", "ok"

  Dim f
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    If f.GetTypeName2 = "SolidBodyFolder" Then
      Exit Do
    End If
    Set f = f.GetNextFeature
  Loop
  If f Is Nothing Then
    L "folder", "not found"
  Else
    L "folder", "found: " & f.Name
    Dim sf, n
    Set sf = f.GetFirstSubFeature
    n = 0
    Do While Not sf Is Nothing
      n = n + 1
      L "body" & n, sf.GetTypeName2 & " : " & sf.Name
      Set sf = sf.GetNextSubFeature
      If n > 20 Then Exit Do
    Loop
    L "count", "n=" & n
  End If
  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag59"
End Sub

Call Main
