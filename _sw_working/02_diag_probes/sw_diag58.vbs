' sw_diag58.vbs - mass properties + part box of saved diag55 gear
Option Explicit
On Error Resume Next
Dim swApp, md, LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag58.log", 8, True)
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

  ' mass properties
  Dim mp
  Set mp = md.Extension.CreateMassProperty
  If mp Is Nothing Then
    L "mp", "create FAILED"
  Else
    mp.UseSystemUnits = False
    L "mp", "volume=" & FormatNumber(mp.Volume, 6) & " mass=" & FormatNumber(mp.Mass, 6) & " surface=" & FormatNumber(mp.SurfaceArea, 3)
  End If

  ' part box (wrapped in its own sub-level OERN)
  TryBox

  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag58"
End Sub

Sub TryBox()
  On Error Resume Next
  Dim bb
  bb = md.GetPartBox(True)
  If Err.Number <> 0 Then
    L "box", "THREW err=" & Err.Number
  Else
    L "box", "x[" & FormatNumber(bb(0)*1000,3) & ".." & FormatNumber(bb(3)*1000,3) & "] y[" & FormatNumber(bb(1)*1000,3) & ".." & FormatNumber(bb(4)*1000,3) & "] z[" & FormatNumber(bb(2)*1000,3) & ".." & FormatNumber(bb(5)*1000,3) & "]"
  End If
  Err.Clear
End Sub

Call Main
