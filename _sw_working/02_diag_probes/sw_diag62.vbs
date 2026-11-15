' sw_diag62.vbs - z40 tooth variants: V1 current, V2 root arc at rb
Option Explicit
On Error Resume Next
Dim swApp, md, ft
Dim LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag62.log", 8, True)
Set lf = LOG
Sub L(tag, msg)
  lf.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Const PI = 3.14159265358979
Dim gPartTpl
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub PlaneSel(tag)
  md.ClearSelection2 True
  Dim b : b = md.Extension.SelectByID2("", "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag, "plane sel=" & b
End Sub
Sub SelSk(tag)
  Dim f
  Set f = md.FirstFeature
  Dim last, lastN
  Set last = Nothing
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then
      Set last = f
      lastN = f.Name
    End If
    Set f = f.GetNextFeature
  Loop
  If last Is Nothing Then
    L tag, "selsk NONE"
    Exit Sub
  End If
  Dim b : b = md.Extension.SelectByID2(lastN, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  L tag, "selsk " & lastN & " res=" & b
End Sub
Sub Extr(tag, flip, d)
  md.SketchManager.InsertSketch True
  SelSk tag
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L tag, "EXTR FAILED"
  Else
    L tag, "OK " & ft.Name
  End If
End Sub
Sub Line(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub
Sub Circ(x, y, r)
  md.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub
Sub Arc2(x1, y1, x2, y2, dirn)
  md.SketchManager.CreateArc 0, 0, 0, x1, y1, 0, x2, y2, 0, dirn
End Sub
Sub CountSegs(tag)
  On Error Resume Next
  WScript.Sleep 300
  Dim segs, ub
  Set segs = md.SketchManager.ActiveSketch.GetSketchSegments
  If Err.Number <> 0 Then
    L tag, "segs-ERR " & Err.Number
    Err.Clear
    Exit Sub
  End If
  ub = UBound(segs)
  L tag, "segs=" & (ub + 1)
End Sub

' rootArcR: rf for V1, rb for V2
Sub ToothV(z, j, rootR)
  Dim m : m = 0.002
  Dim al : al = 20 * PI / 180
  Dim rp : rp = m * z / 2
  Dim rb : rb = rp * Cos(al)
  Dim ra : ra = rp + m
  Dim invp : invp = Tan(al) - al
  Dim ua : ua = Sqr((ra / rb) * (ra / rb) - 1)
  Dim inva : inva = ua - Atn(ua)
  Dim htp : htp = PI / (2 * z)
  Dim psLbPrev : psLbPrev = (j - 1) * 2 * PI / z + 3 * PI / (2 * z) - invp
  Dim psRbJ : psRbJ = j * 2 * PI / z + htp + invp
  Dim psRaJ : psRaJ = psRbJ - inva
  Dim psLaPrev : psLaPrev = psLbPrev + inva
  Dim i, u, r1, r2, a1, a2
  Arc2 rootR * Cos(psLbPrev), rootR * Sin(psLbPrev), rootR * Cos(psRbJ), rootR * Sin(psRbJ), 1
  If rootR < rb - 0.0005 Then
    Line rootR * Cos(psRbJ), rootR * Sin(psRbJ), rb * Cos(psRbJ), rb * Sin(psRbJ)
  End If
  r1 = rb : a1 = psRbJ
  For i = 1 To 8
    u = ua * i / 8
    r2 = rb * Sqr(1 + u * u)
    a2 = psRbJ - (u - Atn(u))
    Line r1 * Cos(a1), r1 * Sin(a1), r2 * Cos(a2), r2 * Sin(a2)
    r1 = r2 : a1 = a2
  Next
  Dim ta
  For i = 1 To 4
    ta = psRaJ + (psLaPrev - psRaJ) * i / 4
    Line ra * Cos(psRaJ + (psLaPrev - psRaJ) * (i - 1) / 4), ra * Sin(psRaJ + (psLaPrev - psRaJ) * (i - 1) / 4), ra * Cos(ta), ra * Sin(ta)
  Next
  r1 = ra : a1 = psLaPrev
  For i = 7 To 0 Step -1
    u = ua * i / 8
    r2 = rb * Sqr(1 + u * u)
    a2 = psLbPrev + (u - Atn(u))
    Line r1 * Cos(a1), r1 * Sin(a1), r2 * Cos(a2), r2 * Sin(a2)
    r1 = r2 : a1 = a2
  Next
  If rootR < rb - 0.0005 Then
    Line rb * Cos(psLbPrev), rb * Sin(psLbPrev), rootR * Cos(psLbPrev), rootR * Sin(psLbPrev)
  End If
End Sub

Sub Ring42()
  PlaneSel "ring"
  Circ 0, 0, 0.042
  Circ 0, 0, 0.008
  Extr "ring", False, 0.018
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber

  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 500
  Ring42
  PlaneSel "V1"
  ToothV 40, 0, 0.0375
  CountSegs "V1"
  Extr "V1", False, 0.018

  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 500
  Ring42
  PlaneSel "V2"
  ToothV 40, 0, 0.0375877
  CountSegs "V2"
  Extr "V2", False, 0.018

  L "done", "diag62"
End Sub

Call Main
