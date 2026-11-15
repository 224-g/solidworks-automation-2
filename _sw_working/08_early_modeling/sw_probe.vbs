Option Explicit
On Error Resume Next
Dim swApp, FSO, f
Set FSO = CreateObject("Scripting.FileSystemObject")
Set f = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_probe.log", True, False)
f.WriteLine "probe start " & Time
Dim i, got
got = False
For i = 1 To 60
  Set swApp = Nothing
  Set swApp = GetObject("", "SldWorks.Application")
  If swApp Is Nothing Then
    Set swApp = CreateObject("SldWorks.Application")
  End If
  If Not swApp Is Nothing Then
    f.WriteLine "SW attached rev=" & swApp.RevisionNumber
    got = True
    Exit For
  End If
  WScript.Sleep 5000
Next
If Not got Then
  f.WriteLine "FAILED to attach after 300s err=" & Err.Number & " " & Err.Description
Else
  Err.Clear
  swApp.Visible = True
  Dim md
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  If md Is Nothing Then
    f.WriteLine "NewDocument FAILED err=" & Err.Number & " " & Err.Description
  Else
    f.WriteLine "NewDocument OK title=" & md.GetTitle
  End If
End If
f.WriteLine "probe done " & Time
f.Close
