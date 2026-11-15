' sw_run_macro.vbs - run the SW macro probe via RunMacro2
Option Explicit
On Error Resume Next
Dim swApp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_run_macro.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Set swApp = CreateObject("SldWorks.Application")
L "start", "rev=" & swApp.RevisionNumber
Dim res
res = swApp.RunMacro2("C:\Users\zgzgd\Documents\DSH\sw_macro_probe.swb", "", "", 0)
L "runmacro", "res=" & res
WScript.Sleep 3000
L "done", "macro dispatched"
