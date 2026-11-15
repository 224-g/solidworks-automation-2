Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_probe2.log", True, True)
On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
lf.WriteLine "attach: " & (Not swApp Is Nothing) & " err=" & Err.Number
Err.Clear
lf.WriteLine "rev=" & swApp.RevisionNumber & " err=" & Err.Number
Err.Clear
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
lf.WriteLine "newdoc: " & (Not md Is Nothing) & " err=" & Err.Number & " desc=" & Err.Description
lf.Close
