' sw_asm_probe4.vbs - did the NULL AddComponent5 actually insert? walk the tree
Option Explicit
On Error Resume Next
Dim swApp, md, comp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_asm_probe4.log", 8, True)
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
  L "newasm", "type=" & md.GetType & " title=" & md.GetTitle
  Set comp = md.AddComponent5("plate", 0, "", False, "", 0.05, 0, 0)
  If comp Is Nothing Then
    L "add5", "NULL-return"
  Else
    L "add5", "OK name=" & comp.Name2
  End If
  WScript.Sleep 800
  ' walk the tree
  Dim f, i
  i = 0
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    i = i + 1
    If i > 60 Then
      L "tree", "CAP reached"
      Exit Do
    End If
    L "tree", i & " type=" & f.GetTypeName2 & " name=" & f.Name
    Set f = f.GetNextFeature
  Loop
  ' save and check size
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_asm_probe4.SLDASM", 0, 2)
  L "save", "res=" & res
  L "done", "probe4 complete"
End Sub

Call Main
