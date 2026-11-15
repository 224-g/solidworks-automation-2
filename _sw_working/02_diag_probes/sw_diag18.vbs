' sw_diag18.vbs - tree walk of saved build#2 parts to check for solid features
Option Explicit
Dim fso, lf, swApp, md, i
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag18.log", True, True)
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
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
Dim folder, file, pkg
pkg = "C:\Users\zgzgd\Documents\DSH\" & ChrW(&H7CBE)&ChrW(&H82F1)&ChrW(&H8054)&ChrW(&H8D5B)&"_"&ChrW(&H8BBE)&ChrW(&H8BA1)&ChrW(&H5305) & "\CAD"
Set folder = fso.GetFolder(pkg)
For Each file In folder.Files
  If LCase(fso.GetExtensionName(file.Name)) = "sldprt" Then
    Set md = swApp.OpenDoc(file.Path, 1)
    WScript.Sleep 500
    L "===== " & file.Name & " type=" & TypeName(md)
    If Not md Is Nothing Then WalkTree
    swApp.CloseDoc file.Name
  End If
Next
L "DONE"
lf.Close
WScript.Quit
