' sw_exit.vbs - graceful SW shutdown
Option Explicit
Dim swApp
On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If Not swApp Is Nothing Then
  swApp.ExitApp
  WScript.Sleep 1000
End If
WScript.Quit
