' sw_diag56.vbs - inspect saved diag55 gear: body count + body boxes
Option Explicit
On Error Resume Next
Dim swApp, md, LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag56.log", 8, True)
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

  Dim vb
  vb = md.GetBodies2(0, False)
  L "bodies", "vartype=" & VarType(vb)
  If VarType(vb) = 8204 Then
    Dim n, i
    n = UBound(vb) + 1
    L "count", "n=" & n
    For i = 0 To UBound(vb)
      Dim bb
      bb = vb(i).GetBodyBox
      L "body" & i, "box x[" & FormatNumber(bb(0)*1000,3) & ".." & FormatNumber(bb(3)*1000,3) & "] y[" & FormatNumber(bb(1)*1000,3) & ".." & FormatNumber(bb(4)*1000,3) & "] z[" & FormatNumber(bb(2)*1000,3) & ".." & FormatNumber(bb(5)*1000,3) & "]"
    Next
  End If
  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag56"
End Sub

Call Main
