' sw_asm_probe3.vbs - AddComponent5 variant matrix
Option Explicit
On Error Resume Next
Dim swApp, md, comp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_asm_probe3.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Const gP = "C:\Users\zgzgd\Documents\DSH\sw_parts8\"
Const gAsmT = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_assembly.asmdot"
Const gAsmA = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\Assembly.asmdot"

Sub Try(tag, tpl, cfgOpt, useRef, existCfg)
  swApp.CloseAllDocuments True
  WScript.Sleep 300
  Set md = swApp.NewDocument(tpl, 0, 0, 0)
  WScript.Sleep 700
  If md Is Nothing Then
    L tag, "newdoc FAILED"
    Exit Sub
  End If
  L tag, "newdoc type=" & md.GetType & " title=" & md.GetTitle
  Set comp = md.AddComponent5("c1", cfgOpt, "", useRef, existCfg, 0, 0, 0)
  If comp Is Nothing Then
    L tag, "ADD5 FAILED"
  Else
    L tag, "ADD5 OK name=" & comp.Name2
  End If
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "rev=" & swApp.RevisionNumber
  ' pre-check: can the part open?
  swApp.CloseAllDocuments True
  Set md = swApp.OpenDoc(gP & "plate.SLDPRT", 1)
  If md Is Nothing Then
    L "openplate", "FAILED"
  Else
    L "openplate", "OK type=" & md.GetType
    swApp.CloseDoc "plate.SLDPRT"
  End If
  ' A: gb template, ConfigOption 0, useRef False
  Try "A-gb-cfg0", gAsmT, 0, False, ""
  ' B: gb template, ConfigOption 1
  Try "B-gb-cfg1", gAsmT, 1, False, ""
  ' C: gb template, ConfigOption 2, existing config 默认
  Try "C-gb-cfg2", gAsmT, 2, False, ChrW(&H9ED8)&ChrW(&H8BA4)
  ' D: ANSI template, ConfigOption 0
  Try "D-ansi-cfg0", gAsmA, 0, False, ""
  ' E: gb + AddComponent4 with 默认
  swApp.CloseAllDocuments True
  WScript.Sleep 300
  Set md = swApp.NewDocument(gAsmT, 0, 0, 0)
  WScript.Sleep 700
  Set comp = md.AddComponent4("c4", ChrW(&H9ED8)&ChrW(&H8BA4), 0, 0, 0)
  If comp Is Nothing Then
    L "E-add4-def", "FAILED"
  Else
    L "E-add4-def", "OK name=" & comp.Name2
  End If
  L "done", "probe3 complete"
End Sub

Call Main
