' sw_asm_probe2.vbs - test correct-arg AddComponent5/4 + RunMacro2 retry
Option Explicit
On Error Resume Next
Dim swApp, md, comp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_asm_probe2.log", 8, True)
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
  L "newasm", "type=" & md.GetType
  ' 8-arg AddComponent5 (SW2024 typelib signature)
  Set comp = md.AddComponent5("p5", 0, "", False, "", 0, 0, 0)
  If comp Is Nothing Then
    L "md.AddComponent5-8arg", "FAILED"
  Else
    L "md.AddComponent5-8arg", "OK name=" & comp.Name2
  End If
  ' 5-arg AddComponent4
  Set comp = md.AddComponent4("p4", "", 0.1, 0, 0)
  If comp Is Nothing Then
    L "md.AddComponent4", "FAILED"
  Else
    L "md.AddComponent4", "OK name=" & comp.Name2
  End If
  ' RunMacro2 retry
  Dim r
  r = swApp.RunMacro2("C:\Users\zgzgd\Documents\DSH\sw_macro_probe.swb", "", "", 0)
  L "runmacro", "res=" & r
  WScript.Sleep 2500
  L "done", "probe2 complete"
End Sub

Call Main
