' sw_asm_a.vbs - Stage A: create assembly + insert 24 components with transforms
Option Explicit
On Error Resume Next
Dim swApp, md, comp, mathUtil, mathT
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_asm_a.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Const gAsmTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_assembly.asmdot"
Const gParts = "C:\Users\zgzgd\Documents\DSH\sw_parts8\"

' insert one component, optionally rotated about X or Y
Sub Ins(tag, name, x, y, z, rot)
  On Error Resume Next
  Set comp = md.AddComponent5(tag, gParts & name & ".SLDPRT", x, y, z)
  If comp Is Nothing Then
    L tag, "INSERT FAILED"
    Exit Sub
  End If
  If rot = "rx" Then
    ' R_x(-90): (x,y,z)->(x,z,-y)
    Dim arx
    arx = Array(1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1)
    Set mathT = mathUtil.CreateTransform(arx)
    comp.Transform2 = mathT
    L tag, "ok rx90"
  ElseIf rot = "ry" Then
    ' R_y(180): (x,y,z)->(-x,y,-z)
    Dim ary
    ary = Array(-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1)
    Set mathT = mathUtil.CreateTransform(ary)
    comp.Transform2 = mathT
    L tag, "ok ry180"
  Else
    L tag, "ok ident"
  End If
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "rev=" & swApp.RevisionNumber
  Set mathUtil = swApp.GetMathUtility
  swApp.CloseAllDocuments True
  WScript.Sleep 300
  Set md = swApp.NewDocument(gAsmTpl, 0, 0, 0)
  If md Is Nothing Then
    L "newasm", "FAILED"
    Exit Sub
  End If
  WScript.Sleep 800
  L "newasm", "ok"

  Ins "plate", "plate", 0, 0, 0, "rx"
  Ins "brktA", "bracket", 0.090, 0.012, 0, ""
  Ins "brktB", "bracket", 0.1503, 0.012, 0, ""
  Ins "tower", "tower", 0.2703, 0.012, 0, ""
  Ins "shaft1", "shaft1", 0.090, 0.077, -0.020, ""
  Ins "shaft2", "shaft2", 0.1503, 0.077, 0, ""
  Ins "gear1", "gear1", 0.090, 0.077, 0.012, ""
  Ins "gear2", "gear2", 0.1503, 0.077, 0.012, ""
  Ins "crank", "crank", 0.1503, 0.077, 0.040, ""
  Ins "pin", "pin", 0.1853, 0.077, 0.044, ""
  Ins "rod", "rod", 0.1853, 0.077, 0.052, ""
  Ins "slider", "slider", 0.2703, 0.078, 0.060, ""
  Ins "rail", "rail", 0.2703, 0.077, 0.084, "ry"
  Ins "motor", "motor", 0.090, 0.077, -0.020, ""
  Ins "anvil", "anvil", 0.3508, 0.032, 0.070, "rx"
  Ins "work", "work", 0.3858, 0.030, 0.045, "rx"
  Ins "bolt1", "bolt", 0.020, 0.017, -0.042, "rx"
  Ins "bolt2", "bolt", 0.412, 0.017, -0.042, "rx"
  Ins "bolt3", "bolt", 0.020, 0.017, 0.088, "rx"
  Ins "bolt4", "bolt", 0.412, 0.017, 0.088, "rx"
  Ins "nut1", "nut", 0.020, 0, -0.042, "rx"
  Ins "nut2", "nut", 0.412, 0, -0.042, "rx"
  Ins "nut3", "nut", 0.020, 0, 0.088, "rx"
  Ins "nut4", "nut", 0.412, 0, 0.088, "rx"

  md.Extension.SelectByID2 "", "", 0, 0, 0, False, 0, Nothing, 0
  md.ShowNamedView2 "*Isometric", 7
  WScript.Sleep 800
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_asm_stageA.SLDASM", 0, 2)
  L "save", "res=" & res
  Dim res2 : res2 = md.SaveBMP("C:\Users\zgzgd\Documents\DSH\sw_shots8\asm_stageA.bmp", 1280, 960)
  L "bmp", "res=" & res2
  L "done", "stage A complete"
End Sub

Call Main
