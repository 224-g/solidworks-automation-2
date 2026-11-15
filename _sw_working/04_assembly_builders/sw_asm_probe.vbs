' sw_asm_probe.vbs - probe AddComponent5 dispatch on the assembly doc
Option Explicit
On Error Resume Next
Dim swApp, md, comp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_asm_probe.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "rev=" & swApp.RevisionNumber
  swApp.CloseAllDocuments True
  WScript.Sleep 300
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_assembly.asmdot", 0, 0, 0)
  WScript.Sleep 800
  If md Is Nothing Then
    L "newasm", "FAILED"
    Exit Sub
  End If
  L "newasm", "type=" & md.GetType & " title=" & md.GetTitle
  Set comp = md.AddComponent5("plate", "C:\Users\zgzgd\Documents\DSH\sw_parts8\plate.SLDPRT", 0, 0, 0)
  If comp Is Nothing Then
    L "md.AddComponent5", "FAILED"
  Else
    L "md.AddComponent5", "OK name=" & comp.Name2
  End If
  Dim ad
  Set ad = swApp.ActiveDoc
  Set comp = ad.AddComponent5("plate2", "C:\Users\zgzgd\Documents\DSH\sw_parts8\plate.SLDPRT", 0.1, 0, 0)
  If comp Is Nothing Then
    L "active.AddComponent5", "FAILED"
  Else
    L "active.AddComponent5", "OK name=" & comp.Name2
  End If
  L "done", "probe complete"
End Sub

Call Main
