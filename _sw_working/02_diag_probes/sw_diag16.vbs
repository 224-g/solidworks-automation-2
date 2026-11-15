' sw_diag16.vbs - feature tree walk of the diag13 gear
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag16.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Sub WalkTree
  On Error Resume Next
  Dim f, n
  Set f = md.FirstFeature
  n = 0
  Do While Not f Is Nothing
    n = n + 1
    L "FEAT " & n & " name=" & f.Name & " type=" & f.GetTypeName2
    Set f = f.GetNextFeature
  Loop
  L "total features=" & n
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
L "closed docs"
Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag13_gear.SLDPRT", 1)
WScript.Sleep 800
L "opened type=" & TypeName(md)
If Not md Is Nothing Then WalkTree
L "DONE"
lf.Close
WScript.Quit
