' sw_diag60.vbs - BodyFolder.GetBodyCount via GetSpecificFeature2
Option Explicit
On Error Resume Next
Dim swApp, md, LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag60.log", 8, True)
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
    If f.GetTypeName2 = "SolidBodyFolder" Then Exit Do
    Set f = f.GetNextFeature
  Loop
  If f Is Nothing Then
    L "folder", "not found"
  Else
    Dim bf
    Set bf = f.GetSpecificFeature2
    If bf Is Nothing Then
      L "bf", "GetSpecificFeature2 Nothing"
    Else
      L "bf", "ok count=" & bf.GetBodyCount
      Dim i, bd
      For i = 0 To bf.GetBodyCount - 1
        Set bd = bf.GetBodyAt(i)
        Dim bb
        bb = bd.GetBodyBox
        L "body" & i, "x[" & FormatNumber(bb(0)*1000,2) & ".." & FormatNumber(bb(3)*1000,2) & "] y[" & FormatNumber(bb(1)*1000,2) & ".." & FormatNumber(bb(4)*1000,2) & "] z[" & FormatNumber(bb(2)*1000,2) & ".." & FormatNumber(bb(5)*1000,2) & "]"
      Next
    End If
  End If
  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag60"
End Sub

Call Main
