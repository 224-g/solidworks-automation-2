Option Explicit
Dim swApp, doc, fso, logFile
Set fso = CreateObject("Scripting.FileSystemObject")
Set logFile = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_save_log.txt", True)
On Error Resume Next

Set swApp = CreateObject("SldWorks.Application")
If Err.Number <> 0 Then
    logFile.WriteLine "FATAL CreateObject: " & Err.Number & " " & Err.Description
    logFile.Close
    WScript.Quit 1
End If

Set doc = swApp.ActiveDoc
If doc Is Nothing Then
    logFile.WriteLine "FATAL: no active doc"
    logFile.Close
    WScript.Quit 1
End If
logFile.WriteLine "Active doc title: " & doc.GetTitle()

doc.SaveAs3 "C:\Users\zgzgd\Documents\DSH\气缸体.SLDPRT", 0, 1
If Err.Number <> 0 Then
    logFile.WriteLine "FATAL save: " & Err.Number & " " & Err.Description
Else
    logFile.WriteLine "SAVED OK (silent) -> " & doc.GetTitle()
End If

logFile.Close
WScript.Quit 0
